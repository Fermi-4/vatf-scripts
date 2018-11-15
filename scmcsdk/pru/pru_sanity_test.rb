require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../lib/evms_data'

include LspTestScript
include EvmData
def setup
  self.as(LspTestScript).setup
end

def run
  begin
    ports = get_default_eth_ports(@equipment['dut1'].name)
    default_eth_port_check(ports)
    set_result(FrameworkConstants::Result[:pass], "Test Passed. Verified ports: #{ports.keys}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

def clean
  self.as(LspTestScript).clean
end

#function to run verify pru ports
def default_eth_port_check(ports)
  for port in ports.keys do
     @equipment['dut1'].send_cmd("ethtool -i #{port}|grep driver", @equipment['dut1'].prompt, 10)
     ethtool_response = @equipment['dut1'].response
     if !(ethtool_response =~ /driver:\s#{ports[port]}/)
      raise "Failed to initialize #{port}."
    end
  end
end
