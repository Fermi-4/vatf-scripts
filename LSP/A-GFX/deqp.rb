# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || /etc/init.d/weston start && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || echo "weston failed"',@equipment['dut1'].prompt,10)
  raise "Weston did not start, tests require weston" if @equipment['dut1'].response.scan(/weston\s*failed/im).length > 1
end

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd('mkdir ' + @linux_dst_dir,@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd('cd ' + @linux_dst_dir,@equipment['dut1'].prompt)
  if !dut_dir_exist?('test-resources')
    url = @test_params.params_chan.app[0]
    tarball = File.basename(url)
    @equipment['dut1'].send_cmd("wget #{url}", @equipment['dut1'].prompt, 600)
    @equipment['dut1'].send_cmd("tar -zxvf #{tarball}", @equipment['dut1'].prompt, 600)
  end
  @equipment['dut1'].send_cmd('cd test-resources/deqp-tests',@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("./#{@test_params.params_chan.test[0]}", @equipment['dut1'].prompt, 600)
  raw_results = @equipment['dut1'].response.match(/Test\s*run\s*totals:.*?#{@equipment['dut1'].prompt}/im)
  if !raw_results || !raw_results[0].match(/Passed:\s*[\d\/]+\s*\(100.0%\)/)
    fail_result = raw_results ? raw_results[0] : @equipment['dut1'].response
    set_result(FrameworkConstants::Result[:fail], "Test failed: #{fail_result}")
  else
    set_result(FrameworkConstants::Result[:pass], "Test passed: #{raw_results[0]}")
  end
end
