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
  if @equipment['dut1'].name.match(/j7*/)
    nulldrm_libdir = "#{@linux_dst_dir}/nulldrmusr"
    if !dut_dir_exist?(nulldrm_libdir)
      @equipment['dut1'].send_cmd("rm -rf ti-img-rogue-umlibs", @equipment['dut1'].prompt, 30)
      @equipment['dut1'].send_cmd("git clone git://git.ti.com/graphics/ti-img-rogue-umlibs.git -b linuxws/thud/k4.19/1.10.5371573", @equipment['dut1'].prompt, 300)
      @equipment['dut1'].send_cmd("ln -sf #{@linux_dst_dir}/ti-img-rogue-umlibs/targetfs/j721e_linux/nulldrmws/release/usr #{nulldrm_libdir}", @equipment['dut1'].prompt)
      @equipment['dut1'].send_cmd("ls #{nulldrm_libdir}/lib", @equipment['dut1'].prompt)
      raise "Unable to setup nulldrm libs" if @equipment['dut1'].response.match(/No\s*such\s*file\s*or\s*directory/im)
      create_lib_link('/usr/lib/libgbm.so', '/usr/lib/libgbm.so.2')
      create_lib_link("#{nulldrm_libdir}/lib/libIMGegl.so", "#{nulldrm_libdir}/lib/libIMGegl.so.1")
      create_lib_link("#{nulldrm_libdir}/lib/libsrv_um.so", "#{nulldrm_libdir}/lib/libsrv_um.so.1")
    end
    execfile = "LD_LIBRARY_PATH=#{nulldrm_libdir}/lib:/usr/lib ./GLBenchmark2"
  else
    execfile = './GLBenchmark2'
  end
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

def create_lib_link(l_pattern, l_link)
  @equipment['dut1'].send_cmd("ls #{l_link}", @equipment['dut1'].prompt)
  if @equipment['dut1'].response.match(/No\s*such\s*file\s*or\s*directory/im)
    @equipment['dut1'].send_cmd("ls #{l_pattern}* | tail -1", @equipment['dut1'].prompt)
    return if @equipment['dut1'].response.match(/No\s*such\s*file\s*or\s*directory/im)
    lib = @equipment['dut1'].response.match(/^#{l_pattern}[^\r\n]+/)[0]
    @equipment['dut1'].send_cmd("ln -sf #{lib} #{l_link}", @equipment['dut1'].prompt)
  end
end
