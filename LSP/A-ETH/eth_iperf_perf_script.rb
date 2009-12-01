# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
include LspTestScript
			
def setup
  BuildClient.enable_config_step
  super
end
			
def run
    # Initialize DUT to run file-based performance test
			
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
			
    iface = @test_params.params_chan.instance_variable_defined?(:@interface) ? @test_params.params_chan.interface[0] : 'eth0'
    @equipment['dut1'].send_cmd("ifconfig #{iface}", @equipment['dut1'].prompt)
    src_ip = reg_ensureb(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
    puts "default_perf_iperf_script_run-2"
		
		puts "* * * * * * * * * * * * * "
		puts iface
		puts "* * * * * * * * * * * * * "
    
    puts @equipment['pc1'].send_cmd("ifconfig #{iface}", @equipment['dut1'].prompt)
		puts "* * * * * * * * * * * * * "
		
    dest_ip = reg_ensureb(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
		
		puts "default_perf_iperf_script_run-2: Checking link continuity."
			
    @equipment['dut1'].send_cmd("ping -c 4 #{@equipment['pc1'].telnet_ip}", /4 received/)
			
    if @equipment['dut1'].timeout?
      result = 4
    end
			
    # *********************** set the src & destination ip's as the usb devices ***********************
			
		pc_ip = @equipment['pc1'].telnet_ip
		dut_ip = @equipment['dut1'].telnet_ip
			
    # *********************** Execute USB iperf performance test ***********************
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Performance Numbers (#{@rtp_db.get_platform})",{:bgcolor => "green", :colspan => "5"},{:color => "red"}]],{:border => "1",:width=>"40%"})
    @results_html_file.add_row_to_table(res_table, ["TCP Window Size in KBytes", "Bandwidth Mbits/sec", "Transfer Size in MBytes", "Interval in sec"])
    window_sizes = @test_params.params_chan.window_size[0].split(' ')
    #duration = 60
		bwidth_size = 10
		duration = @test_params.params_chan.duration[0]        
        i=0
        window_sizes.each {|window_size|
            
						result, dur, bw, xfer, jit, pctloss = run_perf_test(pc_ip, dut_ip, bwidth_size, (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i)
						
            break if result > 0
            
						@results_html_file.add_row_to_table(res_table, [window_size, bw, xfer, dur])
            i+=1	        
        }

			if result == 0 
        set_result(FrameworkConstants::Result[:pass], "Test Pass.")
			elsif result == 1
        set_result(FrameworkConstants::Result[:fail], "Timeout executing iperf performance test")
			elsif result == 2
        set_result(FrameworkConstants::Result[:fail], "Fail message received executing iperf performance test")
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
	self.as(LspTestScript).clean
  #super
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
		
			# *********************** Simple helper function to catch for errors in the regex matching ***********************
  def reg_ensure(regex, match)
    rx = regex.match(@equipment['pc1'].response) 
    return rx != nil ? rx[match] : nil
  end
		
  # *********************** Simple helper function to catch for errors in the regex matching ***********************
  def reg_ensureb(regex, match)
    rx = regex.match(@equipment['dut1'].response) 
    return rx != nil ? rx[match] : nil
  end
		
	# ********************************************* Get IP address of the DUT ***************************************************
		
	def parse_dut_resp(response, name)
		
		puts "**************************** ******************************************"
		puts response
		puts " "
		puts "**************************** *****************************************"
		duration = /([\d\.]+)\s+?sec\s/m.match(@equipment['dut1'].response).captures
		xfer1 = /\s+([\d\.]+\s+?[MK])Bytes\s/m.match(@equipment['dut1'].response).captures
		bwl = /\s+([\d\.]+\s+?[MK])bits/m.match(@equipment['dut1'].response).captures
		
		[duration, xfer1, bw1]
	end
		
	def parse_pc_tcp_resp(response)

		puts "**************************** parse_tcp_resp 145 ******************************************"
		puts response
		puts " "
		puts "**************************** parse_tcp_resp 148 *****************************************"
		duration = /([\d\.]+)\s+?sec\s/m.match(@equipment['dut1'].response).captures
		xfer1 = /\s+([\d\.]+\s+?[MK])Bytes\s/m.match(@equipment['dut1'].response).captures
		bwl = /\s+([\d\.]+\s+?[MK])bits/m.match(@equipment['dut1'].response).captures
		jit = /([\d\.]+)\s+?ms/m.match(@equipment['dut1'].response).captures
		pctloss1 = /[\s\d\/]+?\(([\d\.]+)%\)/m.match(@equipment['pc1'].response).captures
		
		[duration, xfer1, bw1, jit, pctloss1]
	end
		
	def parse_pc_udp_resp(response)
		puts "**************************** ******************************************"
		puts response
		puts " "
		puts "**************************** *****************************************"
		duration = /([\d\.]+)\s+?sec\s/m.match(@equipment['dut1'].response).captures
		xfer1 = /\s+([\d\.]+\s+?[MK])Bytes\s/m.match(@equipment['dut1'].response).captures
		bwl = /\s+([\d\.]+\s+?[MK])bits/m.match(@equipment['dut1'].response).captures
		jit = /([\d\.]+)\s+?ms/m.match(@equipment['dut1'].response).captures
		pctloss1 = /[\s\d\/]+?\(([\d\.]+)%\)/m.match(@equipment['pc1'].response).captures
		
		[duration, xfer1, bw1, jit, pctloss1]
	end
	
	def send_ctrl_c ()

		@equipment['dut1'].send_cmd("\cC", /#/,10)
		sleep 2
		@equipment['dut1'].send_cmd("\cC", /#/,10)
		
		[r_err]
	end
	
  # for usb iperf throughput steps:
  # 1. Setup usb on both DUT and PC sides, configuring both devices on a separate network as the normal ethernet device 
  # 2. Start iperf server on the PC side 
  # 3. Start iperf client on the DUT side
  # 4. Collect results from the PC side
  def run_perf_test(pc_ip, dut_ip, bw_size, packet_size, duration, proto, counter)
			
    result = 0
			
    puts "eth_iperf_perf_script-7 - Setup server side on PC."
		puts " "
			
    # *********************** setup the iperf server side PC/DUT ***********************
		if proto == 'tcp'
			puts "eth_iperf_perf_script-7a - Starting Iperf Server TCP on Linux PC."
			@equipment['pc1'].send_cmd("./iperf -s &> perf.log", /\]\s+\d+/)
		elsif proto == 'mlti'
			puts "eth_iperf_perf_script-7b - Starting Iperf Multicast TCP on Linux PC."
			@equipment['pc1'].send_cmd("./iperf -s -u -B 224.0.36.36 &> perf.log", /\]\s+\d+/)
		else
			puts "eth_iperf_perf_script-7c - Starting Iperf Server UDP on Linux PC."
			@equipment['pc1'].send_cmd("./iperf -u -s &> perf.log", /\]\s+\d+/)
		end
				
		response = @equipment['pc1'].response
		
    if response.index(/Password/) != nil
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}", /.*/)
			response = @equipment['pc1'].response
		end
			
    sleep (2)
    puts "***********7f************ "
		puts response
		puts "***********7g************ "
			
    # *********************** get the pid of the iperf process we just started ***********************
      #pid = reg_ensure(/(\]\s+)(\d+)/, 'pc1', 2)
      pid = reg_ensure(/(\]\s+)(\d+)/, 2)
			
    # **************** send traffic from DUT client ***********************
			
    if proto == 'tcp'
      puts "eth_iperf_perf_script-8a - Transferring iperf TCP data to and from PC."
			@equipment['dut1'].send_cmd("./iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -d  >perf.log", /@/, duration.to_i + 60)
    elsif proto == 'mlti'
      puts "eth_iperf_perf_script-8b - Transferring iperf Client Multicast CDC UDP data from Linux PC."
			@equipment['dut1'].send_cmd("./iperf -c 224.0.36.36 -u -w #{packet_size}k -t #{duration} -b 30M >perf.log", /@/, duration.to_i + 60)
    else
      puts "eth_iperf_perf_script-8c - Transferring iperf CDC UDP data from DUT."
			@equipment['dut1'].send_cmd("./iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -u -b #{bw_size}m >perf.log", /@/, duration.to_i + 60)
    end
			
			# *********************** check for errors ***********************
    puts "eth_iperf_perf_script-9 - Checking log for errors."
		puts " "
			
		if @equipment['dut1'].timeout?
			puts "eth_iperf_perf_script-9a - Linux PC timed out."
			puts " "
			 
			@equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/)
			puts "eth_iperf_perf_script-9b - Linux PC timed out."
			result = 1
				return result
			puts "eth_iperf_perf_script-9c - Kill Iperf server on WinXP."
    end
			
    sleep(2)
			
		puts "eth_iperf_perf_script-9d - Checking log for errors."
			
		if proto == 'tcp'
			puts "eth_iperf_perf_script-9e - Checking log for errors."
			@equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
		elsif proto == 'mlti'
			puts "eth_iperf_perf_script-9f - Checking log for errors."
			@equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
		else
			puts "eth_iperf_perf_script-9g - Checking log for errors."
			@equipment['pc1'].send_cmd("cat perf.log", /@/)
		end
			
		response = @equipment['pc1'].response
			
    puts "***********9h************ "
		puts response
		puts "***********9i************ "
			
    sleep(2)
			
		if proto == 'tcp'
			puts "eth_iperf_perf_script-10a - Checking for errors."
			duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec.+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec/m.match(@equipment['pc1'].response).captures
		elsif proto == 'mlti'
			puts "eth_iperf_perf_script-10b - Checking for errors."
			duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits/m.match(@equipment['pc1'].response).captures
			xfer2=bw2=0
		else
			puts "eth_iperf_perf_script-10c - Checking for errors."
			duration,xfer1,bw1,jit1,pctloss1 = parse_pc_udp_resp(response)
		end
		
		sleep 2
		puts "Here is the DUT response."
		puts " "
		puts "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-"
		puts " "
			
    # *********************** parse/format the results ***********************
    puts "eth_iperf_perf_script-12 - Parsing test results."
			
		if /\s*([kK])/.match(bw1.to_s)
			bw1 = "%.3f" % (bw1.to_f / 1000)
		else
			bw1 = "%.3f" % (bw1.to_f)
		end
			
		if /\s*([kK])/.match(bw2.to_s)
			bw2 = "%.3f" % (bw2.to_f / 1000)
		else
			bw2 = "%.3f" % (bw2.to_f)
		end
			
		if /\s*([kK])/.match(xfer1.to_s)
			xfer1 = "%.3f" % (xfer1.to_f / 1000)
		else
			xfer1 = "%.3f" % (xfer1.to_f)
		end
			
		if /\s*([kK])/.match(xfer2.to_s)
			xfer2 = "%.3f" % (bw2.to_f / 1000)
		else
			xfer2 = "%.3f" % (xfer2.to_f)
		end
				
		jit = "%.3f" % (jit1.to_f)
				
    bw=xfer=jit=pctloss=nil
    bw = (bw1.to_f + bw2.to_f).to_s if bw1 and bw2
		xfer = (xfer1.to_f + xfer2.to_f).to_s if xfer1 and xfer2
				
		puts " "
    puts "=================== Data #{bw1} #{xfer1} #{bw2} #{xfer2} #{"%.3f" % (jit1.to_f)} #{"%.3f" % (pctloss1.to_f)} ===================="
		puts " "
    puts "=========================== Data #{bw} #{xfer} =============================="
		puts " "
				
    # *********************** ensure results are valid ***********************
    if (duration == nil || bw == nil || xfer == nil)
      if @test_params.params_chan.comm_mode[0] == 'cdc' 
				puts "eth_iperf_perf_script-13a - Send 1st Ctrl-C."
				@equipment['dut1'].send_cmd("\cC", /#/,10)
				puts "eth_iperf_perf_script-13a - Send 2nd Ctrl-C."
				sleep 2
				@equipment['dut1'].send_cmd("\cC", /#/,10)
				puts "eth_iperf_perf_script-13a - Kill any active iperf sessions on DUT and PC."
				@equipment['dut1'].send_cmd("kill -9 #{pid.to_s}", /.*/) 
        @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/) 
      else
				
        @equipment['pc2'].send_cmd("taskkill /F /IM IPerf*", /.*/)
      end
				
      result = 3
      return result
				
		else
			puts "eth_iperf_perf_script-13a - Send 1st Ctrl-C."
			@equipment['dut1'].send_cmd("\cC", /#/,10)
			puts "eth_iperf_perf_script-13a - Send 2nd Ctrl-C."
			sleep 2
			@equipment['dut1'].send_cmd("\cC", /#/,10)
			sleep 2
		end
			
		xfer = "%.3f" % (xfer.to_f)
		bw = "%.3f" % (bw.to_f)
		jit = "%.3f" % (jit1.to_f)
		pctloss = "%.3f" % (pctloss1.to_f)
		
			[result, duration, bw, xfer, jit, pctloss]
  end
  
  