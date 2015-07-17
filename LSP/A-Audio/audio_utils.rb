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
  r_string = 'pids=( ) ; arecord ' + prep_audio_string(audio_info[0]) + ' & pids+=( $! )' 
  audio_info[1..-1].each do |r_info|
    r_string += " ; arecord " + prep_audio_string(r_info) + ' & pids+=( $! )' 
    r_sys = r_info['sys']
  end
  r_string += ' ; wait ${pids[@]}'
  r_sys.send_cmd(r_string, r_sys.prompt, audio_info[0]['duration'].to_i)
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
  p_string = 'pids=( ) ; aplay ' + prep_audio_string(audio_info[0])  + ' & pids+=( $! )' 
  audio_info[1..-1].each do |p_info|
    p_string += " ; aplay " + prep_audio_string(p_info)  + ' & pids+=( $! )' 
  end
  p_string += ' ; wait ${pids[@]}'
  p_sys.send_cmd(p_string, p_sys.prompt, audio_info[0]['duration'].to_i)
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
  r_string = 'arecord ' + prep_audio_string(rec_audio_info[0]) + " & "
  rec_audio_info[1..-1].each do |r_info|
    r_string += ' arecord ' + prep_audio_string(r_info) + " & "
  end
  r_sys.send_cmd(r_string, /Recording\s*.+/im, 5)
  p_sys = play_audio_info[0]['sys']
  p_string = 'pids=( ) ; aplay ' + prep_audio_string(play_audio_info[0]) + ' & pids+=( $! )'
  play_audio_info[1..-1].each do |p_info|
    p_string += " ; aplay " + prep_audio_string(p_info) + ' & pids+=( $! )'
  end
  p_string += ' ; wait ${pids[@]}'
  p_sys.send_cmd(p_string, p_sys.prompt, play_audio_info[0]['duration'].to_i)
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
  if wav_info.match(/pcm_\w\d+\w+/i)
    result['fmt'] = wav_info.match(/pcm_(\w\d+\w+)/i).captures[0]
    sf, endian = result['fmt'].match(/(\w\d+)(\w+)/i).captures[0..1]
    result['format'] = "#{sf.upcase()}_#{endian.upcase()}"  
  else
    result['fmt'] = wav_info.match(/pcm_(\w+)/i).captures[0]
    result['format'] = result['fmt'].upcase()
  end
  result['sample_length'] = result['fmt'].match(/\d+/)[0].to_i
  if wav_info.match(/\d+\s*channels/i)
    result['channels'] = wav_info.match(/(\d+)\s*channels/i).captures[0].to_i
  elsif wav_info.match(/stereo/i)
    result['channels'] = 2
  elsif wav_info.match(/mono|alaw|ulaw/i)
    result['channels'] = 1
  end
  result['rate'] = wav_info.match(/(\d+)\s*Hz/i).captures[0].to_i
  result
end

#Function to set the volume of an audio control, takes
#  level, float in the range [0,1] that specify the volume (0-no volume, 1-max volume)
#  ctrl, mixer control whose volume will be set
#  card, id of the card where the volume will be set
#  sys, object used to communicate with the system where the volume of the control will
#       be set
#Returns, true if the volume was set successfully false otherwise
def set_volume(level=0.75, ctrl='PCM', card=0,sys=@equipment['dut1'])
  sys.send_cmd("amixer -c #{card} sget '#{ctrl}'", sys.prompt, 10)
  return true if sys.response.match(/Unable\s*to\s*find.*?#{ctrl}/im)
  vol_limit = sys.response.match(/Limits:\s*(?:playback|capture)\s*\d+\s*-\s*(\d+)/i).captures[0].to_i
  new_volume = (vol_limit*level).ceil().to_int
  new_volume = level < 0 ? 0 : level > 1 ? vol_limit : new_volume
  sys.send_cmd("amixer -c #{card} sset '#{ctrl}' #{new_volume}", sys.prompt, 10)
  new_level = sys.response.match(/(?:playback|capture)\s*(\d+).*?dB\]/i).captures[0].to_i
  new_volume == new_level
end

#Function to set the state of an audio control, takes
#  state, string containing the state of the control i.e on
#  ctrl, mixer control whose state will be set
#  card, id of the card where the ctrl will be set
#  sys, object used to communicate with the system where the volume of the control will
#       be set
#Returns, true if the volume was set successfully false otherwise
def set_state(state, ctrl, card=0, sys=@equipment['dut1'])
  ctrl_arr = ctrl
  ctrl_arr = [ctrl] if !ctrl.kind_of?(Array)
  local_ctrl = "'#{ctrl_arr[0]}'"
  ctrl_arr[1..-1].each {|c_info| local_ctrl += " '#{c_info}'"}
  sys.send_cmd("amixer -c #{card} sget #{local_ctrl}", sys.prompt, 10)
  return true if sys.response.match(/Unable\s*to\s*find.*?#{ctrl_arr[0]}/im)
  sys.send_cmd("amixer -c #{card} sset #{local_ctrl} '#{state}'", sys.prompt, 10)
  new_state = sys.response.match(/(?:playback|capture|item\d+:).*?(#{state})\]*/i).captures[0].to_i
  state == new_state
end

#Function to set the state of an audio control using amixer cset, takes
#  state, string containing the state of the control i.e on
#  ctrl, mixer control whose state will be set
#  card, id of the card where the ctrl will be set
#  sys, object used to communicate with the system where the volume of the control will
#       be set
#Returns, true if the volume was set successfully false otherwise
def cset_state(state, ctrl, card=0, sys=@equipment['dut1'])
  ctrl_arr = ctrl
  ctrl_arr = [ctrl] if !ctrl.kind_of?(Array)
  local_ctrl = "'#{ctrl_arr[0]}'"
  ctrl_arr[1..-1].each {|c_info| local_ctrl += " '#{c_info}'"}
  sys.send_cmd("amixer -c #{card} cget name=#{local_ctrl}", sys.prompt, 10)
  return true if sys.response.match(/Cannot\s*find\s*the\s*given\s*element\s*from\s*control/im)
  sys.send_cmd("amixer -c #{card} cset name=#{local_ctrl} #{state}", sys.prompt, 10)
  new_state = sys.response.match(/values=\s*(#{state})/i).captures[0].to_i if 
  state == new_state
end

#Function to setup (enable/disable, gains, etc) the audio devices
#before running the play/capture test, takes
#  sys, object used to communicate with the system where the volume of the control will
#       be set
#Returns, two arrays. Element 0 contains the rec devices info and element
#         1 containg the playout devices info  
def setup_devices(sys=@equipment['dut1'], volume=0.6)
  dut_rec_dev = []
  dut_play_dev = []
  sys.send_cmd("ls /sys/class/sound/ | grep 'card'", sys.prompt,10)
  c_dirs = sys.response.scan(/^card[^\s]*/)
  c_dirs.each do |card|
    sys.send_cmd("echo \"TI $(cat /sys/class/sound/#{card}/id)\"", sys.prompt,10)
    rec_dev_info = sys.response.match(/^TI\s*([^\n\r]+)/).captures[0].gsub(/\s*/,'')
    rec_dev_info += '|' + rec_dev_info.gsub(/x/,'')
    play_dev_info = rec_dev_info
    rec_dev_info = @test_params.params_chan.rec_device[0] if @test_params.params_chan.instance_variable_defined?(:@rec_device)
    play_dev_info = @test_params.params_chan.rec_device[0] if @test_params.params_chan.instance_variable_defined?(:@play_device)
    d_rec_dev = get_audio_rec_dev(rec_dev_info)
    d_play_dev = get_audio_play_dev(play_dev_info)
    #Turning on playout/capture ctrls
    if d_rec_dev
      ['Left PGA Mixer Line1L', 'Right PGA Mixer Line1R', 
       'Left PGA Mixer Mic3L', 'Right PGA Mixer Mic3R', 'Output Left From MIC1LP',
       'Output Left From MIC1RP', 'Output Right From MIC1RP',
       'Left PGA Mixer Mic2L', 'Right PGA Mixer Mic2R'
       ].each do |ctrl|
          puts "Warning: Unable to turn on #{ctrl}!!!" if !set_state('on',ctrl, d_rec_dev['card'])
      end
    cset_state('on','ADC Capture Switch', d_rec_dev['card'])
    if @equipment['dut1'].name == 'am43xx-epos'
      ['MIC1RP P-Terminal', 'MIC1LP P-Terminal'].each {|ctrl| set_state('FFR 10 Ohm', ctrl, d_rec_dev['card'])}
    end
    #Setting volume
    set_volume(0, 'ADC', d_rec_dev['card'])
      ['PCM', 'PGA', 'Mic PGA'].each do |ctrl|
        puts "Warning: Unable to set the volume in #{ctrl}, playback volume may be low!!!" if !set_volume(volume, ctrl, d_play_dev['card'])
      end
      dut_rec_dev << d_rec_dev
    end
    if d_play_dev
      [['Speaker Driver', 0], 'Speaker Left', 'Speaker Right', ['SP Driver', 0], 
        'SP Left', 'SP Right', 'Output Left From Left DAC', 'Output Right From Right DAC',
        ['HP Driver',0], 'HP Left', 'HP Right'].each do |ctrl|
        puts "Warning: Unable to turn on #{ctrl}!!!" if !set_state('on',ctrl, d_play_dev['card'])
      end
      ['PCM', 'HP DAC', 'DAC', 'HP Analog', 'SP Analog', 'Speaker Analog', 'Mic PGA'].each do |ctrl|
        puts "Warning: Unable to set the volume in #{ctrl}, playback volume may be low!!!" if !set_volume(volume, ctrl, d_play_dev['card'])
      end
      dut_play_dev << d_play_dev
    end
  end
  [dut_rec_dev, dut_play_dev]
end

#Function used to play an audio file on the host, takes
#  audio_info and array whose element are the data structure used by 
#  function prep_audio_string
def host_playout(audio_info)
  p_sys = audio_info[0]['sys']
  p_sys.send_cmd("aplay -D hw:0,0 -d #{audio_info[0]['duration']} -t #{audio_info[0]['type']} " \
  "-r #{audio_info[0]['rate']} -f #{audio_info[0]['format']} " \
  "-c #{audio_info[0]['channels']} #{audio_info[0]['file']}", p_sys.prompt, audio_info[0]['duration'].to_i + 1)
end

#Function used to play an audio file on the host, takes
#  audio_info and array whose element are the data structure used by 
#  function prep_audio_string
def host_rec(audio_info)
  p_sys = audio_info[0]['sys']
  p_sys.send_cmd("arecord -D hw:0,0 -d #{audio_info[0]['duration']} -t #{audio_info[0]['type']} " \
  "-r #{audio_info[0]['rate']} -f #{audio_info[0]['format']} " \
  "-c #{audio_info[0]['channels']} #{audio_info[0]['file']}", p_sys.prompt, audio_info[0]['duration'].to_i + 1)
end
