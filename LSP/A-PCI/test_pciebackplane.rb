# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/test_pcie'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  # dut2->RC board  
  add_equipment('dut2', @equipment['dut1'].params['dut2']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['dut2'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)

  # dut3->RC board  
  add_equipment('dut3', @equipment['dut1'].params['dut3']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['dut3'], log_path)
  end
  @equipment['dut3'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut3'].power_port)

  # before configuring EP, power down RC
  @equipment['dut2'].shutdown({'power_handler' => @power_handler})
  @equipment['dut3'].shutdown({'power_handler' => @power_handler})

  # boot up dut1 --- EP board
  setup_boards('dut1')
end

def run
  #self.as(LspTestScript).run
  result = 0
  result_msg = ''

  params = {}
  params['num_pfs'] = @test_params.params_chan.instance_variable_defined?(:@num_pfs) ? @test_params.params_chan.num_pfs[0] : '1'
  params['num_vfs'] = @test_params.params_chan.instance_variable_defined?(:@num_vfs) ? @test_params.params_chan.num_vfs[0] : '0'
  params['msi_int'] = @test_params.params_chan.instance_variable_defined?(:@msi_interrupts) ? @test_params.params_chan.msi_interrupts[0] : '16'
  params['msix_int'] = @test_params.params_chan.instance_variable_defined?(:@msix_interrupts) ? @test_params.params_chan.msix_interrupts[0] : '16'
  params['linux_version'] = @equipment['dut1'].get_linux_version
  # option: 'legacy, msi, msix'
  params['int_mode'] = @test_params.params_chan.instance_variable_defined?(:@int_mode) ? @test_params.params_chan.int_mode[0] : 'msi'

  prepare_ep(params)
  bringup_rc('dut2', '2', params)
  # Since dut2 is the same as dut3, use dut2 images
  bringup_rc('dut3', '2', params)

  # Run pcie backplane tests
  eth_nodes = {}
  rcs = ['dut2', 'dut3']
  rcs.each {|rc|

    @equipment["#{rc}"].send_cmd("lspci", @equipment["#{rc}"].prompt, 10)
    raise "Endpoint is not showing in RC using lspci" if !@equipment["#{rc}"].response.match(/01:00\.0/i)

    @equipment["#{rc}"].send_cmd("lspci -vv", @equipment["#{rc}"].prompt, 10)
    res = check_pcie_speed(@equipment["#{rc}"].response, @equipment["#{rc}"].name)
    if res != 0
      report_msg "Test Fail Reason: LnkSta is not at expected speed", "dut2"
      result += res
    end

    @equipment["#{rc}"].send_cmd("ifconfig -a", @equipment["#{rc}"].prompt, 10)
    @equipment["#{rc}"].send_cmd("lspci |grep 'RAM memory' ", @equipment["#{rc}"].prompt, 5)
    res = @equipment["#{rc}"].response
    @equipment["#{rc}"].send_cmd("echo $?",/^0[\n\r]*/m, 2)
    raise "Did not see 'RAM memory' in lspci" if @equipment["#{rc}"].timeout?
    # res: 0001:01:00.0 RAM memory: Texas Instruments Device b00d
    ep_node = res.match(/^([\d:\.]+)\s+/i).captures[0]
    ep_node_escape = ep_node.gsub(/:/, '\:')
    @equipment["#{rc}"].send_cmd("echo #{ep_node} > /sys/bus/pci/devices/#{ep_node_escape}/driver/unbind", @equipment["#{rc}"].prompt, 10)
    @equipment["#{rc}"].send_cmd("echo #{ep_node} > /sys/bus/pci/drivers/ntb_hw_epf/bind", @equipment["#{rc}"].prompt, 10)
    raise "Failed to bind ntb_hw_epf." if @equipment["#{rc}"].response.match(/failed\s+with\s+error/i)
 
    @equipment["#{rc}"].send_cmd("depmod -a", @equipment["#{rc}"].prompt, 10)
    @equipment["#{rc}"].send_cmd("modprobe ntb_transport", @equipment["#{rc}"].prompt, 10)
    @equipment["#{rc}"].send_cmd("modprobe ntb_netdev", @equipment["#{rc}"].prompt, 10)
    raise "Failed to modprobe ntd." if @equipment["#{rc}"].response.match(/modprobe\s*:\s*error/i)
    eth_node = @equipment["#{rc}"].response.match(/(eth\d+)\s+created/i).captures[0]
    eth_nodes[rc] = eth_node
    
    @equipment["#{rc}"].send_cmd("ifconfig -a", @equipment["#{rc}"].prompt, 10)
    test_ip = @equipment["#{rc}"].params['test_ip']
    #@equipment["#{rc}"].send_cmd("ifconfig #{eth_node} #{test_ip} up", @equipment["#{rc}"].prompt, 10)
    @equipment["#{rc}"].send_cmd("ifconfig #{eth_node} #{test_ip} up", /link\s+becomes\s+ready/i, 10)
    sleep 1
    @equipment["#{rc}"].send_cmd("ifconfig -a", @equipment["#{rc}"].prompt, 10)

  } 
  
  # ping between dut2 and dut3
  ping_cnt = @test_params.params_chan.instance_variable_defined?(:@ping_cnt) ? @test_params.params_chan.ping_cnt[0] : '10'
  ping_ip(@equipment["dut2"], eth_nodes['dut2'], @equipment['dut3'].params['test_ip'], ping_cnt)
  ping_ip(@equipment["dut3"], eth_nodes['dut3'], @equipment['dut2'].params['test_ip'], ping_cnt)

  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end

end

def clean
  #super
  @power_handler.switch_on(@equipment['dut2'].power_port)
  @power_handler.switch_on(@equipment['dut3'].power_port)
  self.as(LspTestScript).clean
  clean_boards('dut2')
  clean_boards('dut3')
end

def ping_ip(dut, eth_iface, ipaddr, ping_cnt)
  timeout = ping_cnt.to_i + 30
  dut.send_cmd("ping -I #{eth_iface} -c #{ping_cnt} #{ipaddr}", dut.prompt, timeout)
  if dut.timeout? or (dut.response =~ Regexp.new("(\s100%\spacket\sloss)"))
    dut.send_cmd("\cC echo 'Kill ping process...'", dut.prompt, 20)
    raise "Failed to ping (#{ipaddr}) on #{eth_iface}"
  end
end




