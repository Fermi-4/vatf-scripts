# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../../LSP/A-PCI/test_pcie'
require File.dirname(__FILE__)+'/../../armtest/run_arm_test'

include LspTestScript
def setup
  # dut2 board setup
  add_equipment('dut2', @equipment['dut1'].params['dut2']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['dut2'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)
  # boot 1st EVM
  setup_boards('dut1')
  # boot 2nd EVM
  # check if both dut's not same
  if @equipment['dut1'].name != @equipment['dut2'].name
    params2 = {'platform'=>@equipment['dut2'].name}
    boot_params2 = translate_params2(params2)
    setup_boards('dut2', boot_params2)
  else
    setup_boards('dut2')
  end
end

def run
  # get dut params
  cclink_git = @test_params.params_chan.user_git_repo[0]
  interface = @test_params.params_chan.interface[0].to_s
  constraint = @test_params.params_chan.constraint[0]
  timeout = @test_params.params_chan.timeout[0].to_i
  adapter_num = @test_params.params_chan.adapter_num[0].to_i
  # ip addresses for dut1 and dut2
  dut1_if02, dut2_if02 = "192.168.1.100", "192.168.1.200"
  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  git_dir = cclink_git.match(/\/([\w]+).git/)[1]
  begin
    clone_user_git_repo(cclink_git)
    set_date_time(@equipment['dut1'])
    set_date_time(@equipment['dut2'])
    setup_cclink(@equipment['dut1'], @equipment['dut2'], dut1_if02, dut2_if02, git_dir, tmp_path, interface)
    run_cclink_master_slave(@equipment['dut1'], @equipment['dut2'], constraint, adapter_num, timeout)
    set_result(FrameworkConstants::Result[:pass], "CC-Link IE Field Basic Master Slave test passed for interface: #{interface}.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to run cclink master slave application
def run_cclink_master_slave(master, slave, constraint, adapter_num, timeout)
  master.send_cmd("./Master_sample /usr/share/cclink/MasterParameter.csv", "Press 'enter' Key after select.*:", 10)
  master.send_cmd("#{adapter_num}", "Exit the application", 10)
  sleep(5)
  slave.send_cmd("./Slave_sample /usr/share/cclink/SlaveParameter.csv", "Press 'enter' Key after select.*:", 10)
  slave.send_cmd("#{adapter_num}", "#{constraint}#{constraint}", timeout)
  if @equipment['dut1'].timeout? or !(slave.response =~ Regexp.new("(#{constraint})"))
    raise "Failed to match contraint '#{constraint}' or Test timed out after #{timeout} seconds."
  end
  slave.send_cmd("\cC echo 'Closing Application.'", "Closing Application", 10)
  master.send_cmd("5", "Exit the application", 10, true, false)
  master.send_cmd("6", "Exit the application", 10, true, false)
  master.send_cmd("7", "Exit the application", 10, true, false)
  master.send_cmd("\cC echo 'Closing Application.'", "Closing Application", 10)
end

# function to setup cclink environment
def setup_cclink(master, slave, dut1_if02, dut2_if02, git_dir, tmp_path, interface)
  slave.send_cmd("tftp -g -r #{tmp_path}/#{git_dir}.tar.gz #{@equipment['server1'].telnet_ip}",\
                 slave.prompt, 60)
  if interface != 'eth0'
    master.send_cmd("ifconfig #{interface} #{dut1_if02}; ifconfig", master.prompt, 10)
    slave.send_cmd("ifconfig #{interface} #{dut2_if02}; ifconfig", slave.prompt, 10)
  end
  slave.send_cmd("ifconfig #{interface} | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'", slave.prompt, 10)
  slave_ip = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/.match(slave.response)
  master.send_cmd("tar xzf #{git_dir}.tar.gz", master.prompt, 30)
  master.send_cmd("cd cclink/CCIEF-BASIC_Master/build/linux", master.prompt, 10)
  master.send_cmd("make", master.prompt, 10)
  master.send_cmd("sed -i 's/2,[0-9.]*,Slave1 IP address/2,#{slave_ip},Slave1 IP address/' /usr/share/cclink/\
MasterParameter.csv", master.prompt, 10)
  slave.send_cmd("tar xzf #{git_dir}.tar.gz", slave.prompt, 30)
  slave.send_cmd("cd cclink/CCIEF-BASIC_Slave/build/linux", slave.prompt, 10)
  slave.send_cmd("make", slave.prompt, 10)
end

# function to set dut date and time
def set_date_time(dut)
  dut.send_cmd("date -s '#{Time.now.getutc.strftime("%Y-%m-%d %H:%M:%S")}'", dut.prompt, 10)
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
