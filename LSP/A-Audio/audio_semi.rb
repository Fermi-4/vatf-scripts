require File.dirname(__FILE__)+'/../default_target_test'
require File.dirname(__FILE__)+'/../../lib/result_forms'
require File.dirname(__FILE__)+'/../../lib/utils'

include LspTargetTestScript

def run
  set_audio_iface()
  test_result = true
  file_op_wait = 100
  @equipment['dut1'].send_cmd("mkdir /test", @equipment['dut1'].prompt) #Make sure test folder exists
  ref_file_url = @test_params.params_chan.file_url[0]
  ref_path, dut_src_file = get_file_from_url(ref_file_url)
  ref_pcm_path = File.join(@linux_temp_folder, 'audio_src_file.pcm')
  dut_test_file = File.join(@linux_dst_dir,'audio_test_file.pcm')
  local_test_file = File.join(@linux_temp_folder, 'audio_tst_file.pcm')
  @equipment['dut1'].send_cmd("rm -rf #{dut_test_file}*", @equipment['dut1'].prompt)
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}*",@equipment['server1'].prompt)
  @equipment['server1'].send_cmd("avprobe #{ref_path}",@equipment['server1'].prompt,file_op_wait)
  wav_info = @equipment['server1'].response
  audio_info, duration = case(wav_info)
                           when /Audio:\s*pcm/i
                             info = parse_wav_audio_info(wav_info)
                             @equipment['server1'].send_cmd("avconv -i #{ref_path} -f #{info['fmt']} #{ref_pcm_path}", @equipment['server1'].prompt, file_op_wait)
                             [info, File.size(ref_pcm_path)*8/(info['sample_length']*info['rate']*info['channels'])]
                           else
                             raise "Unable to parse audio info for #{@test_params.params_chan.file_url[0]}"
                           end
  rec_duration = duration + 2
  table_title = ''
  test_type = @test_params.params_chan.test_type[0].strip.downcase
  dut_rec_dev, dut_play_dev = setup_devices()
  table_title += "\n\nRec Dev " + dut_rec_dev.join("\nRec Dev ") if test_type.include?('record') && !dut_rec_dev.empty?
  table_title += "\n\nPlay Dev " + dut_play_dev.join("\nPlay Dev ") if test_type.include?('play') && !dut_play_dev.empty?
  host_play_dev = get_audio_play_dev(nil,'analog',@equipment['server1'])
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
      dut_play_info = []
      dut_rec_info = []
      dut_play_dev.each do |p_dev|
        dut_play_info << dut_audio_info.merge({'card'=>p_dev['card'],
                                               'device'=>p_dev['device'],
                                               'file'=>dut_src_file,
                                               'duration'=>duration,
                                               'type'=>'wav'})
      end
      dut_rec_dev.each do |r_dev|
        dut_rec_info << dut_audio_info.merge({'card'=>r_dev['card'],
                                              'device'=>r_dev['device'],
                                              'file'=>"#{dut_test_file}.card#{r_dev['card']}",
                                              'duration'=>rec_duration,
                                              'type' => 'raw'})
      end
      host_chk_rec_info = host_audio_info.merge({'duration'=>rec_duration,
                                                 'type'=>'raw'})
      while(current_test_res == FrameworkConstants::Result[:nry])
        res_win = ResultWindow.new("Audio #{test_type} test")
        res_win.add_buttons({'name' => "Play Ref(#{File.basename(ref_file_url)})", 
                             'action' => :play_audio, 
                             'action_params' => [host_audio_info.merge({'sys'=>@equipment['server1'],
                                                                       'file'=>ref_path,
                                                                       'duration'=>duration})]})
        case (test_type)
          when 'play'
            play_audio(dut_play_info)
            res_win.add_buttons({'name' => 'Play(DUT)', 
                                 'action' => :play_audio, 
                                 'action_params' => dut_play_info})
          when 'record'
            play_rec_audio([host_audio_info.merge({'sys'=>@equipment['server1'],
                                                   'file'=>ref_path,
                                                   'duration'=>duration,
                                                   'type'=>'wav',
                                                   'playout_func' => :host_playout})], 
                                                   dut_rec_info)
            dut_rec_dev.each do |r_dev|
              scp_pull_file(dut_ip, "#{dut_test_file}.card#{r_dev['card']}", File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}"))
              res_win.add_buttons({'name' => "Play Recorded card#{r_dev['card']} (HOST) ", 
                                   'action' => :host_playout, 
                                   'action_params' => [host_chk_rec_info.merge({'file'=>File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}")})]})
            end
          when 'play+record'
            play_rec_audio(dut_play_info, dut_rec_info)
            dut_rec_dev.each do |r_dev|
              scp_pull_file(dut_ip, "#{dut_test_file}.card#{r_dev['card']}", File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}"))
              res_win.add_buttons({'name' => "Play Recorded card#{r_dev['card']} (HOST) ", 
                                   'action' => :host_playout, 
                                   'action_params' => [host_chk_rec_info.merge({'file'=>File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}")})]})
            end
          else
            raise "Test type #{test_type} not supported"
        end
        res_win.show()
        current_test_res, current_comment = res_win.get_result()
      end
      if current_test_res == FrameworkConstants::Result[:pass]
        @results_html_file.add_rows_to_table(res_table,[[buffer_size, period, ["Passed",{:bgcolor => "green"}],current_comment]])
      else
        test_result = false
        @results_html_file.add_rows_to_table(res_table,[[buffer_size, period, ["Failed",{:bgcolor => "red"}],current_comment]])
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
  @equipment['server1'].send_cmd("wget --no-proxy --tries=1 -T10 #{url} -O #{host_path}", @equipment['server1'].prompt, 200)
  @equipment['server1'].send_cmd("wget #{url} -O #{host_path}", @equipment['server1'].prompt, 200) if @equipment['server1'].response.match(/failed/im)
  raise "Host is unable to fetch file from #{url}" if @equipment['server1'].response.match(/error/im)
  @equipment['dut1'].send_cmd("wget #{url} -O #{dut_path}", @equipment['dut1'].prompt, 200)
 # raise "Dut is unable to fetch file from #{url}" if @equipment['dut1'].response.match(/error/im)
 	[host_path, dut_path]
end

#Function to load the appropriate interface func depending on the audio
#interface used to test
def set_audio_iface()
	if @test_params.params_chan.instance_variable_defined?(:@audio_iface) && @test_params.params_chan.audio_iface[0] == 'pulseaudio'
		require File.dirname(__FILE__)+'/audio_utils_pulse'
	else
		require File.dirname(__FILE__)+'/audio_utils'
	end
end
