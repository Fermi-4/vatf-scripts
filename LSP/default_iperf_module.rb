#03-07-2011 - Removed many debug status messages.

# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_target_test'

module IperfTestScript
  include LspTargetTestScript

  def setup
    send_status("-------------------------- default_iperf_module: Status message - setup ---------------------------- "+ __LINE__.to_s)
    super
  end


	# Configure the Cisco access point.	
	def setup_connect_equipment
    send_status("-------------------------- default_iperf_module: Status message - setup_connect_equipment -------------------- "+ __LINE__.to_s)
    @err_code = 0
	end


	def run_collect_performance_data
    send_status("-------------------------- default_iperf_module: Status message - collect_performance_data logic -------------------- "+ __LINE__.to_s)
	end

  
  def clean
    send_status("-------------------------- default_iperf_module: Status message - clean ---------------------------- "+ __LINE__.to_s)
  end


  def send_status(resp)
    puts "\n"
		puts " #{resp} "
		puts "\n"
  end


  def run_client_iperf(iface=nil)
    i = p = result = 0
    port = 7000
    log_file = "perf.log"
    data = Array.new(20){[]}
    perfdata = Array.new
    @test_time  = @test_params.params_chan.test_time[0]
    @tot_samples = (@test_params.params_chan.test_time[0].to_i / @test_params.params_chan.top_sample_secs[0].to_i) - 3
    @top_delay = @test_params.params_chan.top_sample_secs[0].to_i
    @test_params.params_chan.buffer_size.each do |packet_size|
    start_iperf_svr("#{@test_params.params_chan.port[0]}", "#{log_file}")
    data[i][0] = packet_size
    start_top('dut1',"top"+i.to_s+".log")
    pkt_size = packet_size.to_i/2
    sleep 2

    server_ip = @test_params.params_control.remote_ip[0]
    if(iface != nil)
      dut_ip = get_iface_ip_addr(iface)
      server_ip = get_server_lan_ip(dut_ip) if dut_ip != ''
    end
    # Start Iperf on client EVM
    if @test_params.params_chan.protocol[0] == "tcp"
      #@equipment['dut1'].send_cmd("iperf -c #{@test_params.params_control.remote_ip[0]} -p #{@test_params.params_chan.port[0]} -w #{pkt_size}K -t #{@test_time} -N -d\n", @equipment['dut1'].prompt, @test_time.to_i + 60)
      @equipment['dut1'].send_cmd("iperf -c #{server_ip} -w #{pkt_size}K -t #{@test_time} -N -d\n", @equipment['dut1'].prompt, @test_time.to_i + 60)
    else
      #@equipment['dut1'].send_cmd("iperf -c #{@test_params.params_control.remote_ip[0]} -p #{@test_params.params_chan.port[0]} -u -w #{pkt_size}K -b #{@test_params.params_chan.bw[0]} -t #{@test_time} -N", @equipment['dut1'].prompt, @test_time.to_i + 60)
      @equipment['dut1'].send_cmd("iperf -c #{server_ip} -u -w #{pkt_size}K -b #{@test_params.params_chan.bw[0]} -t #{@test_time} -N", @equipment['dut1'].prompt, @test_time.to_i + 60)
    end

    if @equipment['dut1'].timeout?
      @err_code = 1
      raise "The iperf test to #{server_ip} timed out and could not be completed. "+ __LINE__.to_s
    end

    sleep 1

    # Get desired performance data via a matching filter
    # data[i][0] = window size, data[i][1] = @test_time, data[i][2] = Xfer 1, data[i][3] = Bandwidth 1, data[i][4] = Xfer 2, data[i][5] = Bandwidth 2, data[i][6] = Total Bandwidth
 	  data[i][0] = "#{packet_size}"
    @pk_size = "#{packet_size}"

    if @test_params.params_chan.protocol[0] == "tcp"
      if /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits\/sec.+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits\/sec/m.match(@equipment['dut1'].response)
        duration,xfer1,bw1,xfer2,bw2 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits\/sec.+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits\/sec/m.match(@equipment['dut1'].response).captures
      else
        @err_code = 3
        break
      end
    else
      if /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits\/sec\s+?([\d\.]+)\s+?ms\s+([\d\.]+)\/+([\d\.]+)[\s\d\/]+?\(([\d\.]+)%\)/m.match(@equipment['dut1'].response)
        duration,xfer1,bw1,jit1,pkt_lost,pkt_sent,pct_loss1 = /-([\d\.]+)\s+?sec\s+?([\d\.]+\s+?[GMK])Bytes\s+?([\d\.]+\s+?[GMK])bits\/sec\s+?([\d\.]+)\s+?ms\s+([\d\.]+)\/+([\d\.]+)[\s\d\/]+?\(([\d\.]+)%\)/m.match(@equipment['dut1'].response).captures
      else
        @err_code = 4
        break
      end
    end

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
	    xfer2 = "%.3f" % (xfer2.to_f / 1000)
    else
 	    xfer2 = "%.3f" % (xfer2.to_f)
    end

    jitter = "%.3f" % (jit1.to_f)
    tot_bw = (bw1.to_f + bw2.to_f).to_s if bw1 and bw2
    tot_xfer = (xfer1.to_f + xfer2.to_f).to_s if xfer1 and xfer2

    data[i][1] = duration
    data[i][2] = xfer1
    data[i][3] = bw1
    data[i][4] = xfer2
    data[i][5] = bw2
    data[i][6] = tot_bw
    data[i][7] = tot_xfer

    if @test_params.params_chan.protocol[0] == "udp"
      data[i][8] = jitter
      data[i][9] = pkt_lost
      data[i][10] = pkt_sent
      data[i][11] = pct_loss1
        
    else
      data[i][8] = "NA"
      data[i][9] = "NA"
      data[i][10] = "NA"
      data[i][11] = "NA"
    end

    data[i][12] = 0
    sleep 1

    @equipment['dut1'].send_cmd("cat top"+i.to_s+".log", @equipment['dut1'].prompt, @test_time.to_i + 10)
    top_response = @equipment['dut1'].response
    @top_average = process_top_data1(top_response)
    data[i][12] = @top_average
    @test_data << data[i].flatten
    data_count = data.size
    perfdata << {'name'=> "BW_#{@test_params.params_chan.protocol[0].upcase}_#{packet_size}", 'value'=> tot_bw.to_f, 'units' => "Mb/s"}

    i = i+1
    end

    @array_lines = i
    @array_size = @test_data.size
    result, comment = run_determine_test_outcome

    [result,comment,perfdata]
  end


  def run_client_ping(iface=nil)
    i = p = result = 0
    port = 7000
    log_file = "ping.log"
    data = Array.new(20){[]}
    perfdata = Array.new
    @test_time  = @test_params.params_chan.pings[0]
    @tot_samples = @test_params.params_chan.pings[0].to_i
    @test_params.params_chan.buffer_size.each do |packet_size|
      data[i][0] = packet_size
      server_ip = @test_params.params_control.remote_ip[0]
      if(iface != nil)
        dut_ip = get_iface_ip_addr(iface)
        server_ip = get_server_lan_ip(dut_ip) if dut_ip != ''
      end 
      @equipment['dut1'].send_cmd("ping  -s#{packet_size} -c#{@test_params.params_chan.pings[0]} #{server_ip} >ping"+i.to_s+".log", @equipment['dut1'].prompt, @test_time.to_i + 60)
      # Start Iperf on client EVM                                                                                 "+i.to_s+".log"

      if @equipment['dut1'].timeout?
        @err_code = 7
        raise "The ping to #{server_ip} timed out and could not be completed. "+ __LINE__.to_s
      end

      sleep 1

      # Get desired performance data via a matching filter
      @pkt_size = packet_size
      @equipment['dut1'].send_cmd("cat ping"+i.to_s+".log", @equipment['dut1'].prompt, @test_time.to_i + 10)
      @ping_response = @equipment['dut1'].response

      if /([\d.]*?)\s+pack.*\s+([\d.]*?)\s+pack.*\s([\d.]+)\%/i.match(@ping_response)
        pkts_xmtd,pkts_rcvd,pkt_loss,tot_ping_time = /([\d.]*?)\s+pack.*\s+([\d.]*?)\s+pack.*\s([\d.]+)\%/im.match(@ping_response).captures
      end

      if /([0-9]\.[0-9]*)\/([0-9]\.[0-9]*)\/([0-9].*[0-9])\s+ms/im.match(@ping_response)
        rtt_min,rtt_avg,rtt_max,rtt_mdev = /([0-9]\.[0-9]*)\/([0-9]\.[0-9]*)\/([0-9].*[0-9])\s+ms/im.match(@ping_response).captures
      end

      data[i][0] = packet_size
      data[i][1] = pkts_xmtd
      data[i][2] = pkts_rcvd
      data[i][3] = pkt_loss
      data[i][4] = "NA"
      #data[i][4] = tot_ping_time
      data[i][5] = rtt_min
      data[i][6] = rtt_avg
      data[i][7] = rtt_max
      data[i][8] = "NA"
      #data[i][8] = rtt_mdev

      @test_data << data[i].flatten
      @array_size = data.size
      perfdata << {'name'=> "PING_#{@test_params.params_chan.protocol[0].upcase}_#{packet_size}", 'value'=> rtt_avg.to_f, 'units' => "ms"}

      i = i+1
    end

    @array_lines = i
    result, comment = run_determine_test_outcome
    [result,comment,perfdata]
  end


	def run_determine_test_outcome
    send_status("-------------------------- default_iperf_module: Status message - run_determine_test_outcome -------------------- "+ __LINE__.to_s)

    packet_size = @pk_size.to_i * 2

    if @test_params.params_chan.mode[0] == "iperf"
      mode = @test_params.params_chan.mode[0].upcase + " performance"
    else
      mode = @test_params.params_chan.mode[0].upcase
    end

    case @err_code
      when 0
        result = FrameworkConstants::Result[:pass]
        comment = "#{mode} test was successful."
      when 1
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} test timed out at packet size #{packet_size} Kbytes."
      when 2
        result = FrameworkConstants::Result[:fail]
        comment = "AP Product String Not Found."
      when 3
        result = FrameworkConstants::Result[:fail]
        comment = "Iperf TCP performance data could not be calculated #{@err_code}."
      when 4
        result = FrameworkConstants::Result[:fail]
        comment = "Iperf UDP performance data could not be calculated #{@err_code}."
      when 5
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} timed out with the remote device."
      when 6
        result = FrameworkConstants::Result[:fail]
        comment = "The EVM was not rebooted correctly."
      when 7
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} test failed - timeout."
      when 8
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} performance test failed."
      when 9
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} test failed."
      when 10
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} test failed."
      when 11
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} test failed."
      when 12
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} test failed - timeout."
      else
        result = FrameworkConstants::Result[:fail]
        comment = "#{mode} performance test failed."
      end

      [result,comment]
	end


	# Send configuration commands to the local host PC with commands such as starting Iperf or other such programs.
  def start_iperf_svr(port, log_file)
    device = "server1"
    host_pid = check_iperf_is_runnning(@equipment["server1"])

    if host_pid
      @equipment["#{device}"].send_cmd("kill -9 #{host_pid.to_s}")
      send_status("-------------------- default_iperf_module: Status message - Iperf has been stopped on #{device} ------------------------- "+ __LINE__.to_s)
    else
      send_status("-------------------- default_iperf_module: Status message - Iperf is being started on #{device} ------------------------- "+ __LINE__.to_s)
    end

    sleep 3
    
    if @test_params.params_chan.protocol[0] == "tcp"
      #@equipment["#{device}"].send_cmd("iperf -s -N -p#{@test_params.params_chan.port[0]} >#{log_file} &\n")
      @equipment["#{device}"].send_cmd("iperf -s -N >#{log_file} &\n")
    else
      #@equipment["#{device}"].send_cmd("iperf -s -N -p#{@test_params.params_chan.port[0]} -u >#{log_file} &")
      @equipment["#{device}"].send_cmd("iperf -s -N -u >#{log_file} &")
    end
    
    host_pid = check_iperf_is_runnning(@equipment["#{device}"])
  end


  def start_top(device, file)
    @current_top_file_name = file
    iface_grep = 'tiwlan]'
    iface_grep = 'wl1271]' if is_kernel_ge37?
    @equipment["#{device}"].send_cmd("nohup top -d #{@top_delay} -n #{@tot_samples} -b |grep #{iface_grep} >#{file} &", @equipment["#{device}"].prompt, 10)
  end


  def process_top_data1(response)
    wifi_cpu_pct = Array.new
    send_status("-------------------- default_iperf_module: Status message - TOP results are being processed from the cat response------------------------- "+ __LINE__.to_s)
    final_pct = count = tmp_pct = diff = 0
    iface_regex = /tiwlan/
    iface_regex = /irq\/\d+\-wl\d+/
    wifi_cpu_pct = response.scan(/(\s[\d]+)\%\s+\[#{iface_regex}\]/)
    count = wifi_cpu_pct.flatten!.size
    tst = wifi_cpu_pct[0].match(/([\d]+)/).captures[0].to_i

    for j in 0..count - 1 do
      pct = wifi_cpu_pct[j].to_i

      if pct == 0
        diff = diff + 1
      else
        tmp = tmp_pct
        tmp_pct = tmp + pct
      end
    end 

    count = count - diff    
    final_pct = "%.3f" % (tmp_pct.to_f/ count.to_f)

    [final_pct]
  end


	def get_dut_ip
    @equipment['dut1'].send_cmd("ifconfig -a", @equipment['dut1'].prompt, 5)
    sleep 1
    dut_ip = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match("#{@equipment['dut1'].response}").captures[0]

    dut_ip
  end


  def get_proc_list
		@equipment['dut1'].send_cmd("ps", @equipment['dut1'].prompt, 5)
    proc = ""
  end


  def check_iperf_is_runnning(device)
    @equipment['server1'].send_cmd("ps -A | grep iperf",@equipment['server1'].prompt)

    if pid = /(\d+)\s+pts.+?iperf/im.match(device.response)
      pid = /(\d+)\s+pts.+?iperf/im.match(device.response).captures[0]
    else
      pid ? pid.captures[0] : false
    end

    pid
  end


  def send_status(resp)
    puts "\n"
		puts " #{resp} "
		puts "\n"
  end


  def kill_pid(device, pid)
     @equipment["#{device}"].send_cmd("kill -9 #{pid.to_s}")
  end


  def reg_ensure(regex, match)
    rx = regex.match(@equipment['pc1'].response) 
    return rx != nil ? rx[match] : nil
  end

  def get_server_lan_ip(dut_ip)
    ip_addr = ''
    @equipment['server1'].send_cmd("ifconfig")
    #          inet addr:158.218.103.11  Bcast:158.218.103.255  Mask:255.255.254.0
    @equipment['server1'].response.lines.each do |current_line|
      if (line_match = current_line.match(/^\s+inet\s+addr:(#{dut_ip.gsub('.','\.').sub(/\d+$/,'\d+')})\s+Bcast:.*/))
        ip_addr = line_match.captures[0]
      end
    end
    ip_addr
  end

  def get_iface_ip_addr(iface)
    addr = ''
    @equipment['dut1'].send_cmd("ifconfig #{iface}",@equipment['dut1'].prompt)
    net_info = @equipment['dut1'].response
    net_info.lines.each do |current_line|
      if current_line.match(/^\s*inet\s*addr:[\d\.]{7,15}\s+Bcast:.+/i)
      addr = current_line.match(/^\s*inet\s*addr:([\d\.]{7,15})\s+Bcast:.+/i).captures[0]
      end
    end
    addr
  end

   def is_kernel_ge37?
    @equipment['dut1'].send_cmd("uname -a", @equipment['dut1'].prompt)
    version_arr = @equipment['dut1'].response.match(/Linux.*?(\d+\.\d+\.\d+).*/im).captures[0].split(/\./)
    version_arr[0].to_i > 2  || (version_arr[0].to_i == 2 && version_arr[1].to_i > 6) || (version_arr[0].to_i == 2 && version_arr[1].to_i == 6 && version_arr[2].to_i >= 37)
  end


end
