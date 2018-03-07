# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/A-Display/drm/capture_utils'
require File.dirname(__FILE__)+'/../../LSP/A-Display/drm/drm_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../../LSP/A-Audio/audio_utils'
require File.dirname(__FILE__)+'/../android_test_module'

include CaptureUtils
include AndroidTest

=begin
 Test to validate media decode through HDMI, requires:
   - HDMI frame grabber, for example
     https://www.blackmagicdesign.com/products/intensitypro4k
   - HDMI switch, for example
     http://www.kramerelectronics.com/products/model.asp?pid=534
   - Network connectivity on the host and dut.
   - Adding "hdmiqual" capability the board's bench and 
     staf registration command.
=end

def run

  num_passed = 0
  total = 0
  media_srcs = @test_params.params_chan.media_url
  audio_server = media_srcs[0].match(/tp:\/\/([^\/]+)/)[1].sub(/.*?@/,'')
  hdmi_out_info = @equipment['dut1'].video_io_info.hdmi_outputs.keys[0]
  hdmi_in_info = @equipment['server1'].video_io_info.hdmi_inputs.keys[0]
  raise "Trying to connect io from different swithes" if hdmi_out_info != hdmi_in_info
  begin
    staf_handle = STAFHandle.new("#{@staf_service_name.to_s}_audio_handle")
  rescue Exception => e
    staf_handle = nil
  end

  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Media",{:bgcolor => "4863A0"}], 
                                            ["Capture Mode", {:bgcolor => "4863A0"}],
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
  end

  perf_data = []


  media_srcs.each do |src|
    video_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')
    audio_test_file = File.join(@linux_temp_folder, 'audio_tst_file.pcm')
    ref_path, s_file = get_file_from_url(src, nil)
    staf_mutex('video_capture', 36000000) do

      add_equipment('hdmi_sw', hdmi_out_info, true) do |e_class, log_path|
        e_class.new(hdmi_out_info, log_path)
      end

      video_capture = MediaCapture.new(@equipment['server1'])
      @equipment['hdmi_sw'].disconnect_video_audio()
      sleep 1
      @equipment['hdmi_sw'].connect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0], @equipment['server1'].video_io_info.hdmi_inputs.values[0])
      sleep 5

      edid_test = false
      edid_arr = []
      sw_edid = video_capture.get_edid()

      drm_info = get_properties()
      hdmi_info = drm_info['Connectors:'].select{ |x| x['name'].match(/HDMI/) }
      
      hdmi_info.each do |h_inf|
        edid_arr << h_inf['props:']['1 EDID:']['value:'].gsub(/[^\da-fA-f]+/,'')
        edid_test |= edid_arr[-1].downcase == sw_edid.downcase
      end
      if !edid_test
        total += 1
        add_result_row(res_table, s_file, '', false, "EDID detection failed capture card EDID #{sw_edid} not in modetest EDID(s) #{edid_arr.to_s}")
        next
      end

      res = true
      res_string = ''
      num_comp = -1
      mode_info = width = height = nil
      data = play_media(s_file) do
        begin
          sleep 5
          drm_info = get_properties()
          hdmi = drm_info['Connectors:'].select{ |x| x['name'].match(/HDMI/)}[0]
          hdmi_enc = drm_info['Encoders:'].select{ |x| x['id'] == hdmi['encoder'] }[0]
          hdmi_crtc = drm_info['CRTCs:'].select{ |x| x['id'] == hdmi_enc['crtc'] }[0]
          mode_info = hdmi_crtc['other_info'].split(/\s+/)
          width, height = mode_info[0].split('x')
          interlace = height.include?('i') ? 'i' : 'p'
          height = height.gsub('i','').to_i
          frame_rate = mode_info[1]
          num_comp = video_capture.capture_media(video_test_file, audio_test_file, width, height, frame_rate, interlace)
        rescue Exception => e
          res_string += "\n#{e.to_s}"
        end
      end
      conv_file = video_test_file
      if num_comp == 3
        conv_file = change_uyvy_to_rgb(video_test_file, width, height) 
      end

      video_ref_files = get_ref_file(s_file, mode_info[0], mode_info[1])
      if video_ref_files.empty?
        total += 1
        add_result_row(res_table, s_file, "#{mode_info[0]}@#{mode_info[1]}", false, "Unable to get ref file for mode")
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
          h['psnr'].each {|comp, val| qual_res &= val >= 40 || comp == 'a'
                                      qual_string+="-Frame ##{i}: Component #{comp} failed PSNR #{val}dB\n" if val < 40 && comp != 'a'}
          h['ssim'].each {|comp, val| qual_res &= val >= 99 || comp == 'a'
                                      qual_string+="-Frame ##{i}: Component #{comp} failed SSIM #{val}%\n" if val < 99 && comp != 'a'}
        end
        break if qual_res
      end
      res &= qual_res
      res_string += qual_string
      if res
        res_string += "-Video Result: #{result.length} video frames passed\n"
      end
      
      #exit if !res #Uncomment this line if you want to stop on a display failure

      processed_audio = audio_test_file + '.processed'
      remove_offset(audio_test_file, processed_audio,
                    video_capture.get_recorded_sample_size(),
                    video_capture.get_audio_sampling_rate(),
                    video_capture.get_recorded_audio_channels())
      audio_res = false
      if staf_handle
        audio_name = File.basename(src,'.wav')
        staf_req = staf_handle.submit(audio_server, "DEJAVU","MATCH FILE #{processed_audio}")
        staf_result = STAFResult.unmarshall_response(staf_req.result)
        puts staf_result
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
      add_result_row(res_table, s_file, "#{mode_info[0]}@#{mode_info[1]}", res && audio_res, res_string)
    end
  end

  set_result(num_passed != total || total == 0 ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],
             "#{num_passed}/#{total} passed ", perf_data)

end

def add_result_row(res_table, media, s_mode, res, res_string)
  @results_html_file.add_rows_to_table(res_table,[[media,
                                           s_mode,
                                           res == -1 ? ["Not testable",{:bgcolor => "yellow"}] : 
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
end


def play_media(dut_src_file)
  send_adb_cmd("logcat -c")
  comp = CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })
  t1 = Thread.new do
    send_adb_cmd("shell am start -W -n #{comp} -a action.intent.anction.VIEW -d file://#{File.join(@linux_dst_dir, File.basename(dut_src_file))}")
  end
  if block_given?
    yield
  else
    t1.join(2)
  end
  t1.join()
  send_adb_cmd("logcat  -d")
end

def get_ref_file(ref_file, mode, fps, cap_sys=@equipment['server1'])
  cap_sys.send_cmd("mkdir #{@linux_temp_folder}", cap_sys.prompt) if !File.exists?(@linux_temp_folder)
  cap_sys.send_cmd("rm #{@linux_temp_folder}/ref_*.rgb*", cap_sys.prompt)
  result = []
  f_name = [File.basename(ref_file,'.*'), mode,fps+'fps.argb'].join('_')
  f_base_name = 'ref_' + f_name + '.tar.xz'
  remote_url = "#{HOST_UTILS_URL}/android/ref-media/#{f_base_name}"
  local_file = File.join(@linux_temp_folder, f_base_name)
  wget_file(remote_url, local_file)
  cap_sys.send_cmd("tar -C #{@linux_temp_folder} -Jxvf #{local_file} || rm #{local_file}",
                  cap_sys.prompt,
                  600)
  result << File.join(@linux_temp_folder, f_name) if !cap_sys.response.match(/Error/i)
  result
end
