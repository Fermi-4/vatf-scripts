# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'  
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../dev_utils'
require File.dirname(__FILE__)+'/wb_cap'

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
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && /etc/init.d/weston stop && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("ls #{@linux_dst_dir} || mkdir #{@linux_dst_dir}",@equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("rm #{@linux_dst_dir}/*",@equipment['dut1'].prompt) 
end

def run
  num_passed = 0
  total = 0
  wb_devices = get_type_devices(@test_params.params_chan.ip_type[0])
  dut_test_file = File.join(@linux_dst_dir,'video_test_file.yuv')
  
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
  multi_disp_modes.select!{|s_mode| s_mode[0]['plane'] && s_mode[s_mode.length-1]['plane']}

  video_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')

  multi_disp_modes.each do |s_mode|
    video_width, video_height = s_mode[0]['mode'].split('x').map(&:to_i)
    wb_devices.each do |dev|
      device = '/dev/'+dev
      @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --list-formats", @equipment['dut1'].prompt, 10)
      pix_fmts = @equipment['dut1'].response.scan(/(?<=Pixel\sFormat:\s')\w+/im)
      test_formats = @test_params.params_chan.instance_variable_defined?(:@test_formats) ? @test_params.params_chan.test_formats : pix_fmts
      num_frames = 10
      plane_info_str = "Scale: #{s_mode[0]['plane']['scale']}, pix_fmt: #{s_mode[0]['plane']['format']}" if s_mode[0]['plane']
      test_formats.each do |tst_format|
        
        v4l2_log = set_mode(s_mode,/Video input set to.*?#{@equipment['dut1'].prompt}/im) do
          sleep 3
          @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} -i #{disp_idx[s_mode[0]['connectors_names'][0]]} --set-fmt-video=pixelformat=#{tst_format.upcase()} --stream-to=#{dut_test_file} --stream-mmap=6 --stream-count=#{num_frames} --stream-poll", @equipment['dut1'].prompt, 300)
        end

      end        
    end
  end

  @equipment['dut1'].send_cmd("ls && echo 'Negative test passed!!!'", @equipment['dut1'].prompt)
  set_result(@equipment['dut1'].response.match(/^Negative test passed!!!/m) ? \
               FrameworkConstants::Result[:pass] :
               FrameworkConstants::Result[:fail], @equipment['dut1'].response)
end

def get_disp_idxs(drm_props)
  sorted_conns = drm_props["Connectors:"].sort_by { |conn| conn["id"] }
  result = {}
  sorted_conns.each_index { |i| result[sorted_conns[i]["name"].strip().downcase()] = i }
  result
end
