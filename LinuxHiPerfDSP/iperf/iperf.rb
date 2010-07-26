# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for c6x-Linux releases
  require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
  include C6xTestScript
      
  def setup
    #BuildClient.enable_config_step
    super
  end
      
  def run
    connect_to_equipment('server1')
    # @equipment['dut1'].set_api('psp')
    # connect_to_equipment('dut1')

    @equipment['dut1'].send_cmd("cd /opt \n", /#{@equipment['dut1'].prompt}/, 10) 
    @equipment['server1'].send_cmd("cd /opt \n", /#{@equipment['server1'].prompt}/, 10) 
    result = 0 		#0=pass, 1=timeout, 2=fail message detected
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
    puts "Checking link continuity. --- "
    @equipment['dut1'].send_cmd("ping -c 4 #{@equipment['server1'].telnet_ip}", /4\s+packets\s+received.*?/)

    if @equipment['dut1'].timeout?
      result = 6
    end
    pc_ip = @equipment['server1'].telnet_ip
    dut_ip = @equipment['dut1'].telnet_ip

    # *********************** Execute USB iperf performance test ***********************
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Performance Numbers (#{@rtp_db.get_platform} - #{@test_params.params_chan.protocol[0]})",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"40%"})
    @results_html_file.add_row_to_table(res_table, ["TCP Window Size in KBytes", "Bandwidth Mbits/sec", "Transfer Size in MBytes", "Interval in sec", "Jitter in ms", "%Packet Loss"])
    window_sizes = @test_params.params_chan.window_size[0].split(' ')

    duration = @test_params.params_chan.duration[0]       
        i=0
        window_sizes.each {|window_size|
            result, dur, bw, xfer,jitter,pctloss = run_perf_test(pc_ip, dut_ip,(window_size.to_i/2).to_s, duration, @test_params.params_chan.protocol[0])
            break if result > 0
            @results_html_file.add_row_to_table(res_table, [window_size, bw, xfer, dur, jitter, pctloss])
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
    self.as(C6xTestScript).clean
    #super
  end
      
private
def cleanup(pc_pid)
    @equipment['server1'].send_cmd("kill -9 #{pc_pid.to_s}", @equipment['server1'].prompt) 
    @equipment['dut1'].send_cmd("ps -a", @equipment['dut1'].prompt, 10)
    sleep (3)
    if(/(\d+)\s+pts.+?iperf/im.match(@equipment['dut1'].response))
      dut_pid = /(\d+)\s+pts.+?iperf/im.match(@equipment['dut1'].response).captures
      @equipment['dut1'].send_cmd("kill -9 #{dut_pid.to_s}", @equipment['dut1'].prompt) 
    end

 end
  # for usb iperf throughput steps:
  # 1. Setup usb on both DUT and PC sides, configuring both devices on a separate network as the normal ethernet device 
  # 2. Start iperf server on the PC side 
  # 3. Start iperf client on the DUT side
  # 4. Collect results from the PC side
  def run_perf_test(pc_ip, dut_ip, packet_size, duration, proto)
    result = 0
    # *********************** setup the iperf server side PC/DUT ***********************
    if proto == 'tcp'
      puts "Starting Iperf Server TCP on Linux PC. --- "
      @equipment['server1'].send_cmd("iperf -s > perf.log &", /\]\s+\d+/, 70)
    elsif proto == 'mlti'
      puts "Starting Iperf Multicast TCP on Linux PC. --- "
      @equipment['server1'].send_cmd("iperf -s -u -B 224.0.36.36 > perf.log &", /\]\s+\d+/)
    else
      puts "Starting Iperf Server UDP on Linux PC. --- "
      @equipment['server1'].send_cmd("iperf -s -u &", /Server\s+listening.*?UDP\sport.*?/, 70)
    end
    @equipment['server1'].send_cmd("echo $!", @equipment['server1'].prompt, 10)
    if(/(\d+)/.match(@equipment['server1'].response))
      pc_pid = /(\d+)/.match(@equipment['server1'].response).captures
    else
      raise "Iperf failed to start on server"
    end
    if proto == 'tcp'
      puts "Transferring Iperf TCP data to and from PC. --- "
      @equipment['dut1'].send_cmd("iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -r", @equipment['dut1'].prompt, duration.to_i + 60)
      if /\sserver threads\s/.match(@equipment['dut1'].response)
        puts "Result:  Re-running this window size --- "
        cleanup(pc_pid)
        @equipment['server1'].send_cmd("iperf -s &", /Server\slistening.*?TCP\swindow.*?/, 70)
        sleep 7
        @equipment['dut1'].send_cmd("iperf -c #{pc_ip} -w #{packet_size}k -t #{duration} -r", @equipment['dut1'].prompt, duration.to_i + 60)
      end
    elsif proto == 'mlti'
      puts "Transferring Iperf Client Multicast CDC data from Linux PC. --- "
      @equipment['dut1'].send_cmd("iperf -c 224.0.36.36 -u -t #{duration} -b 30M ", @equipment['dut1'].prompt, duration.to_i + 60)
    else
      puts "Transferring Iperf CDC UDP data from DUT. --- "
      @equipment['dut1'].send_cmd("iperf -c #{pc_ip} -t #{duration} -u -b 100m", @equipment['dut1'].prompt, duration.to_i + 360)
    end

    if @equipment['dut1'].timeout?
      puts "DUT timed out. --- "
      cleanup(pc_pid)
      result = 1
      return result
    end
    if proto == 'tcp'
      puts "Checking log for TCP errors. --- "
      @equipment['server1'].send_cmd("cat perf.log", @equipment['server1'].prompt)
    elsif proto == 'mlti'
      puts "Checking log for Multicast errors. --- "
      @equipment['server1'].send_cmd("cat perf.log", /([0-9]*\.?[0-9]+)(?=\s+Mbits)/)
    else
      puts "Checking log for UDP errors. --- "
      @equipment['server1'].send_cmd("cat perf.log", @equipment['server1'].prompt)
    end
    if proto == 'tcp'
      puts "Checking for TCP errors. --- "
      duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec.+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec/m.match(@equipment['server1'].response).captures
    elsif proto == 'mlti'
      puts "Checking for Multicast errors. --- "
      duration,xfer1,bw1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits/m.match(@equipment['server1'].response).captures
      xfer2=bw2=0
    else
      puts "Checking for UDP errors. --- "
      duration,xfer1,bw1,jit1,lost,total = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[MK])bits\/sec\s+([\d\.]+\s+ms).*?([\d\.]+)\/([\d.]+)/m.match(@equipment['dut1'].response).captures
      xfer2=bw2=0
    end

    # *********************** parse/format the results ***********************
    puts "Parsing test results. --- "
      
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

    puts " "
    puts "================= Performance Data Total BW: #{bw} Xfer Rate: #{xfer} #{bw1} #{xfer1} #{bw2} #{xfer2} ===================="
    puts " "
    puts "======================================== Test Data: #{jit1} #{lost} #{total} ==============================================="
    puts " "

    xfer = "%.3f" % (xfer.to_f)
    bw = "%.3f" % (bw.to_f)
    jit = "%.3f" % (jit1.to_f)
    pctloss1 = ((lost.to_f)/(total.to_f))*100
    pctloss = "%.3f" % (pctloss1.to_f)
    cleanup(pc_pid)
    [result, duration, bw, xfer, jit, pctloss]

    #[result, duration, bw, xfer]
  end

  
  