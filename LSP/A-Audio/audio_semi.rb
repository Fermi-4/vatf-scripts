require File.dirname(__FILE__)+'/../default_target_test'
require File.dirname(__FILE__)+'/audio_utils'
require File.dirname(__FILE__)+'/../../lib/utils'

include LspTargetTestScript

def run
  test_result = true
  file_op_wait = 100
  @equipment['dut1'].send_cmd("mkdir /test", @equipment['dut1'].prompt) #Make sure test folder exists
  ref_file_url = @test_params.params_chan.file_url[0]
  ref_path, dut_src_file = get_file_from_url(ref_file_url)
  ref_pcm_path = File.join(@linux_temp_folder, 'audio_src_file.pcm')
  dut_test_file = File.join(@linux_dst_dir,'audio_test_file.pcm')
  local_test_file = File.join(@linux_temp_folder, 'audio_tst_file.pcm')
  @equipment['dut1'].send_cmd("rm -rf #{dut_test_file}", @equipment['dut1'].prompt)
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
  @equipment['server1'].send_cmd("gst-launch-0.10 filesrc location=#{ref_path} ! wavparse ! filesink location=#{ref_pcm_path}", @equipment['server1'].prompt, file_op_wait)
  @equipment['server1'].send_cmd("file #{ref_path}",@equipment['server1'].prompt,file_op_wait)
  wav_info = @equipment['server1'].response
  audio_info, duration = case(wav_info)
                           when /WAVE\s*audio/
                             info = parse_wav_audio_info(wav_info)
                             [info, File.size(ref_pcm_path)*8/(info['sample_length']*info['rate']*info['channels'])]
                           else
                             raise "Unable to parse audio info for #{@test_params.params_chan.file_url[0]}"
                           end
  rec_duration = duration + 2
  rec_dev_info = @equipment['dut1'].name.gsub(/\-.*?$/i,'').gsub(/beaglebone/i,'am335x')
  play_dev_info = rec_dev_info
  rec_dev_info = @test_params.params_chan.rec_device[0] if @test_params.params_chan.instance_variable_defined?(:@rec_device)
  play_dev_info = @test_params.params_chan.rec_device[0] if @test_params.params_chan.instance_variable_defined?(:@play_device)
  test_type = @test_params.params_chan.test_type[0].strip.downcase
  table_title = ''
  host_play_dev = get_audio_play_dev(nil,'analog',@equipment['server1'])
  dut_rec_dev = get_audio_play_dev(rec_dev_info)
  table_title += "Rec Dev #{dut_rec_dev.to_s}\n\n" if test_type.include?('record')
  dut_play_dev = get_audio_play_dev(play_dev_info)
  table_title += "Play Dev #{dut_play_dev.to_s}\n\n" if test_type.include?('play')
  dut_ip = get_ip_addr()
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([[table_title,{:bgcolor => "4863A0", :colspan => "4"}]], 
                                            {:border => "1",:width=>"20%"})
  @results_html_file.add_rows_to_table(res_table,[[["Buffer size (#frames)",{:bgcolor => "98AFC7"}], 
                                            ["Interrupt interval (#frames)", {:bgcolor => "98AFC7"}],
                                            ["Result", {:bgcolor => "98AFC7"}],
                                            ["Comment", {:bgcolor => "98AFC7"}]]])      
  @test_params.params_chan.buffer_size.each do |buffer_size|
    @test_params.params_chan.period.each do |period|
      audio_info['buffer-size'] = buffer_size
      audio_info['period-size'] = period
      current_test_res = FrameworkConstants::Result[:nry]
      current_comment = ''
      host_audio_info = audio_info.merge({'sys'=>@equipment['server1'],
                                          'card'=>host_play_dev['card'],
                                          'device'=>host_play_dev['device']})
      dut_audio_info = audio_info.merge({'sys'=>@equipment['dut1']})
      dut_play_info = dut_audio_info.merge({'card'=>dut_play_dev['card'],
                                            'device'=>dut_play_dev['device'],
                                            'file'=>dut_src_file,
                                            'duration'=>duration,
                                            'type'=>'wav'})
      dut_rec_info = dut_audio_info.merge({'card'=>dut_rec_dev['card'],
                                           'device'=>dut_rec_dev['device'],
                                           'file'=>dut_test_file,
                                           'duration'=>rec_duration,
                                           'type' => 'raw'})
      host_chk_rec_info = host_audio_info.merge({'file'=>local_test_file,
                                                 'duration'=>rec_duration,
                                                 'type'=>'raw'})
      while(current_test_res == FrameworkConstants::Result[:nry])
        res_win = ResultWindow.new("Audio #{test_type} test")
        res_win.add_buttons({'name' => "Play Ref(#{File.basename(ref_file_url)})", 
                             'action' => :play_audio, 
                             'action_params' => host_audio_info.merge({'sys'=>@equipment['server1'],
                                                                       'file'=>ref_path,
                                                                       'duration'=>duration})})
        case (test_type)
          when 'play'
            play_audio(dut_play_info)
            res_win.add_buttons({'name' => 'Play(DUT)', 
                                 'action' => :play_audio, 
                                 'action_params' => dut_play_info})
          when 'record'
            play_rec_audio(host_audio_info.merge({'sys'=>@equipment['server1'],
                                                  'file'=>ref_path,
                                                  'duration'=>duration,
                                                  'type'=>'wav'}), 
                                                 dut_rec_info)
            scp_pull_file(dut_ip, dut_test_file, local_test_file)
            res_win.add_buttons({'name' => 'Play Recorded(HOST)', 
                                 'action' => :play_audio, 
                                 'action_params' => host_chk_rec_info})
          when 'play+record'
            play_rec_audio(dut_play_info, dut_rec_info)
            scp_pull_file(dut_ip, dut_test_file, local_test_file)
            res_win.add_buttons({'name' => 'Play Recorded(HOST)', 
                                 'action' => :play_audio, 
                                 'action_params' => host_chk_rec_info})
          else
            raise "Test type #{test_type} not supported"
        end
        res_win.show()
        current_test_res, curren_comment = res_win.get_result()
      end
      if current_test_res == FrameworkConstants::Result[:pass]
        @results_html_file.add_rows_to_table(res_table,[[buffer_size, period, ["Passed",{:bgcolor => "green"}],curren_comment]])
      else
        test_result = false
        @results_html_file.add_rows_to_table(res_table,[[buffer_size, period, ["Failed",{:bgcolor => "red"}],curren_comment]])
      end
    end
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed, audio has problems")
  end
end


#Function to fetch the test file in the dut and host
def get_file_from_url(file_url)	  
  url = file_url
  host_path = File.join(@linux_temp_folder, 'audio_src_file.wav')
  dut_path = File.join(@linux_dst_dir, 'audio_src_file.wav')
  @equipment['server1'].send_cmd("wget --no-proxy --tries=1 -T10 #{url} -O #{host_path}", @equipment['server1'].prompt, 100)
  @equipment['server1'].send_cmd("wget #{url} -O #{host_path}", @equipment['server1'].prompt, 100) if @equipment['server1'].response.match(/failed/im)
  raise "Host is unable to fetch file from #{url}" if @equipment['server1'].response.match(/error/im)
  @equipment['dut1'].send_cmd("wget #{url} -O #{dut_path}", @equipment['dut1'].prompt, 100)
  raise "Dut is unable to fetch file from #{url}" if @equipment['dut1'].response.match(/error/im)
 	[host_path, dut_path]
end

