# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript
			
	def setup
		BuildClient.enable_config_step
		super
	end
			
	def run
		connect_to_equipment('pc1')
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
		src_ip = reg_ensure(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
	
		send_status("run test on #{iface} - test"+ __LINE__.to_s)
		send_status ("run - test"+ __LINE__.to_s)
		
    dest_ip = reg_ensureb(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
			
		send_status("Checking link continuity. --- "+ __LINE__.to_s)
			
    @equipment['dut1'].send_cmd("ping -c 4 #{@equipment['pc1'].telnet_ip}", /4\s+packets\s+received.*?/)
			
    if @equipment['dut1'].timeout?
      result = 6
    end
		
		intfc_spd = get_intfc_spd ()
		
    # *********************** set the src & destination ip's as the usb devices ***********************
			
		pc_ip = @equipment['pc1'].telnet_ip
		dut_ip = @equipment['dut1'].telnet_ip
			
    # *********************** Execute USB iperf performance test ***********************
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Performance Numbers (#{@rtp_db.get_platform} - #{@test_params.params_chan.protocol[0]}) - Interface Speed: #{intfc_spd.to_s} Mb/s",{:bgcolor => "green", :colspan => "5"},{:color => "red"}]],{:border => "1",:width=>"40%"})
    @results_html_file.add_row_to_table(res_table, ["TCP Window Size in KBytes", "Bandwidth Mbits/sec", "Transfer Size in MBytes", "Interval in sec"])
    window_sizes = @test_params.params_chan.window_size[0].split(' ')
		
		send_status("Platform Type: #{@rtp_db.get_platform} - Line Speed: #{intfc_spd} Mb/s --- "+ __LINE__.to_s)

		duration = @test_params.params_chan.duration[0]        						##{@test_params.params_chan.protocol[0]}
        i=0
        window_sizes.each {|window_size|
=begin
						#result, dur, bw, xfer, jit, pctloss = run_perf_test(pc_ip, dut_ip, bwidth_size, (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i)
						#result, dur, bw, xfer = run_perf_test(pc_ip, dut_ip, bwidth_size, (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i, intfc_spd)
=end
						result, dur, bw, xfer = run_perf_test(pc_ip, dut_ip, intfc_spd, (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i)
						
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
        set_result(FrameworkConstants::Result[:fail], "Unable to get initial connectivity to Ethernet device")
			elsif result == 5
        set_result(FrameworkConstants::Result[:fail], "Unable to get Ethernet interface speed information")
			elsif result == 6
        set_result(FrameworkConstants::Result[:fail], "Unable to ping remote IP address")
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
		
	def send_status(msg)
		puts " "
		puts "--------------- eth_iperf_perf #{msg} ------------------"
		puts " "
	end

	def get_intfc_spd ()
    @equipment['dut1'].send_cmd("ethtool eth0", @equipment['dut1'].prompt)
			
    if @equipment['dut1'].timeout?
      result = 5
    end

		intfc_spd = /Speed\:\s+([\d\.]+)Mb\/s/m.match(@equipment['dut1'].response).captures
		send_status("#{intfc_spd} Mb/s --- "+ __LINE__.to_s)
		
		[intfc_spd]
	end
		
	def send_sudo ()
		@equipment['pc1'].send_cmd("sudo su -", /Password/, 10)
			
		response = @equipment['pc1'].response
		
		puts "------------------------------  Response Start ---------------------------------"+ __LINE__.to_s
		puts "#{response}"
		puts "------------------------------  Response End ---------------------------------"+ __LINE__.to_s
		
		if response.scan(/Password/) != nil
			send_status("Enter send_sudo --- "+ __LINE__.to_s)
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}\n\n", /\x0a/, 10)
			response = @equipment['pc1'].response
			send_status("Exit send_sudo --- "+ __LINE__.to_s)
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
  def run_perf_test(pc_ip, dut_ip, intfc_spd, packet_size, duration, proto, counter)
			
    result = 0
			
		send_status("Iperf server startup.--- "+ __LINE__.to_s)
		@equipment['pc1'].send_cmd("ps -a", /\@/, 10)
			
    # *********************** setup the iperf server side PC/DUT ***********************
		if proto == 'tcp'
			send_status("Starting Iperf Server TCP on Linux PC. --- "+ __LINE__.to_s)
			sleep 3
			#@equipment['pc1'].send_cmd("iperf -s & > perf.log", /perf.log/, 70)
			@equipment['pc1'].send_cmd("iperf -s & \\r", /Server\s+listening.*?TCP\sport.*?/, 10)
		elsif proto == 'mlti'
			send_status("Starting Iperf Multicast TCP on Linux PC. --- "+ __LINE__.to_s)
			@equipment['pc1'].send_cmd("iperf -s -u -B 224.0.36.36 &> perf.log", /\]\s+\d+/)
		else
			send_status("Starting Iperf Server UDP on Linux PC. --- "+ __LINE__.to_s)
			#@equipment['pc1'].send_cmd("iperf -s -u & >perf.log", /perf.log/, 70)
			@equipment['pc1'].send_cmd("iperf -s -u & \\r", /Server\s+listening.*?UDP\sport.*?/, 70)
		end
				
		#sleep (duration.to_i + 10)
		
		response = @equipment['pc1'].response

		puts "------------------------------  Response Start ---------------------------------"+ __LINE__.to_s
		puts "#{response}"
		puts "------------------------------  Response End ---------------------------------"+ __LINE__.to_s

		
		if response.scan(/Password/) != nil
			@equipment['pc1'].send_cmd("#{@equipment['pc1'].telnet_passwd}", /.*/)
			response = @equipment['pc1'].response
		end
		
		send_status("LineStatus: --- "+ __LINE__.to_s)
		
		@equipment['pc1'].send_cmd("ps -a", /\@/, 10)		
    
		sleep (3)
			
    # *********************** get the pid of the iperf process we just started ***********************
			
		pid = /(\d+)\s+pts.+?iperf/im.match(@equipment['pc1'].response).captures
			
    # **************** send traffic from DUT client ***********************
		
		send_status("PID:  #{pid} --- Speed: #{intfc_spd} Mb/s Window Size: #{packet_size} --- "+ __LINE__.to_s)
		
		sleep 2
		
		if proto == 'tcp'
			send_status("Transferring Iperf TCP data to and from PC. --- "+ __LINE__.to_s)
			#@equipment['dut1'].send_cmd("iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -d >perf.log", @equipment['dut1'].prompt, duration.to_i + 60)
			@equipment['dut1'].send_cmd("iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -d", @equipment['dut1'].prompt, duration.to_i + 60)
			
			sleep 6
			
			if /\sserver threads\s/.match(@equipment['dut1'].response)
				send_status("Result:  Re-running this window size --- "+ __LINE__.to_s)
				@equipment['pc1'].send_cmd("\cC", /#/,10)
				sleep 3
				@equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/)
				sleep 3
				@equipment['pc1'].send_cmd("iperf -s &", /Server\slistening.*?TCP\swindow.*?/, 70)
				sleep 7
				@equipment['dut1'].send_cmd("iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -d", @equipment['dut1'].prompt, duration.to_i + 60)
			end

    elsif proto == 'mlti'
			send_status("Transferring Iperf Client Multicast CDC data from Linux PC. --- "+ __LINE__.to_s)
			@equipment['dut1'].send_cmd("iperf -c 224.0.36.36 -u -w #{packet_size}k -t #{duration} -b 30M >perf.log", @equipment['dut1'].prompt, duration.to_i + 60)
    else
			send_status("Transferring Iperf CDC UDP data from DUT. --- "+ __LINE__.to_s)
			
			@equipment['dut1'].send_cmd("\cC", @equipment['dut1'].prompt, 10)
			sleep 3
			@equipment['dut1'].send_cmd("iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -u -b 100m", @equipment['dut1'].prompt, duration.to_i + 60)
    end
			
		sleep 3
		
		response = @equipment['dut1'].response
=begin
		puts "------------------------------  Response Start ---------------------------------"+ __LINE__.to_s
		puts "#{response}"
		puts "------------------------------  Response End ---------------------------------"+ __LINE__.to_s
=end
			# *********************** check for errors ***********************
		send_status("Checking log for errors. --- "+ __LINE__.to_s)
			
		if @equipment['dut1'].timeout?
			send_status ("Linux PC timed out. --- "+ __LINE__.to_s)
			 
			@equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/)
			send_status ("Linux PC timed out. --- "+ __LINE__.to_s)
			result = 1
				return result
			#send_status ("Kill Iperf server on WinXP. --- "+ __LINE__.to_s)
    end
			
    sleep(2)
			
		send_status ("Line Status Location: --- "+ __LINE__.to_s)
			
		if proto == 'tcp'
			send_status("Checking log for TCP errors. --- "+ __LINE__.to_s)
			#@equipment['dut1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
			#@equipment['dut1'].send_cmd("cat perf.log", @equipment['dut1'].prompt)							#
		elsif proto == 'mlti'
			send_status("Checking log for Multicast errors. --- "+ __LINE__.to_s)
			@equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
		else
			send_status("Checking log for UDP errors. --- "+ __LINE__.to_s)
			#response = @equipment['dut1'].response
			#@equipment['dut1'].send_cmd("cat perf.log", @equipment['dut1'].prompt)
		end
			
		response = @equipment['dut1'].response
			
		if proto == 'tcp'
			send_status("Checking for TCP errors. --- "+ __LINE__.to_s)
			sleep 5
			duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec.+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec/m.match(@equipment['dut1'].response).captures
		elsif proto == 'mlti'
			send_status("Checking for Multicast errors. --- "+ __LINE__.to_s)
			duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits/m.match(@equipment['pc1'].response).captures
			xfer2=bw2=0
		else
			send_status("Checking for UDP errors. --- "+ __LINE__.to_s)
			#duration,xfer1,bw1,jit1,pctloss1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec.+?([\d\.]+)\s+?ms/m.match(@equipment['dut1'].response).captures
			#    duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec\s+[\d\.]+\s+ms.+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec\s+[\d\.]+\s+ms/m.match(@equipment['dut1'].response).captures
			#duration,xfer1,bw1,jit1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec\s+[\d\.]+\s+ms/m.match(@equipment['dut1'].response).captures
			duration,xfer1,bw1,jit1,jit2,jit3 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec\s+([\d\.]+\s+ms).*?([\d\.]+)\/([\d.]+)/m.match(@equipment['dut1'].response).captures
			xfer2=bw2=0
		end
		
		sleep 2
		
    # *********************** parse/format the results ***********************
		send_status("Parsing test results. --- "+ __LINE__.to_s)
			
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

    bw=xfer=jit=pctloss=nil
    bw = (bw1.to_f + bw2.to_f).to_s if bw1 and bw2
		xfer = (xfer1.to_f + xfer2.to_f).to_s if xfer1 and xfer2
				
    #puts "=================== Data #{bw1} #{xfer1} #{bw2} #{xfer2} #{"%.3f" % (jit1.to_f)} #{"%.3f" % (pctloss1.to_f)} ===================="
    #puts "=================== Data #{bw1} #{xfer1} #{bw2} #{xfer2} ===================="
		puts " "
    puts "================= Performance Data Total BW: #{bw} Xfer Rate: #{xfer} #{bw1} #{xfer1} #{bw2} #{xfer2} ===================="
		puts " "
		puts "======================================== Test Data: #{jit1} #{jit2} #{jit3} ==============================================="
		puts " "
		send_status ("Line Status Location: --- "+ __LINE__.to_s)

		if /(\d+)\s+pts.+?iperf/im.match(@equipment['pc1'].response).captures
			@equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /@/) 
		end
		
		puts "------------------------------  Response Start ---------------------------------"+ __LINE__.to_s
		puts "#{response}"
		puts "------------------------------  Response End ---------------------------------"+ __LINE__.to_s
		
    sleep 1
		
		# *********************** ensure results are valid ***********************
    if (duration == nil || bw == nil || xfer == nil)
				@equipment['dut1'].send_cmd("kill -9 #{pid.to_s}", /.*/) 
        @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /@/) 
        @equipment['pc2'].send_cmd("taskkill /F /IM IPerf*", /.*/)
		else
			send_status("Send 1st Ctrl-C. --- "+ __LINE__.to_s)
			@equipment['dut1'].send_cmd("\cC", /#/,10)
			send_status("Send 2nd Ctrl-C. --- "+ __LINE__.to_s)
			sleep 1
			@equipment['dut1'].send_cmd("\cC", /#/,10)
			sleep 1
		end
			
		xfer = "%.3f" % (xfer.to_f)
		bw = "%.3f" % (bw.to_f)
		#jit = "%.3f" % (jit1.to_f)
		#pctloss = "%.3f" % (pctloss1.to_f)
		
			#[result, duration, bw, xfer, jit, pctloss]
			[result, duration, bw, xfer]
  end
  
  