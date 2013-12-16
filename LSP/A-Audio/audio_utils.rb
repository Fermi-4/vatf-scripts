require File.dirname(__FILE__)+'/../../lib/utils'
 
#Function to obtain audio recording device information, takes
#  card_info, (Optional) a string or regex to match in the card description
#  dev_info, (Optional) a string or regex to match in the device description
#  dut, (Optional) the driver object used to communicate with the equipment whose
#       recording device information will be parsed
#Returns an array of hashtables if card_info == nil and dev_info == nil,
#        or a hashtable containing the device information of the first card/device
#        that matches card_info and/or dev_info. The hash(es) returned contain
#        the following entries {'card'=><card number>,
#                               'card_info' => <card description>,
#                               'device' => <device number>,
#                               'device_info' => <device desciption>}
def get_audio_rec_dev(card_info=nil, dev_info=nil, dut=@equipment['dut1'])
  dut.send_cmd("arecord -l", dut.prompt, 5)
  parse_dev_info(dut.response, card_info, dev_info)
end

#Function to obtain audio playout device information, takes
#  card_info, (Optional) a string or regex to match in the card description
#  dev_info, (Optional) a string or regex to match in the device description
#  dut, (Optional) the driver object used to communicate with the equipment whose
#       recording device information will be parsed
#Returns an array of hashtables if card_info == nil and dev_info == nil,
#        or a hashtable containing the device information of the first card/device
#        that matches card_info and/or dev_info. The hash(es) returned contain
#        the following entries {'card'=><card number>,
#                               'card_info' => <card description>,
#                               'device' => <device number>,
#                               'device_info' => <device desciption>}
def get_audio_play_dev(card_info=nil, dev_info=nil, dut=@equipment['dut1'])
  dut.send_cmd("aplay -l", dut.prompt, 5)
  parse_dev_info(dut.response, card_info, dev_info)
end

#Function to parse the string returned by aplay/arecord -l
#Returns an array of hashtables if card_info == nil and dev_info == nil,
#        or a hashtable containing the device information of the first card/device
#        that matches card_info and/or dev_info. The hash(es) returned contain
#        the following entries {'card'=><card number>,
#                               'card_info' => <card description>,
#                               'device' => <device number>,
#                               'device_info' => <device desciption>}
def parse_dev_info(string, card_info=nil, dev_info=nil)
  devs_info = string.scan(/card\s*(\d+)\s*:([^,]+),\s*device\s*(\d+)\s*:(.*)/i)
  result = []
  devs_info.each {|c_info| result << {'card' => c_info[0],
                                      'card_info' => c_info[1],
                                      'device' => c_info[2],
                                      'device_info' => c_info[3]}}
  return result.detect {|c_info| (!card_info || c_info['card_info'].match(/#{card_info}/i)) &&
                                (!dev_info || c_info['device_info'].match(/#{dev_info}/i))} if card_info || dev_info
  result
end

#Function to compare the samples of two signals contained in two arrays, 
#it performs the cross_correlation of the samples returning the maximum value
#of the convolution of the array with minimum length against the array of
# maximum length, takes
#  arr1, an array of samples
#  arr2, an array of samples
#  coarse_check, float between 0 and 1 to run a 1000 byte check to detemine the 
#                indeces with the best possible matches. The index with the best
#                matches will be those where the check is >= coarse_check. 
#                To disable it set it to < 0
#Returns the maximum value of the convolution, the values are in the range
#[-1,1]
def compare_signals(arr1, arr2, coarse_check=-1)
  a1 = arr1
  a2 = arr2
  if arr1.length < arr2.length
    a1 = arr2
    a2 = arr1
  end
  steps = a1.length - a2.length
  res_arr = []
  c_check_arr = []
  if coarse_check > 0
    c_check_length = [1000, a2.length].min
    c_check_a2 = a2[0...c_check_length]
    max_check = -1
    (0..steps).each do |s|
      puts "At index " + s.to_s if s % (a2.length/4).to_i == 0
      c_check_sim = cross_correlation(a1[s...s+c_check_length], c_check_a2)
      if c_check_sim > max_check
        c_check_arr[0] = s 
        max_check = c_check_sim
        puts "got " + c_check_sim.to_s + " at " + s.to_s
      end
      c_check_arr << s if c_check_sim >= coarse_check
    end
    c_check_arr.delete_at(0) if c_check_arr.length > 1
    c_check_arr.each do |i|
      res_arr << cross_correlation(a1[i...i+a2.length], a2)
    end
  else
    max_check = -1
    (0..steps).each do |s|
      c_val = cross_correlation(a1[s..-1*(steps-s+1)], a2)
      if c_val > max_check
        max_check = c_val
        puts "got " + c_val.to_s + " at " + s.to_s
      end
      puts "At index " + s.to_s if s % (a2.length/4).to_i == 0
      res_arr << c_val
    end
  end
  res_arr.max
end

#Function to create the aplay and arecord command line arguments, takes
#  audio_info, a Hash whose entries are:
#               'card' => <int>           :card id
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
def prep_audio_string(audio_info={})
  audio_inf = {'card' => 0, 'device' => 0, 'type' => 'raw', 
                'duration' => 10, 'rate' => 8000, 
                'format' => 'SE16_LE', 'channels' => 2, 
                'file' => nil}.merge(audio_info)
  raise "Audio file not specified" if !audio_inf['file']
  "-D hw:#{audio_inf['card']},#{audio_inf['device']} -t #{audio_inf['type']} " \
  "-d #{audio_inf['duration']} -r #{audio_inf['rate']} -f #{audio_inf['format']} " \
  "-c #{audio_inf['channels']} --period-size=#{audio_inf['period-size']} " \
  "--buffer-size=#{audio_inf['buffer-size']} #{audio_inf['file']}" 
end

#Function to record audio in a file, takes
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
  rec_string = prep_audio_string(audio_info)
  sys = audio_info['sys']
  sys.send_cmd("arecord #{rec_string}", sys.prompt, audio_info['duration'].to_i)
end

#Function to play audio from a file, takes
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
  play_string = prep_audio_string(audio_info)
  sys = audio_info['sys']
  sys.send_cmd("aplay #{play_string}", sys.prompt, audio_info['duration'].to_i)
end

#Function to play and record audio simultaneously, takes
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
  r_string = prep_audio_string(rec_audio_info)
  r_sys = rec_audio_info['sys']
  r_sys.send_cmd("arecord #{r_string} &", /Recording\s*.+/im, 5)
  p_string = prep_audio_string(play_audio_info)
  p_sys = play_audio_info['sys']
  p_sys.send_cmd("aplay #{p_string}", p_sys.prompt, play_audio_info['duration'].to_i)
  sleep(5) #wait 5 secs for recording to finish
end

#Function to parse the information for wave audio files returned by the file command, takes
#  wav_info,  string containing the results of the command file <wav file>
#Returns a Hash whose entries are:
#  'endianness' => <string>   :endianness of the audio samples big or little
#  'sample_length' => <int>   :bits per sample per channel
#  'channels'      => <int>   :number of channels 1(mono), 2(stereo)
#  'rate' => <int>            :sampling rate in Hz
#  'format' => <string>       :S<16,32,20,...>_<L,B>E
def parse_wav_audio_info(wav_info)
  result = {}
  result['endianness'] = wav_info.match(/(\w+)-endian/i).captures[0]
  result['sample_length'] = wav_info.match(/(\w+)\s*bit/i).captures[0].to_i
  result['channels'] = 1
  result['channels'] = 2 if wav_info.match(/stereo/i)
  result['rate'] = wav_info.match(/(\d+)\s*Hz/i).captures[0].to_i
  endian = 'LE'
  endian = 'BE' if result['endianness'].strip().downcase == 'big'
  result['format'] = "S#{result['sample_length']}_#{endian}"
  result
end
