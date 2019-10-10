# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def run
  type = @test_params.params_chan.instance_variable_defined?(:@type) ? @test_params.params_chan.type[0].downcase() : 'drm'
  @equipment['dut1'].send_cmd('/etc/init.d/matrix-gui-2.0 stop',@equipment['dut1'].prompt,10)
  if type != 'wayland'
    @equipment['dut1'].send_cmd('/etc/init.d/weston stop; sleep 3',@equipment['dut1'].prompt,10)
  else
    @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || /etc/init.d/weston start; sleep 3',@equipment['dut1'].prompt,10)
  end
  sleep 3
  perf_data = []
  @equipment['dut1'].send_cmd("ls /usr/bin/glmark* | grep -o 'glmark.*'",@equipment['dut1'].prompt)
  tests = @equipment['dut1'].response.scan(/glmark[\w].*/)
  tests.select! { |t| t.match(/#{type}/) }
  tests.each do |test|
    @equipment['dut1'].send_cmd("#{test}", @equipment['dut1'].prompt, 700)
    @equipment['dut1'].response.downcase().scan(/\[.*?ms/im).each do |result|
      if result.match(/\[terrain\].*?Error.*?SGXKickTA:\s*TA\s*went\s*out\s*of\s*Mem/im)
        puts "Known issue  \"#{result}\" for terrain test skipping metric"
        next
      end
      result = result.gsub(/\[[\s\d\.]{5,}.*?PVR_K:.*?\.\s*This\s*is\s*not\s*an\s*error[^\.]+\.[\r\n]/,'')
      res_arr = result.split(/\s+/,3)
      t_dat = res_arr[2].split(/:\s*/)
      metric = t_dat[0]
      1.upto(t_dat.length - 2) do |i|
        t_perf = t_dat[i].split(/\s+/)
        perf_data << {'name' => compose_metric(metric, res_arr),
                      'units' => t_perf.length > 2 ? t_perf[1] : metric,
                      'values' => t_perf[0].to_f}
        metric = t_perf[-1]
      end
      t_perf = t_dat[-1].split(/\s+/)
      perf_data << {'name' => compose_metric(metric, res_arr),
                    'units' => t_perf.length > 1 ? t_perf[1] : metric,
                    'values' => t_perf[0].to_f}
    end
    score = @equipment['dut1'].response.match(/glmark\d*\s*score:\s*(\d+)/im).captures[0]
    perf_data << {'name' => 'score',
                  'units' => 'none',
                  'values' => score.to_f}
  end
  set_result(FrameworkConstants::Result[:pass], "GFX test passed", perf_data)
end

def compose_metric(name, extra)
  ext0 = extra[0].gsub(/[\[\]]+/,'')
  result = "#{name.gsub('frametime','ftime')}-#{ext0[0..2]}-"
  ext1 = extra[1].gsub(ext0,' ')
  if result.length + ext1.length > 29
    ext1.gsub('false','f').gsub('true','t').gsub('=0.','=.').gsub('sub','s').split(':').each do |dat|
      dat_arr = dat.split('=')
      dat_n_arr = dat_arr[0].split('-')
      if dat_n_arr.length > 1
        result += "#{dat_n_arr[0][0]}#{dat_n_arr[1][0]}".strip()
      else
        result += "#{dat_n_arr[0][0..1]}".strip()
      end
        result += dat_arr[1]
    end
  else
    result = "#{result}#{extra[1]}"
  end
  result.gsub(/[><]+/,'')
end
