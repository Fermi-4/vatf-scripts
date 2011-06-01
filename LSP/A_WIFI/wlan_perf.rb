# ---------------------------------- Change Log ----------------------------------
#03-07-2011 - Removed cfg_access_point subroutine.
#03-07-2011 - Removed many debug status messages.
#03-07-2011 - Added local_ip variable to define the local tiwlan0 interface ip address.
#03-07-2011 - renamed client wlan configuration file names.
#03-07-2011 - Modified run_bluetooth_scan filter expression to recognize the WinXP Bluetooth interface name.
#03-09-2011 - Modified test results HTML page to include Cisco AP software image file names.
#03-09-2011 - When testing Bluetooth, the Protocol and Security fields on the HTML will show N/A.

require File.dirname(__FILE__)+'/../default_iperf_module'

include IperfTestScript

  def setup
    send_status("-------------------------- wlan_perf_module: Status message - setup --------------------------  "+ __LINE__.to_s)
    super
  end

	# Configure the Cisco access point.	
	def setup_connect_equipment
    @err_code = 0
    send_status("-------------------------- wlan_perf_module: Status message - setup_connect_equipment --------------------------  "+ __LINE__.to_s)
    @equipment['ap1'].connect({'type'=>'telnet'})
    get_AP_info
	end


	def run
    @test_data = Array.new
    @array_size = 0
    send_status("-------------------------- wlan_perf_module: Status message - Wifi client configuration started --------------------------  "+ __LINE__.to_s)
    sleep 1
    @equipment['dut1'].send_cmd("ls -l", @equipment['dut1'].prompt)
    get_proc_list

    #if /\s+wpa_supplicant\s+/im.match(@equipment['dut1'].response)
    #  @err_code = 2
    #  raise "The WIFI interface is still active from last run. A manual reboot will be required. "+ __LINE__.to_s
    #end

    cfg_bluetooth_client
    sleep 1
    cfg_wifi_client
    sleep 1
    send_status("-------------------------- wlan_perf_module: Status message - collect_performance_data logic started --------------------------  "+ __LINE__.to_s)

    if @test_params.params_chan.mode[0] == "iperf"
      iface = nil
      iface = 'wlan0' if is_kernel_ge37?
      result = run_client_iperf(iface)
    elsif @test_params.params_chan.mode[0] == "bluetooth"
      result = run_bluetooth_scan
      get_bluetooth_capabilities
    else
      iface = nil
      iface = 'wlan0' if is_kernel_ge37?
      result = run_client_ping(iface)
    end

    create_html_page

    if @test_params.params_chan.mode[0] == "bluetooth"
      set_result(result[0],result[1])
    else
      set_result(result[0],result[1],result[2])
    end
	end


  def clean
    send_status("-------------------------- wlan_perf_module: Status message - clean --------------------------  "+ __LINE__.to_s)
  end


	# capture miscellaneous information from the particular Cisco access point being used	
	def get_AP_info
		@equipment['ap1'].send_cmd("en",'Password',5)
		sleep 2
    @equipment['ap1'].send_cmd(@equipment['ap1'].login, "",2)
		sleep 2
		@equipment['ap1'].send_cmd("show version", @equipment['ap1'].boot_prompt, 5)
    sleep 2

    if /Product\/Model\s+Number\s+\:\s+(.*\d\s)/.match("#{@equipment['ap1'].response}")
      @ap_mdl = /Product\/Model\s+Number\s+\:\s+(.*\d\s)/.match("#{@equipment['ap1'].response}").captures[0]
    else
      @err_code = 2
    end
    
    if /Cisco IOS Software\,\s+([a-zA-Z].*\w\))?/i.match("#{@equipment['ap1'].response}")
      @APIOSversion = /Cisco IOS Software\,\s+([a-zA-Z].*\w\))?/i.match("#{@equipment['ap1'].response}").captures[0]
    else
      @APIOSversion = "Not found"
    end
    
    if /BOOTLDR\:\s+([a-zA-Z].*\w\))?/i.match("#{@equipment['ap1'].response}")
      @APbootLdrVersion = /BOOTLDR\:\s+([a-zA-Z].*\w\))?/i.match("#{@equipment['ap1'].response}").captures[0]
    else
      @APbootLdrVersion = "Not found"
    end
    
    if /image file is\s+\"flash\:\/*([a-zA-Z].*\w)?/i.match("#{@equipment['ap1'].response}")
      @APimgFileName = /image file is\s+\"flash\:\/*([a-zA-Z].*\w)?/i.match("#{@equipment['ap1'].response}").captures[0]
    else
      @APimgFileName = "Not found"
    end
 	end


	# This routine will configure and enable the particular test platform (EVM) to be used as a wireless client.
	def cfg_wifi_client
    file = @test_params.params_chan.security[0]+"_evm.txt"
    if is_kernel_ge37?
      send_file(@equipment['dut1'],File.join(File.dirname(__FILE__),'cfg-scripts','iw',"#{file}"))
    else
      send_file(@equipment['dut1'],File.join(File.dirname(__FILE__),'cfg-scripts','am1808',"#{file}"))
    end
    @equipment['dut1'].send_cmd("cd /home/root", @equipment['dut1'].prompt)
    sleep 1
    wifi_iface = "tiwlan0"
    wifi_iface = "wlan0" if is_kernel_ge37?
    #@equipment['dut1'].send_cmd("ifconfig #{wifi_iface} #{@test_params.params_control.local_ip[0]} netmask 255.255.255.0 up", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("ifdown #{wifi_iface}", @equipment['dut1'].prompt)
    sleep 1
    @equipment['dut1'].send_cmd("ifup #{wifi_iface}", @equipment['dut1'].prompt)
    sleep 1
    @equipment['dut1'].send_cmd("ifconfig #{wifi_iface}", @equipment['dut1'].prompt)
    sleep 1
    wlan_ip = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match("#{@equipment['dut1'].response}").captures[0]
    @equipment["dut1"].send_cmd("ping -c 3 #{get_server_lan_ip(wlan_ip)}", @equipment['dut1'].prompt, 20)
  end

	# This routine will configure and enable the particular test platform (EVM) to be used as a wireless client.
	def cfg_bluetooth_client
    @equipment['dut1'].send_cmd("cd /usr/share/wl1271-demos/bluetooth/scripts", @equipment['dut1'].prompt)
    sleep 1
    send_status ("-------------------------- wlan_perf_module: Status message - Configuring Bluetooth interface -------------------------------------- "+ __LINE__.to_s)
    @equipment['dut1'].send_cmd("./BT_Demo.sh", "===>", 30)
    tst_response = @equipment['dut1'].response
    sleep 2

    if /\/firm.*\/([a-zA-Z0-9].+)L/im.match("#{tst_response}")
      @bt_frmwre_ver = /\/firm.*\/([a-zA-Z0-9]+\_[0-9]+.[0-9]+.[0-9]+.[a-z]+)/im.match("#{tst_response}").captures[0]
    else
      @bt_frmwre_ver = "Not found"
    end

    @equipment['dut1'].send_cmd("10", @equipment['dut1'].prompt,10)
    sleep 2
  end


	def run_bluetooth_scan
    i=0
    data = Array.new(20){[]}
    perfdata = Array.new
    @equipment['dut1'].send_cmd("cd /usr/share/wl1271-demos/bluetooth/scripts", @equipment['dut1'].prompt)
    sleep 1
    send_status ("-------------------------- wlan_perf_module: Status message - Configuring Bluetooth interface -------------------------------------- "+ __LINE__.to_s)
    @equipment['dut1'].send_cmd("./BT_Inquiry.sh", @equipment['dut1'].prompt, 30)
    tst_response = @equipment['dut1'].response
    sleep 2

    if /([0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+)/im.match(@equipment['dut1'].response)
      #@bt_mac,@bt_device_name = /([0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+)\s+([0-9a-zA-Z]+\-[0-9a-zA-Z]+\-[0-9a-zA-Z]+)/im.match(@equipment['dut1'].response).captures
      @bt_mac,@bt_device_name = /([0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+:[0-9a-zA-Z]+)\s+([0-9a-zA-Z].*)/i.match(@equipment['dut1'].response).captures
    else
      @bt_found = @bt_device_name = "Not found"
      raise "No Bluetooth client devices found. "+ __LINE__.to_s
    end

    @test_data << data[i].flatten
    @array_lines = 1
    sleep 2
    packet_size = 1
    result, comment = run_determine_test_outcome
    [result,comment]
  end


  def get_bluetooth_capabilities
    i=0
    tmp1 = ""
    cap_data = Array.new
    perfdata = Array.new
    @equipment['dut1'].send_cmd("cd /usr/share/wl1271-demos/bluetooth/scripts", @equipment['dut1'].prompt)
    sleep 1
    send_status ("-------------------------- wlan_perf_module: Status message - Configuring Bluetooth interface -------- #{@bt_mac} ------------------------------ "+ __LINE__.to_s)
    @equipment['dut1'].send_cmd("./BT_Get_Device_Capabilies.sh", "",5)
    tst1_response = @equipment['dut1'].response
    sleep 1
    @equipment['dut1'].send_cmd("#{@bt_mac}", @equipment['dut1'].prompt, 15)
    tst2_response = @equipment['dut1'].response
    sleep 2
    
    if tst2_response.scan(/Service\s+Name\:\s+([a-zA-Z].*\w)?/i)
      cap_data = tst2_response.scan(/Service\s+Name\:\s+([a-zA-Z].*\w)?/i)
    else
      raise "No Bluetooth services were found on device #{@bt_device_name}. "+ __LINE__.to_s
    end
    
    count = cap_data.flatten!.size
    @cap2_data = cap_data
    @array_lines = 1

    for j in 0..count - 1 do
      tmp1 << @cap2_data[j].to_s

      if j < count - 1
        tmp1 << ", "
      end

    end 

    @capabilities = tmp1

    result, comment = run_determine_test_outcome
    [result,comment]
  end

	# This routine will send a ping from either the test platform to the host or from the host to the test platform.
	def chk_ping_fm_dut (device, count)
    send_status("-------------------- default_iperf_module: Status message - Iperf module is sending a ping to #{device} ------------------------- "+ __LINE__.to_s)

    if device == "ap1"
      tempy = "ping -c #{@test_params.params_control.test_time[0]} #{@test_params.params_control.ap_wifi_ip[0]}"
    else
      tempy = "ping -c #{@test_params.params_control.test_time[0]} #{get_server_lan_ip(@test_params.params_control.local_ip[0])}"
    end

		@equipment["#{device}"].send_cmd("#{tempy}", /\s+packet\s+loss/, count.to_i + 15)

    if @equipment['dut1'].timeout?
      @err_code = 5
      raise "The ping to #{get_server_lan_ip(@test_params.params_control.local_ip[0])} timed out and could not be completed. "+ __LINE__.to_s
    end

    if /([\d\.]+)\%\s+packet\s+loss?/.match("#{@equipment['dut1'].response}").captures[0].to_i == "0"
      @err_code = 0
    end
	end


  def send_file(device,file)
    in_file = File.new(file, 'r')
		raw_test_lines = in_file.readlines
    send_status("-------------------------- wlan_perf_module: Status message - Sending configuration file: #{file} ------ #{device} ------------------------ "+ __LINE__.to_s)
  		raw_test_lines.each do |current_line|
      device.send_cmd(current_line, /#{device.prompt}|>|#/)
      test2 = device.response

      if test2.match(/WiLink.*\_([\d].*)/)
        @drvr_ver = test2.match(/WiLink.*\_([\d].*)/).captures[0]
      end

      if test2.match(/Rev.*\s+([\d].*)/)
        @frmwr_ver = test2.match(/Rev.*\s+([\d].*)/).captures[0]
      end

      sleep 0.6
	  	end

    in_file.close
  end


  def create_html_page
    @intfc_spd =100
    i = @array_lines
    
    send_status("----------------------- wlan_module: Status message - Creating test results html page -------- #{@test_params.params_chan.protocol[0]} -------------------- "+ __LINE__.to_s)

    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Wireless Access Point Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    res_table = @results_html_file.add_table([["Access Point Model",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["IOS Software Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Bootloader Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Image File Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    @results_html_file.add_rows_to_table(res_table,[[["#{@ap_mdl}",{:bgcolor => "white"},{:size => "2.5"}],["#{@APIOSversion}",{:bgcolor => "white"},{:size => "2"}],["#{@APbootLdrVersion}",{:bgcolor => "white"},{:size => "2"}],["#{@APimgFileName}",{:bgcolor => "white"},{:size => "2"}]]])

    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Bluetooth-Wireless Client Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    res_table = @results_html_file.add_table([["EVM Model",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["WIFI Protocol",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["WIFI Security",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["WIFI Driver Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["WIFI Firmware Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Bluetooth Firmware Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

     if @test_params.params_chan.mode[0].downcase == "bluetooth"
       @test_params.params_chan.protocol[0] = "N/A"
       @test_params.params_chan.security[0] = "N/A"
     end 

    @results_html_file.add_rows_to_table(res_table,[[["#{@rtp_db.get_platform}",{:bgcolor => "white"},{:size => "2"}],["#{@test_params.params_chan.protocol[0].upcase}",{:bgcolor => "white"},{:size => "2"}],["#{@test_params.params_chan.security[0].upcase}",{:bgcolor => "white"},{:size => "2"}],["#{@drvr_ver}",{:bgcolor => "white"},{:size => "2"}],["#{@frmwr_ver}",{:bgcolor => "white"},{:size => "2"}],["#{@bt_frmwre_ver}",{:bgcolor => "white"},{:size => "2"}]]])

    if @test_params.params_chan.mode[0].downcase == "iperf"
      @results_html_file.add_paragraph("")
      res_table = @results_html_file.add_table([["Miscellaneous Iperf Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
      res_table = @results_html_file.add_table([["IP Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["IP Protocol",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Port Number",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
      #@results_html_file.add_rows_to_table(res_table,[[[@test_params.params_control.ip_vsn[0],{:bgcolor => "white"},{:size => "2"}],[@test_params.params_chan.protocol[0].upcase,{:bgcolor => "white"},{:size => "2"}],[@test_params.params_chan.port[0],{:bgcolor => "white"},{:size => "2"}]]])
     @results_html_file.add_rows_to_table(res_table,[[[@test_params.params_control.ip_vsn[0],{:bgcolor => "white"},{:size => "2"}],[@test_params.params_chan.protocol[0].upcase,{:bgcolor => "white"},{:size => "2"}],[@test_params.params_chan.port[0],{:bgcolor => "white"},{:size => "2"}]]])
    end

    @results_html_file.add_paragraph("")

    if @test_params.params_chan.mode[0].downcase == "iperf"
      res_table = @results_html_file.add_table([["Iperf Performance Numbers",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
      res_table = @results_html_file.add_table([["Default Iperf Window Size \(Kbs\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Bandwidth in Mbits/sec",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Total Transfer Size in MBytes",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Test Interval in sec",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Jitter (ms)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Percent Loss \(%\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Average WLAN CPU Utilization",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
    elsif @test_params.params_chan.mode[0].downcase == "ping"
      res_table = @results_html_file.add_table([["Ping Statistics",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
      res_table = @results_html_file.add_table([["Ping Window Size \(Kbs\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Total Packets Transmitted",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Total Packets Received",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Percent Loss \(%\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Total Ping Time \(ms\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["RTT Minimum \(ms\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["RTT Average \(ms\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["RTT Maximum \(ms\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["RTT mdev \(ms\)",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
    else
      res_table = @results_html_file.add_table([["Remote Bluetooth Device Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
      res_table = @results_html_file.add_table([["Remote Device MAC Address",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Remote Device Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                                      ["Remote Device Capabilities",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
    end

    if @test_params.params_chan.mode[0].downcase  == "iperf"
      if @test_params.params_chan.protocol[0] == "tcp"
        for j in 0..i-1 do
          @results_html_file.add_rows_to_table(res_table,[[[@test_data[j][0],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][6],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][7],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][1],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][8],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][11],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][12],{:bgcolor => "white"},{:size => "2"}]]])
        end
      else
        for j in 0..i-1 do
          @results_html_file.add_rows_to_table(res_table,[[[@test_data[j][0],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][6],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][7],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][1],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][8],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][11],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][12],{:bgcolor => "white"},{:size => "2"}]]])
        end
      end
    elsif @test_params.params_chan.mode[0].downcase  == "ping"
      for j in 0..i-1 do
        @results_html_file.add_rows_to_table(res_table,[[[@test_data[j][0],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][1],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][2],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][3],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][4],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][5],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][6],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][7],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][8],{:bgcolor => "white"},{:size => "2"}],[@test_data[j][9],{:bgcolor => "white"},{:size => "2"}]]])
      end
    else
      for j in 0..i-1 do
        @results_html_file.add_rows_to_table(res_table,[[[@bt_mac,{:bgcolor => "white"},{:size => "2"}],[@bt_device_name,{:bgcolor => "white"},{:size => "2"}],[@capabilities,{:bgcolor => "white"},{:size => "2"}]]])
      end
    end
  end


  def get_proc_list
		@equipment['dut1'].send_cmd("ps", @equipment['dut1'].prompt, 5)
    proc = ""
  end

