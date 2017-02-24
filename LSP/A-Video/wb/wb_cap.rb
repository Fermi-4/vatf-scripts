# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'  
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../dev_utils'
require File.dirname(__FILE__)+'/../../A-Display/drm/drm_utils'

include LspTargetTestScript

=begin
  Script to test DSS-WB capture mode, the test will set a mode using
  modetest, capture the displayed mode in the dut via DSS-WB capture,
  copy the captured mode to the host, and compare against a downloaded
  reference to determine pass/fail.
  Requires:
    -Adding "hdmi" capability to board's bench and staf registration
    command.
=end

def setup
  super
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && systemctl stop weston && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['server1'].send_cmd("mkdir #{@linux_temp_folder}") if !File.exists?(@linux_temp_folder) #make sure the data folder exists 
  @equipment['dut1'].send_cmd("ls #{@linux_dst_dir} || mkdir #{@linux_dst_dir}",@equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("rm #{@linux_dst_dir}/*",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("killall -9 kmstest; killall -9 memtester", @equipment['dut1'].prompt)
end

def run
  num_passed = 0
  total = 0
  @results_html_file.add_paragraph("")
  wb_devices = get_type_devices(@test_params.params_chan.ip_type[0])
  dut_test_file = File.join(@linux_dst_dir,'video_test_file.yuv')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.yuv')
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
  dut_ip = get_ip_addr()
  
  res_table = @results_html_file.add_table([["Device",{:bgcolor => "4863A0"}],
                                            ["Test Fmt", {:bgcolor => "4863A0"}],
                                            ["Connector",{:bgcolor => "4863A0"}], 
                                            ["Encoder", {:bgcolor => "4863A0"}],
                                            ["CRTC", {:bgcolor => "4863A0"}],
                                            ["Mode", {:bgcolor => "4863A0"}],
                                            ["Plane", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])

  formats = Hash.new(['default'])
  drm_info = get_properties()
  disp_idx = get_disp_idxs(drm_info)
  
  single_disp_modes, multi_disp_modes = get_test_modes(drm_info, formats, nil, ['XR24'])
  
  video_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')
  free_mem = 1920 * 1080 * 26 * 4
  single_disp_modes.each do |s_mode|
      next if s_mode[0]['mode'].match(/\d+x\d+i/)
      video_width, video_height = s_mode[0]['mode'].split('x').map(&:to_i)
      wb_devices.each do |dev|
        device = '/dev/'+dev
        @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --list-formats", @equipment['dut1'].prompt, 10)
        pix_fmts = @equipment['dut1'].response.scan(/(?<=Pixel\sFormat:\s')\w+/im)
        test_formats = @test_params.params_chan.instance_variable_defined?(:@test_formats) ? @test_params.params_chan.test_formats : pix_fmts
        num_frames = 10
        plane_info_str = "Scale: #{s_mode[0]['plane']['scale']}, pix_fmt: #{s_mode[0]['plane']['format']}" if s_mode[0]['plane']
        test_formats.each do |tst_format|
          @equipment['dut1'].send_cmd("ls #{dut_test_file} && rm #{dut_test_file}", @equipment['dut1'].prompt) #Remove previous test file if any
          @equipment['server1'].send_cmd("rm #{local_test_file}") if File.exists?(local_test_file) #Remove local test file, if exists 
          
          format_length = case(tst_format.downcase())
            when 'xr24','ar24'
              4
            when 'bg24','rg24'
              3
            when 'yuyv','uyvy'
              2
            when 'nv12'
              1.5
          end

          v4l2_log = nil
          use_memory(free_mem) do
            v4l2_log = set_mode(s_mode[0],/Video input set to.*?#{@equipment['dut1'].prompt}/im) do
              sleep 3
              @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} -i #{disp_idx[s_mode[0]['connectors_names'][0]]} --set-fmt-video=pixelformat=#{tst_format.upcase()} --stream-to=#{dut_test_file} --stream-mmap=6 --stream-count=#{num_frames} --stream-poll", @equipment['dut1'].prompt, 300)
            end
          end

          next if @test_params.params_chan.instance_variable_defined?(:@negative_test) || v4l2_log.match(/drm.*?\*ERROR\*|Atomic\s*test\s*failed/im)

          disp_captured = v4l2_log.match(/^Video\s*input\s*set\s*to\s*\d+.*?-\s*(.*?):\s*ok/i)[1].gsub(/[\/\\]+/,'-')

          scp_pull_file(dut_ip, dut_test_file, local_test_file)

          p_info = ''
          p_info = ["_P",
          s_mode[0]['plane']['xyoffset'][0],
          s_mode[0]['plane']['xyoffset'][1],
          s_mode[0]['plane']['scale'],
          s_mode[0]['plane']['format']].join('_') if s_mode[0]['plane']
          ref_file = "ref_capture_#{disp_captured}_#{s_mode[0]['mode']}#{p_info}.#{tst_format}.tar.xz"

          ref_path = get_ref do |base_uri|
             base_uri + '/host-utils/wb/ref-media/' + ref_file 
          end
          if !ref_path
            puts "No reference #{ref_file} file found"
            add_result_row(res_table, device, tst_format, s_mode, true,  "No reference #{ref_file} file found", plane_info_str)
            next
          end
          trunc_local_ref = ref_path
          if File.exists?(ref_path) && File.size(ref_path) != File.size(local_test_file)
            trunc_local_ref = ref_path+'.trunc'
            frame_size = (format_length * video_height * video_width).to_i
            @equipment['server1'].send_cmd("dd if=#{ref_path} of=#{trunc_local_ref} bs=#{frame_size} count=#{num_frames}", @equipment['server1'].prompt,600)
          end
          @equipment['server1'].send_cmd("md5sum #{trunc_local_ref} #{local_test_file} | grep -o '^[^ ]*'",@equipment['server1'].prompt, 600)
          qual_res = @equipment['server1'].response.split()
          res = qual_res[0].strip() == qual_res[1].strip()
          if !res
            t_string = "failed, converted file failed test (#{num_frames} frames), #{qual_res[0]} != #{qual_res[1]}"
          else
            num_passed += 1
            t_string = "passed (#{num_frames} frames)"
          end
          total += 1
          add_result_row(res_table, device, tst_format, s_mode, res,  t_string, plane_info_str)
        end            
    end
  end

  if @test_params.params_chan.instance_variable_defined?(:@negative_test)
    @equipment['dut1'].send_cmd("ls && echo 'Negative test passed!!!'", @equipment['dut1'].prompt)
    set_result(@equipment['dut1'].response.match(/^Negative test passed!!!/m) ? \
               FrameworkConstants::Result[:pass] :
               FrameworkConstants::Result[:fail], @equipment['dut1'].response)
  else
    set_result(num_passed != total || total == 0 ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],
             "#{num_passed}/#{total} passed ")
  end

end

def add_result_row(res_table, dev, fmt, s_mode, res, res_string, plane_info_str)
  @results_html_file.add_rows_to_table(res_table,[[dev,
                                           fmt,
                                           "#{s_mode[0]['connectors_names'][0]} (#{s_mode[0]['connectors_ids'][0]})", 
                                           s_mode[0]['encoder'],
                                           s_mode[0]['crtc_id'],
                                           "#{ s_mode[0]['mode']}@#{ s_mode[0]['framerate']}",
                                           s_mode[0]['plane'] ? plane_info_str : 'No plane',
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
end

def get_disp_idxs(drm_props)
  sorted_conns = drm_props["Connectors:"].sort_by { |conn| conn["id"] }
  result = {}
  sorted_conns.each_index { |i| result[sorted_conns[i]["name"].strip().downcase()] = i }
  result
end

#Function to set a drm mode, takes:
#  params, a hashe that defines a mode to set on
#          a display by specifying the following hash entries:
#
#     format => <value>                     :the format of the data to display, needs to be one of the following
#                                            /* YUV packed */
#                                                 UYVY
#                                                 VYUY
#                                                 YUYV
#                                                 YVYU
#                                            /* YUV semi-planar */
#                                                 NV12
#                                                 NV21
#                                                 NV16
#                                                 NV61
#                                            /* YUV planar */
#                                                 YU12
#                                                 YV12
#                                            /* RGB16 */
#                                                 AR12
#                                                 XR12
#                                                 AB12
#                                                 XB12
#                                                 RA12
#                                                 RX12
#                                                 BA12
#                                                 BX12
#                                                 AR15
#                                                 XR15
#                                                 AB15
#                                                 XB15
#                                                 RA15
#                                                 RX15
#                                                 BA15
#                                                 BX15
#                                                 RG16
#                                                 BG16
#                                            /* RGB24 */
#                                                 BG24
#                                                 RG24
#                                            /* RGB32 */
#                                                 AR24
#                                                 XR24
#                                                 AB24
#                                                 XB24
#                                                 RA24
#                                                 RX24
#                                                 BA24
#                                                 BX24
#                                                 AR30
#                                                 XR30
#                                                 AB30
#                                                 XB30
#                                                 RA30
#                                                 RX30
#                                                 BA30
#                                                 BX30
#     crtc_id => <value>                    : id of the crtc to used, for -P and optionally for -s and -v.
#                                             Optional if not specifying plane_params, otherwise required
#     connectors_ids => [id1,id2, ..., idx] : array of connector ids,
#     mode => <value>                       : string containing the mode, i.e. 800x480
#     framerate => <value>                  : expected frame rate in Hz
#    'plane' => (Optional) a Hash whose entries are:
#       width => <value>                      : width of the plane in pixels
#       height => <value>                     : height of the plane in pixels
#       scale => <value>                      : (Optional) fraction to scale, i.e. 0.5,
#       xyoffset => [<xoffset>,<yoffset>]     : (Optional) x,y offsets array in pixels, 
def set_mode(params, expected=nil, dut=@equipment['dut1'], timeout=600)
  regex = expected ? expected : /press\s*enter\s*to\s*exit.*?#{dut.prompt}/im
  response = ''
  p_string = ''
  if params['plane']
    p = params['plane']
    p_string = ' -p '
    p_string += "@#{p['id']}:"
    p_string += p['xyoffset'].join(',') + '-' if p['xyoffset']
    p_string += "#{(p['width'].to_f*p['scale']).to_i}x"
    p_string += "#{(p['height'].to_f*p['scale']).to_i}"
    p_string += ' -f '+ p['format'] if p['format']
  end
  t1 = Thread.new do
    dut.send_cmd("kmstest -c #{params['connectors_names'][0]} -r " \
                 "@#{params['crtc_id']}:#{params['mode']}@#{params['framerate']}" \
                 " -f XR24 #{p_string} 2>&1 &",
                 /#{regex}|Killed\s*kmstest|kmstest:\s*no\s*process\s*killed/, timeout)
    response = dut.response
  end
  if block_given?
    yield
  else
    t1.join(2)
  end
  dut.send_cmd("\nkillall -9 kmstest 2>&1; sleep 1", dut.prompt)
  t1.join()
  response
end
