require File.dirname(__FILE__)+'/audio_utils'
 
#Function to obtain audio recording device information, takes
#  dut, (Optional) the driver object used to communicate with the equipment whose
#       recording device information will be parsed
#Returns the array specified in parse_dev_info
def get_pulseaudio_rec_dev(dut=@equipment['dut1'])
  dut.send_cmd("pulseaudio --start; pactl list", dut.prompt, 15)
  parse_pulseaudio_dev_info(dut.response, "Source")
end

#Function to obtain audio playout device information, takes
#  dut, (Optional) the driver object used to communicate with the equipment whose
#       recording device information will be parsed
#Returns the array specified in parse_dev_info
def get_pulseaudio_play_dev(dut=@equipment['dut1'])
  dut.send_cmd("pulseaudio --start; pactl list", dut.prompt, 15)
  parse_pulseaudio_dev_info(dut.response, "Sink")
end

#Function to parse the string returned by pactl list
#Returns an array of hashtables of type type
#        containing the device information of all the first card/device
#        that matche type. . The hash(es) returned contain
#        the following entries {'card'=><card number>,
#                               'card_info' => <card description>,
#                               'device' => <device number>,
#                               'device_info' => <device desciption>}
def parse_pulseaudio_dev_info(string, type)
  devs_info = get_sections(string, /^[\w ]+#\d+/i)
  parsed_inf = {}
  result = []
  devs_info.each do |t, info|
    next if !t.match(/#{type}/)
    dev_info = get_sections(info,/^\t{1}\w.*?:/m)
    if dev_info.has_key?('Ports:')
      parsed_inf[t] = {}
      dev_info.each do |d_key, d_info|
        parsed_inf[t][d_key] = {}
        if d_info.match(/^\t+\w.*?[:=]/)
          parsed_inf[t][d_key] = get_sections(d_info,/^\t+\w.*?[:=]/)
        else
          parsed_inf[t][d_key] = d_info.strip()
        end
      end
    end 
  end
  
  parsed_inf.each do |c, inf|
    c_id = c.match(/.*?#(\d+)/)[1]
    result << {'card' => c_id,
               'card_info' => inf['Description:'],
               'device' => inf['Name:'],
               'device_info' => inf['Sample Specification:']}
  end

  result
end

#Function to create the aplay and arecord command line arguments, takes
#  audio_info, a Hash whose entries are:
#                'card' => <int>           :card id
#                'device' => <int>        :device id 
#                'type' => <string>       :file type (voc, wav, raw or au)
#                'duration' => <number>,  :record/play time in secs
#                'rate' => <int>          :sampling rate in Hz 
#                'format' => <string>     :data format of the audio samples one of
#                                          S8, U8, S16_LE, S16_BE, U16_LE, U16_BE,
#                                          S24_LE, S24_BE, U24_LE, U24_BE, S32_LE,
#                                          S32_BE, U32_LE, U32_BE, FLOAT_LE,
#                                          FLOAT_BE, FLOAT64_LE, FLOAT64_BE,
#                                          IEC958_SUBFRAME_LE, IEC958_SUBFRAME_BE,
#                                          MU_LAW, A_LAW, IMA_ADPCM, MPEG, GSM,
#                                          SPECIAL, S24_3LE, S24_3BE, U24_3LE,
#                                          U24_3BE, S20_3LE, S20_3BE, U20_3LE,
#                                          U20_3BE, S18_3LE, S18_3BE, U18_3LE
#                'channels' => <int>      :number of audio channels, 1(mono), 
#                                          2(stereo), etc
#                'period-size'=> <int>    :distance between interrupts is # frames
#                'buffer-size'=> <int>    :buffer duration is # frames
#                 'file' => <string>      :audio source/destination file path
def prep_audio_string(audio_info={}, add_opts='')
  audio_inf = {'card' => 0, 'device' => 0, 'type' => 'raw', 
               'rate' => 8000, 
               'format' => 's16le', 'channels' => 2, 
               'file' => nil}.merge(audio_info)
  raise "Audio file not specified" if !audio_inf['file']
  "-d #{audio_inf['card']} --latency=#{audio_inf['period-size']} " \
  "--process-time=#{audio_inf['buffer-size']}" \
  "--rate=#{audio_inf['rate']} --format=#{audio_inf['format'].downcase().delete("_")} " \
  "--channels=#{audio_inf['channels']} --file-format=wav " \
  " #{add_opts} #{audio_inf['file']}" 
end

#Function to record audio in a file, takes an array of
#  audio_info, a Hash whose entries are:
#               'card' => <int>          :card id
#               'device' => <int>        :device id 
#               'type' => <string>       :file type (voc, wav, raw or au)
#               'duration' => <number>,  :record/play time in secs
#               'rate' => <int>          :sampling rate in Hz 
#               'format' => <string>     :data format of the audio samples one of
#                                         S8, U8, S16_LE, S16_BE, U16_LE, U16_BE,
#                                         S24_LE, S24_BE, U24_LE, U24_BE, S32_LE,
#                                         S32_BE, U32_LE, U32_BE, FLOAT_LE,
#                                         FLOAT_BE, FLOAT64_LE, FLOAT64_BE,
#                                         IEC958_SUBFRAME_LE, IEC958_SUBFRAME_BE,
#                                         MU_LAW, A_LAW, IMA_ADPCM, MPEG, GSM,
#                                         SPECIAL, S24_3LE, S24_3BE, U24_3LE,
#                                         U24_3BE, S20_3LE, S20_3BE, U20_3LE,
#                                         U20_3BE, S18_3LE, S18_3BE, U18_3LE
#               'channels' => <int>      :number of audio channels, 1(mono), 
#                                         2(stereo), etc
#               'period-size'=> <int>    :distance between interrupts is # frames
#               'buffer-size'=> <int>    :buffer duration is # frames
#               'file' => <string>       :destination file path
#               'sys' => <driver object> :object used to communincate with the
#                                         system in whic the audio will be recorded
def rec_audio(audio_info)
  r_sys = audio_info[0]['sys']
  r_string = 'pulseaudio --start; pids=( ) ; pacat -r ' + prep_audio_string(audio_info[0], '--volume=50000 --raw') + ' & pids+=( $! )' 
  audio_info[1..-1].each do |r_info|
    r_string += " ; pacat -r " + prep_audio_string(r_info, '--volume=50000 --raw') + ' & pids+=( $! )'
    r_sys = r_info['sys']
  end
  r_string += " ; pidof pacat && sleep #{audio_info[0]['duration']} ; kill ${pids[@]}"
  r_sys.send_cmd(r_string, r_sys.prompt, audio_info[0]['duration'].to_i + 1)
end

#Function to play audio from a file, takes an array of
#  audio_info, a Hash whose entries are:
#               'card' => <int>          :card id
#               'device' => <int>        :device id 
#               'type' => <string>       :file type (voc, wav, raw or au)
#               'duration' => <number>,  :record/play time in secs
#               'rate' => <int>          :sampling rate in Hz 
#               'format' => <string>     :data format of the audio samples one of
#                                         S8, U8, S16_LE, S16_BE, U16_LE, U16_BE,
#                                         S24_LE, S24_BE, U24_LE, U24_BE, S32_LE,
#                                         S32_BE, U32_LE, U32_BE, FLOAT_LE,
#                                         FLOAT_BE, FLOAT64_LE, FLOAT64_BE,
#                                         IEC958_SUBFRAME_LE, IEC958_SUBFRAME_BE,
#                                         MU_LAW, A_LAW, IMA_ADPCM, MPEG, GSM,
#                                         SPECIAL, S24_3LE, S24_3BE, U24_3LE,
#                                         U24_3BE, S20_3LE, S20_3BE, U20_3LE,
#                                         U20_3BE, S18_3LE, S18_3BE, U18_3LE
#               'channels' => <int>      :number of audio channels, 1(mono), 
#                                         2(stereo), etc
#               'period-size'=> <int>    :distance between interrupts is # frames
#               'buffer-size'=> <int>    :buffer duration is # frames
#               'file' => <string>       :audio source file path
#               'sys' => <driver object> :object used to communincate with the
#                                         system in which the audio will be played
def play_audio(audio_info)
  p_sys = audio_info[0]['sys']
  p_string = 'pulseaudio --start; pids=( ) ; pacat -p ' + prep_audio_string(audio_info[0])  + ' & pids+=( $! )' 
  audio_info[1..-1].each do |p_info|
    p_string += " ; pacat -p " + prep_audio_string(p_info) + ' & pids+=( $! )'
  end
  p_string += " ; pidof pacat && sleep #{audio_info[0]['duration']} ; kill ${pids[@]}"
  p_sys.send_cmd(p_string, p_sys.prompt, audio_info[0]['duration'].to_i + 1)
end

#Function to play and record audio simultaneously, takes arrays of
#  play_audio_info and rec_audio_info, Hashes whose entries are:
#               'card' => <int>          :card id
#               'device' => <int>        :device id 
#               'type' => <string>       :file type (voc, wav, raw or au)
#               'duration' => <number>,  :record/play time in secs
#               'rate' => <int>          :sampling rate in Hz 
#               'format' => <string>     :data format of the audio samples one of
#                                         S8, U8, S16_LE, S16_BE, U16_LE, U16_BE,
#                                         S24_LE, S24_BE, U24_LE, U24_BE, S32_LE,
#                                         S32_BE, U32_LE, U32_BE, FLOAT_LE,
#                                         FLOAT_BE, FLOAT64_LE, FLOAT64_BE,
#                                         IEC958_SUBFRAME_LE, IEC958_SUBFRAME_BE,
#                                         MU_LAW, A_LAW, IMA_ADPCM, MPEG, GSM,
#                                         SPECIAL, S24_3LE, S24_3BE, U24_3LE,
#                                         U24_3BE, S20_3LE, S20_3BE, U20_3LE,
#                                         U20_3BE, S18_3LE, S18_3BE, U18_3LE
#               'channels' => <int>      :number of audio channels, 1(mono), 
#                                         2(stereo), etc
#               'period-size'=> <int>    :distance between interrupts is # frames
#               'buffer-size'=> <int>    :buffer duration is # frames
#               'file' => <string>       :audio source/destination file path
#               'sys' => <driver object> :object used to communincate with the
#                                         system in which the audio will be played/recorded
def play_rec_audio(play_audio_info, rec_audio_info)
  r_sys = rec_audio_info[0]['sys']
  r_string = 'pulseaudio --start; pids=( ) ; pacat -r ' + prep_audio_string(rec_audio_info[0],'--volume=50000 --raw') + ' & pids+=( $! )' 
  rec_audio_info[1..-1].each do |r_info|
    r_string += ' ; pacat -r ' + prep_audio_string(r_info,'--volume=50000 --raw') + ' & pids+=( $! )'
  end
  r_sys.send_cmd(r_string, r_sys.prompt, 5)
  r_sys.send_cmd("\necho ${pids[@]}",r_sys.prompt,5)
  r_pids = r_sys.response.scan(/^\d+.*/).join(' ')
  if play_audio_info[0]['playout_func']
    send(play_audio_info[0]['playout_func'],play_audio_info)
  else
		p_sys = play_audio_info[0]['sys']
    p_string = ' '
		if p_sys != r_sys
		  p_string = 'pulseaudio --start; pids=( ) ;'
    end
    p_string += 'pacat -p ' + prep_audio_string(play_audio_info[0]) + ' & pids+=( $! )'
    play_audio_info[1..-1].each do |p_info|
      p_string += " ; pacat -p " + prep_audio_string(p_info) + ' & pids+=( $! )'
    end
		p_string += " ; pidof pacat && sleep #{rec_audio_info[0]['duration'].to_i} ; kill ${pids[@]}"
		p_sys.send_cmd(p_string, p_sys.prompt, play_audio_info[0]['duration'].to_i + 5)
	end
  r_sys.send_cmd("kill #{r_pids}") 
  sleep(5) #wait 5 secs for recording to finish
end

#Function to setup (enable/disable, gains, etc) the audio devices
#before running the play/capture test, takes
#  sys, object used to communicate with the system where the volume of the control will
#       be set
#  volume, float representing the volume setting for the devices
#          [0-1] 0-silence, 1-100%
#Returns, two arrays. Element 0 contains the rec devices info and element
#         1 containg the playout devices info 
def setup_devices(sys=@equipment['dut1'], volume=0.6)
  config_devices(sys, volume)
  [get_pulseaudio_rec_dev, get_pulseaudio_play_dev(sys)]
end
