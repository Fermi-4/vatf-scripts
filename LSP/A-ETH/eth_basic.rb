# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

def setup
  super
end

def run
        puts "eth_basic.run"
        commands = ensure_commands = ""
        commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
        ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
        
        # get the eth0 ip of the unit (not always the same as telnet_ip due to portmaster)
        #@equipment['dut1'].send_cmd("ifconfig eth0", @equipment['dut1'].prompt)
        #return reg_ensure(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 'dut1', 1)
        
        
        result, cmd = execute_cmd(commands)
        if result == 0 
            set_result(FrameworkConstants::Result[:pass], "Test Pass.")
        elsif result == 1
            set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
        elsif result == 2
            set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
        else
            set_result(FrameworkConstants::Result[:nry])
        end
  ensure 
    result, cmd = execute_cmd(ensure_commands)
end

def clean
  super
end

def ping_self
  @result = 0
  @equipment['dut1'].send_cmd("ifconfig eth0", /packets/)
  
  puts "||#{@equipment['dut1'].response}||"
  dut_ip = reg_ensure(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/, 1)
  puts "##dut_ip=#{dut_ip}##"
  
  @equipment['dut1'].send_cmd("ping -c 2 #{dut_ip}", /2 packets transmitted\, 2 received/)
  if @equipment['dut1'].timeout?
        @result = 1
  end
end
  

private


  # Simple helper function to catch for errors in the regex matching
  def reg_ensure(regex, match)
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
    	@equipment['dut1'].send_cmd("./iperf -c #{dest_ip} -w #{packet_size}k -t #{duration}",
                                               /Mbits/,
                                               duration.to_i + 30)
    else
        @equipment['dut1'].send_cmd("./iperf -u -c #{dest_ip} -w #{packet_size}k -t #{duration}",
                                               /\d+\s+ms/,
                                               duration.to_i + 30)
    end
    
    # check for errors
    if @equipment['dut1'].timeout?
        @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/) 
        result = 1
        return result
    end
    
    sleep(1)
    @equipment['pc1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
    
    
    # parse the results
    if proto == 'tcp'
      duration = reg_ensure(/([0-9]*\.?[0-9]+)(?=\s+(sec))/, 2)
    else
      duration = reg_ensure(/([0-9]*\.?[0-9]+)(?=\s+(sec))/, 1)
    end
    bw        = reg_ensure(/([0-9]*\.?[0-9]+)(?=\s+Mbits)/, 1)
    xfer       =reg_ensure(/([0-9]*\.?[0-9]+)(?=\s+MBytes)/, 1)
    
    # ensure results are valid
    if (duration == nil || bw == nil || xfer == nil)
      @equipment['pc1'].send_cmd("kill -9 #{pid.to_s}", /Killed/) 
      result = 3
      return result
    end
    
    [result, duration, bw, xfer]  
  end
  
  