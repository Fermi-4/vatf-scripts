# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'  
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../dev_utils'

include LspTargetTestScript

def run
  @equipment['dut1'].send_cmd("mkdir #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm  #{@linux_dst_dir}/*", @equipment['dut1'].prompt) #Make sure we have enough disk space for the f2f operations
  @equipment['dut1'].send_cmd('modprobe ti-vpe',@equipment['dut1'].prompt,10)
  if @equipment['dut1'].response.index(/fatal/i)
    set_result(FrameworkConstants::Result[:fail], "Unable to load vpe modules")
    return
  end
  vpe_dev = '/dev/' + get_type_devices('vpe')[0]
  ref_file_url = @test_params.params_chan.instance_variable_defined?(:@ref_video_url) ? @test_params.params_chan.ref_video_url[0] : nil
  ref_path, dut_src_file = get_file_from_url(@test_params.params_chan.video_url[0], ref_file_url)
  src_format = @test_params.params_chan.src_format[0]
  test_format = @test_params.params_chan.test_format[0]
  video_width = @test_params.params_chan.video_width[0].to_i
  video_height = @test_params.params_chan.video_height[0].to_i
  src_video_height = video_height
  src_video_width = video_width
  scaling = @test_params.params_chan.instance_variable_defined?(:@scaling) ? @test_params.params_chan.scaling[0].to_f : 1
  video_width, video_height = get_scaled_resolution(src_video_width, src_video_height, scaling) if scaling != 1
  interlace = 0
  if @test_params.params_chan.instance_variable_defined?(:@deinterlace)
    interlace = 1
    src_video_height = (src_video_height/2).to_i
  end
  translen = 1 + rand(3)
  dut_test_file = File.join(@linux_dst_dir,'video_test_file.yuv')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.yuv')
  @equipment['dut1'].send_cmd("rm -rf #{dut_test_file}", @equipment['dut1'].prompt)
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
  @equipment['dut1'].send_cmd("test-v4l2-m2m #{vpe_dev} #{dut_src_file} #{src_video_width} #{src_video_height} #{src_format} #{dut_test_file} #{video_width} #{video_height} #{test_format} #{interlace} #{translen}", @equipment['dut1'].prompt, 300)
  num_frames = @equipment['dut1'].response.match(/frames\s*left\s*(\d+)/im)[1].to_i + 1
  dut_ip = get_ip_addr()
  scp_pull_file(dut_ip, dut_test_file, local_test_file)
  if @test_params.params_chan.instance_variable_defined?(:@auto)
    format_length = case(test_format.downcase())
      when 'argb32','abgr32'
        4
      when 'rgb24','bgr24'
        3
      when 'yuyv','uyvy'
        2
      when 'nv12'
        1.5
    end
    ref_path = get_reference(@test_params.params_chan.video_url[0],
                              video_width,
                              video_height,
                              test_format,
                              interlace)
    trunc_local_ref = ref_path
    if File.size(ref_path) != File.size(local_test_file)
      trunc_local_ref = ref_path+'.trunc'
      frame_size = (format_length * video_height * video_width).to_i
      @equipment['server1'].send_cmd("dd if=#{ref_path} of=#{trunc_local_ref} bs=#{frame_size} count=#{num_frames}", @equipment['server1'].prompt,600)
    end
    @equipment['server1'].send_cmd("md5sum #{trunc_local_ref} #{local_test_file} | grep -o '^[^ ]*'",@equipment['server1'].prompt, 600)
    qual_res = @equipment['server1'].response.split()
    if qual_res[0].strip() != qual_res[1].strip()
      set_result(FrameworkConstants::Result[:fail], "Test Failed, converted file failed test (#{num_frames} frames), #{qual_res[0]} != #{qual_res[1]}")
    else
      set_result(FrameworkConstants::Result[:pass], "Test passed (#{num_frames} frames)")
	  end
	else
    require File.dirname(__FILE__)+'/../../../lib/result_forms'
	  test_result = FrameworkConstants::Result[:nry]
	  test_string = ''
	  while(test_result == FrameworkConstants::Result[:nry])
	    res_win = ResultWindow.new("VPE #{video_width}x#{video_height} Test. Formats: #{src_format}->#{test_format}, Interlace #{interlace}, Tx length #{translen}")
	    video_info = {'pix_fmt' => test_format.upcase(), 'width' => video_width,
	                  'height' => video_height, 'file_path' => ref_path,
	                  'sys'=> @equipment['server1']}
	    res_win.add_buttons({'name' => 'Play Ref file', 
                           'action' => :play_video, 
                           'action_params' => video_info})
      res_win.add_buttons({'name' => 'Play Test file', 
                           'action' => :play_video, 
                           'action_params' => video_info.merge({'file_path'=>local_test_file, 'pix_fmt' => test_format.upcase()})})
      res_win.show()
      test_result, test_string = res_win.get_result()
    end
    set_result(test_result, test_string)
	end
  ensure
    @equipment['dut1'].send_cmd('modprobe -r ti-vpe', @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      raise "Unable to remove module, system may have hung" if !is_uut_up?(@equipment['dut1'])
    end
end


def get_reference(video_url, width, height, format, interlace)
  ref_file = ['ref',
              File.basename(video_url), 
              'to',
              "#{width}x#{height}",
              format,
              interlace == 0 ? 'nodeinter' : 'deinter'].join('_') 
  ref_file += '.' + format + '.tar.xz'
  
  files = get_ref do |base_uri|
    base_uri + '/host-utils/vpe/ref-media/' + ref_file 
  end
  files[0]
end

