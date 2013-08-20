
require File.dirname(__FILE__)+'/ipsec_connect_module'
require File.dirname(__FILE__)+'/utilities'

# !!!! Load this file each time to make sure that the aliasing below happens only to the setup method within this file. !!!!
load File.dirname(__FILE__)+'/../../LSP/A-ETH/eth_iperf.rb'
# Alias the setup method in LSP/A-ETH/eth_iperf so that it can be run even after overriding it with our setup method
alias aliased_setup_method_from_eth_iperf setup

# IPSEC connection implementation
include IpsecConnectionScript

def setup
  # Stop ipsec on the Linux PC side to avoid having the EVM unable to load its files
  self.as(IpsecConnectionScript).stop_ipsec(@equipment)

  # Run setup from ../../LSP/A-ETH/eth_iperf
  aliased_setup_method_from_eth_iperf 

  # Create keys, certificates and establish the IPSEC connection using Strongswan between EVM and Linux PC
  self.as(IpsecConnectionScript).establish_ipsec_connection(@equipment, @test_params)

  # If the IPSEC connection was successfully established then load the opt/ltp files if needed
  if IpsecConnectionScript.result == 0
    # TFTP the opt/ltp files if needed   (THIS IS A WORKAROUND UNTIL THE TEST FILESYSTEM HAS STRONGSWAN IPSEC INCLUDED)
    linux_utils = LinuxHelperUtilities.new
    linux_utils.set_vatf_equipment(@equipment)
    beta_side = linux_utils.BETA_SIDE()
    if !linux_utils.files_exist?(beta_side, "/opt/ltp/bin", "ltp-pan")
      linux_utils.tftp_file("ltp.tar.gz", "", "/opt", @equipment['server1'].telnet_ip, beta_side)
      linux_utils.untar_file("ltp.tar.gz", "/opt", beta_side)
    end
  end
end

def run
  if IpsecConnectionScript.result == 0
    # IPSEC connection was successfully established so continue on with testing
    super
  else
    # IPSEC connection was NOT successfully established so fail the test and set the test comment using the IpsecConnectScript's comment text
    set_result(FrameworkConstants::Result[:fail], "Test Failed.\r\n#{IpsecConnectionScript.comment_text}")
  end

  # Stop ipsec on both sides to be friendly to other tests
  self.as(IpsecConnectionScript).stop_offload_indices()
  self.as(IpsecConnectionScript).stop_ipsec(@equipment)
  self.as(IpsecConnectionScript).stop_ipsec_evm(@equipment)
end

def clean
  super
end
