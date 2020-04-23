# -*- coding: ISO-8859-1 -*-
# This script is a wrapper script to run u-boot pytest suite 
#  

require File.dirname(__FILE__)+'/../default_test_module'
   
include LspTestScript   

def setup
  @equipment['dut1'].set_api('psp')
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
end

def run
  result = 0

  uboot_root = @test_params.params_chan.instance_variable_defined?(:@uboot_root) ? @test_params.params_chan.uboot_root[0] : "${HOME}/u-boot"
  uboot_test_hooks_dir = @test_params.params_chan.instance_variable_defined?(:@uboot_test_hooks_dir) ? @test_params.params_chan.uboot_test_hooks_dir[0] : "${HOME}/ubtest/uboot-test-hooks"

  board_type, board_id = translate_board_from_opentest(@equipment['dut1'].name)
  params = setup_host_side('dut'=>@equipment['dut1'])
  params = update_mmcsd(params['dut'], params)

  params['server'].send_cmd("hostname", params['server'].prompt, 3)
  hostname = params['server'].response.match(/^([\/\w]+)/).captures[0]
  puts "hostname:" +hostname

  params['server'].send_cmd("cd #{uboot_root};export PATH=#{uboot_test_hooks_dir}/bin:$PATH; export PYTHONPATH=#{uboot_test_hooks_dir}/py/#{hostname}:${PYTHONPATH}; python ./test/py/test.py --bd #{board_type} --id #{board_id} -rA --build-dir build-#{board_type} && echo 'UBTESTPASS' ", params['server'].prompt, 600)
  # sample summary: ====== 103 passed, 191 skipped in 17.43 seconds ========
  if params['server'].response.match(/===+\s*(\d+\s+.*?\s+in\s+[\d\.]+\s+seconds)\s+===/im)
    test_summary = params['server'].response.match(/===+\s*(\d+\s+.*?\s+in\s+[\d\.]+\s+seconds)\s+===/im).captures[0] 
  else
    test_summary = "There is no test summary line and tests might not finish;"
  end
  if /UBTESTPASS/.match(params['server'].response)
    set_result(FrameworkConstants::Result[:pass], "Test Pass; #{test_summary}; please check server side log for details")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Fail; #{test_summary}; please check server side log for details")
  end
end

def clean
  puts "cleaning..."
end

def translate_board_from_opentest(platform)
  bd_id = 'na'
  case platform.downcase
  when /am335x/
    bd_type = 'am335x_evm'
  when /beaglebone-black/
    bd_type = 'am335x_evm'
    bd_id = 'bbb'
  when /am43/
    bd_type = 'am43xx_evm'
  when /am65/
    bd_type = 'am65x_evm_a53'
  when /am57/
    bd_type = 'am57xx_evm'
  when /j7/
    bd_type = 'j721e_evm_a72'
  when /omapl138/
    bd_type = 'omapl138_lcdk'
  else
    raise "No mapping between U-Boot board type and opentest platform name; Please add the mapping for #{platform}"
  end
  [bd_type, bd_id]
end



