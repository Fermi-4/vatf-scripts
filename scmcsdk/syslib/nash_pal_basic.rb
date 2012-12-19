# -*- coding: ISO-8859-1 -*-
require 'fileutils'

require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/utilities.rb'

# Default Server-Side Test script implementation for LSP releases
  
include LspTestScript

def setup
  # connect_to_equipment('server1')
  # Stop IPSEC on the Linux PC before doing anything
  @equipment['server1'].send_sudo_cmd("ipsec stop", /#{@equipment['server1'].prompt}/, 20)
  #super
  self.as(LspTestScript).setup
  @equipment['dut1'].send_cmd("root", /#{@equipment['dut1'].prompt}/, 20)
end

def test_ipsec_test_ipconfs(ipsecVatf, is_pass_through)
  result = 0
  is_clear_previous_result = true
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_cp_1.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.IP_TUNNEL, "ipsec_test_confs/ipsec_ike_1.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_ike_2.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_ike_3.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_ike_4.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_ike_5.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_mp_1.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_up_1.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_up_2.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_up_3.conf", is_clear_previous_result, is_pass_through)
  result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_up_4.conf", is_clear_previous_result, is_pass_through)
  return result
end

def quick_test_ipsec_test_ipconfs(ipsecVatf)
  ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "ipsec_test_confs/ipsec_cp_1.conf")
  ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.IP_TUNNEL, "ipsec_test_confs/ipsec_ike_1.conf")
end

def tftp_arm_executables(path)
end

def get_variable_value(string)
  puts(" string: #{string}\r\n")
  value = ""
  items = string.split("=")
  puts(" items[0]: #{items[0]}\r\n")
  if (items.length > 1)
    value = items[1].gsub(">]", "")
    value = value.gsub('\"', "")
    value = value.tr("\"", "")
  end
  return value
end

def run
  # create ipsec utilities set
  ipsecVatf = IpsecUtilitiesVatf.new
  nashPAL = NashPalTestBenchVatf.new
  result = 0
  comments = ""
  additional_comments = ""
  run_nash_pal = true #false
  
  #secure_dev_bootup()
  
  test_secs = get_variable_value(parse_cmd('test_secs').to_s).to_i
  is_pass_through = ( (get_variable_value(parse_cmd('ipsec_conn').to_s).downcase == "pass") ? true : false )
  puts("Test Parameters:\r\n")
  puts("  test_secs      : #{test_secs}\r\n")
  puts("  is_pass_through: #{is_pass_through}\r\n")
  #exit

  #is_pass_through = false #true
  connection_type = (is_pass_through ? ipsecVatf.PASS_THROUGH : ipsecVatf.IPSEC_CONN)
  
  # Set result error bit to set if failures occur for IPSEC
  ipsecVatf.set_error_bit_to_set(0)
  # Set result error bit to set if failures occur for Nash PAL test
  nashPAL.set_error_bit_to_set(1)
  
  # Set IPSEC config for alpha side as Linux PC (swan version 5) and beta side as EVM (swan version 4). Use the default input ipsec.conf file.
  ipsecVatf.ipsec_typical_config(@equipment, ipsecVatf.FQDN_TUNNEL, "")
  # Dynamically create all keys and certificates and then start IPSEC on the Linux PC and the EVM. Start the ipsec tunnel on the EVM.
  #ipsecVatf.ipsec_typical_start(ipsecVatf.IPV4, ipsecVatf.IP_TUNNEL)
  
  if !run_nash_pal
    ipsecVatf.ipsec_typical_start(ipsecVatf.IPV4, connection_type)
    result |= test_ipsec_test_ipconfs(ipsecVatf, connection_type)
    #quick_test_ipsec_test_ipconfs(ipsecVatf, connection_type)
    result |= ipsecVatf.result
  end
  
  #result |= test_ipsec_test_ipconfs(ipsecVatf, connection_type)
  #quick_test_ipsec_test_ipconfs(ipsecVatf, connection_type)
  # Get any IPSEC error results
  
  # Start the Nash PAL test if IPSEC has no errors
  if (result == 0) and run_nash_pal
    # Run Nash PAL bench test for the specified number of seconds
    nashPAL.run_nash_pal_test_bench(@equipment, test_secs, is_pass_through, ipsecVatf)
    
    puts(" Result code is: #{result}, Nash PAL result is: #{nashPAL.result}\r\n")
  
    # Get any Nash PAL error results
    result |= nashPAL.result
  end
  
  # Set overall test result based on result variable
  if result == 0
    puts("\r\nAll tests have passed!\r\n")
    test_done_result = FrameworkConstants::Result[:pass]
    comments += "Test passed."
  else
    test_done_result = FrameworkConstants::Result[:fail]
    comments += "Test failed.\r\n"
    comments += ".\r\n"
    comments += "#{error_code_bit_breakdown(result)}"
    comments += "."
  end
  comments += "\r\n"
  # Add result text from each part of the test
  comments += ipsecVatf.result_text
  comments += ".\r\n"
  comments += nashPAL.result_text
  comments += ".\r\n"
  puts("\r\n\r\n#{comments}\r\n\r\n")
  # Fix dash display for webpage. The dashes are half the size when displayed on the web page so double them to keep the display line size correct.
  comments = comments.gsub("----", "--------")
  set_result(test_done_result, comments)
end

def clean
  #@equipment['server1'].send_sudo_cmd("ipsec stop", /#{@equipment['server1'].prompt}/, 20)
end
