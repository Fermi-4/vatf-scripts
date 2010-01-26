# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript
			
def setup
  self.as(LspTestScript).setup
end	
			
def run
    # Initialize DUT to run file-based performance test
			
    result = 0 	#0=pass, 1=timeout, 2=fail message detected
    ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
			
    if @test_params.params_chan.instance_variable_defined?(:@init_cmds)
        commands = parse_cmd('init_cmds')
        result, cmd = execute_cmd(commands)
    end
			
    if result > 0 
       set_result(FrameworkConstants::Result[:fail], "Error preparing DUT to run performance test while executing cmd: #{cmd.cmd_to_send}")
       return
     end
      
		pc_ip = ""
		dut_ip = get_dut_ipadd (dut_ip)
			
		puts " "
		puts "- - - - - - - - - - 7a - - - - - - - - - - - -"
		puts " "
		puts dut_ip
		puts " "
		puts "- - - - - - - - - - 7b - - - - - - - - - - - -"
		puts " "
			
    dest_ip = get_pc_ipadd (pc_ip)
		
		result = send_sudo()
		
		#dest_ip = @equipment['pc1'].telnet_ip 
			
    # Execute ethernet traffic ping test    
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Traffic Results",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"40%"})
    @results_html_file.add_row_to_table(res_table, ["TCP Window Size in Bytes", "Ping Result", "Flood Ping Result"])
			
			window_sizes   = @test_params.params_chan.window_size[0].split(' ')
			i=0
			window_sizes.each {|window_size|
      result, ping_res, flood_ping_res = run_traffic_test(dut_ip, dest_ip = @equipment['pc1'].telnet_ip, window_size, @test_params.params_chan.packets_to_send[0], @test_params.params_chan.direction[0], i)
      break if result > 0
      @results_html_file.add_row_to_table(res_table, [window_size, ping_res, flood_ping_res])
      i+=1	              
    }
        
    if result == 0 
        set_result(FrameworkConstants::Result[:pass], "Test Pass.")
    elsif result == 1
        set_result(FrameworkConstants::Result[:fail], "Timeout executing iperf performance test")
    elsif result == 2
        set_result(FrameworkConstants::Result[:fail], "Fail message received executing ping traffic test (either no or invalid packets received)")
    elsif result == 3
        set_result(FrameworkConstants::Result[:fail], "Invalid string recieved from test equipment (DUT or PC)")
		elsif result == 4
				set_result(FrameworkConstants::Result[:nsup])
    else
        set_result(FrameworkConstants::Result[:nry])
    end
			
    ensure 
        result, cmd = execute_cmd(ensure_commands) if @test_params.params_chan.instance_variable_defined?(:@ensure)
			
end		
			
def clean
  self.as(LspTestScript).clean
end
			
private
		
	def send_sudo ()
		@equipment['pc1'].send_cmd("sudo su -", /Password/, 10)
			
		response = @equipment['pc1'].response
			
		if response.index(/Password/) != nil
			puts " "
			puts "------------------------------ Enter Password Routine --------------------------------------"
			puts " "
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}\n\n", /\x0a/, 10)
			response = @equipment['pc1'].response
			puts " "
			puts "------------------------------ Exit Password Routine --------------------------------------"
			puts " "
		end
	end

		# ********************************************* Get IP address of the DUT ***************************************************
	def get_dut_ipadd (dut_ip)
    @equipment['dut1'].send_cmd("ifconfig eth0", /@/, 5)
    response = @equipment['dut1'].response
			
		ipaddr = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(response)[1]
		
		if @equipment['dut1'].timeout?
        @result = 1
		end
		
		[ipaddr]
	end
		
	# ******************************************* Get IP address of the Linux PC *************************************************
	def get_pc_ipadd (pc_ip)
    @equipment['pc1'].send_cmd("ifconfig eth0", /@/, 5)
    response = @equipment['pc1'].response
			
		ipaddr = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(response)[1]
			
		if @equipment['pc1'].timeout?
        @result = 1
		end
		
		[ipaddr]
	end
		
	# ******************************************* Parse the basic ping results *************************************************
	def parse_ping_rslt(response)
		pkts = /\d+\s+packets\s+transmitted,/.match(response)
		rcvd = /\d+\sreceived,/.match(response)
		lst = /\d+%\s+packet\s+loss,/.match(response)
		#rtime = /time\s+\d+.+/.match(response)
		ping_res = "#{pkts} #{rcvd} #{lst}"
		[ping_res]
	end
		
		# ******************************************* Ping From the DUT to the Linux PC *************************************************
	def ping_dut_to_lnx_svr(packet_size, packets_to_send, pc_ip, flood)
		pc_ip = get_pc_ipadd (pc_ip)
		@equipment['dut1'].send_cmd("cd /", /@/, 10)
		sleep 2
		
		if flood  == 0		
			@equipment['dut1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{pc_ip}", /#/, packets_to_send.to_i + 10)
		else
			@equipment['dut1'].send_cmd("ping -q -f -s #{packet_size} -c #{packets_to_send} #{pc_ip}", /#/, packets_to_send.to_i + 10)
		end
		
		response = @equipment['dut1'].response
		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]						#check result of pings
			
		[response, received]
	end
		
		# ******************************************* Ping From the Linux PC to the DUT *************************************************
	def ping_lnx_svr_to_dut(packet_size, packets_to_send, pc_ip, flood)
		dut_ip = get_dut_ipadd (dut_ip)
		
		if flood  == 0		
			@equipment['pc1'].send_cmd("ping -q -s #{packet_size} -c #{packets_to_send} #{dut_ip}", /packet\sloss/, packets_to_send.to_i + 10)
		else
			@equipment['pc1'].send_cmd("ping -q -f -s #{packet_size} -c #{packets_to_send} #{dut_ip}", /@/, packets_to_send.to_i + 10)
		end
		
		response = @equipment['pc1'].response
		
		puts "------------------------------ xxx01 --------------------------------------"
		puts response
		puts "------------------------------ xxx02 --------------------------------------"
		
		if response.index(/Password:/) != nil
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}\x0a", /Password/, packets_to_send.to_i + 10)
			response = @equipment['pc1'].response
		end
			
		puts "------------------------------ xxx03 --------------------------------------"
		puts @equipment['pc1'].response
		puts "------------------------------ xxx04 --------------------------------------"

		received = /([0-9]*\.?[0-9]+)(?=\s+packets)/.match(response)[1]
		[response, received]
	end
		
  def run_traffic_test(dut_ip, pc_ip, packet_size, packets_to_send, direction, counter)
		
    result = 0
    response = ping_res = flood_ping_res = ""
		
    # ******************************************* ping from 1 side to the other *******************************************
    if direction == 'client' # send from DUT->server
			puts "eth_traffic_ping_script_run-9a:  Sending ping from DUT to Linux PC."
    
			response, received = ping_dut_to_lnx_svr(packet_size, packets_to_send, pc_ip, 0)
    else # send from server -> DUT
			puts "eth_traffic_ping_script_run-9a:  Sending ping from Linux PC to DUT."
    
			response, received = ping_lnx_svr_to_dut(packet_size, packets_to_send, dut_ip, 0)
    end
		
    # ******************************************* check for timeout *******************************************
    if @equipment['dut1'].timeout? || @equipment['pc1'].timeout?
				result = 1
       return result
    end
		
    # ******************************************* check the results of the basic pings *******************************************   
		
    if received == 0
      result = 2
      return result
    end
		
		ping_res = parse_ping_rslt(response)
		
    # ******************************************* flood ping from 1 side to the other *******************************************
    if direction == 'client' # send from DUT->server
			puts "eth_traffic_ping_script_run-9a:  Sending ping flood from DUT to Linux PC."
		
			response, received = ping_dut_to_lnx_svr(packet_size, packets_to_send.to_i * 10, pc_ip, 1)
    else # send from server -> DUT, unfortunately have to do so under root context
			puts "eth_traffic_ping_script_run-9a:  Sending ping flood from Linux PC to DUT."
		
			response, received = ping_lnx_svr_to_dut(packet_size, packets_to_send.to_i * 10, dut_ip, 1)
    end
		
    # ******************************************* check for timeout*******************************************
    if @equipment['dut1'].timeout? || @equipment['pc1'].timeout?
        result = 1
        return result
    end
		
    # ******************************************* check to make sure we received something *******************************************
    if received == 0
      result = 2
      return result
    end
		
		flood_ping_res = parse_ping_rslt(response)
		
    # ******************************************* ensure results are valid *******************************************
    if (ping_res== nil || flood_ping_res == nil)
      result = 3
      return result
    end
    [result, ping_res, flood_ping_res]  
  end
  