# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_test_module'
# Default Server-Side Test script implementation for LSP releases
include LspTestScript

def setup
  BuildClient.enable_config_step
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
    
    # src_ip = @equipment['dut1'].telnet_ip
    puts "default_perf_iperf_script_run-1"
    #@equipment['dut1'].send_cmd("ifconfig #{iface}", @equipment['dut1'].prompt)
    #@equipment['dut1'].send_cmd("ifconfig 10.10.10.1 netmask 255.255.255.0 #{iface}", @equipment['dut1'].prompt)
    iface = @test_params.params_chan.instance_variable_defined?(:@interface) ? @test_params.params_chan.interface[0] : 'eth0'
    @equipment['dut1'].send_cmd("ifconfig #{iface}", @equipment['dut1'].prompt)
    src_ip = reg_ensureb(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
    puts "default_perf_iperf_script_run-2"
    
    @equipment['pc1'].send_cmd("ifconfig #{iface}", @equipment['dut1'].prompt)
    dest_ip = reg_ensureb(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
    #dest_ip = @equipment['pc1'].telnet_ip 
    puts "default_perf_iperf_script_run-3"
		
    # Execute ethernet performance test
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "5"},{:color => "red"}]],{:border => "1",:width=>"30%"})
    @results_html_file.add_row_to_table(res_table, ["TCP Window Size in KBytes", "Bandwidth Mbits/sec", "Transfer Size in MBytes", "Interval in sec"])
    window_sizes   = @test_params.params_chan.window_size[0].split(' ')
    duration = @test_params.params_chan.duration[0]        
        i=0
        window_sizes.each {|window_size|
                  
            result, dur, bw, xfer = run_perf_test(src_ip, dest_ip, (window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0], i)
            
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


  # Simple helper function to catch for errors in the regex matching
  def reg_ensure(regex, match)
    rx = regex.match(@equipment['pc1'].response) 
    return rx != nil ? rx[match] : nil
  end
  
  # Simple helper function to catch for errors in the regex matching
  def reg_ensureb(regex, match)
    rx = regex.match(@equipment['dut1'].response) 
    return rx != nil ? rx[match] : nil
  end
  
  def run_perf_test(src_ip, dest_ip, packet_size, duration, proto, counter)
  
    result = 0
    
    # make sure the pc is not running any iperf servers
    @equipment['pc1'].send_cmd("killall -9 iperf ; rm -rf perf.log", /.*/)
    
    # setup server side iperf pc
    if proto == 'tcp'
    	@equipment['pc1'].send_cmd("iperf -w #{packet_size}k -s > perf.log &", /\]\s+\d+/)
    else
      @equipment['pc1'].send_cmd("iperf -u -w #{packet_size}k -s > perf.log &", /\]\s+\d+/)
    end
    
    # get the pid of the iperf process we just started
    pid = reg_ensure(/(\]\s+)(\d+)/, 2)
    
    # send traffic from DUT client
    if proto == 'tcp' 
    	@equipment['dut1'].send_cmd("./iperf -c #{dest_ip} -w #{packet_size}k -t #{duration} -d", /Mbits/, duration.to_i + 30)
    else
      @equipment['dut1'].send_cmd("./iperf -u -c #{dest_ip} -w #{packet_size}k -t #{duration} -d", /\d+\s+ms/, duration.to_i + 30)
    end
    
    # check for errors
    if @equipment['dut1'].timeout?
        @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/) 
        result = 1
        return result
    end
    
    sleep(1)
    #@equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
	@equipment['pc1'].send_cmd("cat perf.log", /Done/)
    
	duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+)\s+?[MK]Bytes\s+?([\d\.]+)\s+?[MK]bits\/sec.+?([\d\.]+)\s+?[MK]Bytes\s+?([\d\.]+)\s+?[MK]bits\/sec/m.match(@equipment['pc1'].response).captures
    
    # parse the results
	bw=xfer=nil
	bw = (bw1.to_f + bw2.to_f).to_s if bw1 and bw2
	xfer = (xfer1.to_f + xfer2.to_f).to_s if xfer1 and xfer2
	puts "============== Data #{bw1} #{xfer1} #{bw2} #{xfer2}"
  
    # ensure results are valid
    if (duration == nil || bw == nil || xfer == nil)
      @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/) 
      result = 3
      return result
    end
    
    [result, duration, bw, xfer]  
  end
  
  