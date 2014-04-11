# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'
require File.dirname(__FILE__)+'/../../../lib/result_forms'
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/vpfe_utils'   

include LspTargetTestScript

def run
  capture_path = File.join(@linux_dst_dir, 'vpfe_capture_test.raw')
  local_test_file = File.join(@linux_temp_folder, 'vpfe_tst_file.raw')
  @equipment['dut1'].send_cmd("mkdir -p #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm -f #{capture_path}", @equipment['dut1'].prompt) #Make sure that test file is new
  test_result = true
  test_string = ''
  fmt_opts = get_fmt_options()
  capture_opts = get_sensor_capture_options()
  dut_ip = get_ip_addr()
  fmt_opts['frame-size'].each_index do |res_idx|
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Frame size",{:bgcolor => "4863A0"}], 
                                            ["Pixel format", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}],
                                            ["Test Params", {:bgcolor => "4863A0"}]])
    fmt_opts['pixel-format'].each_index do |pix_idx|
      resolution = fmt_opts['frame-size'][res_idx]
      pix_fmt = fmt_opts['pixel-format'][pix_idx]
      test_params = {}
      width,  height = resolution.split(/x/i)
      capture_opts.each do |opt,vals|
        if opt == '-w'
          test_params[opt] = resolution.strip()
        elsif opt == '-f'
          test_params[opt] = pix_fmt.strip()
        elsif opt == '-d'
          test_params[opt] = @test_params.params_chan.device[0] if @test_params.params_chan.instance_variable_defined?(:@device)
        elsif opt == '-l'
          test_params[opt] = @test_params.params_chan.iterations[0] if @test_params.params_chan.instance_variable_defined?(:@iterations)
          test_params[opt] = 1 if ["SBGGR8", "SGBRG8", "SGRBG8", "SRGGB8"].include?(pix_fmt)
        elsif opt == '-p'
          test_params[opt] = capture_path
        elsif opt == '-z'
          test_params[opt] = nil if @test_params.params_chan.instance_variable_defined?(:@compact)
#        elsif opt == '-k'    #Commented out, place holder for crop feature. Uncomment and change
#          left = 16*res_idx  #(if needed) once crop is implemented in sensorCapture app
#          top = 16*pix_idx
#          width = width.to_i - left
#          height = height.to_i - top
#          test_params[opt] = "#{left},#{top},#{width}x#{height}" if pix_idx % 2 == 1
        elsif vals.kind_of?(Set)
          test_params[opt] = vals.to_a[(pix_idx + rand(0..1)) % vals.length]
        elsif vals.kind_of?(Array)
          test_params[opt] = rand(vals[0].to_i..vals[1].to_i)
        elsif vals.kind_of?(Hash)
          if opt == "-m" && @test_params.params_chan.instance_variable_defined?(:@mem_mode)
            test_params[opt] = vals[@test_params.params_chan.mem_mode[0].downcase()]
          elsif opt == "-i" && @test_params.params_chan.instance_variable_defined?(:@input_type)
            test_params[opt] = vals[@test_params.params_chan.input_type[0].downcase()]
          else
            hash_vals = vals.values
            test_params[opt] = hash_vals[(pix_idx + rand(0..1)) % hash_vals.length]
          end
        end
      end
      puts "Test params: " + test_params.to_s
      trial_result = FrameworkConstants::Result[:nry]
	  while(trial_result == FrameworkConstants::Result[:nry])
	    @equipment['dut1'].send_cmd("rm -rf #{capture_path}", @equipment['dut1'].prompt)
        @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
        sensor_capture(test_params, width.to_f * height.to_f / 2000)
        scp_pull_file(dut_ip, capture_path, local_test_file)
	    res_win = ResultWindow.new("Capture #{resolution} Test. Pix fmt: #{pix_fmt}#{test_params.has_key?("-k") ? ', Cropped ' + test_params['-k'] : ''}")
	    video_info = {'pix_fmt' => pix_fmt, 'width' => width,
	                  'height' => height, 'file_path' => local_test_file,
	                  'sys'=> @equipment['server1']}
		res_win.add_buttons({'name' => 'Play Test file', 
		                     'action' => :play_video, 
		                     'action_params' => video_info})
        res_win.show()
        trial_result, res_string = res_win.get_result()
        test_string += ", #{resolution}:#{pix_fmt}" + res_string if trial_result == FrameworkConstants::Result[:fail]
      end
      test_result = test_result && (trial_result == FrameworkConstants::Result[:pass])
      @results_html_file.add_rows_to_table(res_table,[[resolution, 
			                                           pix_fmt,
			                                           trial_result == FrameworkConstants::Result[:pass] ? ["Passed",{:bgcolor => "green"}] :
			                                           ["Failed",{:bgcolor => "red"}],
			                                           res_string,
			                                           test_params.select{ |k,v|
			                                             !['-w', '-f', '-p'].include?(k)
			                                           }.to_s]])

    end
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "DRM Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Test failed" + test_string)
  end
end

def play_video(params)
  pixel_fmts = {"RGB565" => 'rgb565le',
                "RGB565X" => 'rgb565be',
	            "RGB32" => 'rgba',
	            "RGB24" => 'rgb24',
	            "YUYV2X8" => 'yuyv422',
	            "UYVY2X8" => 'uyvy422',
	            "NV12" => 'nv12',
	            "YUV420" => 'yuv420p',
	            #You need to download and compile raw2rgbpnm from git@gitorious.org:raw2rgbpnm/raw2rgbpnm.git
	            #for these formats
	            "SBGGR8" => "SBGGR8",
	            "SGBRG8" => "SGBRG8",
                "SGRBG8" => "SGRBG8",
                "SRGGB8" => "SRGGB8"}
  if ["SBGGR8", "SGBRG8", "SGRBG8", "SRGGB8"].include?(params['pix_fmt'])
    converted_file = params['file_path'].gsub(/[^\.]+$/, 'pnm')
    params['sys'].send_cmd("raw2rgbpnm -f #{pixel_fmts[params['pix_fmt']]} -s #{params['width']}x#{params['height']} #{params['file_path']} #{converted_file}", params['sys'].prompt, 600)
    params['sys'].send_cmd("avplay #{converted_file}", params['sys'].prompt, 600)
  else
    params['sys'].send_cmd("avplay -pixel_format #{pixel_fmts[params['pix_fmt']]} -video_size #{params['width']}x#{params['height']} -f rawvideo #{params['file_path']}", params['sys'].prompt, 600)
  end
end



