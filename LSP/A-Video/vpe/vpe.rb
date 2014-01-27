# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'  
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../../../lib/result_forms'

include LspTargetTestScript

def run
  @equipment['dut1'].send_cmd("mkdir #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd('modprobe ti-vpe',@equipment['dut1'].prompt,10)
  if @equipment['dut1'].response.index(/fatal/i)
    set_result(FrameworkConstants::Result[:fail], "Unable to load vpe modules")
    return
  end
  ref_file_url = @test_params.params_chan.instance_variable_defined?(:@ref_video_url) ? @test_params.params_chan.ref_video_url[0] : nil
  ref_path, dut_src_file = get_file_from_url(@test_params.params_chan.video_url[0], ref_file_url)
  src_format = @test_params.params_chan.src_format[0]
  test_format = @test_params.params_chan.test_format[0]
  video_width = @test_params.params_chan.video_width[0].to_i
  video_height = @test_params.params_chan.video_height[0].to_i
  src_video_height = video_height
  interlace = 0
  if @test_params.params_chan.instance_variable_defined?(:@deinterlace)
    interlace = 1
    src_video_height = (video_height/2).to_i
  end
  translen = 1 + rand(3)
  dut_test_file = File.join(@linux_dst_dir,'video_test_file.yuv')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.yuv')
  @equipment['dut1'].send_cmd("rm -rf #{dut_test_file}", @equipment['dut1'].prompt)
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
  @equipment['dut1'].send_cmd("testvpem2m #{dut_src_file} #{video_width} #{src_video_height} #{src_format} #{dut_test_file} #{video_width} #{video_height} #{test_format} #{interlace} #{translen}", @equipment['dut1'].prompt, 300)
  dut_ip = get_ip_addr()
  scp_pull_file(dut_ip, dut_test_file, local_test_file)
  if @test_params.params_chan.instance_variable_defined?(:@auto)
    jnd_max = @test_params.params_chan.jnd_criteria[0].to_f
    test_results = @equipment['video_tester'].file_to_file_test({'ref_file' => ref_path, 'test_file' => local_test_file, 'data_format' => test_format, 'tst_data_format' => test_format, 'format' => [video_width,video_height,30],'video_height' => video_height , 'video_width' => video_width, 'num_frames' => 1000, 'metric_window' => [0,0,video_width,video_height]})
    luma = @equipment['video_tester'].get_jnd_scores({'component' => 'y'})
    chroma = @equipment['video_tester'].get_jnd_scores({'component' => 'chroma'})
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["JND luma",{:bgcolor => "4863A0"}], 
                                              ["JND chroma", {:bgcolor => "4863A0"}]])
    @results_html_file.add_rows_to_table(res_table,[["min #{luma.min} max #{luma.max}", "min #{chroma.min} max #{chroma.max}"]])
    if luma.max >= jnd_max || chroma.max >= jnd_max
      set_result(FrameworkConstants::Result[:fail], "Test Failed, converted file failed jnd test")
    else
      set_result(FrameworkConstants::Result[:pass], "Test passed")
	  end
	else
	  test_result = FrameworkConstants::Result[:nry]
	  test_string = ''
	  while(test_result == FrameworkConstants::Result[:nry])
	    res_win = ResultWindow.new("VPE #{video_width}x#{video_height} Test. Formats: #{src_format}->#{test_format}, Interlace #{interlace}, Tx length #{translen}")
	    video_info = {'pix_fmt' => test_format, 'width' => video_width,
	                  'height' => video_height, 'file_path' => ref_path,
	                  'sys'=> @equipment['server1']}
	    res_win.add_buttons({'name' => 'Play Ref file', 
                           'action' => :play_video, 
                           'action_params' => video_info})
      res_win.add_buttons({'name' => 'Play Test file', 
                           'action' => :play_video, 
                           'action_params' => video_info.merge({'file_path'=>local_test_file, 'pix_fmt' => test_format})})
      res_win.show()
      test_result, test_string = res_win.get_result()
    end
    set_result(test_result, test_string)
	end
  ensure
    @equipment['dut1'].send_cmd('modprobe -r ti-vpe', @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      raise "Unable to remove module, system may have hung"
    end
end

#Function to fetch the test file in the dut and host
def get_file_from_url(url, ref_file_url=nil)
  r_file_url = ref_file_url ? ref_file_url : url
  file_name = File.basename(url)
  r_file_name = File.basename(r_file_url)
  host_path = File.join(@linux_temp_folder, r_file_name)
  dut_path = File.join(@linux_dst_dir, file_name)
  @equipment['server1'].send_cmd("wget --no-proxy --tries=1 -T10 #{r_file_url} -O #{host_path}", @equipment['server1'].prompt, 300)
  @equipment['server1'].send_cmd("wget #{r_file_url} -O #{host_path}", @equipment['server1'].prompt, 300) if @equipment['server1'].response.match(/failed/im)
  raise "Host is unable to fetch file from #{r_file_url}" if @equipment['server1'].response.match(/error/im)
  @equipment['dut1'].send_cmd("wget #{url} -O #{dut_path}\n", @equipment['dut1'].prompt, 300)
  raise "Dut is unable to fetch file from #{url}" if @equipment['dut1'].response.match(/error/im)
 	[host_path, dut_path]
end

def play_video(params)
  p_fmt = case(params['pix_fmt'])
            when /yuyv/i, /uyvy/i, /vyuy/i, /yvyu/i
              params['pix_fmt'] + '422'
            when /yuv444/i, /nv16/i, /nv61/i
              puts "avplay does not support #{pix_fmt} format"
              return
            when /argb32/i, /abgr32/
              params['pix_fmt'].gsub(/\d+$/,'').gsub(/^a/,'') + 'a'
            when /yuv420/
              params['pix_fmt'] + 'p'
            else
              params['pix_fmt']
          end
  params['sys'].send_cmd("avplay -pixel_format #{p_fmt} -video_size #{params['width']}x#{params['height']} -f rawvideo #{params['file_path']}", params['sys'].prompt, 300)
end



