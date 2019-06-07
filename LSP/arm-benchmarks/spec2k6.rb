require File.dirname(__FILE__)+'/../TARGET/dev_test_perf_gov'
require 'bigdecimal'


def determine_arch()
  @equipment['dut1'].send_cmd("uname -a",@equipment['dut1'].prompt)
  if @equipment['dut1'].response.match(/aarch64/)
    return '64'
  else
    return '32'
  end
end


def determine_num_cores()
  @equipment['dut1'].send_cmd("grep -c ^processor /proc/cpuinfo",@equipment['dut1'].prompt)
  if @equipment['dut1'].response.match(/^(\d+)\s*$/)
    return @equipment['dut1'].response.match(/^(\d+)\s*$/).captures[0]
  else
    raise "Could not determine number of DUT cores"
  end
end


def run_generate_script()
  raw_test_lines = [
    "opkg update",
    "opkg install --nodeps spec2k6",
    "cd /opt/spec2k6/scripts",
    "./specint2006_fpga.sh #{determine_arch()} `grep -c ^processor /proc/cpuinfo`"
  ]
  out_file = File.new(File.join(@linux_temp_folder, 'test.sh'),'w')
  raw_test_lines.each do |current_line|
    out_file.print(current_line+"\n")
  end
  out_file.close
end


def geo_mean(xs)
  one = BigDecimal.new 1
  xs.map { |x| BigDecimal.new x }.inject(one, :*) ** (one / xs.size.to_f)
end


def calculate_spec2k6_score()
  ref = {
    'perlbench' => 9770,
    'bzip2' => 9650,
    'gcc' => 8050,
    'mcf' => 9120,
    'gobmk' => 10490,
    'hmmer' => 9330,
    'sjeng' => 12100,
    'libquantum' => 20720,
    'h264ref' => 22130,
    'omnetpp' => 6250,
    'astar' => 7020,
    'xalancbmk' => 6900
  }
  spec2k6_data = {}
  values = {}
  ratio = {}
  num_cores = determine_num_cores().to_i
  if File.exists?(File.join(@linux_temp_folder,'test.log'))
    data = File.new(File.join(@linux_temp_folder,'test.log'),'r').read
    data.scan(/([\w\d]+):([\w\d\._]+):\s+elapsed\s+execution\s+time.+=\s+(\d+)\s+sec/) {|b,w,t|
      if !values.has_key? b or !values[b].has_key? w
        values.merge!(b =>  { w => t.to_i})
      else
        values.merge!(b =>  { w => [t.to_i, values[b][w]].max })
      end
    }
    values = values.map{|k,v| { k => v.values.inject(0, :+) }}
    values = values.map{|k,v| (ref[k]/v.to_f)*num_cores }
    spec2k6_rate = geo_mean(values).to_f
    spec2k6_data = {'name' => 'Spec2K6_rate', 'value' => spec2k6_rate, 'units' => ''}
  end
  return spec2k6_data
end


def run_save_results(return_non_zero)
  puts "\n Spec2K6::run_save_results"
  result = run_determine_test_outcome(return_non_zero)
  if result.length == 3 && result[2] != nil
    perfdata = result[2]
    perfdata = perfdata << calculate_spec2k6_score()
    perfdata = perfdata.concat(@target_sys_stats) if @target_sys_stats
    set_result(result[0],result[1],perfdata)
  elsif File.exists?(File.join(@linux_temp_folder,'perf.log'))
    perfdata = []
    data = File.new(File.join(@linux_temp_folder,'perf.log'),'r').readlines
    data.each {|line|
      if /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line)
        name,value,units = /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line).captures
        perfdata << {'name' => name, 'value' => value, 'units' => units}
      end
    }
    perfdata = perfdata.concat(@target_sys_stats) if @target_sys_stats
    set_result(result[0],result[1],perfdata)
  else
    set_result(result[0],result[1], @target_sys_stats)
  end
end
