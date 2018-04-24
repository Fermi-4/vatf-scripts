require File.dirname(__FILE__)+'/../default_test_module' 
#require 'gnuplot.rb'
####### Setup Information ##########
## on AM335x, DCAN works in profile 1
################################
include LspTestScript

def setup
    super
end

def run
    perf_data = []
    # Collect all parameters from test case/bench/dut
    dut_can_channel = @test_params.params_chan.instance_variable_defined?(:@can_channel_number) ? @test_params.params_chan.can_channel_number[0] : 'can0'
    kvaser_can_channel = @equipment['dut1'].params['kvaser_can_port'][dut_can_channel]
    test_type = @test_params.params_chan.instance_variable_defined?(:@can_test_type) ? @test_params.params_chan.can_test_type[0] : 'legacy'
    databaudrate = @test_params.params_chan.instance_variable_defined?(:@databaudrate_in_kbps) ? @test_params.params_chan.databaudrate_in_kbps[0] : @test_params.params_chan.baudrate_in_kbps[0]
    conversion_unit = {'sec'=>1,'min'=>60,'hour'=>3600}
    duration = @test_params.params_chan.duration[0].to_i * conversion_unit[@test_params.params_chan.duration_units[0]].to_i
    can_type=determine_can_ip
    can_params = {'baudrate'=>@test_params.params_chan.baudrate_in_kbps[0].to_i*1000,'direction'=>@test_params.params_chan.direction[0],'test_duration'=>duration,'kvaser_channel'=>kvaser_can_channel, 'dut_channel'=>dut_can_channel, 'can_type'=>can_type, 'test_type'=>test_type,'databaudrate'=>databaudrate.to_i*1000} 
    
    mutex_timeout = duration*1000
    staf_mutex("kvasercan", mutex_timeout) do

       # Check presence of required can channels on test equipment and dut
       if (@equipment['can_kvaser'].check_channel(can_params)==false)
           set_result(FrameworkConstants::Result[:fail], "Check kvaser tool connection to PC - the channel cannot be listed on PC")
           return
       end
       if (check_dut_can_chan(dut_can_channel)==false)
           set_result(FrameworkConstants::Result[:fail], "DUT can channel is not found - check the dtb/config/switch settings on EVM")
           return
       end

       # Configure dut for the communication
       configure_dut_can_chan(can_params)
       if (can_params['direction']=='tx')
          initial_dut_can_stats=get_dut_stats
          initial_stats=/\d* frames\/s\s*\S*max tx rate/.match(initial_dut_can_stats).to_s.gsub("frames/s",'').gsub('max tx rate','').strip.to_i
          start_transmit(can_params)
          server_side_stats=@equipment['can_kvaser'].receive(can_params)
          if (server_side_stats == false)
             set_result(FrameworkConstants::Result[:fail], "Unable to receive on can test equipment side. Check if receive application is present and if the bitrates are supported by the test application.")
             return
          end
          stop_transmit(can_params)
          final_dut_can_stats=get_dut_stats
          final_stats=/\d* frames\/s\s*\S*max tx rate/.match(final_dut_can_stats).to_s.gsub("frames/s",'').gsub('max tx rate','').strip.to_i
          match=final_stats - initial_stats
          if (can_params['can_type'] == "dcan")
             perf_data << {'name' => "Server Side Average Rate", 'value' => server_side_stats["mean_rate"], 'units' => "msg/s"}
             perf_data << {'name' => "Server Side Error Report", 'value' => server_side_stats["sum_error"], 'units' => "msg"}
          else
             perf_data << {'name' => "Server Side Average Rate", 'value' => server_side_stats["mean_rx"], 'units' => "msg/s"}
             perf_data << {'name' => "Server Side Total Report", 'value' => server_side_stats["total"], 'units' => "msg"}
          end
          perf_data << {'name' => "DUT Side Max TX Rate", 'value' => match, 'units' => "frames/s"}
       else
          initial_dut_can_stats=get_dut_stats
          initial_stats=/\d* frames\/s\s*\S*max rx rate/.match(final_dut_can_stats).to_s.gsub("frames/s",'').gsub('max rx rate','').strip.to_i
          start_receive(can_params)
          if (@equipment['can_kvaser'].transmit(can_params) == false)
           set_result(FrameworkConstants::Result[:fail], "Unable to transmit on can test equipment side. Check if transmit application is present and if the bitrates are supported by the test application.")
           return
          end
          stop_receive(can_params)
          final_dut_can_stats=get_dut_stats
          final_stats=/\d* frames\/s\s*\S*max rx rate/.match(final_dut_can_stats).to_s.gsub("frames/s",'').gsub('max rx rate','').strip.to_i
          match = final_stats - initial_stats
          perf_data << {'name' => "DUT Side Max RX Rate", 'value' => match, 'units' => "frames/s"}
       end
       if perf_data.size > 0
          set_result(FrameworkConstants::Result[:pass], "Performance data collected",perf_data)
       else
          set_result(FrameworkConstants::Result[:fail], "Could not get Performance data")
       end
  end
end

def check_dut_can_chan(chan)
  response=@equipment['dut1'].send_cmd("grep #{chan} /proc/net/dev") 
  @equipment['dut1'].log_info("DUT response is #{@equipment['dut1'].response}")
  if response.to_s.strip.empty?
     @equipment['dut1'].log_info("DUT can channel is not found - check the dtb/config/switch settings on EVM")
     return false
  end
end

def determine_can_ip
  response=@equipment['dut1'].send_cmd("ls /proc/device-tree/*|grep mcan")
  if (response.include? "mcan@")
    can_ip="mcan"
  else
    can_ip="dcan"
  end
  can_ip
end

def configure_dut_can_chan(can_params)
  @equipment['dut1'].send_cmd("ip link set #{can_params['dut_channel']} down", @equipment['dut1'].prompt)
  if (can_params['can_type'] == "dcan")
     @equipment['dut1'].send_cmd("ip link set #{can_params['dut_channel']} type can bitrate #{can_params['baudrate']}", @equipment['dut1'].prompt)
  else
     if (can_params['test_type'] == "legacy")
        @equipment['dut1'].send_cmd("ip link set #{can_params['dut_channel']} type can bitrate #{can_params['baudrate']} dbitrate #{can_params['baudrate']} fd on", @equipment['dut1'].prompt)
     else
        @equipment['dut1'].send_cmd("ip link set #{can_params['dut_channel']} type can bitrate #{can_params['baudrate']} dbitrate #{can_params['databaudrate']} fd on", @equipment['dut1'].prompt)
     end
  end
  @equipment['dut1'].send_cmd("ip link set #{can_params['dut_channel']} up", @equipment['dut1'].prompt)
end

def start_transmit(can_params)
  if (can_params['can_type'] == "mcan" && can_params['test_type'] == "canfd")
     additional_params= " -f"
  end
     @equipment['dut1'].send_cmd("cangen #{can_params['dut_channel']} -g 0 -i #{additional_params} &", @equipment['dut1'].prompt)    
end

def stop_transmit(can_params)
     @equipment['dut1'].send_cmd("killall cangen", @equipment['dut1'].prompt)        
end

def start_receive(can_params)
     @equipment['dut1'].send_cmd("killall candump", @equipment['dut1'].prompt)        
     @equipment['dut1'].send_cmd("candump -L #{can_params['dut_channel']} -s 2 &", @equipment['dut1'].prompt)        
end

def stop_receive(can_params)
  count=0
  if (can_params['can_type'] == "mcan" && can_params['test_type'] == "canfd")
     rx_output=@equipment['dut1'].response
  end
     @equipment['dut1'].send_cmd("killall candump", @equipment['dut1'].prompt)        
  if (can_params['can_type'] == "mcan" && can_params['test_type'] == "canfd")
     rx_output.each_line{|line|
         if (line.include? "##")
            puts "FD message detected"
         else
            set_result(FrameworkConstants::Result[:fail], "Could not detect FD messages as expected")
            return
         end
       }
  end
end

def get_dut_stats
  stats=@equipment['dut1'].send_cmd("cat /proc/net/can/stats")
end

