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
  left_ref, right_ref = separate_audio_chans(ref_pcm_path)
  rec_duration = duration + 2
  table_title = ''
  use_plugins = @equipment['dut1'].name.match(/j7.*/) 
  dut_rec_dev, dut_play_dev = setup_devices(@equipment['dut1'], 0.6, use_plugins)
  table_title += "\n\nRec Dev " + dut_rec_dev.join("\nRec Dev ") + "\n\nPlay Dev " + dut_play_dev.join("\nPlay Dev ")
  dut_ip = get_ip_addr()
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([[table_title,{:bgcolor => "4863A0", :colspan => "4"}]], 
                                            {:border => "1",:width=>"20%"})
  @results_html_file.add_rows_to_table(res_table,[[["Buffer size (#frames)",{:bgcolor => "98AFC7"}], 
                                            ["Interrupt interval (#frames)", {:bgcolor => "98AFC7"}],
                                            ["Result", {:bgcolor => "98AFC7"}],
                                            ["Comment", {:bgcolor => "98AFC7"}]]]) 
  audio_info['buffer-size'] = @test_params.params_chan.buffer_size[0]
  audio_info['period-size'] = @test_params.params_chan.period[0]
  dut_audio_info = audio_info.merge({'sys'=>@equipment['dut1']})
  test_audio = []
  dut_rec_dev.each do |r_dev|
    next if r_dev['card_info'].match(/USB/) || r_dev['device_info'].match(/USB/)
    dut_play_dev.each do |p_dev|
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
  s_rate = audio_info['rate']
  test_audio.each do |current_audio|
    processed_audio = current_audio + '.processed'
    left_tst, right_tst = remove_offset(current_audio, processed_audio, audio_info['sample_length']/8, audio_info['rate'], audio_info['channels'])
    left_corr = get_correlation(left_ref[audio_info['rate']..-1], left_tst[0..-1*s_rate*2])
    right_corr = get_correlation(right_ref[audio_info['rate']..-1], right_tst[0..-1*s_rate*2])
    left_cross = get_correlation(left_ref[audio_info['rate']..-1], right_tst[0..-1*s_rate*2])
    right_cross = get_correlation(right_ref[audio_info['rate']..-1], left_tst[0..-1*s_rate*2])
    if left_corr > 0.9 && right_corr > 0.9 && left_cross.abs < 0.1 && right_cross.abs < 0.1
      @results_html_file.add_rows_to_table(res_table,[[audio_info['buffer-size'],
                                                       audio_info['period-size'], 
                                                      ["Passed",{:bgcolor => "green"}],
                                                      "Channels matched, correlations: left = #{left_corr} right = #{right_corr} cross = #{left_cross} & #{right_cross}"]])
    else
      test_result = false
      @results_html_file.add_rows_to_table(res_table,[[audio_info['buffer-size'],
                                                       audio_info['period-size'],
                                                      ["Failed",{:bgcolor => "red"}],
                                                       "Channels did not match, correlations: left = #{left_corr} right = #{right_corr}  cross = #{left_cross} & #{right_cross}"]])
    end  
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed, audio has problems see table in link for details")
  end
end

def get_correlation(ref_audio, test_audio)
   ref_idx = zero_crossing(ref_audio)
   test_idx = zero_crossing(test_audio)
   ref = ref_audio[ref_idx..-1]
   test = test_audio[test_idx..(ref.length+test_idx-1)]
   limit = [ref.length, test.length].min
   cross_correlation(ref[0..limit-1], test[0..limit-1])
end

def zero_crossing(arr)
   arr.each_index do |i| 
     if i + 3 < arr.length
       return i if (arr[i] < 0 && arr[i+1] <= 0 && arr[i+2] > 0 && arr[i+3] > 0) || arr[i] < 0 && arr[i+1] < 0 && arr[i+2] >= 0 && arr[i+3] > 0
     end
   end
end
