require File.dirname(__FILE__)+'/audio_semi'

include LspTargetTestScript

def run
  set_audio_iface()
  test_result = true
  file_op_wait = 100
  @equipment['dut1'].send_cmd("mkdir /test", @equipment['dut1'].prompt) #Make sure test folder exists
  ref_file_url = @test_params.params_chan.file_url[0]
  audio_name = File.basename(ref_file_url,'.wav')
  ref_path, dut_src_file = get_file_from_url(ref_file_url)
  ref_pcm_path = File.join(@linux_temp_folder, 'audio_src_file.pcm')
  dut_test_file = File.join(@linux_dst_dir,'audio_test_file.pcm')
  local_test_file = File.join(@linux_temp_folder, 'audio_tst_file.pcm')
  audio_server = ref_file_url.match(/tp:\/\/([^\/]+)/)[1].sub(/.*?@/,'')
  staf_handle = STAFHandle.new("#{@staf_service_name.to_s}_audio_handle")
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
  duration = [15, duration].min
  rec_duration = duration + 2
  table_title = ''
  test_type = @test_params.params_chan.test_type[0].strip.downcase
  use_plugins = @equipment['dut1'].name.match(/j7.*/) 
  dut_rec_dev, dut_play_dev = setup_devices(@equipment['dut1'], 0.6, use_plugins)
  dut_play_dev.select! {|p_dev| !p_dev['card_info'].match(/USB/) && !p_dev['device_info'].match(/USB/)}
  dut_rec_dev.select! {|r_dev| !r_dev['card_info'].match(/USB/) && !r_dev['device_info'].match(/USB/)}
  table_title += "\n\nRec Dev " + dut_rec_dev.join("\nRec Dev ") if test_type.include?('record') && !dut_rec_dev.empty?
  table_title += "\n\nPlay Dev " + dut_play_dev.join("\nPlay Dev ") if test_type.include?('play') && !dut_play_dev.empty?
  host_play_dev = get_audio_play_dev(nil,'analog',@equipment['server1'])
  host_play_dev = Hash.new('') if !host_play_dev
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
                                          'card'=>host_play_dev ? host_play_dev['card'] : 'nocard',
                                          'device'=> host_play_dev ? host_play_dev['device'] : 'nodevice'})
      dut_audio_info = audio_info.merge({'sys'=>@equipment['dut1']})
      host_chk_rec_info = host_audio_info.merge({'duration'=>rec_duration,
                                                 'type'=>'raw',
                                                 'file'=>local_test_file})
      test_audio = []
			case (test_type)
				when 'play'
          test_result &= dut_play_dev.length > 0
          dut_play_dev.each do |p_dev|
            dut_play_info = [dut_audio_info.merge({'card'=>p_dev['card'],
                                                 'device'=>p_dev['device'],
                                                 'file'=>dut_src_file,
                                                 'duration'=>duration,
                                                 'type'=>'wav'})]
            play_rec_audio(dut_play_info, host_chk_rec_info.merge({'sys'=>@equipment['server1'],
                                                                   'duration'=>rec_duration,
                                                                   'type'=>'raw',
                                                                   'playout_func' => :host_rec}))
            test_audio << host_chk_rec_info['file']
          end
				when 'record'
          test_result &= dut_rec_dev.length > 0
          dut_rec_dev.each do |r_dev|
            dut_rec_info = [dut_audio_info.merge({'card'=>r_dev['card'],
                                              'device'=>r_dev['device'],
                                              'file'=>"#{dut_test_file}.card#{r_dev['card']}",
                                              'duration'=>rec_duration,
                                              'type' => 'raw'})]
            play_rec_audio([host_audio_info.merge({'sys'=>@equipment['server1'],
                                                   'file'=>ref_path,
                                                   'duration'=>duration,
                                                   'type'=>'wav',
                                                   'playout_func' => :host_playout})], 
                                                   dut_rec_info)
					  t_file = File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}")
						scp_pull_file(dut_ip, "#{dut_test_file}.card#{r_dev['card']}", t_file)
						test_audio << t_file
					end
				when 'play+record'
          test_result &= dut_play_dev.length > 0 && dut_rec_dev.length > 0
          dut_play_dev.each do |p_dev|
            dut_rec_dev.each do |r_dev|
              next if p_dev['card_info'] != r_dev['card_info']
              dut_rec_info = [dut_audio_info.merge({'card'=>r_dev['card'],
                                                'device'=>r_dev['device'],
                                                'file'=>"#{dut_test_file}.card#{r_dev['card']}",
                                                'duration'=>rec_duration,
                                                'type' => 'raw'})]
              dut_play_info = [dut_audio_info.merge({'card'=>p_dev['card'],
                                                 'device'=>p_dev['device'],
                                                 'file'=>dut_src_file,
                                                 'duration'=>duration,
                                                 'type'=>'wav'})]
              play_rec_audio(dut_play_info, dut_rec_info)
              t_file = File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}")
              scp_pull_file(dut_ip, "#{dut_test_file}.card#{r_dev['card']}", t_file)
              test_audio << t_file
            end
          end
				else
					raise "Test type #{test_type} not supported"
			end
      
      test_audio.each do |current_audio|
        processed_audio = current_audio + '.processed'
        remove_offset(current_audio, processed_audio, audio_info['sample_length']/8, audio_info['rate'], audio_info['channels'])
        staf_req = staf_handle.submit(audio_server, "DEJAVU","MATCH FILE #{processed_audio}") 
        staf_result = STAFResult.unmarshall_response(staf_req.result)
				if staf_req.rc == 0 && staf_result['song_name'] == audio_name
					@results_html_file.add_rows_to_table(res_table,[[buffer_size, period, 
					                                                ["Passed",{:bgcolor => "green"}],
					                                                "Recorded audio matched expected audio: wanted #{audio_name}, got #{staf_result['song_name']}"]])
				else
					test_result = false
					audio = staf_req.rc == 0 ? staf_result['song_name'] : 'no match found'
					@results_html_file.add_rows_to_table(res_table,[[buffer_size, period,
					                                                ["Failed",{:bgcolor => "red"}],
					                                                "Recorded audio did not match expected audio: wanted #{audio_name}, got #{audio}"]])
				end
			end
    end
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed, audio has problems see table in link for details")
  end
end

