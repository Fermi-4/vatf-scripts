# This script is intended to be generic enough to run tests on any ethernet
# interface. Its main function is to set the host network interface corresponding to the interface on the dut.

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../network_utils'

include LspTestScript

def setup
  # dut2->master board  
  add_equipment('dut2', @equipment['dut1'].params['master']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['master'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)

  # boot up dut1 --- slave 
  setup_boards('dut1')

  # boot up dut2 --- master
  boot_params2 = translate_params2({'platform'=>@equipment['dut2'].name})
  setup_boards('dut2', boot_params2)

  # check if testptp and ptp4l is in the filesystem
  app_installed?(@equipment['dut1'], "testptp")
  app_installed?(@equipment['dut1'], "ptp4l")
  app_installed?(@equipment['dut2'], "testptp")
  app_installed?(@equipment['dut2'], "ptp4l")
end

def run
  result = 0
  msg = ''
  @equipment['dut1'].send_cmd("ifconfig -a", @equipment['dut1'].prompt, 10, false)
  slave_iface = @test_params.params_control.instance_variable_defined?(:@slave_iface) ? @test_params.params_control.slave_iface[0].to_s : 'eth1'
  @equipment['dut1'].send_cmd("ethtool -i #{slave_iface}", @equipment['dut1'].prompt, 10, false)

  @equipment['dut2'].send_cmd("ifconfig -a", @equipment['dut2'].prompt, 10, false)
  master_iface = @test_params.params_control.instance_variable_defined?(:@master_iface) ? @test_params.params_control.master_iface[0].to_s : 'eth1'
  @equipment['dut2'].send_cmd("ethtool -i #{master_iface}", @equipment['dut2'].prompt, 10, false)

  slave_ip = @equipment['dut1'].params['test_ip']
  master_ip = @equipment['dut2'].params['test_ip']

  # bring up iface
  bringup_iface(@equipment['dut1'], slave_iface, slave_ip)
  bringup_iface(@equipment['dut2'], master_iface, master_ip)

  # ping each other
  ping_ip(@equipment['dut1'], master_ip)
  ping_ip(@equipment['dut2'], slave_ip)

  # options
  #Delay Mechanism
  #-A        Auto, starting with E2E
  #-E        E2E, delay request-response (default)
  #-P        P2P, peer delay mechanism
  #Network Transport
  #-2        IEEE 802.3
  #-4        UDP IPV4 (default)
  #-6        UDP IPV6
  #Time Stamping
  #-H        HARDWARE (default)
  #-S        SOFTWARE
  #-L        LEGACY HW
  delay_option = @test_params.params_control.instance_variable_defined?(:@delay_option) ? @test_params.params_control.delay_option[0].to_s : '-E'
  network_option = @test_params.params_control.instance_variable_defined?(:@network_option) ? @test_params.params_control.network_option[0].to_s : '-2'
  timestamp_option = @test_params.params_control.instance_variable_defined?(:@timestamp_option) ? @test_params.params_control.timestamp_option[0].to_s : '-H'

  # gen config file for both
  cfg_file = '/test/ptp.cfg'
  configs = {}
  gen_config_file(@equipment['dut1'], configs, cfg_file)
  gen_config_file(@equipment['dut2'], configs, cfg_file)

  # set different time on master(dut2) and slave(dut1)
  master_time = 100000
  testptp_settime(@equipment['dut2'], master_time)
  slave_time = 900000
  testptp_settime(@equipment['dut1'], slave_time)

  # master side
  @equipment['dut2'].send_cmd("ptp4l #{delay_option} #{network_option} #{timestamp_option} -i #{master_iface} -l 6 -m -q -f #{cfg_file}", "assuming the grand master role", 30, false)
  raise "Could not start master!" if @equipment['dut2'].timeout?

  sleep 1
  # slave side
  timeout = 30 # run ptp4l 5 mins
  @equipment['dut1'].send_cmd("ptp4l #{delay_option} #{network_option} #{timestamp_option} -i #{slave_iface} -l 6 -m -q -f #{cfg_file} -s & (PID=$!;echo $PID;sleep #{timeout+20}; kill $PID; ps -ef |grep ptp4l)", @equipment['dut1'].prompt, (timeout+30), false)
  slave_response = @equipment['dut1'].response
  @equipment['dut2'].send_cmd("\cC echo 'Closing Application.'", @equipment['dut2'].prompt, 20)

  # check the messages
  if ! @equipment['dut1'].response.match(/port\s+1:\s+UNCALIBRATED\s+to\s+SLAVE\s+on\s+MASTER_CLOCK_SELECTED/i)
    result += 1
    msg += "Expected message is not received and failed to sync to Master;"
  end

  # check if the offset becomes stable and smaller
  offsets = slave_response.scan(/master\s+offset\s+([-\d]+)\s+s/)
  puts offsets.length
    
  max_offset = 30 # maximum offset we allowed
  sample_cnt = 10
  fail_cnt = 0
  offsets.last(sample_cnt).each do |offset|
    puts offset
    if offset.to_s.to_i.abs > max_offset
      fail_cnt += 1
      result += 1
    end
  end

  msg += "#{fail_cnt} offsets are not within the range; it did not converge which means it did not sync to master. " if fail_cnt != 0

  # Check if ptp clock time is synced
  master_time_now = testptp_gettime(@equipment['dut2']) 
  slave_time_now = testptp_gettime(@equipment['dut1']) 
  time_diff = master_time_now.to_f - slave_time_now.to_f
  if time_diff > 1
    msg += "ptp clock on slave is not synced with master ptp clock with testptp;"
    result += 1
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed: #{msg}")
  end
 
end

# bring up iface
def bringup_iface(dut, iface, ipaddr)
  dut.send_cmd("ifconfig #{iface}", dut.prompt, 10, false)
  raise "Interface #{iface} not found" if dut.response.match(/not\s+found/i)
  dut.send_cmd("ifconfig #{iface} up", dut.prompt, 10, false)
  dut.send_cmd("ip a show #{iface}", dut.prompt, 10, false)
  raise "#{iface} is not up" if ! dut.response.match(/,UP/)
  dut.send_cmd("ifconfig #{iface} #{ipaddr}", dut.prompt, 10, false)
end

def ping_ip(dut, ipaddr)
  dut.send_cmd("ping -c 10 #{ipaddr}", dut.prompt, 20, false)
  if dut.timeout?
    dut.send_cmd("\cC echo 'Kill ping process...'", dut.prompt, 20)
    raise "Failed to ping (#{ipaddr})"
  end
end

# testptp get ptp clock time
def testptp_gettime(dut)
  dut.send_cmd("testptp -g", dut.prompt, 10)
  if !dut.response.match(/clock\s+time:/i)
    raise "testptp failed to get ptp clock time"
  end
  time_now = dut.response.match(/clock\s+time:\s+([\.\d]+)\s+/i).captures[0]
  return time_now
end

# testptp set ptp clock time 
def testptp_settime(dut, val)
  dut.send_cmd("testptp -g && testptp -T #{val} && testptp -g", dut.prompt, 10)
  if !dut.response.match(/set\s+time\s+ok/i)
    raise "testptp failed to set ptp clock time by val"
  end
end

# testptp shift ptp clock time 
def testptp_shifttime(dut, val)
  dut.send_cmd("testptp -t #{val}", dut.prompt, 10)
  if !dut.response.match(/time\s+shift\s+ok/i)
    raise "testptp failed to shift ptp clock time by val"
  end
end

# testptp adjust ptp clock frequercy 
def testptp_adjustfreq(dut, val)
  dut.send_cmd("testptp -f #{val}", dut.prompt, 10)
  if !dut.response.match(/frequency\s+adjustment\s+ok/i)
    raise "testptp failed to adjust ptp clock frequency by val"
  end
end

# function to generate config file
def gen_config_file(dut, configs={}, cfg_file)
  dut.send_cmd("echo \"[global]\"$'\\n'\"tx_timestamp_timeout 400\" > #{cfg_file}", dut.prompt, 10)
  dut.send_cmd("cat #{cfg_file}", dut.prompt, 10)
end

def app_installed?(dut, app_name)
  dut.send_cmd("which #{app_name}; echo $?", /^0[\0\n\r]+/im, 5)
  raise "#{app_name} is not installed!" if dut.timeout?
end

