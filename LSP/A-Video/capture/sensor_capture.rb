# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'
require File.dirname(__FILE__)+'/../../../lib/result_forms'
require File.dirname(__FILE__)+'/../../../lib/utils'

include LspTargetTestScript

def run
  set_capture_app()
  capture_path = File.join(@linux_dst_dir, 'video_capture_test.raw')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')
  @equipment['dut1'].send_cmd("mkdir -p #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm -f #{capture_path}", @equipment['dut1'].prompt) #Make sure that test file is new
  test_result = true
  test_string = ''
  ip_type = @test_params.params_chan.capture_ip_type[0]
  cap_devs = get_capture_devices(ip_type)
  raise "No capture device of type #{ip_type} found" if !cap_devs
  cap_devs.each do |dev|
    capture_device = '/dev/' + dev
    fmt_opts = get_fmt_options(capture_device)
    capture_opts = get_sensor_capture_options(capture_device)
    dut_ip = get_ip_addr()
    fmt_opts['frame-size'].each_index do |res_idx|
      @results_html_file.add_paragraph("")
      res_table = @results_html_file.add_table([["Capture Device",{:bgcolor => "4863A0"}],
                                              ["Frame size",{:bgcolor => "4863A0"}], 
                                              ["Pixel format", {:bgcolor => "4863A0"}],
                                              ["Result", {:bgcolor => "4863A0"}],
                                              ["Comment", {:bgcolor => "4863A0"}],
                                              ["Test Params", {:bgcolor => "4863A0"}]])
      fmt_opts['pixel-format'].each_index do |pix_idx|
        resolution = fmt_opts['frame-size'][res_idx]
        pix_fmt = fmt_opts['pixel-format'][pix_idx]
        width,  height = resolution.split(/x/i)
        test_params = get_test_opts(capture_opts, resolution, pix_fmt, capture_path)
        puts "Test params: " + test_params.to_s
        trial_result = FrameworkConstants::Result[:nry]
        while(trial_result == FrameworkConstants::Result[:nry])
          @equipment['dut1'].send_cmd("rm -rf #{capture_path}", @equipment['dut1'].prompt)
          @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
          sensor_capture(test_params, width.to_f * height.to_f / 2000)
          if @equipment['dut1'].response.downcase.include?('unsupported video format')
            trial_result = FrameworkConstants::Result[:pass]
            res_string = "Negative test"
            break 
          end
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
        @results_html_file.add_rows_to_table(res_table,[[capture_device,
                                                         resolution, 
                                                         pix_fmt,
                                                         trial_result == FrameworkConstants::Result[:pass] ? ["Passed",{:bgcolor => "green"}] :
                                                         ["Failed",{:bgcolor => "red"}],
                                                         res_string,
                                                         test_params.select{ |k,v|
                                                           !['-w', '-f', '-p'].include?(k)
                                                         }.to_s]])
      end
    end
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "Capture Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Capture Test failed" + test_string)
  end
end

def play_video(params)
  pixel_fmts = {"RGB565" => 'rgb565le',
                "RGB565X" => 'rgb565be',
                "RGB32" => 'rgba',
                "RGB24" => 'rgb24',
                "YUYV2X8" => 'yuyv422',
                "YUYV" => 'yuyv422',
                "UYVY2X8" => 'uyvy422',
                "UYVY" => 'uyvy422',
                "NV12" => 'nv12',
                "YUV420" => 'yuv420p',
                #You need to download and compile raw2rgbpnm from git@gitorious.org:raw2rgbpnm/raw2rgbpnm.git
                #for these formats
                "SBGGR8" => "SBGGR8",
                "SGBRG8" => "SGBRG8",
                "SGRBG8" => "SGRBG8",
                "SRGGB8" => "SRGGB8",
                ##Setting these formats to YUYV since the function will call the tx functions on the file
                "VYUY" => 'yuyv422',
                "YVYU" => 'yuyv422',
                }
  if ["SBGGR8", "SGBRG8", "SGRBG8", "SRGGB8"].include?(params['pix_fmt'])
    converted_file = params['file_path'].gsub(/[^\.]+$/, 'pnm')
    src_file = params['file_path'].gsub(/[^\.]+$/, '1fr')
    [converted_file, src_file].each {|f| File.delete(f) if File.exist?(f)} 
    frame_size = params['width'].to_i * params['height'].to_i
    num_frames = File.size(params['file_path'])/frame_size
    if num_frames > 0
      File.open(params['file_path'],'rb') do |ifd|
        File.open(src_file,'wb') do |ofd|
          ifd.read((num_frames*frame_size/2).to_i)
          ofd.write(ifd.read(frame_size))
        end
      end
      params['sys'].send_cmd("raw2rgbpnm -f #{pixel_fmts[params['pix_fmt']]} -s #{params['width']}x#{params['height']} #{src_file} #{converted_file}", params['sys'].prompt, 600)
      params['sys'].send_cmd("avplay #{converted_file}", params['sys'].prompt, 600)
    end
  else
    conv_file = params['file_path']
    if params['pix_fmt'] == "VYUY"
      conv_file += '.conv'
      vyuy_to_yuyv(params['file_path'], conv_file)
    elsif params['pix_fmt'] == "YVYU"
      conv_file += '.conv'
      yvyu_to_yuyv(params['file_path'], conv_file)
    end
    params['sys'].send_cmd("avplay -pixel_format #{pixel_fmts[params['pix_fmt']]} -video_size #{params['width']}x#{params['height']} -f rawvideo #{conv_file}", params['sys'].prompt, 600)
  end
end

def get_capture_devices(ip_type)
  @equipment['dut1'].send_cmd("ls /sys/class/video4linux/")
  video_devs = @equipment['dut1'].response.scan(/video\d+\s+/im)
  result = []
  video_devs.each do |dev|
    @equipment['dut1'].send_cmd("cat /sys/class/video4linux/#{dev.strip()}/name")
    result << dev.strip if @equipment['dut1'].response.downcase.include?(ip_type.downcase)
  end
  return result.empty? ? nil : result
end

def set_capture_app()
  res = @equipment['dut1'].send_cmd("yavta")
  if res.include?("command not found")
    require File.dirname(__FILE__)+'/sens_cap_utils'
  else
    require File.dirname(__FILE__)+'/yavta_utils'
  end
end

def vyuy_to_yuyv(in_file, out_file)
  out_f = File.open(out_file, 'wb') do |ofd|
    in_f = File.open(in_file, 'rb') do |ifd|
      while(!ifd.eof?)
        pixels = ifd.read(4)
        ofd.write(pixels[1..3])
        ofd.write(pixels[0])
      end
    end
  end
end

def yvyu_to_yuyv(in_file, out_file)
  out_f = File.open(out_file, 'wb') do |ofd|
    in_f = File.open(in_file, 'rb') do |ifd|
      while(!ifd.eof?)
        pixels = ifd.read(4)
        ofd.write(pixels[0])
        ofd.write(pixels[1..3].reverse)
      end
    end
  end
end


