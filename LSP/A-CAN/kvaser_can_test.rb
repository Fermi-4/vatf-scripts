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
  perf = []
  loop_iteration = 0
  can_channel = @test_params.params_chan.instance_variable_defined?(:@can_channel_number) ? @test_params.params_chan.can_channel_number[0] : 'can0'

  while (loop_iteration<@test_params.params_chan.loop_count[0].to_i)
	    @equipment['dut1'].send_cmd("ip link set #{can_channel} down", @equipment['dut1'].prompt, 1)
	    @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 1)
      @equipment['dut1'].send_cmd("ip link set #{can_channel} type can bitrate #{@test_params.params_chan.baudrate_in_kbps[0].to_i*1000} triple-sampling on", @equipment['dut1'].prompt, 1)
	    @equipment['dut1'].send_cmd("ip link set #{can_channel} up", @equipment['dut1'].prompt, 1)
	    loop_iteration = loop_iteration+1
	 end
	@equipment['dut1'].send_cmd("date", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("cat /proc/net/can/reset_stats", @equipment['dut1'].prompt, 1)
  start_can_statistics = @equipment['dut1'].response.split(/\r\n/)
	conversion_unit = {'sec'=>1000,'min'=>60000,'hour'=>3600000}
  duration = @test_params.params_chan.duration[0].to_i * conversion_unit[@test_params.params_chan.duration_units[0]].to_i
	params_to_can_kvaser = {'baudrate'=>	@test_params.params_chan.baudrate_in_kbps[0],'direction'=>@test_params.params_chan.direction[0],'test_duration'=>	duration} 
	@equipment['can_kvaser'].create_vbscript(params_to_can_kvaser)
	@equipment['can_kvaser'].transfer_kvaser_script(params_to_can_kvaser)
	@equipment['can_kvaser'].start_kvaser_script(params_to_can_kvaser)
	@equipment['dut1'].send_cmd("date", @equipment['dut1'].prompt, 1)
	if (@test_params.params_chan.direction[0].to_s == 'tx')
			 puts "ENTERED TX CASE TTTTTT\n"
	 # if (@test_params.params_chan.poll_mode[0].to_i == 1)
	  #		 puts "ENTERED POLL MODE CASE PPPPPPPPP\n"
	  		# if (@test_params.params_chan.can_version[0].to_s == 'A')
	  		   @equipment['dut1'].send_cmd("cansequence #{can_channel} -p &", @equipment['dut1'].prompt, 1)
	      # else 
	      #   @equipment['dut1'].send_cmd("cansequence can0 -p -e &", @equipment['dut1'].prompt, 1)
	      # end
	  #else
	   #puts "ENTERED INTERRUPT MODE CASE IIIIIIIIIIIIII\n"
	   # interrupt-mode using cansend?
	  #end
	else
	  puts "ENTERED RX CASE RRRRRRRRR\n"
	  @equipment['dut1'].send_cmd("candump #{can_channel} -d", @equipment['dut1'].prompt, 1)
	end
	duration_on_tee = duration/1000.to_i  
	sleep duration_on_tee # sleep while test is running for the specified duration
	@equipment['dut1'].send_cmd("date", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd(" cat /proc/net/can/stats", @equipment['dut1'].prompt, 1)
	stop_can_statistics = @equipment['dut1'].response.split(/\r\n/)  
	puts "STOP_CAN_STATISTICS ARE #{stop_can_statistics}\n"
		if (@test_params.params_chan.direction[0].to_s == 'tx')
		 puts "STOP TEST AREA ENTERED TX CASE TTTTTT\n"
		#  if (@test_params.params_chan.poll_mode[0].to_i == 1)
		 # puts "STOP TEST AREA ENTERED POLL MODE CASE PPPPPPP\n"
	      @equipment['dut1'].send_cmd("kill -9 `ps | grep cansequence | grep -v grep | awk '{print $1}'`", @equipment['dut1'].prompt, 10) # kill cansequence as part of end of operation
	      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	    #else
	       # kill cansend?
	    #end
    else
       puts "STOP TEST AREA ENTERED RX CASE RRRRRRRR\n" 
        @equipment['dut1'].send_cmd("kill -9 `ps | grep candump | grep -v grep | awk '{print $1}'`", @equipment['dut1'].prompt, 10) # kill candump as part of end of operation
	      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	  end
	@equipment['dut1'].send_cmd("ip -d -s link show #{can_channel}", @equipment['dut1'].prompt, 1)
	ip_stats = @equipment['dut1'].response.split(/\r\n/)  
	@equipment['dut1'].send_cmd(" cat /proc/net/can/stats", @equipment['dut1'].prompt, 1)
	end_can_statistics = @equipment['dut1'].response.split(/\r\n/)  
	puts "START_CAN_STATISTICS ARE #{start_can_statistics}\n"
	puts "STOP_CAN_STATISTICS ARE #{stop_can_statistics}\n"
  puts "END_CAN_STATISTICS ARE #{end_can_statistics}\n"
 # flag = save_results(start_can_statistics,end_can_statistics,ip_stats)
#ensure 
 # if perf.size > 0
  #  set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
 # else
 #   set_result(FrameworkConstants::Result[:fail], "Could not get Power Performance data")
 # end
    set_result(FrameworkConstants::Result[:fail], "Verify Manually. Data is #{end_can_statistics} and #{ip_stats}\n")

end
def save_results(start_can_statistics,end_can_statistics,ip_stats)
  super
   res_table = @results_html_file.add_table([["CAN STATISTICS and IP STATISTICS",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
  @results_html_file.add_row_to_table(res_table,["CAN_START_STATS","CAN_END_STATS","IP_DATA_STATS"])
  @results_html_file.add_row_to_table(res_table,[start_can_statistics,end_can_statistics,ip_stats])
  return 1
end






