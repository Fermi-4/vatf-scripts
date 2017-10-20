# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'  
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../dev_utils'

include LspTargetTestScript

def run
  require File.dirname(__FILE__)+'/../../../lib/result_forms' if !@test_params.params_chan.instance_variable_defined?(:@auto)
  @equipment['dut1'].send_cmd("mkdir #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  base_url = @test_params.params_chan.instance_variable_defined?(:@base_url) ? @test_params.params_chan.base_url[0] : 'http://anonymous:anonymous@gtopentest-server.gt.design.ti.com/anonymous/common/Multimedia/Video/'
  src_video_height = @test_params.params_chan.video_height[0].to_i
  src_video_width = @test_params.params_chan.video_width[0].to_i
  wb_devices = get_type_devices(@test_params.params_chan.ip_type[0])
  dut_test_file = File.join(@linux_dst_dir,'video_test_file.yuv')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.yuv')
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
  dut_ip = get_ip_addr()
  test_result = true
  test_string = ''
  passed = 0
  failed = 0
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Device",{:bgcolor => "4863A0"}], 
                                            ["Src Fmt", {:bgcolor => "4863A0"}],
                                            ["Test Fmt", {:bgcolor => "4863A0"}],
                                            ["Scaling", {:bgcolor => "4863A0"}],
                                            ["Test res", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])
  wb_devices.each do |dev|
    device = '/dev/'+dev
    @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --list-formats", @equipment['dut1'].prompt, 10)
    pix_fmts = @equipment['dut1'].response.scan(/(?<=Pixel\sFormat:\s')\w+/im)
    prand = Random.new(src_video_height*src_video_width*pix_fmts.join('').bytes.inject(:+))
    test_formats = @test_params.params_chan.instance_variable_defined?(:@test_formats) ? @test_params.params_chan.test_formats : pix_fmts
    num_frames = 70
    mmap_buffs = 6
    pix_fmts.each do |src_format|
      @equipment['dut1'].send_cmd("rm  #{@linux_dst_dir}/*", @equipment['dut1'].prompt, 30) #Make sure we have enough disk space for the f2f operations
      ref_url = File.join(base_url, get_file_url_suffix(src_video_width, src_video_height, src_format))
      ref_path, dut_src_file = get_file_from_url(ref_url, ref_url)
      test_formats.each do |test_format|
        scaling = @test_params.params_chan.instance_variable_defined?(:@scaling) ? @test_params.params_chan.scaling[0].to_f : get_scaling(src_video_width, src_video_height, prand)
        video_width, video_height = get_scaled_resolution(src_video_width, src_video_height, scaling)
        format_length = @test_params.params_chan.instance_variable_defined?(:@negative_test) ? 4 : get_format_length(test_format)
        @equipment['dut1'].send_cmd("rm #{dut_test_file}", @equipment['dut1'].prompt, 30) #Remove previous test file if any
        use_memory(src_video_width.to_i * src_video_height.to_i * 8 * format_length + 5*2**20) do
          @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --set-fmt-video-out=width=#{src_video_width},height=#{src_video_height},pixelformat=#{src_format.upcase()} --stream-from=#{dut_src_file} --set-fmt-video=width=#{video_width},height=#{video_height},pixelformat=#{test_format.upcase()} --stream-to=#{dut_test_file} --stream-mmap=#{mmap_buffs} --stream-out-mmap=#{mmap_buffs} --stream-count=#{num_frames} --stream-poll", @equipment['dut1'].prompt, 300)
          #@equipment['dut1'].send_cmd("/home/root/tests/wbtest -d #{device} -i #{dut_src_file} -j #{src_video_width}x#{src_video_height} -k #{src_format.upcase()} -o #{dut_test_file} -p #{video_width}x#{video_height} -q #{test_format.upcase()} -n 70", @equipment['dut1'].prompt, 300)
        end
        next if @test_params.params_chan.instance_variable_defined?(:@negative_test)
        scp_pull_file(dut_ip, dut_test_file, local_test_file)
        if @test_params.params_chan.instance_variable_defined?(:@auto)
          ref_path = get_reference(ref_url,
                                   video_width,
                                   video_height,
                                   test_format)
          trunc_local_ref = ref_path
          trunc_local_tst = local_test_file
          count = num_frames
          frame_size = (format_length * video_height * video_width).to_i
          @equipment['server1'].log_info("Ref file size = #{File.size(ref_path)}, frame size = #{frame_size}, frames = #{File.size(ref_path)/frame_size}")
          @equipment['server1'].log_info("Test file size = #{File.size(local_test_file)}, frame size = #{frame_size}, frames = #{File.size(local_test_file)/frame_size}")
          if File.size(ref_path) > File.size(local_test_file)
            trunc_local_ref = ref_path+'.trunc'
            count = File.size(local_test_file)/frame_size
            @equipment['server1'].send_cmd("dd if=#{ref_path} of=#{trunc_local_ref} bs=#{frame_size} count=#{count}", @equipment['server1'].prompt,600)
          elsif File.size(local_test_file) > File.size(ref_path)
            trunc_local_tst = local_test_file+'.trunc'
            count = File.size(ref_path)/frame_size
            @equipment['server1'].send_cmd("dd if=#{local_test_file} of=#{trunc_local_tst} bs=#{frame_size} count=#{count}", @equipment['server1'].prompt,600)
          end
          @equipment['server1'].send_cmd("md5sum #{trunc_local_ref} #{trunc_local_tst} | grep -o '^[^ ]*'",@equipment['server1'].prompt, 600)
          qual_res = @equipment['server1'].response.split()
          if qual_res[0].strip() != qual_res[1].strip() || count < num_frames
            t_result = FrameworkConstants::Result[:fail]
            t_string = "failed, #{count} frames processed" + (count < num_frames ? "" : ", #{qual_res[0]} != #{qual_res[1]}")
          else
            t_result = FrameworkConstants::Result[:pass]
            t_string = "passed #{count} frames processed"
          end
        else
          t_result = FrameworkConstants::Result[:nry]
          while(t_result == FrameworkConstants::Result[:nry])
            res_win = ResultWindow.new("WriteBack #{video_width}x#{video_height} Test. Formats: #{src_format}->#{test_format}")
            video_info = {'pix_fmt' => src_format.upcase(), 'width' => src_video_width,
                          'height' => src_video_height, 'file_path' => ref_path,
                          'sys'=> @equipment['server1']}
            res_win.add_buttons({'name' => 'Play Ref file', 
                                 'action' => :play_video, 
                                 'action_params' => video_info})
            res_win.add_buttons({'name' => 'Play Test file', 
                                 'action' => :play_video, 
                                 'action_params' => video_info.merge({'file_path'=>local_test_file,
                                                                      'pix_fmt' => test_format.upcase(),
                                                                      'width' => video_width,
                                                                      'height' => video_height})})
            res_win.show()
            t_result, t_string = res_win.get_result()
          end
        end
        if t_result == FrameworkConstants::Result[:pass]
          test_result = test_result && true
          passed += 1
        else
          test_string += "#{dev}@#{video_width}x#{video_height}+#{src_format}->#{test_format}: #{t_string}; "
          test_result = false
          failed += 1
        end
        @results_html_file.add_rows_to_table(res_table,[[device, 
                                           src_format,
                                           test_format,
                                           scaling.to_s,
                                           "#{video_width}x#{video_height}",
                                           t_result == FrameworkConstants::Result[:pass] ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           t_string]])
      end
    end
	end
  if @test_params.params_chan.instance_variable_defined?(:@negative_test)
    @equipment['dut1'].send_cmd("ls && echo 'Negative test passed!!!'", @equipment['dut1'].prompt)
    set_result(@equipment['dut1'].response.match(/^Negative test passed!!!/m) ? \
               FrameworkConstants::Result[:pass] :
               FrameworkConstants::Result[:fail], @equipment['dut1'].response)
  else
    set_result(test_result && !wb_devices.empty? ? FrameworkConstants::Result[:pass] : FrameworkConstants::Result[:fail], "Passed: #{passed}, Failed: #{failed}\n" + test_string)
  end
end


def get_file_url_suffix(width, height, format)
  res = {}

  res['352x288'] = 'cif/waterfall_cif'
  res['176x144'] = 'qcif/mobile_qcif'
  res['720x480'] = 'SDTV/shields_720x480_420p_252frames'
  res['720x576'] = 'SDTV/traffic_720x576_420p_200frames'
  res['1920x1080'] = '1920x1080/BigBuckBunny_1920_1080_24fps_100frames'

  get_video_ext(format).upcase() + '/' + res["#{width}x#{height}"] + '.' + get_video_ext(format)
end

def get_video_ext(format)
  fmt = format.downcase()
  result = Hash.new(fmt)
  
  result['xr24']='bgra'
  result['ar24']='bgra'
  result['nm12']='nv12'
  
  result[fmt]
end

def get_scaling(width, height, prand)
  if (width.to_i * height.to_i) > 101376
    prand.rand()/2 + 0.5
  else
    prand.rand() + 1
  end
end

def get_reference(video_url, width, height, format)
  ref_file = ['ref',
              File.basename(video_url), 
              'to',
              "#{width}x#{height}",
              format].join('_') 
  ref_file += '.' + format + '.tar.xz'
  
  files = get_ref do |base_uri|
    base_uri + '/host-utils/wb/ref-media/' + ref_file 
  end
  files[0]
end
