require File.dirname(__FILE__)+'/../default_target_test'
require File.dirname(__FILE__)+'/audio_utils'

include LspTargetTestScript

def run
  duration = 10
  table_title = ''
  test_type = @test_params.params_chan.test_type[0].strip.downcase
  dut_rec_dev, dut_play_dev = setup_devices(@equipment['dut1'], 0.6)
  dut_play_dev.select! {|p_dev| !p_dev['card_info'].match(/USB/) && !p_dev['device_info'].match(/USB/)}
  dut_rec_dev.select! {|r_dev| !r_dev['card_info'].match(/USB/) && !r_dev['device_info'].match(/USB/)}
  host_play_dev = get_audio_play_dev(nil,'analog',@equipment['server1'])
  host_play_dev = Hash.new('') if !host_play_dev
  @results_html_file.add_paragraph("")
  test_result = false
  comment = "Failed: "
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && systemctl stop weston && sleep 3', @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("modetest -c | grep -i connected | grep HDMI | grep -o '^[0-9]*'",@equipment['dut1'].prompt)
  hdmi_conn = @equipment['dut1'].response.match(/(^\d+)/im).captures[0] if @equipment['dut1'].response.match(/^\d+/im)
  case (test_type)
    when 'play'
      test_result = !dut_play_dev.empty?
      dut_play_dev.each do |p_dev|
        @equipment['dut1'].send_cmd("modetest -t -s #{hdmi_conn}:1280x720 &",/setting\s*mode.*?connectors\s*#{hdmi_conn}/) if hdmi_conn && p_dev['device_info'].match(/hdmi/im)
        @equipment['dut1'].send_cmd("time aplay -i -f cd -d #{duration} -D hw:#{p_dev['card']},#{p_dev['device']} /dev/urandom",
                                    /Playing\s*raw\s*data\s*'\/dev\/urandom'[^\r\n]+/im,10)
        
        test_result, cmt = get_result(duration, p_dev['device_info'])
        @equipment['dut1'].send_cmd("killall -9 modetest") if hdmi_conn && p_dev['device_info'].match(/hdmi/im)
        if !test_result
          comment += cmt
          break
        end
      end
    when 'record'
      dut_rec_dev.each do |r_dev|
        @equipment['dut1'].send_cmd("time arecord -i -f cd -d #{duration} -D hw:#{r_dev['card']},#{r_dev['device']} > /dev/null",
                                    /Recording\s*WAVE\s*'stdin'[^\r\n]+/im,10)
        test_result, cmt = get_result(duration, r_dev['device_info'])
        if !test_result
          comment += cmt
          break
        end
      end
    else
      raise "Test type #{test_type} not supported"
  end

  if test_result
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], comment)
  end
end

def get_result(duration, dev)
  return [false, "Audio op failed:\n#{@equipment['dut1'].response}"] if @equipment['dut1'].timeout?
  sleep(3)
  @equipment['dut1'].send_cmd(" ",/===\s*PAUSE\s*===/im, 5)
  sleep(3)
  @equipment['dut1'].send_cmd(" ",/.*/im, 5)
  sleep(2)
  @equipment['dut1'].send_cmd(" ",/===\s*PAUSE\s*===/im, 5)
  sleep(4.15)
  @equipment['dut1'].send_cmd(" ",/real.*?#{@equipment['dut1'].prompt}/im, 10)
  return [false, "Problem detected for audio op\n#{@equipment['dut1'].response}"] if @equipment['dut1'].response.match(/Error|underrun|overrun/im)
  minutes, secs = @equipment['dut1'].response.match(/real\s*(\d+)m\s*([\d\.]+)s/).captures
  t_secs = minutes.to_f * 60 + secs.to_f
  e_secs = duration.to_f + 7
  @results_html_file.add_paragraph("Result for #{dev}: #{e_secs <= t_secs}. Expected at least #{e_secs} sec delay, measured #{t_secs} sec".gsub(/[\r\n]+/,''))
  [e_secs <= t_secs, "Measured op + pause time is #{t_secs}, expected at least #{e_secs} sec delay"]
end
