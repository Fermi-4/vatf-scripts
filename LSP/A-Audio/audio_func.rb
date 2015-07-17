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
  dut_rec_dev, dut_play_dev = setup_devices(@equipment['dut1'], 0.6)
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
                                                 'type'=>'raw',
                                                 'file'=>local_test_file})
      test_audio = []
			case (test_type)
				when 'play'
					play_rec_audio(dut_play_info, host_chk_rec_info.merge({'sys'=>@equipment['server1'],
																															   'duration'=>rec_duration,
																															   'type'=>'raw',
																															   'playout_func' => :host_rec}))
				  test_audio << host_chk_rec_info['file']
				when 'record'
					play_rec_audio([host_audio_info.merge({'sys'=>@equipment['server1'],
																								 'file'=>ref_path,
																								 'duration'=>duration,
																								 'type'=>'wav',
																								 'playout_func' => :host_playout})], 
																								 dut_rec_info)
					dut_rec_dev.each do |r_dev|
					  t_file = File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}")
						scp_pull_file(dut_ip, "#{dut_test_file}.card#{r_dev['card']}", t_file)
						test_audio << t_file
					end
				when 'play+record'
					play_rec_audio(dut_play_info, dut_rec_info)
					dut_rec_dev.each do |r_dev|
					  t_file = File.join(@linux_temp_folder, "local_test_file.card#{r_dev['card']}")
						scp_pull_file(dut_ip, "#{dut_test_file}.card#{r_dev['card']}", t_file)
						test_audio << t_file
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

#Function to remove the dc offset of an audio file, takes
#  infile, string containing the path of the audio file
#  out_file, string containing the path where the processed audio
#            will be stored
#  fmt_bytes, int indicating the number of bytes per channel of a sample
#  s_rate, int indicating the sample rate of the source audio
#  channels, int indicating the number of audio channels in the audio
#  add_wav, boolean indicating if a wav header should be added to processed audio
#  is_wav, boolean indicating if the source file is wav container file
def remove_offset(in_file, out_file, fmt_bytes=2, s_rate=44100, channels=2, add_wav=true, is_wav=false)
  data = []
  d_means = []
  n_arrs = []
  pack_type = case(fmt_bytes)
                when 1
                  'c'
                when 2
                  's<'
                when 3,4
                  'l<'
                else
                  'q<'
              end
  channels.times { |i| data[i] = [] } 
  data_size = File.size(in_file)
  File.open(in_file, 'rb') do |ifd|
    ifd.read(44) if is_wav
    while !ifd.eof?
		  channels.times { |i| data[i] << (ifd.read(fmt_bytes).unpack(pack_type)[0]) }
		end
  end
  channels.times { |i| d_means << mean(data[i]) }
  puts "These are the channels means #{d_means.to_s}"
  channels.times do |i| 
    d_means[i] =  0  if d_means[i] < 130 && d_means[i] > -130
    n_arrs[i] = data[i].collect { |j| j - d_means[i] }
  end
  File.open(out_file, 'wb') do |ofd|
    if add_wav
			ofd.write('RIFF')
			ofd.write([data_size + 36].pack('l<'))
			ofd.write('WAVE')
			ofd.write('fmt ')
			ofd.write([16].pack('l<'))
			ofd.write([1].pack('s<'))
			ofd.write([channels].pack('s<'))
			ofd.write([s_rate].pack('l<'))
			ofd.write([s_rate*fmt_bytes*channels].pack('l<'))
			ofd.write([fmt_bytes*channels].pack('s<'))
			ofd.write([fmt_bytes*8].pack('s<'))
			ofd.write('data')
			ofd.write([data_size].pack('l<'))
		end
		if channels == 1
		  ofd.write(n_arrs[0].pack(pack_type+'*'))
		else
      ofd.write(n_arrs[0].zip(*n_arrs[1..-1]).flatten.pack(pack_type+'*'))
    end
  end
end
