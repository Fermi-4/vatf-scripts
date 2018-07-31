# -*- coding: ISO-8859-1 -*-
# Test display order feature in omapdrm
require File.dirname(__FILE__)+'/../../default_test_module'

include LspTestScript   

def run
  result_str = ""
  connectors = parse_connectors()
  raise "At least one connector must be enabled to run this test" if connectors.length < 1
  translated_boot_params = setup_host_side({})
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Observed Display order",{:bgcolor => "4863A0"}], 
                                            ["boot param", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])
  #Displays disabled test
  translated_boot_params['bootargs_append'] = get_optargs(-1)
  no_connectors = boot_and_parse(translated_boot_params)
  result = no_connectors.empty?
  result_str = "Disabling displays failed: #{no_connectors.values.join(', ')} found" if !result
  add_result_row(res_table, "Displays disabled",
                 translated_boot_params['bootargs_append'], result,
                 result_str)
  #Single display enabled test
  connectors.keys.each do |disp|
    translated_boot_params['bootargs_append'] = get_optargs(disp)
    current_connectors = boot_and_parse(translated_boot_params)
    current_str = ''
    res = current_connectors.length == 1
    current_str = ", Single display test failed: expected only 1 connector but found #{current_connectors.length}" if !res
    res &= current_connectors[0] == connectors[disp]
    current_str += ", Single display test failed: expected #{connectors[disp]} but found #{current_connectors[0]}" if  current_connectors[0] != connectors[disp]
    add_result_row(res_table, connectors[disp],
                   translated_boot_params['bootargs_append'], res,
                   current_str)
    result &= res
    result_str += current_str
  end
  #Display order test
  if connectors.length > 1
    #Default order
    translated_boot_params['bootargs_append'] = get_optargs(connectors.keys)
    current_connectors = boot_and_parse(translated_boot_params)
    current_str = ''
    res = current_connectors == connectors
    result &= res
    current_str = ", Default display order test failed: expected #{connectors} connectors but found #{current_connectors}" if !res
    result_str += current_str
    add_result_row(res_table, current_connectors,
                   translated_boot_params['bootargs_append'], res,
                   current_str)
    #Reverse order
    translated_boot_params['bootargs_append'] = get_optargs(connectors.keys.reverse)
    current_connectors = boot_and_parse(translated_boot_params)
    res = true
    current_str = ''
    if current_connectors.length != connectors.length
      res = false
      current_str = ", Reverse display order test failed: expected #{connectors.length} connectors but found #{current_connectors.length}"
    end
    connectors.each do |k,v|
      if current_connectors[connectors.length - k - 1] != v
        res = false
        current_str += ", Reverse display order test failed: expected #{v} connector but found #{current_connectors[connectors.length - k - 1]}"
      end
    end
    result &= res
    result_str += current_str
    add_result_row(res_table, current_connectors,
                   translated_boot_params['bootargs_append'], res,
                   current_str)
  end
  set_result(result ? FrameworkConstants::Result[:pass] : FrameworkConstants::Result[:fail], result_str)
end

def add_result_row(res_table, order, boot_param, res, res_string)
  @results_html_file.add_rows_to_table(res_table,[[order, 
                                           boot_param,
                                           res ? ["Passed",{:bgcolor => "green"}] : ["Failed",{:bgcolor => "red"}],
                                           res_string]])
end

def parse_connectors()
  result = {}
  @equipment['dut1'].send_cmd('modetest -c | grep connected', @equipment['dut1'].prompt)
  connectors = @equipment['dut1'].response.scan(/connected\s+([^\s]+)\s+0x/i).flatten
  connectors.each_with_index { |c,i| result[i] = c }
  result
end

def get_optargs(disp)
  "omapdrm.displays=#{Array(disp).join(',')}"
end

def boot_and_parse(translated_boot_params)
  @equipment['dut1'].set_systemloader(translated_boot_params)
  boot_dut(translated_boot_params)
  connect_to_equipment('dut1')
  @equipment['dut1'].send_cmd('cat /proc/cmdline', @equipment['dut1'].prompt)
  parse_connectors()
end
