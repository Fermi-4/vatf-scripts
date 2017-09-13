=begin
Script to test capture functionality. It can be run in two modes:
  - auto: The script performs a capture and compares against
          previously saved references to determine pass/fail. Requires
          auto param defined in test definition, and an entry in the
          bench file params field of syntax:
            'sensor_info' => {'id' => <sensor box unique id>,
                              ['light' => {<light src power object> => <port id>}]
                             }
          where:
            * 'id' references a global unique identifier for the sensor,
                 that is used to retrieved the appropiate reference
                 files for the setup
            * 'light': is an optional entry that reference the object in
                 the bench that is used to turn on the light source that
                 iluminates the target of the capture
            
          for example, additional bench definition required for this 
          test could be:
            pwr = EquipmentInfo.new("power_controller", "192.168.0.10")
            pwr.telnet_ip = '192.168.0.10'
            pwr.driver_class_name = 'DevantechRelayController'
            
            dut = EquipmentInfo.new("dra7xx-evm", "linux_videosensor")
              .
              .
              .
            dut.params = {'sensor_info' => 
                            {'id' => 'ov10633_box4',
                             'light' => {pwr => 1}
                            }
                         }
  - semi-auto: The scripts performs a capture and pops-up a window so
          the user can play the captured frames and click on pass or
          fail. 
=end
require File.dirname(__FILE__)+'/../../default_target_test'
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../dev_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../../A-Display/drm/capture_utils'
require 'matrix'
require 'fileutils'

include LspTargetTestScript
include CaptureUtils

def run
  if @equipment['dut1'].params['sensor_info']['light']
    light_info = @equipment['dut1'].params['sensor_info']['light'].keys[0]
    add_equipment('light', light_info) do |e_class, log_path|
      e_class.new(light_info, log_path)
    end
    @equipment['light'].switch_off(@equipment['dut1'].params['sensor_info']['light'].values[0])
  end
  cap_rand = Random.new(1492694516)
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt)
  capture_path = File.join(@linux_dst_dir, 'video_capture_test.raw')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')
  @equipment['dut1'].send_cmd("mkdir -p #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm -f #{capture_path}", @equipment['dut1'].prompt) #Make sure that test file is new
  test_result = true
  test_string = ''
  ip_type = @test_params.params_chan.capture_ip_type[0]
  cap_devs = get_type_devices(ip_type)
  raise "No capture device of type #{ip_type} found" if !cap_devs
  set_capture_app(ip_type)
  capture_mem_needed = 1600*1200*48
  cap_devs.each do |dev|
    capture_device = '/dev/' + dev
    if @equipment['dut1'].name == 'omapl138-lcdk'
      next if @equipment['dut1'].send_cmd("v4l2-ctl -d #{capture_device} -I", @equipment['dut1'].prompt, 10).match(/S-Video/im)
    end
    fmt_opts = get_fmt_options(capture_device)
    capture_opts = get_sensor_capture_options(capture_device)
    dev_interrupt_info = ''
    if @test_params.params_chan.instance_variable_defined?(:@video_standard)
      dev_interrupt_info = @test_params.params_chan.video_standard[0].upcase()+'_'
      raise "Unable to set the video standard on the input" if !set_video_standard(@test_params.params_chan.video_standard[0], capture_device)
    elsif cap_devs.length > 1
      @equipment['dut1'].send_cmd("hexdump /sys/class/video4linux/#{dev}/device/of_node/interrupts",@equipment['dut1'].prompt,10)
      dev_interrupt_info = (@equipment['dut1'].response.scan(/^[0-9A-F ]+/im)*'').gsub(/\s+/,'').sub(/0+/,'') + "_"
    end
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
        resolution = @test_params.params_chan.instance_variable_defined?(:@scaling) ? fmt_opts['frame-size'][0] : fmt_opts['frame-size'][res_idx]
        pix_fmt = fmt_opts['pixel-format'][pix_idx]
        width,  height = resolution.split(/x/i)
        f_length = get_format_length(pix_fmt)
        width,  height = get_scaled_resolution(width, height, cap_rand.rand()) if @test_params.params_chan.instance_variable_defined?(:@scaling)
        test_params = get_test_opts(capture_opts, "#{width}x#{height}", pix_fmt, capture_path)
        puts "Test params: " + test_params.to_s
        trial_result = FrameworkConstants::Result[:nry]
        play_width = ''
        play_height = ''
        while(trial_result == FrameworkConstants::Result[:nry])
          res_string = ''
          @equipment['dut1'].send_cmd("rm -rf #{capture_path}", @equipment['dut1'].prompt, 100)
          @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
          cap_width, cap_height = nil
          use_memory(capture_mem_needed) do
            cap_width, cap_height = sensor_capture(test_params, [width.to_f * height.to_f / 1000, 30].max)
          end
          scp_pull_file(dut_ip, capture_path, local_test_file)
          play_width = cap_width && cap_height ? cap_width : width
          play_height = cap_width && cap_height ? cap_height : height
          if @equipment['dut1'].response.downcase.include?('unsupported video format')
            trial_result = FrameworkConstants::Result[:pass]
            res_string = "Negative test"
            break 
          end
          if @test_params.params_chan.instance_variable_defined?(:@auto)
            l_files = []
            filter = nil
            filter = 'hqdn3d=20:20' if sub8bit_ch_fmts_list.include?(pix_fmt)
            l_files << convert_to_argb(local_test_file, play_width, play_height, pix_fmt, filter)
            format_length = 4
            test_frame = File.join(@linux_temp_folder,"tstFrame#{play_width}x#{play_height}.#{pix_fmt}.argb")
            ref_name = "#{dev_interrupt_info}#{@equipment['dut1'].params['sensor_info']['id']}_#{play_width}x#{play_height}.4.argb"
            brightness_adj = 0
            if raw_sensor_fmts_list.include?(pix_fmt) || sub8bit_ch_fmts_list.include?(pix_fmt)
              format_length = 1 if raw_sensor_fmts_list.include?(pix_fmt)
              ref_name = "#{dev_interrupt_info}#{@equipment['dut1'].params['sensor_info']['id']}_#{play_width}x#{play_height}.#{pix_fmt}.argb"
            end
            video_ref_file = get_ref() do |base_url|
              [base_url,'host-utils', 'sensor-capture', 'ref-media', "#{ref_name}.tar.xz"].join('/')
            end
            if !video_ref_file
              res_string = " Unable to get ref file\n"
              trial_result = FrameworkConstants::Result[:fail]
              next
            end
            if format_length == 4
              @equipment['server1'].send_cmd("dd if=#{l_files[0]} of=#{test_frame} bs=$((#{play_width}*#{play_height}*4)) count=1 skip=60")
              video_ref_file.clone.each do |r_file|           
                brightness_adj = get_brightness_adjustment(r_file, test_frame, play_width, play_height)
                if brightness_adj > 0
                  adj_video = r_file + '.adj'
                  adjust_4ch_frames(video_ref_file[0], adj_video, play_width, play_height,
                                 [1]*4, [0]+[-brightness_adj]*3)
                  video_ref_file << adj_video
                elsif brightness_adj < 0
                  adj_video = l_files[0] + '.adj'
                  adjust_4ch_frames(l_files[0], adj_video, play_width, play_height,
                                 [1]*4, [0]+[brightness_adj]*3)
                  l_files << adj_video
                end
              end
            end
            qual_res = false
            result = []
            first_frame = 17
            pass_criteria = 90
            qual_res = false
            frame_pass_info = {}
            failed_frames = -1
            fail_info = []
            video_ref_file.each do |v_ref|
              l_files.each do |l_file|
                fail_info << {'file' => l_file, 'fr' => -1, 'score' => 300}
                fail_count = 0
                result = get_psnr_ssim_argb(v_ref, l_file, play_width, play_height, format_length)
                if result.empty? || !result[first_frame]
                  trial_result = FrameworkConstants::Result[:fail]
                  res_string = "-Capture test failed, could not asses quality\n"
                  break
                end
                qual_res = true
                frame_pass_info["#{v_ref}/#{l_file}"] = [result.length+1, first_frame-1]
                result[first_frame..-1].each_with_index do |h, i|
                  t_frame_num = i+first_frame
                  frame_res = h['ssim']['r'] >= pass_criteria && h['ssim']['g'] >= pass_criteria && h['ssim']['b'] >= pass_criteria
                  qual_res &= frame_res
                  if !frame_res
                    fail_count += 1
                    fail_sum = h['ssim']['r'] + h['ssim']['g'] + h['ssim']['b']
                    fail_info[-1].merge!({'fr' => t_frame_num, 'score' => fail_sum}) if fail_info[-1]['score'] > fail_sum
                  end
                  frame_pass_info["#{v_ref}/#{l_file}"][0] = t_frame_num if frame_res && frame_pass_info["#{v_ref}/#{l_file}"][0] > t_frame_num
                  frame_pass_info["#{v_ref}/#{l_file}"][1] = t_frame_num if frame_res && frame_pass_info["#{v_ref}/#{l_file}"][1] < t_frame_num
                  #vals = Vector::elements(h['ssim'].values)
                  #ref = Vector::elements(Array.new(vals.size, 100))
                  #t_val = 1.0 - vals.inner_product(ref)/ref.magnitude()**2
                  #qual_res &= t_val <= pass_criteria
                  #res_string+="-Frame ##{i+first_frame}: failed SSIM #{(1-t_val)*100}%\n" if t_val > pass_criteria
                end
                failed_frames = fail_count if failed_frames < 0 || fail_count < failed_frames
                break if qual_res
              end
              break if qual_res
            end
            #Check if exposure setting changed during capture
            if !qual_res
              first_ps = frame_pass_info.select { |r_n, fr_a| fr_a[0] == first_frame }
              last_ps = frame_pass_info.select { |r_n, fr_a| fr_a[1] == result.length - 1 }
              @equipment['server1'].log_info("Exposure change data #{first_ps.to_s} and #{last_ps.to_s}")
              first_ps.each do |f_n, f_vals|
                last_ps.each do |l_n, l_vals|
                  qual_res = true if l_vals[0] == (f_vals[1] + 1)
                  break if qual_res
                end
                break if qual_res
              end 
            end
            if qual_res
              trial_result = FrameworkConstants::Result[:pass]
              res_string = "-Capture Result: #{result.length - first_frame} video frames passed\n"
            else
              res_string = "-Capture Result: #{failed_frames} video frames failed\n"
              trial_result = FrameworkConstants::Result[:fail]
              if File.exists?(local_test_file)
                bad_frame = fail_info.max { |a,b| a['score'] <=> b['score'] }
                @equipment['server1'].send_cmd("dd if=#{bad_frame['file']} of=#{test_frame} bs=$((#{play_width}*#{play_height}*#{format_length != 1 ? 4 : 1})) count=1 skip=#{bad_frame['fr']}")
                @equipment['server1'].send_cmd("tar -Jcvf #{test_frame}.tar.xz #{test_frame}")
                failed_frame_info = upload_file("#{test_frame}.tar.xz")
                @results_html_file.add_paragraph("failed_#{play_width}x#{play_height}_#{pix_fmt}.argb.tar.xz",nil,nil,failed_frame_info[1]) if failed_frame_info
                FileUtils.mv(local_test_file, File.join(File.dirname(local_test_file),"failed_#{dev_interrupt_info}#{play_width}x#{play_height}_#{pix_fmt}.raw"))
                FileUtils.mv(l_files[0], File.join(File.dirname(l_files[0]),"failed_#{dev_interrupt_info}#{play_width}x#{play_height}_#{pix_fmt}.argb")) if format_length != 1
              end
            end
          else
            require File.dirname(__FILE__)+'/../../../lib/result_forms'
            res_win = ResultWindow.new("Capture #{play_width}x#{play_height} Test. Pix fmt: #{pix_fmt}#{test_params.has_key?("-k") ? ', Cropped ' + test_params['-k'] : ''}")
            video_info = {'pix_fmt' => pix_fmt, 'width' => play_width,
                          'height' => play_height, 'file_path' => local_test_file,
                          'sys'=> @equipment['server1']}
            res_win.add_buttons({'name' => 'Play Test file', 
                                 'action' => :play_video, 
                                 'action_params' => video_info})
            res_win.show()
            trial_result, res_string = res_win.get_result()
          end
        end
        test_string += "- #{play_width}x#{play_height}:#{pix_fmt} failed\n" if trial_result == FrameworkConstants::Result[:fail]
        test_result = test_result && (trial_result == FrameworkConstants::Result[:pass])
        @results_html_file.add_rows_to_table(res_table,[[capture_device,
                                                         "#{play_width}x#{play_height}", 
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

def clean()
  @equipment['light'].switch_on(@equipment['dut1'].params['sensor_info']['light'].values[0]) if @equipment['dut1'].params['sensor_info']['light']
  super
end

def set_capture_app(type)
   res = @equipment['dut1'].send_cmd("v4l2-ctl",@equipment['dut1'].prompt, 30)
   if !res.include?("command not found")
     require File.dirname(__FILE__)+'/v4l2ctl_utils'
   else
    res = @equipment['dut1'].send_cmd("yavta",@equipment['dut1'].prompt, 30)
    if res.include?("command not found")
      require File.dirname(__FILE__)+'/sens_cap_utils'
    else
      require File.dirname(__FILE__)+'/yavta_utils'
    end
  end
end

def get_brightness_adjustment(ref_frame, tst_frame, width, height)
  adj_frame=tst_frame+'.adj'
  val_re = /[^,]+/
  mean_re = /^\*\s*mean\s*vals\s*=\s*\[#{val_re},\s*(#{val_re}),\s*(#{val_re}),\s*(#{val_re})/
  ref_info = adjust_4ch_frames(ref_frame, adj_frame, width, height,
                               [1]*4, [0]*4)
  puts ref_info
  ref_rgb = ref_info.match(mean_re).captures.map(&:to_f)
  tst_info = adjust_4ch_frames(tst_frame, adj_frame, width, height,
                               [1]*4, [0]*4)
  tst_rgb = tst_info.match(mean_re).captures.map(&:to_f)
  return 0 if mean(tst_rgb) < 5 || mean(ref_rgb) < 5
  (mean(ref_rgb) - mean(tst_rgb)).to_i
end
