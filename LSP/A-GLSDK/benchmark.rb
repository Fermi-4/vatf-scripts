# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('/etc/init.d/weston stop; sleep 3',@equipment['dut1'].prompt,10)
end

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd('mkdir ' + @linux_dst_dir,@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd('cd ' + @linux_dst_dir,@equipment['dut1'].prompt)
  if !dut_dir_exist?('glbenchmark')
    url = @test_params.params_chan.benchmark[0]
    tarball = File.basename(url)
    @equipment['dut1'].send_cmd("wget #{url}", @equipment['dut1'].prompt, 600)
    @equipment['dut1'].send_cmd("tar -zxvf #{tarball}", @equipment['dut1'].prompt, 600)
  end
  execfile = './GLBenchmark2'
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}/glbenchmark", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("#{execfile} 2>&1 | grep -i 'Log:.*GLB.*|[0-9]*'", @equipment['dut1'].prompt)
  tests_table = @equipment['dut1'].response.slice(/^Log:\s*(.*?)#{@equipment['dut1'].prompt}/im,1).gsub(/^\s*Log:\s+/im,'').split(/[\s\|]+/im)
  tests_table = Hash[*tests_table]
  perf_data = []
  tests = @test_params.params_chan.tests.join().downcase.strip() == 'all' ? tests_table.keys() : @test_params.params_chan.tests
  tests.each do |test|
    @equipment['dut1'].send_cmd("#{execfile} -t #{tests_table[test]} -d ./data ", @equipment['dut1'].prompt, 600)
    non_zero = false
    fps = @equipment['dut1'].response.scan(/(?<=FPS = )[\d\.]+/i).select{ |f| non_zero |= f.to_f > 0 }
    metrics = @equipment['dut1'].response.match(/^Log:\s*Application::FinishCurrentTest\((.*?):\s*([\d\.]+)\s*([\w\/]+)\s*(.*?)FPS/i).captures
    perf_data << {'name' => "#{test.sub(/^.*?_/,'')}-fps",
                  'units' => 'fps',
                  'values' => fps.length() > 0 ? fps : metrics[3]}
    perf_data << {'name' => "#{test.sub(/^.*?_/,'')}-#{metrics[0].gsub(/\s+/,'-')}",
                  'units' => metrics[2].gsub(/\s+/,'-'),
                  'values' => metrics[1]}
  end
  set_result(FrameworkConstants::Result[:pass], "GFX test passed", perf_data)
end
