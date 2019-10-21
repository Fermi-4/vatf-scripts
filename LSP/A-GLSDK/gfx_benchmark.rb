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
  if !dut_dir_exist?('gfxbench5-bins*')
    url = @test_params.params_chan.benchmark[0]
    tarball = File.basename(url)
    @equipment['dut1'].send_cmd("wget #{url}", @equipment['dut1'].prompt, 600)
    @equipment['dut1'].send_cmd("tar -Jxvf #{tarball}", @equipment['dut1'].prompt, 600)
  end
  @equipment['dut1'].send_cmd('cd gfxbench5-bins',@equipment['dut1'].prompt)
  width = @test_params.params_chan.instance_variable_defined?(:@width) ? @test_params.params_chan.width[0].to_i : 1920
  height = @test_params.params_chan.instance_variable_defined?(:@height) ? @test_params.params_chan.height[0].to_i : 1080
  execfile = "./testfw_app --gfx egl --gl_api gles -w #{width} -h #{height}"
  perf_data = []
  @test_params.params_chan.tests.each do |test|
    @equipment['dut1'].send_cmd("#{execfile} -t #{test}", @equipment['dut1'].prompt, 600)
    raw_results = @equipment['dut1'].response.match(/\[INFO\s*\]:\s*({.*?"results":.*})/im).captures[0]
    raise "Unable to parse results for #{test}" if !raw_results
    perf_data << {'name' => "fps-#{test}",
                  'units' => 'fps',
                  'values' => raw_results.match(/"fps":\s*([\d+\.]+),/).captures[0].to_f}
    perf_data << {'name' => "score-#{test}",
                  'units' => 'none',
                  'values' => raw_results.match(/"score":\s*([\d+\.]+),/).captures[0].to_f}
  end
  set_result(FrameworkConstants::Result[:pass], "GFX test passed", perf_data)
end
