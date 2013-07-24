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

def get_param_value(equipment_designator, variable)
  value = @equipment[equipment_designator].params[variable]
  value = (value == nil ? "" : value)
  return value
end

def run
  # create ipsec utilities set
  ipsecVatf = IpsecUtilitiesVatf.new
  nashPAL = NashPalTestBenchVatf.new
  cascadeIf = CascadeSetupUtilities.new
  result = 0
  comments = ""
  additional_comments = ""
  run_nash_pal = true #false
  
  # Set TFTP paths to be used by the Nash PAL test. If path = "" that means use the default setting.
  server_tftp_path = File.join(@tester.downcase.strip, @test_params.target.downcase.strip, @test_params.platform.downcase.strip)
  evm_to_path = ""
  miw_arm_apps_path = "/home/gtscmcsdk-systest/tempdown/temp_MS5_arm_executeables"
  miw_dsp_apps_path = "/home/gtscmcsdk-systest/tempdown/temp_MS5_dsp_executeables"
  miw_relative_directory = ""
  
  #secure_dev_bootup()
  # Set default settings
  test_secs = 300
  is_pass_through = false
  is_secure_data = false
  is_nat_traversal = false
  is_bridge = false
  alpha_side_nat_public_ip = ""
  alpha_side_nat_gateway_ip = ""
  beta_side_nat_public_ip = ""
  beta_side_nat_gateway_ip = ""
  
  test_secs = get_variable_value(parse_cmd('test_secs').to_s).to_i if @test_params.params_chan.instance_variable_defined?(:@test_secs)
  is_pass_through = ( (get_variable_value(parse_cmd('ipsec_conn').to_s).downcase == "pass") ? true : false )  if @test_params.params_chan.instance_variable_defined?(:@ipsec_conn)
  is_secure_data = ( (get_variable_value(parse_cmd('ipsec_data').to_s).downcase == "secure") ? true : false )  if @test_params.params_chan.instance_variable_defined?(:@ipsec_data)
  is_nat_traversal = ( (get_variable_value(parse_cmd('ipsec_nat').to_s).downcase == "yes") ? true : false )  if @test_params.params_chan.instance_variable_defined?(:@ipsec_nat)
  is_cascade_mode = ( (get_variable_value(parse_cmd('if_mode').to_s).downcase == "bridge") ? true : false )  if @test_params.params_chan.instance_variable_defined?(:@if_mode)

  alpha_ip = @equipment['server1'].telnet_ip
  beta_ip = @equipment['dut1'].telnet_ip

  alpha_side_nat_public_ip = get_param_value('server1', "nat_gateway_public_ip")
  alpha_side_nat_gateway_ip = get_param_value('server1', "nat_gateway_private_ip")
  beta_side_nat_public_ip = get_param_value('dut1', "nat_gateway_public_ip")
  beta_side_nat_gateway_ip = get_param_value('dut1', "nat_gateway_private_ip")
  #dss_dir = @equipment['server1'].params["@dss_dir"]
  #is_secure_data = true
  #is_nat_traversal = true
  #test_secs = 43200
  #is_pass_through = false #true

  puts("Test Parameters:\r\n")
  puts("  test_secs             : #{test_secs}\r\n")
  puts("  is_cascade_mode       : #{is_cascade_mode}\r\n")
  puts("  is_pass_through       : #{is_pass_through}\r\n")
  puts("  is_secure_data        : #{is_secure_data}\r\n")
  puts("  is_nat_traversal      : #{is_nat_traversal}\r\n")
  puts("    (alpha_nat_pub_ip)  : #{alpha_side_nat_public_ip}\r\n")
  puts("    (alpha_nat_gway_ip) : #{alpha_side_nat_gateway_ip}\r\n")
  puts("    (beta_nat_pub_ip)   : #{beta_side_nat_public_ip}\r\n")
  puts("    (beta_nat_gway_ip)  : #{beta_side_nat_gateway_ip}\r\n")
  #puts("  dss_dir                 : #{dss_dir}\r\n")
  sleep(5)

  connection_type = (is_pass_through ? ipsecVatf.PASS_THROUGH : ipsecVatf.IPSEC_CONN)
  
  # Set result error bit to set if failures occur for IPSEC
  ipsecVatf.set_error_bit_to_set(0)
  # Set result error bit to set if failures occur for Nash PAL test
  nashPAL.set_error_bit_to_set(1)
  
  # Set IPSEC config for alpha side as Linux PC (swan version 5) and beta side as EVM (swan version 4). Use the default input ipsec.conf file.
  ipsecVatf.ipsec_typical_config(@equipment, ipsecVatf.FQDN_TUNNEL, "")
  # Dynamically create all keys and certificates and then start IPSEC on the Linux PC and the EVM. Start the ipsec tunnel on the EVM.
  #ipsecVatf.ipsec_typical_start(ipsecVatf.IPV4, ipsecVatf.IP_TUNNEL)
    
  if is_secure_data
    # Set beta side to use secure data for IPSEC
    ipsecVatf.set_secure_data(ipsecVatf.BETA_SIDE())
    ipsecVatf.set_ipsec_template_file("ipsec_conf_secure_data_template.txt")
  end
  
  if is_nat_traversal
    miw_dsp_apps_path = "/home/gtscmcsdk-systest/tempdown/temp_MS5_dsp_executeables_nat"
    # Set alpha and beta side to use nat_traversal
    ipsecVatf.set_nat_traversal(ipsecVatf.ALPHA_SIDE(), is_nat_traversal, alpha_side_nat_public_ip, alpha_side_nat_gateway_ip, beta_side_nat_public_ip)
    #ipsecVatf.set_nat_traversal(ipsecVatf.ALPHA_SIDE(), is_nat_traversal, alpha_side_nat_public_ip, "", beta_side_nat_public_ip)
    ipsecVatf.set_nat_traversal(ipsecVatf.BETA_SIDE(), is_nat_traversal, beta_side_nat_public_ip, beta_side_nat_gateway_ip, alpha_side_nat_public_ip)
    ipsecVatf.set_ipsec_template_file("ipsec_conf_nat_traversal_template.txt")
  end
  
  if is_nat_traversal and is_secure_data
    # If both nat and secure data then make sure to use the nat traversal template which has the modifications needed for secure data as well.
    ipsecVatf.set_ipsec_template_file("ipsec_conf_nat_traversal_template.txt")
  end
  
  # Setup bridge interfaces
  if is_cascade_mode
    cascadeIf.set_common(@equipment, "", "", "")
    cascadeIf.set_bridge_info(beta_ip, "", alpha_ip)
    cascadeIf.set_tftp_info("", "", "", "", "", miw_arm_apps_path)
    cascadeIf.copy_dtb_files_to_tftp_server_tftp_directory()
    cascadeIf.transfer_dtb_files_to_evm(alpha_ip)
    cascadeIf.copy_multiIf_dtb_file_to_evm_boot_directory_and_reboot_evm_to_use_this_file()
    #cascadeIf.copy_singleIf_dtb_file_to_evm_boot_directory_and_reboot_evm_to_use_this_file()
    cascadeIf.set_bridge_interfaces()
    result |= cascadeIf.result
  end
  
  if (result == 0) and !run_nash_pal
    ipsecVatf.ipsec_typical_start(ipsecVatf.IPV4, connection_type)
    #result |= test_ipsec_test_ipconfs(ipsecVatf, connection_type)
    #quick_test_ipsec_test_ipconfs(ipsecVatf, connection_type)
    result |= ipsecVatf.result
  end
  
  #result |= test_ipsec_test_ipconfs(ipsecVatf, connection_type)
  #quick_test_ipsec_test_ipconfs(ipsecVatf, connection_type)
  # Get any IPSEC error results
  
  # Start the Nash PAL test if IPSEC has no errors
  if (result == 0) and run_nash_pal
    # Set paths for ARM and DSP file paths for the Nash PAL test
    nashPAL.set_miw_tftp_paths(server_tftp_path, evm_to_path, miw_arm_apps_path, miw_dsp_apps_path, miw_relative_directory)
    
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
  comments += cascadeIf.result_text
  comments += ".\r\n"
  puts("\r\n\r\n#{comments}\r\n\r\n")
  # Fix dash display for webpage. The dashes are half the size when displayed on the web page so double them to keep the display line size correct.
  comments = comments.gsub("----", "--------")
  set_result(test_done_result, comments)
end

def clean
  #@equipment['server1'].send_sudo_cmd("ipsec stop", /#{@equipment['server1'].prompt}/, 20)
end
