# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/test_protocols'

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
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]
  cmd = @test_params.params_chan.cmd[0]
  ping_count = @test_params.params_chan.ping_count[0].to_i
  # ip addresses for dut1 and dut2
  dut1_if = @equipment['dut1'].params['dut1_if']
  dut2_if = @equipment['dut2'].params['dut2_if']
  test_comment = ""
  begin
    @power_handler.switch_off(@equipment['dut2'].power_port)
    sleep(5)
    @power_handler.switch_on(@equipment['dut2'].power_port)
    sleep(5)
    if connect_to_equipment('dut2')
      @equipment['dut2'].send_cmd("I#{dut2_if}", "", 5)
      sleep(5)
    else
      raise "Failed to connect serial at BIOS side."
    end
    enable_feature(@equipment['dut1'], feature, cmd, dut1_if, false)
    ping_status(@equipment['dut1'], dut2_if, ping_count)
    @equipment['dut2'].send_cmd("SCN", "", 5, true, false)
    @equipment['dut1'].send_cmd("cat /sys/kernel/debug/#{feature}/node_table", @equipment['dut1'].prompt, 10)
    test_comment += "Feature #{feature} verified with LINUX and BIOS."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
