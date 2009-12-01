# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

#class Usb_cdc_traffic_pingTestPlan < TestPlan
def setup
  BuildClient.enable_config_step
  super
end

def run
    # *********************** Initialize DUT to run file-based performance test *********************** 
			
    result = 0 		#0=pass, 1=timeout, 2=fail message detected
		#pc_select = 1	# indicates which PC is selected by  the USB switch.  1=WinXP PC 2=Linux PC
		ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
			
		if @test_params.params_chan.instance_variable_defined?(:@init_cmds)
      commands = parse_cmd('init_cmds')
      result, cmd = execute_cmd(commands)
    end
			
    if result > 0 
      set_result(FrameworkConstants::Result[:fail], "Error preparing DUT to run performance test while executing cmd: #{cmd.cmd_to_send}")
      return
    end
			
    # *********************** make sure a usb device exists & set it's IP on the DUT and PC sides ***********************
    puts "usb_cdc_traffic_ping_script_run-1"
			
    @equipment['dut1'].send_cmd("dmesg | grep usb0", /Gadget/)
			
    if @test_params.params_chan.comm_mode[0] == 'cdc'
      @equipment['pc1'].send_cmd("dmesg | grep usb0", /usb/)
    end
			
    if @equipment['dut1'].timeout? || @equipment['pc1'].timeout?
      result = 1
      return result
    end
			
    # *********************** setup the usb devices ***********************
    puts "usb_cdc_traffic_ping_script_run-2: Configure DUT interface."
			
    @equipment['dut1'].send_cmd("ifconfig usb0 #{@equipment['dut1'].usb_ip} netmask 255.255.255.0", /.*/)
    sleep 3
    puts "usb_cdc_traffic_ping_script_run-2a: DUT interface configured."
    response = ''
			
    if  @test_params.params_chan.comm_mode[0] == 'cdc'
      puts "usb_cdc_traffic_ping_script_run-2b: Configuring the Linux PC USB IP address."
      @equipment['pc1'].send_cmd("sudo /sbin/ifconfig usb0 #{@equipment['pc1'].usb_ip} netmask 255.255.255.0", /Password/)    
      response = @equipment['pc1'].response
      
      if response.index(/Password/) != nil
        @equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}", /.*/)
        response = @equipment['pc1'].response
      end
    else
      puts "usb_cdc_traffic_ping_script_run-2c: Re-configuration of the USB interface configuration from DOS is not supported under Windows."
			puts " "
    end
			
    puts "usb_cdc_traffic_ping_script_run-3: Sending Ping to PC for a connectivity check."
		puts " "
			
    @equipment['dut1'].send_cmd("ping -c 4 #{@equipment['pc1'].usb_ip}", /4 received/)
			
    if @equipment['dut1'].timeout?
      result = 4
    end
			
    # *********************** set the src & destination ip's as the usb devices ***********************
    pc_ip = @equipment['pc1'].usb_ip
		pc_ip = @equipment['pc2'].usb_ip
    dut_ip = @equipment['dut1'].usb_ip
			
    # *********************** Execute USB Ping test ***********************
    @results_html_file.add_paragraph("")
			
    res_table = @results_html_file.add_table([["Traffic Results",{:bgcolor => "green", :colspan => "5"},{:color => "red"}]],{:border => "1",:width=>"40%"})
    @results_html_file.add_row_to_table(res_table, ["TCP Window Size in Bytes", "Ping Result", "Flood Ping Result"])
			
    window_sizes   = @test_params.params_chan.window_size[0].split(' ')
    i=0
			
     window_sizes.each {|window_size|
      break if result > 0
			result, ping_res, flood_ping_res = run_traffic_test(@equipment['dut1'].usb_ip, dest_ip = @equipment['pc1'].usb_ip, window_size, @test_params.params_chan.packets_to_send[0], @test_params.params_chan.direction[0], i)
			
      @results_html_file.add_row_to_table(res_table, [window_size, ping_res, flood_ping_res])
      i+=1	              
    }
        
    if result == 0 
        set_result(FrameworkConstants::Result[:pass], "Test Pass.")
    elsif result == 1
        set_result(FrameworkConstants::Result[:fail], "Timeout executing ping test")
    elsif result == 2
        set_result(FrameworkConstants::Result[:fail], "Fail message received executing ping traffic test (either no or invalid packets received)")
    elsif result == 3
        set_result(FrameworkConstants::Result[:fail], "Invalid string recieved from test equipment (DUT or PC)")
    elsif result == 4
        set_result(FrameworkConstants::Result[:fail], "Unable to get initial connectivity to usb device")
    else
        set_result(FrameworkConstants::Result[:nry])
    end
			
    ensure 
        result, cmd = execute_cmd(ensure_commands) if @test_params.params_chan.instance_variable_defined?(:@ensure)
end

def clean
  super
end

private

	def parse_lnx_ping_rslt(response)
		pkts = /\d+\s+packets\s+transmitted,/.match(response)
		rcvd = /\d+\sreceived,/.match(response)
		lst = /\d+%\s+packet\s+loss,/.match(response)
		rtime = /time\s+\d+.+/.match(response)
		ping_res = "#{pkts} #{rcvd} #{lst} #{rtime}"
		[ping_res]
	end

	def parse_win_ping_rslt(response)
		pkts = /Packets:\s+Sent\s+=\s+(\d+)+,/.match(response)
		rcvd = /Received\s+=\s+(\d+)+,/.match(response)
		lst = /Lost\s+=\s+(\d+)\s\(+(\d+)%\s+loss\),/.match(response)
		rmin = /Minimum\s+=\s+(\d+)+ms,/.match(response)
		rmax = /Maximum\s+=\s+(\d+)+ms,/.match(response)
		ravg = /Average\s+=\s+(\d+)+ms/.match(response)
		flood_ping_res = "#{pkts} #{rcvd} #{lst}"
		[flood_ping_res]
	end

	def ping_dut_to_lnx_svr(packet_size, packets_to_send, pc_ip)
		@equipment['dut1'].send_cmd("cd /", /@/, 10)
		sleep 2
			
		@equipment['dut1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{pc_ip}", /#/, packets_to_send.to_i + 10)
		response = @equipment['dut1'].response
		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]						#check result of pings
			
		[response, received]
	end

	def ping_lnx_svr_to_dut(packet_size, packets_to_send, pc_ip)
		dut_ip = @equipment['dut1'].usb_ip
		@equipment['pc1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{dut_ip}", /packet\sloss/, packets_to_send.to_i + 10)
		response = @equipment['pc1'].response
					
		if response.index(/Password/) != nil
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}", /packet\sloss/, packets_to_send.to_i + 10)
			response = @equipment['pc1'].response
		end
			
		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]
		[response, received]
	end
	
	def ping_dut_to_win_svr(packet_size, packets_to_send, pc_ip)
			
		@equipment['dut1'].send_cmd("cd /", /@/, 10)
		sleep 2
			
		@equipment['dut1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{pc_ip}", /#/, packets_to_send.to_i + 10)
		response = @equipment['dut1'].response
			
		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]						#check result of pings
			
		puts " "
		puts response
		puts " "
			
		[response, received]
	end

	def ping_win_svr_to_dut(packet_size, packets_to_send, pc_ip)
		dut_ip = @equipment['dut1'].usb_ip
			
		@equipment['pc2'].send_cmd("ping -l #{packet_size} -n #{packets_to_send} #{dut_ip}", />/, packets_to_send.to_i + 10)
		response = @equipment['pc2'].response
			
		received = /Received\s+=\s+(\d+)/.match(response)[1]
			
		[response, received]
	end
	
	def ping_fld_dut_to_lnx_svr(packet_size, packets_to_send, pc_ip)
		@equipment['dut1'].send_cmd("cd /", /@/, 10)							#
		sleep 2
		@equipment['dut1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{pc_ip}", /@/, packets_to_send.to_i + 30)
		response = @equipment['dut1'].response
			
		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]						#check result of pings
			
		[response, received]
	end

	def ping_fld_lnx_svr_to_dut(packet_size, packets_to_send, pc_ip)
		dut_ip = @equipment['dut1'].usb_ip
			
		@equipment['pc1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{dut_ip}", /@/, packets_to_send.to_i + 60)
		response = @equipment['pc1'].response
					
		if response.index(/Password/) != nil
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}", /packet\sloss/, packets_to_send.to_i + 10)
			response = @equipment['pc1'].response
		end
			
		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]
			
		[response, received]
	end

	
	
  def run_traffic_test(dut_ip, pc_ip, packet_size, packets_to_send, direction, counter)
		
    result = 0
    response = ping_res = flood_ping_res = ""
		
		# **************************  Determine if we are going to ping a Linux PC or a Windows PC **************************
		if @test_params.params_chan.comm_mode[0] == 'cdc'
				pc_ip = @equipment['pc1'].usb_ip
				dut_ip = @equipment['dut1'].usb_ip
					
				if direction == 'client' # send from DUT->server
					puts " "
					puts "usb_cdc_traffic_ping_script_run-4a:  Sending ping from DUT to Linux PC."
					
					response, received = ping_dut_to_lnx_svr(packet_size, packets_to_send, pc_ip)
					
					puts "- - - - - - - - - - - - - 1a - - - - - - - - - - - - - -"
					puts response
					puts "* * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
					puts received
					puts " "
					puts "- - - - - - - - - - - - - 1b - - - - - - - - - - - - - -"
				else # send from server -> DUT
					puts "usb_cdc_traffic_ping_script_run-4b:  Sending ping from Linux PX to DUT."
					
					response, received = ping_lnx_svr_to_dut(packet_size, packets_to_send, dut_ip)
					
					puts "- - - - - - - - - - - - - 2a - - - - - - - - - - - - - -"
					puts response
					puts "* * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
					puts received
					puts " "
					puts "- - - - - - - - - - - - - 2b - - - - - - - - - - - - - -"
					puts " "
					
				end
		else
				pc_ip = @equipment['pc2'].usb_ip
				dut_ip = @equipment['dut1'].usb_ip
				
				if direction == 'client' # send from DUT->server
					puts "usb_cdc_perf_iperf_script_run-4c:  Sending ping from DUT to Windows PC."
					puts " "
					
					response, received = ping_dut_to_win_svr(packet_size, packets_to_send, pc_ip)
				else # send from server -> DUT
					puts "usb_cdc_perf_iperf_script_run-4d:  Sending ping from Windows PC to DUT."
					puts " "
					
					response, received = ping_win_svr_to_dut(packet_size, packets_to_send, pc_ip)
				end
		end
			
		puts "usb_cdc_traffic_ping_script_run-6:  Check ping flood results. "
			
    # ************************** check the results of the basic pings **************************
		
		puts " "
		puts "- - - - - - - - - - 7a - - - - - - - - - - - -"
		puts " "
		puts received
		puts " "
		puts "- - - - - - - - - - 7b - - - - - - - - - - - -"
		puts " "
		
    if received == 0
      result = 2
      return result
    end
		
		sleep 2

	if @test_params.params_chan.comm_mode[0] == 'cdc'
		if direction == 'client'
			puts "- - - - - - - - - - 8a - - - - - - - - - - - -"
			ping_res = parse_lnx_ping_rslt(response)
			puts " "
			puts ping_res
			puts " "
			puts "- - - - - - - - - - 8b - - - - - - - - - - - -"
    else
			puts "- - - - - - - - - - 8c - - - - - - - - - - - -"
			ping_res = parse_lnx_ping_rslt(response)
			puts " "
			puts ping_res
			puts " "
			puts "- - - - - - - - - - 8d - - - - - - - - - - - -"
		end
	else
		if direction == 'client'
			puts "- - - - - - - - - - 8e - - - - - - - - - - - -"
			ping_res = parse_lnx_ping_rslt(response)
			puts " "
			#puts ping_res
			#puts " "
			#puts "- - - - - - - - - - 8f - - - - - - - - - - - -"
			#puts " "
    else
			puts "- - - - - - - - - - 8g - - - - - - - - - - - -"
			ping_res = parse_win_ping_rslt(response)
			puts " "
			#puts ping_res
			#puts " "
			#puts "- - - - - - - - - - 8h - - - - - - - - - - - -"
			#puts " "
		end
	end
			
		puts " "		
			
		#sleep 4
			
		# ************************** ping flood from 1 side to the other **************************
		if @test_params.params_chan.comm_mode[0] == 'cdc'
				pc_ip = @equipment['pc1'].usb_ip
				dut_ip = @equipment['dut1'].usb_ip
				
				if direction == 'client' # send from DUT->server
					puts "usb_cdc_perf_iperf_script_run-9a:  Sending ping flood from DUT to Linux PC."
					@equipment['dut1'].send_cmd("cd /", /@/, 10)
					response, received = ping_fld_dut_to_lnx_svr(packet_size, packets_to_send.to_i * 10, pc_ip)
				else # send from server -> DUT
					puts "usb_cdc_perf_iperf_script_run-9b:  Sending ping flood from Linux PC to DUT."
					response, received = ping_fld_lnx_svr_to_dut(packet_size, packets_to_send.to_i * 10, pc_ip)
				end
		else
				pc_ip = @equipment['pc2'].usb_ip
				
				if direction == 'client' # send from DUT->server
					puts "usb_cdc_perf_iperf_script_run-9c:  Sending ping flood from DUT to Windows PC."
					response, received = ping_dut_to_win_svr(packet_size, packets_to_send.to_i * 10, pc_ip)
					sleep 3
				else # send from server -> DUT
					puts "usb_cdc_perf_iperf_script_run-9d:  Sending ping flood from Windows PC to DUT."
					
					response, received = ping_win_svr_to_dut(packet_size, packets_to_send.to_i * 10, pc_ip)
				end
		end
			
		#sleep 5
			
		puts " "
		puts "- - - - - - - - - - - - 10a - - - - - - - - - - - - - - - - "
		puts " "
		puts packets_to_send
		puts " "
		puts "- - - - - - - - - - - - 10b - - - - - - - - - - - - - - - - "
		puts " "
			
		sleep 2
			
    # ************************** check to make sure we received something **************************
		puts " "
		puts "- - - - - - - - - - - - 11a - - - - - - - - - - - - - - - - "
		puts " "
		puts response
		puts " "
		puts "- - - - - - - - - - - - 11b  - - - - - - - - - - - - - - - -"
		puts " "
			
		sleep 2
		received = ""
			
    if received == 0
      result = 2
      return result
    end
			
		puts " "
		puts "- - - - - - - - - - - - 13a - - - - - - - - - - - - - - - - "
		puts " "
			
		sleep 2
			
		if @test_params.params_chan.comm_mode[0] == 'cdc'
			if direction == 'client'
				flood_ping_res = parse_lnx_ping_rslt(response)
			else
				flood_ping_res = parse_lnx_ping_rslt(response)
			end
		else
			if direction == 'client'
				flood_ping_res = parse_lnx_ping_rslt(response)
			else
				flood_ping_res = parse_win_ping_rslt(response)
			end
		end
		
		puts ping_res
		puts flood_ping_res
		puts " "
		puts "- - - - - - - - - - - - 13b - - - - - - - - - - - - - - - - "
		puts " "
		
	  if received == 0
			result = 2
      return result
    end

		#puts " "
		#puts "- - - - - - - - - - - - 14a - - - - - - - - - - - - - - - - "
		#puts " "
		
    # ensure results are valid
    if (ping_res== nil || flood_ping_res == nil)
      result = 3
      return result
    end
    [result, ping_res, flood_ping_res]  
  end

#end #END_CLASS