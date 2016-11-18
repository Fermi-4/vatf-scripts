# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/drm_utils'
require File.dirname(__FILE__)+'/capture_utils'
require File.dirname(__FILE__)+'/../../A-Audio/audio_utils'
require File.dirname(__FILE__)+'/../../default_target_test'

include LspTargetTestScript
include CaptureUtils

=begin
 Test to validate HDMI displays, requires:
   - HDMI frame grabber, for example
     https://www.blackmagicdesign.com/products/intensitypro4k
   - HDMI switch, for example
     http://www.kramerelectronics.com/products/model.asp?pid=534
   - Network connectivity on the host and dut.
   - Adding "hdmiqual" capability the board's bench and 
     staf registration command.
=end

def setup
  super
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && /etc/init.d/weston stop && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['server1'].send_cmd("mkdir #{@linux_temp_folder}") if !File.exists?(@linux_temp_folder) #make sure the data folder exists 
  @equipment['server1'].send_cmd("mkdir #{SiteInfo::UTILS_FOLDER}") if !File.exists?(SiteInfo::UTILS_FOLDER) #make sure the bins folder exists
  @equipment['dut1'].send_cmd("ls #{@linux_dst_dir} || mkdir #{@linux_dst_dir}",@equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("rm #{@linux_dst_dir}/*",@equipment['dut1'].prompt) 
end

def run
  num_passed = 0
  total = 0
  dut_audio = File.join(@linux_dst_dir, 'audio_src_file.wav')
  ref_file = @test_params.params_chan.audio_file_url[0]
  audio_server = ref_file.match(/tp:\/\/([^\/]+)/)[1].sub(/.*?@/,'')
  @equipment['dut1'].send_cmd("wget #{ref_file} -O #{dut_audio}", @equipment['dut1'].prompt, 200)
  hdmi_adev_info = get_audio_play_dev(nil, 'hdmi')
  aic_adev_info = get_audio_play_dev(nil, 'aic')
  hdmi_out_info = @equipment['dut1'].video_io_info.hdmi_outputs.keys[0]
  hdmi_in_info = @equipment['server1'].video_io_info.hdmi_inputs.keys[0]
  raise "Trying to connect io from different swithes" if hdmi_out_info != hdmi_in_info
  begin
    staf_handle = STAFHandle.new("#{@staf_service_name.to_s}_audio_handle")
  rescue Exception => e
    staf_handle = nil
  end

  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Connector",{:bgcolor => "4863A0"}], 
                                            ["Encoder", {:bgcolor => "4863A0"}],
                                            ["CRTC", {:bgcolor => "4863A0"}],
                                            ["Mode", {:bgcolor => "4863A0"}],
                                            ["Plane", {:bgcolor => "4863A0"}],
                                            ["Audio Card", {:bgcolor => "4863A0"}],
                                            ["Audio Dev", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])

  drm_info = ''
  formats = Hash.new(['default'])
  staf_mutex('video_capture', 36000000) do
    add_equipment('hdmi_sw', hdmi_out_info, true) do |e_class, log_path|
      e_class.new(hdmi_out_info, log_path)
    end
    @equipment['hdmi_sw'].disconnect_video_audio()
    sleep 1
    @equipment['hdmi_sw'].connect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0], @equipment['server1'].video_io_info.hdmi_inputs.values[0])
    sleep 5
    drm_info = get_properties()
    
    if @test_params.params_chan.instance_variable_defined?(:@formats)
      formats = Hash.new() { |h,k| h[k] = @test_params.params_chan.formats }
    elsif @test_params.params_chan.instance_variable_defined?(:@valid_formats)
      formats = get_supported_fmts(drm_info['Connectors:'])
    end
  end

  single_disp_modes, multi_disp_modes = get_test_modes(drm_info, formats, 'hdmi')
  perf_data = []

  video_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')
  audio_test_file = File.join(@linux_temp_folder, 'audio_tst_file.pcm')

  single_disp_modes.each do |s_mode|
    staf_mutex('video_capture', 36000000) do

      perf_data = []
      res_string = ''
      width, height = s_mode[0]['mode'].split('x')
      interlace = height.include?('i') ? 'i' : 'p'
      height = height.gsub('i','').to_i

      add_equipment('hdmi_sw', hdmi_out_info, true) do |e_class, log_path|
        e_class.new(hdmi_out_info, log_path)
      end

      video_capture = MediaCapture.new(@equipment['server1'])
      @equipment['hdmi_sw'].disconnect_video_audio()
      sleep 1
      @equipment['hdmi_sw'].connect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0], @equipment['server1'].video_io_info.hdmi_inputs.values[0])
      sleep 5

      drm_info = get_properties()
      hdmi_info = drm_info['Connectors:'].select{ |x| x['name'].match(/HDMI/) }

      edid_test = false
      edid_arr = []
      sw_edid = video_capture.get_edid()
      
      hdmi_info.each do |h_inf|
        edid_arr << h_inf['props:']['1 EDID:']['value:'].gsub(/[^\da-fA-f]+/,'')
        edid_test |= edid_arr[-1].downcase == sw_edid.downcase
      end
      if !edid_test
        total += 1
        add_result_row(res_table, s_mode, hdmi_adev_info, false, "EDID detection failed capture card EDID #{sw_edid} not in modetest EDID(s) #{edid_arr.to_s}", '')
        next
      end

      if !video_capture.is_capture_mode_supported(width, height, s_mode[0]['framerate'], interlace)
        add_result_row(res_table, s_mode, hdmi_adev_info, -1, "Mode not supported by test equipment", '')
        puts "Mode #{s_mode[0]} not supported by test equipment..."
        next
      end
      plane_info_str = "Scale: #{s_mode[0]['plane']['scale']}, pix_fmt: #{s_mode[0]['plane']['format']}" if s_mode[0]['plane']
      res = true
      res_string = ''
      num_comp = -1
      fps_res = nil
      fps_data = nil
      f_length = get_format_length(s_mode[0]['format'])
      use_memory(width.to_i * height.to_i * 8 * f_length + 5*2**20) do
        fps_res, fps_data = run_perf_sync_flip_test(s_mode) do
          begin
            sleep 5
            @equipment['dut1'].send_cmd("aplay -D hw:#{hdmi_adev_info['card']},#{hdmi_adev_info['device']} -d 12 #{dut_audio} &",@equipment['dut1'].prompt)
            sleep 1
            num_comp = video_capture.capture_media(video_test_file, audio_test_file, width, height, s_mode[0]['framerate'], interlace)
          rescue Exception => e
            res_string += "\n#{e.to_s}"
          end
        end
      end
      conv_file = video_test_file
      if num_comp == 3
        conv_file = change_uyvy_to_rgb(video_test_file, width, height) 
      end

      video_ref_files = get_ref_file(s_mode[0]['mode'], s_mode[0]['format'], s_mode[0]['plane'])
      if video_ref_files.empty?
        total += 1
        add_result_row(res_table, s_mode, hdmi_adev_info, false, "Unable to get ref file for mode", '')
        next
      end
      
      qual_string= 'Could not fetch reference file(s)'
      qual_res = false
      result = []
      video_ref_files.each do |v_ref|
        qual_string= ''
        qual_res = true 
        result = get_psnr_ssim_argb(v_ref, conv_file, width, height, num_comp)
        if result.empty?
          qual_res = false
          qual_string = "-HDMI test failed, could not asses video quality\n"
          break
        end
        result.each_with_index do |h, i|
          h['psnr'].each {|comp, val| qual_res &= val >= 40
                                      qual_string+="-Frame ##{i}: Component #{comp} failed PSNR #{val}dB\n" if val < 40}
          h['ssim'].each {|comp, val| qual_res &= val >= 99
                                      qual_string+="-Frame ##{i}: Component #{comp} failed SSIM #{val}%\n" if val < 99}
        end
        break if qual_res
      end
      res &= qual_res
      res_string += qual_string
      if res
        res_string += "-Video Result: #{result.length} video frames passed\n"
      end
      
      #exit if !res #Uncomment this line if you want to stop on a display failure
      
      if @test_params.params_chan.instance_variable_defined?(:@performance)
        metric_name = "#{s_mode[0]['type']}-#{s_mode[0]['mode']}@#{s_mode[0]['framerate']}-" \
                  "#{s_mode[0]['format']}"
        perf_data << {'name' => metric_name,
                      'units' => 'fps',
                      'values' => fps_data}
      end

      processed_audio = audio_test_file + '.processed'
      remove_offset(audio_test_file, processed_audio,
                    video_capture.get_recorded_sample_size(),
                    video_capture.get_audio_sampling_rate(),
                    video_capture.get_recorded_audio_channels())
      audio_res = false
      if staf_handle
        audio_name = File.basename(ref_file,'.wav')
        staf_req = staf_handle.submit(audio_server, "DEJAVU","MATCH FILE #{processed_audio}")
        staf_result = STAFResult.unmarshall_response(staf_req.result)
        if staf_req.rc == 0 && staf_result['song_name'] == audio_name
          audio_res = true
          res_string += "\n-Audio result: passed\n"
        else
          res_string += "\n-Audio result: failed (expected #{audio_name} got #{staf_result['song_name']})\n"
        end
      else
        audio_res = false
        res_string += "Unable verify recorded audio #{e.to_s}" 
      end
      num_passed += 1 if res && audio_res
      total += 1
      add_result_row(res_table, s_mode, hdmi_adev_info, res && audio_res, res_string, plane_info_str)
    end
  end

  set_result(num_passed != total || total == 0 ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],
             "#{num_passed}/#{total} passed ", perf_data)

end

def add_result_row(res_table, s_mode, hdmi_adev_info, res, res_string, plane_info_str)
  @results_html_file.add_rows_to_table(res_table,[["#{s_mode[0]['connectors_names'][0]} (#{s_mode[0]['connectors_ids'][0]})", 
                                           s_mode[0]['encoder'],
                                           s_mode[0]['crtc_id'],
                                           "#{ s_mode[0]['mode']}@#{ s_mode[0]['framerate']}",
                                           s_mode[0]['plane'] ? plane_info_str : 'No plane',
                                           hdmi_adev_info['card_info'],
                                           hdmi_adev_info['device_info'],
                                           res == -1 ? ["Not testable",{:bgcolor => "yellow"}] : 
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
end

