# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
include LspTestScript
			
def setup
  BuildClient.enable_config_step
  super
end
			
def run
    # Initialize DUT to run file-based performance test
		
		puts " "
		puts "--------------- usb_cdc_perf_iperf ---15a---------------"
		puts " "
		
		if @test_params.params_chan.comm_mode[0] == 'cdc'
			@equipment['usb_sw'].connect_port(2)
				
			puts " "
			puts "Connecting the USB port to a Linux PC."
		else
			@equipment['usb_sw'].connect_port(1)
				
			puts " "
			puts "Connecting the USB port to a WinXP PC."
		end

		puts " "
		puts "--------------- usb_cdc_perf_iperf ---15b---------------"

		sleep 10
		
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
    puts "usb_cdc_perf_iperf_script_run-1"
			
    @equipment['dut1'].send_cmd("dmesg | grep usb0", /Gadget/)
			
    if @test_params.params_chan.comm_mode[0] == 'cdc'
      @equipment['pc1'].send_cmd("dmesg | grep usb0", /usb/)
    end
			
    if @equipment['dut1'].is_timeout || @equipment['pc1'].is_timeout
      result = 1
      return result
    end
			
    # *********************** setup the usb devices ***********************
    puts "usb_cdc_perf_iperf_script_run-2: Configuring the DUT USB0 interface."
			
    response = init_dut()
		
    puts "usb_cdc_perf_iperf_script_run-3: DUT USB0 interface configured."
    response = ''
		
    if  @test_params.params_chan.comm_mode[0] == 'cdc'
      puts "usb_cdc_perf_iperf_script_run-3a: Checking the Linux PC host."
      @equipment['pc1'].send_cmd("sudo /sbin/ifconfig usb0 #{@equipment['pc1'].usb_ip} netmask 255.255.255.0", /Password/)    
      response = @equipment['pc1'].response
      
      if response.index(/Password/) != nil
        @equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}\n\n", /.*/)
        response = @equipment['pc1'].response
      end
    else
      puts "usb_cdc_perf_iperf_script_run-3b: Checking the Iperf Service on Windows XP"
			@equipment['pc2'].send_cmd("tasklist /SVC", /IPerfService/)
      response = @equipment['pc1'].response
    end
			
    puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		puts "usb_cdc_perf_iperf_script-1: Received response from PC."
    puts response
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
    puts "usb_cdc_perf_iperf_script_run-2: Sending Ping to PC."
			
    @equipment['dut1'].send_cmd("ping -c 4 #{@equipment['pc1'].usb_ip}", /4 received/)
		response = @equipment['dut1'].response
			
    if @equipment['dut1'].is_timeout
      result = 4
    end
		
		puts " "
		puts "- - - - - 2a response - - - - - "
		puts response
		puts "- - - - - - - - - - -"

		#ping_chk = /\s+Unreachable\s/.match(response)[1]

		puts " "
		puts "- - - - - 2b response - - - - -"
		#puts ping_chk
		puts "- - - - - - - - - - - - - - - -"
		puts " "

    # *********************** set the src & destination ip's as the usb devices ***********************
    
		pc_ip = @equipment['pc2'].usb_ip
		temp1 = "dut1"
		dut_ip = get_dut_ipadd ()
		puts "- - - - - - - - - - "
		#puts temp1
		#puts dut_ip
		puts "- - - - - - - - - - -"
			
    # *********************** Execute USB iperf performance test ***********************
		@results_html_file.add_paragraph("")
			
		if @test_params.params_chan.protocol[0] == 'udp'
					bw_sizes   = @test_params.params_chan.bw_size[0].split(' ')
					#bw_sizes.each {|bwidth_size|
					window_sizes = @test_params.params_chan.window_size[0].split(' ')
					duration = @test_params.params_chan.duration[0]
					
					res_table = @results_html_file.add_table([["Performance Numbers (#{@rtp_db.get_platform})",{:bgcolor => "green", :colspan => "8"},{:color => "red"}]],{:border => "1",:width=>"40%"})
					@results_html_file.add_row_to_table(res_table, ["Default Bandwidth \(Mhz\)", "TCP Window Size in KBytes", "Bandwidth Mbits/sec", "Transfer Size in MBytes", "Interval in sec", "Jitter", "Percent Loss \(%\)"])
						
						i=0
						window_sizes.each {|window_size|
            
						bwidth_size = 10
						#puts " "
						#puts "5a. 5 Columns."
						result, dur, bw, xfer, jit, pctloss = run_perf_test(pc_ip, dut_ip, bwidth_size, (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i)
							
						break if result > 0
							
						#puts " "
						#puts "5c. 5 Columns."
						@results_html_file.add_row_to_table(res_table, [bwidth_size, window_size, bw, xfer, dur, jit, pctloss])
						
						i+=1	        
					}
					
					@results_html_file.add_row_to_table(res_table, [" "," "," "," "])
					@results_html_file.add_row_to_table(res_table, [" "," "," "," "])
				#}
			else
					window_sizes = @test_params.params_chan.window_size[0].split(' ')
					duration = @test_params.params_chan.duration[0]
					
					res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"35%"})
					@results_html_file.add_row_to_table(res_table, ["TCP Window Size in KBytes", "Bandwidth Mbits/sec", "Transfer Size in MBytes", "Interval in sec"])
					
						i=0
						window_sizes.each {|window_size|
            
						#puts " "
						#puts "5b. 4 Columns."
						result, dur, bw, xfer = run_perf_test(pc_ip, dut_ip, '', (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i)
							
						break if result > 0
							
						#puts " "
						#puts "5d. 4 Columns."
						@results_html_file.add_row_to_table(res_table, [window_size, bw, xfer, dur])
														
						i+=1	        
					}
				#}
			end
			
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

		@equipment['usb_sw'].connect_port(0)				#add 06-03-2009
		
		super
end
			
private
			
	def init_dut ()
    puts " "
		puts "usb_cdc_perf_iperf_script_run-2: Configuring the DUT USB0 interface."
			
    @equipment['dut1'].send_cmd("ifconfig usb0 #{@equipment['dut1'].usb_ip} netmask 255.255.255.0", /@/)
    sleep 3
    puts "usb_cdc_perf_iperf_script_run-3: DUT USB0 interface configured."
    
		response = @equipment['pc1'].response
    puts " "
    puts "---------------------------1a --------------------------------"
		puts response
    puts "---------------------------1a --------------------------------"
    puts " "

		[response]
	
	end

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
	def get_dut_ipadd ()
    @equipment['dut1'].send_cmd("ifconfig usb0", /@/, 5)
    response = @equipment['dut1'].response
			
		ipaddr = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(response)[1]
		
		if @equipment['dut1'].is_timeout
        @result = 1
		end
		
		[ipaddr]
	end

	def get_pc_ipadd (intfc, pc_name)
    #name = "pc" + pc_num.to_i
    
		if @test_params.params_chan.comm_mode[0] == 'cdc'
			@equipment[pc_name].send_cmd("ifconfig #{intfc}", /@/, 5)
		else
			@equipment[pc_name].send_cmd("ipconfig #{intfc}", /@/, 5)
		end
		
		response = @equipment[pc_name].response
			
		ipaddr = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(response)[1]
		
		if @equipment[pc_name].is_timeout
        @result = 1
		end
		
		[ipaddr]
	end

	def parse_dut_resp_rslt(response, name)
		
		#duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits/m.match(@equipment[name].response).captures
		
		puts "**************************** ******************************************"
		puts response
		puts " "
		puts "**************************** *****************************************"
		duration = /([\d\.]+)\s+?sec\s/m.match(@equipment['dut1'].response).captures
		xfer1 = /\s+([\d\.]+\s+?[MK])Bytes\s/m.match(@equipment['dut1'].response).captures
		bwl = /\s+([\d\.]+\s+?[MK])bits/m.match(@equipment['dut1'].response).captures
		
		[duration, xfer1, bw1]
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
			
    # *********************** make sure the pc is not running any iperf servers ***********************
    puts "usb_cdc_perf_iperf_script-6 - Stopping iperf on host PC."
		
    if @test_params.params_chan.comm_mode[0] == 'cdc'
     #@equipment['pc1'].send_cmd("sudo killall -9 iperf ; rm -rf perf.log", /./)
     @equipment['pc1'].send_cmd("killall -9 iperf ; rm -rf perf.log", /./)
      response = @equipment['pc1'].response
			
      if response.index(/Password/) != nil
        puts "usb_cdc_perf_iperf_script-6 - Sending password to Linux PC."
        @equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}\n\n", /.*/)
        response = @equipment['pc1'].response
      end
			
    else
      puts "usb_cdc_perf_iperf_script-6a - Deleting Iperf Service on WinXP."
			
      @equipment['pc2'].send_cmd("taskkill /F /IM iperf*", /terminated/)
    end
			
    sleep (2)
    puts "usb_cdc_perf_iperf_script-7 - Setup server side on PC."
		puts " "
			
    # *********************** setup the iperf server side PC/DUT ***********************
    if @test_params.params_chan.comm_mode[0] == 'cdc'
				if proto == 'tcp'
					puts "usb_cdc_perf_iperf_script-7a - Starting Iperf Server TCP on DUT."
					@equipment['dut1'].send_cmd("./iperf -s &> perf.log", /\]\s+\d+/)
				elsif proto == 'mlti'
					puts "usb_cdc_perf_iperf_script-7b - Starting Iperf Multicast TCP on DUT."
					@equipment['dut1'].send_cmd("./iperf -s -u -B 224.0.36.36 &> perf.log", /\]\s+\d+/)
				else
					puts "usb_cdc_perf_iperf_script-7c - Starting Iperf Server UDP on DUT."
					@equipment['dut1'].send_cmd("./iperf -u -s &> perf.log", /\]\s+\d+/)
				end
    else
				if proto == 'tcp'
					puts "usb_cdc_perf_iperf_script-7d - Starting Iperf Server in WinXP TCP mode."
					@equipment['pc2'].send_cmd("iperf.exe -D -s", /.*/)
				elsif proto == 'mlti'
					puts "usb_cdc_perf_iperf_script-7e - Starting Iperf Multicast Server TCP on DUT."
					@equipment['dut1'].send_cmd("./iperf -s -u -B 224.0.36.36 &> perf.log", /\]\s+\d+/)
				else
					puts "usb_cdc_perf_iperf_script-7f - Starting Iperf Server in WinXP UDP mode."
					@equipment['pc2'].send_cmd("iperf.exe -D -u -s", /.*/)
			end 
    end
			
      sleep (2)
      puts " "
			
    # *********************** get the pid of the iperf process we just started ***********************
    if @test_params.params_chan.comm_mode[0] == 'cdc'
      #pid = reg_ensure(/(\]\s+)(\d+)/, 'pc1', 2)
      pid = reg_ensure(/(\]\s+)(\d+)/, 2)
    end
			
    # **************** send traffic from DUT client ***********************
			
    if @test_params.params_chan.comm_mode[0] == 'cdc'
      if proto == 'tcp'
        puts "usb_cdc_perf_iperf_script-8a - Transferring iperf CDC TCP data to and from DUT."
				@equipment['pc1'].send_cmd("./iperf -c #{dut_ip} -w #{packet_size}k -t #{duration} -d  >perf.log", /@/, duration.to_i + 60)
      elsif proto == 'mlti'
        puts "usb_cdc_perf_iperf_script-8b - Transferring iperf Client Multicast CDC UDP data from Linux PC."
				@equipment['pc1'].send_cmd("./iperf -c 224.0.36.36 -u -w #{packet_size}k -t #{duration} -b 30M >perf.log", /@/, duration.to_i + 60)
      else
        puts "usb_cdc_perf_iperf_script-8c - Transferring iperf CDC UDP data from DUT."
				@equipment['pc1'].send_cmd("./iperf -c #{dut_ip} -w #{packet_size}k -t #{duration} -u -b #{bw_size}m >perf.log", /@/, duration.to_i + 60)
      end
    else
      if proto == 'tcp'
        puts "usb_cdc_perf_iperf_script-8d - Sending iperf RNDIS TCP traffic from DUT."
				#pc_ip = get_pc_ipadd ('usb0', 'pc2')
				pc_ip = @equipment['pc2'].usb_ip
        @equipment['dut1'].send_cmd("./iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -d > perf.log", /#/, duration.to_i + 60)
      elsif proto == 'mlti'
        puts "usb_cdc_perf_iperf_script-8e - Sending iperf Multicast CDC UDP traffic from WinXP PC."
				@equipment['pc2'].send_cmd("iperf -c -B 224.0.36.36 -u -w #{packet_size}k -t #{duration} -T 5 -b 30M &> perf.log", /#/, duration.to_i + 60)
			else
        puts "usb_cdc_perf_iperf_script-8f - Sending iperf RNDIS UDP traffic from DUT."
				@equipment['dut1'].send_cmd("./iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -u -b #{bw_size}m > perf.log", /\d+\s+ms/, duration.to_i + 60)
      end
    end
			
		puts " "
    puts "usb_cdc_perf_iperf_script-8g - Completed sending iperf traffic from DUT."
		puts pc_ip
		puts @equipment['pc2'].usb_ip
    puts " "
    sleep(2)
			
    # *********************** check for errors ***********************
    puts "usb_cdc_perf_iperf_script-9 - Checking log for errors."
		puts " "
			
		if @equipment['pc1'].is_timeout
			puts "usb_cdc_perf_iperf_script-9a - Linux PC timed out."
			puts " "
			 
			if @test_params.params_chan.comm_mode[0] == 'cdc' 
				@equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /.*/)
				puts "usb_cdc_perf_iperf_script-9b - Linux PC timed out."
				result = 1
					return result
			else
				puts "usb_cdc_perf_iperf_script-9c - Kill Iperf server on WinXP."
				#@equipment['pc1'].send_cmd("taskkill /F /IM IPerfService", /.*/)
			end
      result = 1
				return result
    end
			
    sleep(2)
			
		puts "usb_cdc_perf_iperf_script-9d - Checking log for errors."
			
		if @test_params.params_chan.comm_mode[0] == 'cdc'
			if proto == 'tcp'
				puts "usb_cdc_perf_iperf_script-9e - Checking log for errors."
				@equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
			elsif proto == 'mlti'
				puts "usb_cdc_perf_iperf_script-9f - Checking log for errors."
				@equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
			else
				puts "usb_cdc_perf_iperf_script-9g - Checking log for errors."
				@equipment['pc1'].send_cmd("cat perf.log", /@/)
			end
		else
			if proto == 'tcp'
				puts "usb_cdc_perf_iperf_script-9h - Checking log for errors."
				@equipment['dut1'].send_cmd("cat perf.log", /#/)
			elsif proto == 'mlti'
				puts "usb_cdc_perf_iperf_script-9i - Checking log for errors."
				#@equipment['dut1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
				@equipment['dut1'].send_cmd("cat perf.log", /#/)
			else
				puts "usb_cdc_perf_iperf_script-9j - Checking log for errors."
				@equipment['dut1'].send_cmd("cat perf.log", /#/)
			end	
    end
			
    #puts (@equipment['pc1'].response)
    sleep(2)
			
		if @test_params.params_chan.comm_mode[0] == 'cdc'
			if proto == 'tcp'
				puts "usb_cdc_perf_iperf_script-10a - Checking for errors."
				duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec.+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec/m.match(@equipment['pc1'].response).captures
			elsif proto == 'mlti'
				puts "usb_cdc_perf_iperf_script-10b - Checking for errors."
				duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits/m.match(@equipment['pc1'].response).captures
				xfer2=bw2=0
			else
				puts "usb_cdc_perf_iperf_script-10c - Checking for errors."
				duration,xfer1,bw1,jit1,pctloss1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec\s+?([\d\.]+)\s+?ms[\s\d\/]+?\(([\d\.]+)%\)/m.match(@equipment['pc1'].response).captures
			end
		else
			if proto == 'tcp'
				puts "usb_cdc_perf_iperf_script-10d - Checking for errors."
				duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec.+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec/m.match(@equipment['dut1'].response).captures
			elsif proto == 'mlti'
				puts "usb_cdc_perf_iperf_script-10e - Checking for errors."
				
				duration,xfer1,bw1 = parse_dut_resp_rslt(response, 'dut1')
				
				#duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits/m.match(@equipment['pc2'].response).captures
				xfer2=bw2=0
				else
				puts "usb_cdc_perf_iperf_script-10f - Checking for errors."
				duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[MK])Bytes\s+?([\d\.]+\s+?[MK])bits/m.match(@equipment['dut1'].response).captures
			end
		end
			
		sleep 2
		puts "Here is the DUT response."
		puts " "
		puts "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-"
		puts " "
			
    # *********************** parse/format the results ***********************
    puts "usb_cdc_perf_iperf_script-12 - Parsing test results."
			
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
				
		#puts "Jitter:   #{jit}"
		#puts "Percent:   #{pctloss1}"
			
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
				puts "usb_cdc_perf_iperf_script-13a - Send 1st Ctrl-C."
				@equipment['dut1'].send_cmd("\cC", /#/,10)
				puts "usb_cdc_perf_iperf_script-13a - Send 2nd Ctrl-C."
				sleep 2
				@equipment['dut1'].send_cmd("\cC", /#/,10)
				puts "usb_cdc_perf_iperf_script-13a - Kill any active iperf sessions on DUT and PC."
				@equipment['dut1'].send_cmd("kill -9 #{pid.to_s}", /.*/) 
        @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/) 
      else
				
        @equipment['pc2'].send_cmd("taskkill /F /IM IPerf*", /.*/)
      end
				
      result = 3
      return result
				
		else
			puts "usb_cdc_perf_iperf_script-13a - Send 1st Ctrl-C."
			@equipment['dut1'].send_cmd("\cC", /#/,10)
			puts "usb_cdc_perf_iperf_script-13a - Send 2nd Ctrl-C."
			sleep 2
			@equipment['dut1'].send_cmd("\cC", /#/,10)
			sleep 2
		end
			
		xfer = "%.3f" % (xfer.to_f)
		bw = "%.3f" % (bw.to_f)
		jit = "%.3f" % (jit1.to_f)
		pctloss = "%.3f" % (pctloss1.to_f)
		
    if proto == 'udp'
			[result, duration, bw, xfer, jit, pctloss]
		else
			[result, duration, bw, xfer]
		end
  end
  
  