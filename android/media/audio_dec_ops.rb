# -*- coding: ISO-8859-1 -*-'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../../LSP/A-Audio/audio_utils'
require File.dirname(__FILE__)+'/../android_test_module'

include AndroidTest

=begin
 Test to validate audio operations, requires:
   - Looping line-out to line-in
   - staf registration command.
=end

def run

  app_permissions = ["android.permission.READ_EXTERNAL_STORAGE",
                       "android.permission.WRITE_EXTERNAL_STORAGE"]
  
  apk_path = File.join(@linux_temp_folder, File.basename(@test_params.params_chan.apk_url[0]))
  wget_file(@test_params.params_chan.apk_url[0], apk_path)
  pkg = installPkg(apk_path, 'com.ti.test.media',true)
  app_permissions.each{ |permission| send_adb_cmd("shell pm grant #{pkg} #{permission}") }
  num_passed = 0
  total = 0
  media_srcs = @test_params.params_chan.media_url
  local_test_file = File.join(@linux_temp_folder, 'test.wav')
  @equipment['server1'].send_cmd("rm #{local_test_file}")
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Media",{:bgcolor => "4863A0"}], 
                                            ["Audio Op",{:bgcolor => "4863A0"}], 
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])


  audio_test_file = File.join(@linux_dst_dir, 'audio_tst_file.wav')
  staf_handle = STAFHandle.new("#{@staf_service_name.to_s}_audio_handle")
  media_srcs.each do |src|
    audio_server = src.match(/tp:\/\/([^\/]+)/)[1].sub(/.*?@/,'')
    ref_path, s_file = get_file_from_url(src, nil)
    puts "This is the play command shell am start -W -n com.ti.test.media/.MediaIO -a action.intent.action.MAIN --es play_file #{File.join('test', File.basename(s_file))} --activity-single-top"
    send_adb_cmd("shell am start -W -n com.ti.test.media/.MediaIO -a action.intent.action.MAIN --es play_file #{File.join('test', File.basename(s_file))} --activity-single-top")
    send_events_for(['__tab__','__tab__','__enter__'])
    audio_state = 'playing'
    to_vals = [0.33, 0.66]
    t = 0.1
    exec_audio_op('seek', t)
    @test_params.params_chan.audio_ops.each do |op|
      to = case op
        when /seek/i
          t = to_vals[rand(to_vals.length)]
          t
        when /rewind/i
          t = to_vals[rand(to_vals.length)]
          exec_audio_op('seek', (t + 1) / 2)
          t
        when /forward/i
          t = to_vals[rand(to_vals.length)]
          exec_audio_op('seek', t / 2)
          t
        else
          nil
      end
      exec_audio_op(op, to)
      if ['pause', 'play', 'resume'].include?(op.downcase) && audio_state != 'paused'
          exec_audio_op('seek', t)
      end
      if ['play', 'resume'].include?(op.downcase) || (audio_state == 'playing' && op != 'pause') 
        sleep 1
      end
      sleep 0.5
      audio_info = ''
      begin
        audio_info = send_adb_cmd("shell su root tinycap #{audio_test_file} -T 6").match(/Capturing\s*sample:\s*(?<channels>\d+)\s*ch,\s*(?<rate>\d+)\s*hz,\s*(?<sample_length>\d+).*/)
      rescue Exception => e
        add_result_row(res_table, s_file, false, "\n#{e.to_s}")
        next
      end
      if op.downcase == 'pause'
        audio_state = 'paused'
      elsif ['play', 'resume'].include?(op.downcase)
        audio_state = 'playing'
      end
    
      send_adb_cmd("pull -p #{audio_test_file} #{local_test_file}")
      processed_audio = local_test_file + '.processed'
      left_tst, right_tst = remove_offset(local_test_file, processed_audio, audio_info['sample_length'].to_i/8, audio_info['rate'].to_i, audio_info['channels'].to_i, 0.5, true, true)
      audio_name = 'silence'
      if audio_state != "paused"
        staf_req = staf_handle.submit(audio_server, "DEJAVU","MATCH FILE #{processed_audio}") 
        staf_result = STAFResult.unmarshall_response(staf_req.result)
        audio_name = get_ref_file(ref_path, t)
        qual_res = staf_req.rc == 0 && staf_result['song_name'] == audio_name
        audio = staf_result['song_name']
      else
        l_mean = mean(left_tst)
        r_mean = mean(right_tst)
        l_min = left_tst.min
        l_max = left_tst.max
        r_min = right_tst.min
        r_max = right_tst.max
        qual_res = l_mean > -1 && l_mean < 1 && r_mean > -1 && r_mean < 1 &&  l_max < 100 &&  l_min > -100 && r_max < 100 && r_min > -100
        audio_name = "silence (paused) values: |l mean| < 1, |l values| < 100, |r mean| < 1, |r values| < 100"
        audio = "l_mean = #{l_mean}, l min = #{l_min}, l_max = #{l_max}, r_mean = #{r_mean}, r min = #{r_min}, l_max = #{r_max}"
      end
      

      qual_string = ''
      if qual_res
        num_passed += 1
        qual_string = "-Audio #{op} passed, expected #{audio_name}, got #{audio}\n"
      else
        if File.exists?(local_test_file)
            a_name = [op, File.basename(local_test_file)].join('_')
            @equipment['server1'].send_cmd("tar -Jcvf #{a_name}.tar.xz #{processed_audio}")
            failed_audio_info = upload_file("#{a_name}.tar.xz")
            @results_html_file.add_paragraph("failed_#{a_name}.tar.xz",nil,nil,failed_audio_info[1]) if failed_audio_info
        end
        qual_string = "-Audio #{op} failed, expected audio: expected #{audio_name}, got #{audio}\n"      
      end
      
      add_result_row(res_table, s_file, op, qual_res, qual_string)

      total += 1
    end
  end

  set_result(num_passed != total || total == 0 ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],
             "#{num_passed}/#{total} ops passed ")

end

def add_result_row(res_table, media, op, res, res_string)
  @results_html_file.add_rows_to_table(res_table,[[media,
                                           op,
                                           res == -1 ? ["Not testable",{:bgcolor => "yellow"}] : 
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
end


def exec_audio_op(action, to=nil)
  send_adb_cmd("shell am start -W -n com.ti.test.media/.MediaIO -a action.intent.action.VIEW --activity-single-top --es action #{action.downcase()}#{to ? " --ef to #{to}" : ''}")
end

def get_ref_file(ref_file, to)
  [File.basename(ref_file,'.*'), to].join('_')
end
