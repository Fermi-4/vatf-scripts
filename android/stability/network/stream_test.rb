require File.dirname(__FILE__)+'/../../performance/wlan/wlan'
require 'timeout'

def setup
  self.as(AndroidTest).setup
  if @test_params.params_chan.network_type[0].strip.downcase == 'wlan'
    enable_wlan 
  else
    enable_ethernet
  end
end

def run
  test_result = FrameworkConstants::Result[:nry]
  test_comment =''
  send_adb_cmd("logcat -c")
  if @test_params.params_chan.network_type[0].strip.downcase == 'wlan'
    run_wlan_test(@test_params.params_chan.wlan_setup_seq)
  end
  #
  #adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.LAUNCHER -n com.daroonsoft.player/.HomeActivity -d http://158.218.103.22/FILE@TS/test2.3gp
  #
  cycle_duration = -1
  start_time = Time.now
  cycle_duration = @test_params.params_chan.test_duration[0].to_i if @test_params.params_chan.instance_variable_defined?(:@test_duration)
  iteration = 1
  begin 
    @test_params.params_chan.media_streams.each do |current_stream_plus_duration|
      current_stream,duration=current_stream_plus_duration.split(":")
      puts "Playing #{current_stream} iteration #{iteration}, estimated time #{duration} sec"
      send_adb_cmd("logcat -c")
      stream_start=Time.now
      send_adb_cmd("shell am start -W #{@test_params.params_chan.start_stream_intent[0]} -d http://#{@test_params.params_chan.stream_server[0]}/#{current_stream}")
      begin
        status = Timeout::timeout(duration.to_i+30) { 
          while !send_adb_cmd("logcat -d -s #{@test_params.params_chan.player_filter[0]}").include?("#{@test_params.params_chan.player_ended_string[0]}")
            sleep 5
          end
          Time.now
        }
      if (status - stream_start) < (duration.to_i)
          send_adb_cmd("logcat -d")
          test_result = FrameworkConstants::Result[:fail]
          test_comment += "Iteration #{iteration}, Stream #{current_stream} ended before expected\n"
      end
      rescue Exception => e
          send_adb_cmd("logcat -d")
          test_result = FrameworkConstants::Result[:fail]
          test_comment += "Iteration #{iteration}, Stream #{current_stream} did not play or did not finish on the expected time\n#{e.to_s}\n"
      end
    end
    send_events_for(['__back__','__directional_pad_right__','__directional_pad_right__','__enter__'])
    iteration += 1
  end while cycle_duration > (Time.now - start_time)
  if test_result != FrameworkConstants::Result[:fail]
    test_result = FrameworkConstants::Result[:pass]
    test_comment = "All streams played successfully"
  end 
  ensure
    set_result(test_result, test_comment)
end

def get_up_ifaces_info
  result = {}
  if_info=send_adb_cmd("shell netcfg").split("\n")
  if_info.each do |cur_info|
    cur_iface = cur_info.split(/\s+/)
    result[cur_iface[0]]=cur_iface[2] if cur_iface[1].downcase.strip == 'up'
  end
  result
end

def get_down_ifaces_info
  result = []
  if_info=send_adb_cmd("shell netcfg").split("\n")
  if_info.each do |cur_info|
    cur_iface = cur_info.split(/\s+/)
    result << cur_iface[0] if cur_iface[1].downcase.strip == 'down'
  end
  result
end

def enable_ethernet
  ifaces = get_down_ifaces_info
  ifaces.each do |cur_iface|
    if cur_iface.match(/eth\d+/)
      send_adb_cmd("shell netcfg #{cur_iface} up")
      sleep 6
      send_adb_cmd("shell netcfg #{cur_iface} dhcp")
    end
  end
end


