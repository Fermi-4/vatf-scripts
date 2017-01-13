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
  if !dut_dir_exist?('glbenchmark*')
    url = @test_params.params_chan.benchmark[0]
    tarball = File.basename(url)
    @equipment['dut1'].send_cmd("wget #{url}", @equipment['dut1'].prompt, 600)
    @equipment['dut1'].send_cmd("tar -zxvf #{tarball}", @equipment['dut1'].prompt, 600)
  end
  execfile = './GLBenchmark2'
  @equipment['dut1'].send_cmd("gl_dir=`ls -d glbenchmark*/|sort|tail -n 1`; cd $gl_dir", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("#{execfile} 2>&1 | grep -i 'Log:.*GLB.*|[0-9]*'", @equipment['dut1'].prompt)
  tests_table = @equipment['dut1'].response.slice(/^Log:\s*(.*?)#{@equipment['dut1'].prompt}/im,1).gsub(/^\s*Log:\s+/im,'').split(/[\s\|]+/im)
  tests_table = Hash[*tests_table]
  perf_data = []
  tests = @test_params.params_chan.tests.join().downcase.strip() == 'all' ? tests_table.keys() : @test_params.params_chan.tests
  if @test_params.params_chan.instance_variable_defined?(:@show_opp)
    @equipment['dut1'].send_cmd("omapconf show opp", @equipment['dut1'].prompt)
    opp_info = @equipment['dut1'].response.scan(/^\|.*/i)
    if opp_info.length() > 3
      m_name = opp_info[1].scan(/[^\|]+/).collect { |m| m.strip() }
      opp_info[3..-1].each do |c_opp|
        current_opp = c_opp.scan(/[^\|]+/).collect { |m| m.strip() }
        next if current_opp.length() < 5
        name = current_opp[0].strip().gsub(/\s+/,'')
        idx = current_opp[m_name.index('Voltage')] == '' ? m_name.index('Frequency') : m_name.index('Voltage')
        m_info = current_opp[idx].strip().split(/\s+/)
        if m_info.length() == 2
           perf_data << {'name' => "#{name}-#{m_name[idx]}",
                         'units' => m_info[1],
                         'values' => m_info[0]}
        end
      end
    end
  end
  tests.each do |test|
    @equipment['dut1'].send_cmd("#{execfile} -t #{tests_table[test]} -d ./data ", @equipment['dut1'].prompt, 600)
    non_zero = false
    fps = @equipment['dut1'].response.scan(/(?<=FPS = )[\d\.]+/i).select{ |f| non_zero |= f.to_f > 0 }
    metrics = @equipment['dut1'].response.match(/^Log:\s*Application::FinishCurrentTest\((.*?):\s*([\d\.]+)\s*([\w\/]+)\s*(.*?)FPS/i).captures
    perf_data << {'name' => 'test-number',
                  'units' => 'none',
                  'values' => tests_table[test]}
    perf_data << {'name' => "fps-#{test.sub(/^.*?_/,'')}",
                  'units' => 'fps',
                  'values' => fps.length() > 0 ? fps : metrics[3]}
    perf_data << {'name' => "#{metrics[0].gsub(/\s+/,'-')}-#{test.sub(/^.*?_/,'')}",
                  'units' => metrics[2].gsub(/\s+/,'-'),
                  'values' => metrics[1]}
  end
  set_result(FrameworkConstants::Result[:pass], "GFX test passed", perf_data)
end
