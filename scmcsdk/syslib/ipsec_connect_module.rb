
require File.dirname(__FILE__)+'/utilities.rb'

# IPSEC connection script
module IpsecConnectionScript
  @equipment = ""
  @ipsecVatf = IpsecUtilitiesVatf.new
  @ipsec_connection_script_comment_text = ""
  @ipsec_connection_script_result = 0
  @ipsec_connection_script_protocol = "(not_set)"
  @ipsec_connection_script_esp_encryption = "(not_set)"
  @ipsec_connection_script_esp_integrity = "(not_set)"
  @ipsec_connection_script_is_pass_through = "(not_set)"
  @ipsec_connection_script_is_secure_data = "(not_set)"
  @ipsec_connection_script_is_nat_traversal = "(not_set)"
  @ipsec_connection_script_ipsec_template = "(not_set)"
  @is_ipsecVatf_started = false

  def equipment()
    @equipment
  end
  def equipment_set(equipment)
    @equipment = equipment
  end

  def ipsecVatf
    @ipsecVatf
  end
  def ipsecVatf_set(ipsecVatf)
    @ipsecVatf = ipsecVatf
  end

  def is_ipsecVatf_started
    @is_ipsecVatf_started
  end
  def is_ipsecVatf_started_set(is_ipsecVatf_started)
    @is_ipsecVatf_started = is_ipsecVatf_started
  end

  def ipsec_template
    @ipsec_connection_script_ipsec_template
  end
  def ipsec_template_set(string)
    @ipsec_connection_script_ipsec_template = string
  end

  def comment_text
    @ipsec_connection_script_comment_text
  end
  def comment_text_set(string)
    @ipsec_connection_script_comment_text = string
  end
  def comment_text_add(string)
    @ipsec_connection_script_comment_text += string
  end

  def result
    @ipsec_connection_script_result
  end
  def result_set(value)
    @ipsec_connection_script_result = value
  end

  def is_pass_through
    @ipsec_connection_script_is_pass_through
  end
  def is_pass_through_set(value)
    @ipsec_connection_script_is_pass_through = value
  end

  def is_secure_data
    @ipsec_connection_script_is_secure_data
  end
  def is_secure_data_set(value)
    @ipsec_connection_script_is_secure_data = value
  end

  def is_nat_traversal
    @ipsec_connection_script_is_nat_traversal
  end
  def is_nat_traversal_set(value)
    @ipsec_connection_script_is_nat_traversal = value
  end

  def protocol
    @ipsec_connection_script_protocol
  end
  def protocol_set(string)
    @ipsec_connection_script_protocol = string
  end

  def esp_encryption
    @ipsec_connection_script_esp_encryption
  end
  def esp_encryption_set(string)
    @ipsec_connection_script_esp_encryption = string
  end

  def esp_integrity
    @ipsec_connection_script_esp_integrity
  end
  def esp_integrity_set(string)
    @ipsec_connection_script_esp_integrity = string
  end

  def set_all_vars(comment_text, result, protocol, esp_encryption, esp_integrity, is_pass_through, is_secure_data, is_nat_traversal, ipsec_template)
    @ipsec_connection_script_comment_text = comment_text if comment_text != ""
    @ipsec_connection_script_result = result  if result != ""
    @ipsec_connection_script_protocol = protocol  if protocol != ""
    @ipsec_connection_script_esp_encryption = esp_encryption  if esp_encryption != ""
    @ipsec_connection_script_esp_integrity = esp_integrity  if esp_integrity  != ""
    @ipsec_connection_script_is_pass_through = is_pass_through  if is_pass_through  != ""
    @ipsec_connection_script_is_secure_data = is_secure_data  if is_secure_data  != ""
    @ipsec_connection_script_is_nat_traversal = is_nat_traversal  if is_nat_traversal  != ""
    @ipsec_connection_script_ipsec_template = ipsec_template  if ipsec_template  != ""
  end

  def clear_results()
    IpsecConnectionScript.result_set(0)
    IpsecConnectionScript.comment_text_set("")
  end

  def stop_ipsec(equipment)
    equipment['server1'].send_sudo_cmd("ipsec stop", /#{equipment['server1'].prompt}/, 20)
  end
  def stop_ipsec_evm(equipment)
    equipment['dut1'].send_cmd("ipsec stop", /#{equipment['dut1'].prompt}/, 20)
  end
  def stop_offload_indices()
    IpsecConnectionScript.ipsecVatf.inflow_stop_offload(IpsecConnectionScript.ipsecVatf.BETA_SIDE())
  end

  def display_ipsec_test_params(ipsec_conf_template, protocol, encryption, integrity, is_pass_through, is_secure_data, is_nat_traversal, alpha_side_nat_public_ip, alpha_side_nat_gateway_ip, beta_side_nat_public_ip, beta_side_nat_gateway_ip)
    params_display = ""
    params_display += "IPSEC Test Parameters:\r\n"
    params_display += "  ipsec_conf_template   : \"#{ipsec_conf_template}\"\r\n"
    params_display += "  protocol_enc_auth     : #{protocol}_#{encryption}_#{integrity}\r\n"
    params_display += "  is_pass_through       : #{is_pass_through}\r\n"
    params_display += "  is_secure_data        : #{is_secure_data}\r\n"
    params_display += "  is_nat_traversal      : #{is_nat_traversal}\r\n"
    if is_nat_traversal
      params_display += "    (alpha_nat_pub_ip)  : #{(!is_nat_traversal ? "N/A" : alpha_side_nat_public_ip)}\r\n"
      params_display += "    (alpha_nat_gway_ip) : #{(!is_nat_traversal ? "N/A" : alpha_side_nat_gateway_ip)}\r\n"
      params_display += "    (beta_nat_pub_ip)   : #{(!is_nat_traversal ? "N/A" : beta_side_nat_public_ip)}\r\n"
      params_display += "    (beta_nat_gway_ip)  : #{(!is_nat_traversal ? "N/A" : beta_side_nat_gateway_ip)}\r\n"
    end
    return params_display
  end

  def establish_ipsec_connection(equipment, test_params)
    # instantiate ipsec utilities set
    if !IpsecConnectionScript.is_ipsecVatf_started
      IpsecConnectionScript.ipsecVatf_set(IpsecUtilitiesVatf.new)
      IpsecConnectionScript.is_ipsecVatf_started_set(true)
    end
    # Set local variable to use ipsec utilities set instance
    ipsecVatf = IpsecConnectionScript.ipsecVatf

    # clear any previous connection results
    IpsecConnectionScript.clear_results()

    # Set default settings
    result = 0
    comment_text = ""
    is_clear_previous_result = true
    alpha_side_nat_public_ip = ""
    alpha_side_nat_gateway_ip = ""
    beta_side_nat_public_ip = ""
    beta_side_nat_gateway_ip = ""
    is_pass_through = ""
    is_secure_data = ""
    is_nat_traversal = ""
    ipsec_template = "ipsec_conf_template_v2.txt"
    ipsec_conf_template = ""
    protocol = ""
    esp_encryption = ""
    esp_integrity = ""
    crypto_mode = ""
    stop_offload_pre_command = ""
    stop_offload_post_command = ""
    margintime = ""
    rekey_ike_lifetime = ""
    rekey_lifetime = ""

    # Get IPSEC information from v1 test case
    ipsec_conf_template = get_variable_value(test_params.params_chan.ipsec_test_suite[0])  if test_params.params_chan.instance_variable_defined?(:@ipsec_test_suite)
    is_pass_through = get_variable_value(test_params.params_chan.ipsec_conn[0])  if test_params.params_chan.instance_variable_defined?(:@ipsec_conn)
    is_secure_data = get_variable_value(test_params.params_chan.ipsec_data[0])  if test_params.params_chan.instance_variable_defined?(:@ipsec_data)
    is_nat_traversal = get_variable_value(test_params.params_chan.ipsec_nat[0])  if test_params.params_chan.instance_variable_defined?(:@ipsec_nat)
    protocol = get_variable_value(test_params.params_chan.ipsec_protocol[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@ipsec_protocol)
    esp_encryption = get_variable_value(test_params.params_chan.ipsec_encryption[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@ipsec_encryption)
    esp_integrity = get_variable_value(test_params.params_chan.ipsec_integrity[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@ipsec_integrity)

    # Get IPSEC information from v2 test case
    ipsec_conf_template = get_variable_value(test_params.params_chan.conf_template[0])  if test_params.params_chan.instance_variable_defined?(:@conf_template)
    is_pass_through = get_variable_value(test_params.params_chan.conn[0])  if test_params.params_chan.instance_variable_defined?(:@conn)
    is_secure_data = get_variable_value(test_params.params_chan.data[0])  if test_params.params_chan.instance_variable_defined?(:@data)
    is_nat_traversal = get_variable_value(test_params.params_chan.nat[0])  if test_params.params_chan.instance_variable_defined?(:@nat)
    esp_integrity = get_variable_value(test_params.params_chan.integrity[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@integrity)
    crypto_mode = get_variable_value(test_params.params_chan.crypto[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@crypto)
    conn_type = get_variable_value(test_params.params_chan.conn[0])  if test_params.params_chan.instance_variable_defined?(:@conn)
    protocol = get_variable_value(test_params.params_chan.protocol[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@protocol)
    esp_encryption = get_variable_value(test_params.params_chan.encryption[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@encryption)
    esp_integrity = get_variable_value(test_params.params_chan.integrity[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@integrity)
    stop_offload_pre_command = get_variable_value(test_params.params_chan.stop_offload_pre_cmd[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@stop_offload_pre_cmd)
    stop_offload_post_command = get_variable_value(test_params.params_chan.stop_offload_post_cmd[0].downcase)  if test_params.params_chan.instance_variable_defined?(:@stop_offload_post_cmd)
    margintime = get_variable_value(test_params.params_chan.rekey_mt[0])  if test_params.params_chan.instance_variable_defined?(:@rekey_mt)
    rekey_ike_lifetime = get_variable_value(test_params.params_chan.rekey_ikelt[0])  if test_params.params_chan.instance_variable_defined?(:@rekey_ikelt)
    rekey_lifetime = get_variable_value(test_params.params_chan.rekey_lt[0])  if test_params.params_chan.instance_variable_defined?(:@rekey_lt)

    IpsecConnectionScript.set_all_vars(comment_text, result, protocol, esp_encryption, esp_integrity, is_pass_through, is_secure_data, is_nat_traversal, ipsec_template)
      
    # Return immediately with error code if any mandatory parameters are missing
    if protocol == "" or esp_encryption == "" or esp_integrity == ""
      result = 1
      comment_text += "\r\n IpsecConnectionScript.establish_ipsec_connection error: protocol, esp encryption and/or esp integrity parameter missing. \r\n"
      comment_text += "#{display_ipsec_test_params(ipsec_template, protocol, esp_encryption, esp_integrity, is_pass_through, is_secure_data, is_nat_traversal, alpha_side_nat_public_ip, alpha_side_nat_gateway_ip, beta_side_nat_public_ip, beta_side_nat_gateway_ip)}"
      return result
    end

    # Return immediately if user does not want an IPSEC connection started.
    if conn_type == "eth-only"
      comment_text += "\r\n IpsecConnectionScript.establish_ipsec_connection: Bypassing IPSEC connection altogether as specified by user. \r\n"
      IpsecConnectionScript.set_all_vars(comment_text, result, protocol, esp_encryption, esp_integrity, is_pass_through, is_secure_data, is_nat_traversal, ipsec_template)
      return 0
    end
    
    # Set connection parameter state based on test case information.
    is_pass_through = (is_pass_through.downcase == "pass" ? true : false)
    is_secure_data = (is_secure_data.downcase == "secure" ? true : false)
    is_nat_traversal = (is_nat_traversal.downcase == "yes" ? true : false)

    # Get IP addresses for the alpha and beta side
    alpha_ip = equipment['server1'].telnet_ip
    beta_ip = util_get_ip_addr(equipment) 

    # IMPORTANT NOTICE: To run with NAT you will need to add the nat_gateway_xxx information to your bench.rb file. Please see sample lines below
    #      linux_server.params = {'@dss_dir' => '/home/systest-s1/ccsv5/ccs_base/scripting/bin/', 'nat_gateway_public_ip' => '10.218.104.139'}   # <== Shown here is the VATF's corporate network IP address
    #      dut.params = {'nat_gateway_private_ip' => '192.168.1.80', 'nat_gateway_public_ip' => '10.218.104.131'}   # <== Shown here is the NAT gateways IP address for the EVM's local network and the NAT gateways IP address for the corporate network
    #
    if is_nat_traversal
        alpha_side_nat_public_ip = get_param_value_local(equipment['server1'], "nat_gateway_public_ip")
        alpha_side_nat_gateway_ip = get_param_value_local(equipment['server1'], "nat_gateway_private_ip")
        beta_side_nat_public_ip = get_param_value_local(equipment['server1'], "nat_gateway_public_ip")
        beta_side_nat_gateway_ip = get_param_value_local(equipment['dut1'], "nat_gateway_private_ip")
    end

    # Set IPSEC connection protocol, encryption, authentication and connection name to be used in the ipsec.conf file.
    ipsecVatf.set_protocol_encryption_integrity_name(protocol, esp_encryption, esp_integrity, "Conn")

    # Set pass through or secure connection mode.
    connection_type = (is_pass_through ? ipsecVatf.PASS_THROUGH : ipsecVatf.IPSEC_CONN)
    
    # Set result error bit to set if failures occur for IPSEC
    ipsecVatf.set_error_bit_to_set(0)
    
    # Set IPSEC config for alpha side as Linux PC (swan version 5) and beta side as EVM (swan version 5). Use the default input ipsec.conf file.
    ipsecVatf.ipsec_typical_config(equipment, ipsecVatf.FQDN_TUNNEL, "")

    # Set rekey parameters that testcase specifies
    ipsecVatf.set_rekey_parameters(margintime, rekey_ike_lifetime, rekey_lifetime)
    
    # Set IPSEC stop offload pre and post commands.
    ipsecVatf.set_stop_offload_commands(stop_offload_pre_command, stop_offload_post_command)

    if is_secure_data
      # Set beta side to use secure data for IPSEC and set template to use for ipsec.conf file generation.
      ipsecVatf.set_secure_data(ipsecVatf.BETA_SIDE())
      ipsec_template = "ipsec_conf_secure_data_template_v2.txt"
    end
    
    if is_nat_traversal
      # Set alpha and beta side to use nat_traversal and set template to use for ipsec.conf file generation.
      ipsecVatf.set_nat_traversal(ipsecVatf.ALPHA_SIDE(), is_nat_traversal, alpha_side_nat_public_ip, alpha_side_nat_gateway_ip, beta_side_nat_public_ip)
      ipsecVatf.set_nat_traversal(ipsecVatf.BETA_SIDE(), is_nat_traversal, beta_side_nat_public_ip, beta_side_nat_gateway_ip, alpha_side_nat_public_ip)
      ipsec_template = "ipsec_conf_nat_traversal_template_v2.txt"
    end
    
    if is_nat_traversal and is_secure_data
      # If both nat and secure data then make sure to use the nat traversal template which has the modifications needed for secure data as well.
      ipsec_template = "ipsec_conf_nat_traversal_template_v2.txt"
    end

    # If ipsec_conf_template is set then override the previous file name and use the filename it specifies. Legacy for previous version of test. Preference is not to override the filename.
    if ipsec_conf_template != ""
      ipsec_template = ipsec_conf_template
    end
    
    # Set the template file to use for ipsec.conf file generation on both the alpha and beta side.
    ipsecVatf.set_ipsec_template_file(ipsec_template)

    # Generate keys and certificates only.
    ipsecVatf.ipsec_gen_only_start(ipsecVatf.IPV4, connection_type)
    result |= ipsecVatf.result

    # Restart IPSEC with this template file.
    result |= ipsecVatf.ipsec_restart_with_new_ipsec_conf_file(ipsecVatf.IPV4, ipsecVatf.FQDN_TUNNEL, "#{ipsec_template}", is_clear_previous_result, is_pass_through)

    # Offload security policies if crypto_mode is inflow
    if (crypto_mode == "inflow") and (result == 0)
      this_result = 0
      this_result |= ipsecVatf.ipsec_mgr_start(ipsecVatf.BETA_SIDE())
      this_result |= ipsecVatf.inflow_offload(ipsecVatf.BETA_SIDE())
      if this_result != 0
        comment_text += "An error occurred while trying to set inflow mode.\r\n"
      end
      result |= this_result
    end

    # Set overall test result based on result variable and get all result text.
    if result == 0
      comment_text += "IPSEC connection successfully established.\r\n"
    else
      comment_text += "IPSEC connection failed to be established.\r\n"
      ipsecVatf.trigger_key_and_cert_rebuild(ipsecVatf.ALPHA_SIDE())
      ipsecVatf.trigger_key_and_cert_rebuild(ipsecVatf.BETA_SIDE())
    end
    comment_text += "\r\n"
    comment_text += ipsecVatf.result_text
    comment_text += ".\r\n"
    comment_text += "#{display_ipsec_test_params( ipsec_template, protocol, esp_encryption, esp_integrity, is_pass_through, is_secure_data, is_nat_traversal, alpha_side_nat_public_ip, alpha_side_nat_gateway_ip, beta_side_nat_public_ip, beta_side_nat_gateway_ip)}"

    # Fix dash display for webpage. The dashes are half the size when displayed on the web page so double them to keep the display line size correct.
    comment_text = comment_text.gsub("----", "--------")

    # Set externally accessible variables
    IpsecConnectionScript.set_all_vars(comment_text, result, protocol, esp_encryption, esp_integrity, is_pass_through, is_secure_data, is_nat_traversal, ipsec_template)

    # Return result code
    return result
  end
end