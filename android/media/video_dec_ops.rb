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

  app_permissions = ["android.permission.READ_EXTERNAL_STORAGE",
                       "android.permission.WRITE_EXTERNAL_STORAGE"]
  
  apk_path = File.join(@linux_temp_folder, File.basename(@test_params.params_chan.apk_url[0]))
  wget_file(@test_params.params_chan.apk_url[0], apk_path)
  pkg = installPkg(apk_path, 'com.ti.test.videoplaybacktest',true)
  app_permissions.each{ |permission| send_adb_cmd("shell pm grant #{pkg} #{permission}") }
  num_passed = 0
  total = 0
  media_srcs = @test_params.params_chan.media_url
  hdmi_out_info = @equipment['dut1'].video_io_info.hdmi_outputs.keys[0]
  hdmi_in_info = @equipment['server1'].video_io_info.hdmi_inputs.keys[0]
  raise "Trying to connect io from different switches" if hdmi_out_info != hdmi_in_info

  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Media",{:bgcolor => "4863A0"}], 
                                            ["Video Op",{:bgcolor => "4863A0"}], 
                                            ["Capture Mode", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])

  drm_info = ''
  formats = Hash.new(['default'])
  staf_mutex('video_capture', 36000000) do
    add_equipment('hdmi_sw', hdmi_out_info, true) do |e_class, log_path|
      e_class.new(hdmi_out_info, log_path)
    end
    @equipment['hdmi_sw'].disconnect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0])
    sleep 1
    @equipment['hdmi_sw'].connect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0], @equipment['server1'].video_io_info.hdmi_inputs.values[0])
    sleep 5
    drm_info = get_properties()
    hdmi_info = drm_info['Connectors:'].select{ |x| x['name'].match(/HDMI/) }
    mode_idx = get_mode_idx({"name"=>"1280x720", "refresh (Hz)"=>"60"}, hdmi_info[0]["modes:"])
    @equipment['dut1'].send_cmd("su root setprop ro.hwc.hdmiedid #{mode_idx}")
  end

  video_test_file = File.join(@linux_temp_folder, 'video_tst_file.raw')
  audio_test_file = File.join(@linux_temp_folder, 'audio_tst_file.pcm')
  media_srcs.each do |src|
    ref_path, s_file = get_file_from_url(src, nil)
    staf_mutex('video_capture', 36000000) do

      add_equipment('hdmi_sw', hdmi_out_info, true) do |e_class, log_path|
        e_class.new(hdmi_out_info, log_path)
      end

      video_capture = MediaCapture.new(@equipment['server1'])
      @equipment['hdmi_sw'].disconnect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0])
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
        add_result_row(res_table, s_file, '', '', false, "EDID detection failed capture card EDID #{sw_edid} not in modetest EDID(s) #{edid_arr.to_s}")
        next
      end

      num_comp = -1
      mode_info = width = height = nil
      drm_info = get_properties()
      hdmi = drm_info['Connectors:'].select{ |x| x['name'].match(/HDMI/)}[0]
      hdmi_enc = drm_info['Encoders:'].select{ |x| x['id'] == hdmi['encoder'] }[0]
      hdmi_crtc = drm_info['CRTCs:'].select{ |x| x['id'] == hdmi_enc['crtc'] }[0]
      mode_info = hdmi_crtc['other_info'].split(/\s+/)
      width, height = mode_info[0].split('x')
      interlace = height.include?('i') ? 'i' : 'p'
      height = height.gsub('i','').to_i
      frame_rate = mode_info[1].to_f
      send_adb_cmd("shell am start -W -n com.ti.test.videoplaybacktest/.MainActivity -a action.intent.action.MAIN -d file://#{File.join(@linux_dst_dir, File.basename(s_file))} --activity-single-top")
    
      video_state = 'playing'
      to_vals = [0.33, 0.5, 0.66]
      t = 0.1
      exec_video_op('seek', t)
      send_events_for(['__enter__', '__enter__'])
      @test_params.params_chan.video_ops.each do |op|
        to = case op
          when /seek/i
            t = to_vals[rand(to_vals.length)]
            t
          when /rewind/i
            t = to_vals[rand(to_vals.length)]
            exec_video_op('seek', (t + 1) / 2)
            t
          when /forward/i
            t = to_vals[rand(to_vals.length)]
            exec_video_op('seek', t / 2)
            t
          else
            nil
        end
        exec_video_op(op, to)
        if ['pause', 'play', 'resume'].include?(op.downcase)
            exec_video_op('seek', t)
        end
        if ['play', 'resume'].include?(op.downcase) || (video_state == 'playing' && op != 'pause') 
          sleep 1
        end
        sleep 0.5
        begin
          num_comp = video_capture.capture_media(video_test_file, audio_test_file, width, height, frame_rate, interlace, 2)
        rescue Exception => e
          add_result_row(res_table, s_file, "#{mode_info[0]}@#{mode_info[1]}", false, "\n#{e.to_s}")
          next
        end
        conv_file = video_test_file
        if num_comp == 3
          conv_file = change_uyvy_to_rgb(video_test_file, width, height) 
        end

        video_ref_files = get_ref_file(s_file, video_state, op, t, mode_info[0], mode_info[1], interlace)
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
            h['ssim'].each {|comp, val| qual_res &= val >= 98 || comp == 'a'
                                        qual_string+="-Frame ##{i}: Component #{comp} failed SSIM #{val}%\n" if val < 98 && comp != 'a'}
          end
          break if qual_res
        end

        if qual_res
          num_passed += 1
          qual_string += "-Video Result: #{result.length} video frames passed\n"          
        end
        
        add_result_row(res_table, s_file, op, "#{mode_info[0]}@#{mode_info[1]}", qual_res, qual_string)
        
        #exit if !qual_res #Uncomment this line if you want to stop on a display failure

        total += 1
        
        if op.downcase == 'pause'
          video_state = 'paused'
        elsif ['play', 'resume'].include?(op.downcase)
          video_state = 'playing'
        end
      end
    end
  end

  set_result(num_passed != total || total == 0 ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],
             "#{num_passed}/#{total} ops passed ")

end

def add_result_row(res_table, media, op, s_mode, res, res_string)
  @results_html_file.add_rows_to_table(res_table,[[media,
                                           op,
                                           s_mode,
                                           res == -1 ? ["Not testable",{:bgcolor => "yellow"}] : 
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
end


def exec_video_op(action, to=nil)
  send_adb_cmd("shell am start -W -n com.ti.test.videoplaybacktest/.MainActivity -a action.intent.action.TEST_ACTION --activity-single-top --es action #{action.downcase()}#{to ? " --ef to #{to}" : ''}")
end

def get_ref_file(ref_file, video_state, op, to, mode, fps, interlace, cap_sys=@equipment['server1'])
  cap_sys.send_cmd("mkdir #{@linux_temp_folder}", cap_sys.prompt) if !File.exists?(@linux_temp_folder)
  cap_sys.send_cmd("rm #{@linux_temp_folder}/ref_*.rgb*", cap_sys.prompt)
  result = []
  r_files = [['ref', File.basename(ref_file,'.*'), video_state, op, to, mode,fps+'fps.argb'].join('_')]
  r_files << ['ref', File.basename(ref_file,'.*'), video_state, op, to, mode,fps+'fps_f2.argb'].join('_') if interlace == 'i'
  r_files.each do |f_name|
    f_base_name = f_name + '.tar.xz'
    remote_url = "http://gtopentest-server.gt.design.ti.com/anonymous/common/android/ref-files/video-ops/#{f_base_name}"
    local_file = File.join(@linux_temp_folder, f_base_name)
    wget_file(remote_url, local_file)
    cap_sys.send_cmd("tar -C #{@linux_temp_folder} -Jxvf #{local_file} || rm #{local_file}",
                    cap_sys.prompt,
                    600)
    result << File.join(@linux_temp_folder, f_name) if !cap_sys.response.match(/Error/i)
  end
  result
end
