# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
  
def setup
  super
end

def run
  @perfData = []
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  @results_html_file.add_paragraph("")

  @equipment['dut1'].send_cmd("cat /proc/version", @equipment['dut1'].prompt, 10)
  puts "Kernel GCC version: #{@equipment['dut1'].response.scan(/Sourcery\sCodeBench\sLite\s(\d+\.\d+-\d+)/)[0][0]}"
  @equipment['dut1'].send_cmd("cat /proc/cpuinfo", @equipment['dut1'].prompt, 10)
  puts "cpu_speed: #{@equipment['dut1'].response.scan(/Clocking:\s+(\d+)([M|G]Hz)/)[0][0]}"
  cpu_speed = @equipment['dut1'].response.scan(/Clocking:\s+(\d+)([M|G]Hz)/)[0][0]
  puts "cpu_speed_units: #{@equipment['dut1'].response.scan(/Clocking:\s+(\d+)([M|G]Hz)/)[0][1]}"  
  cpu_speed_units = @equipment['dut1'].response.scan(/Clocking:\s+(\d+)([M|G]Hz)/)[0][1]
  mhz = (cpu_speed_units == "MHz") ? cpu_speed.to_i : cpu_speed.to_i*1000

  @equipment['dut1'].send_cmd("cd /opt", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("./coremark.exe", @equipment['dut1'].prompt, 2000)
  parse_results(@equipment['dut1'].response,mhz)

  if !@equipment['dut1'].timeout? 
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  set_result(test_done_result,comment,@perfData)
end

def clean

end

def parse_results(string,cpu_speed)
  label = "Coremark with compiler flags -O3 -mdsbt -lrt / Heap"
  ticks = string.scan(/Total\s+ticks\s+:\s+(\d+)/)[0][0].to_i
  time = string.scan(/Total\s+time\s+\(secs\):\s+(\d+\.\d+)/)[0][0].to_f
  itsPerSec = string.scan(/Iterations\/Sec\s+:\s+(\d+\.\d+)/)[0][0].to_f
  iterations = string.scan(/Iterations\s+:\s+(\d+)/)[0][0].to_i
  coremark = string.scan(/CoreMark\s+1\.0\s+:\s+(\d+\.\d+)/)[0][0].to_f/cpu_speed
  
  @res_table = @results_html_file.add_table([["#{label}",{:bgcolor => "blue", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
  @results_html_file.add_row_to_table(@res_table,["Ticks",ticks])
  @results_html_file.add_row_to_table(@res_table,["Time",time])
  @results_html_file.add_row_to_table(@res_table,["Its/sec",itsPerSec])
  @results_html_file.add_row_to_table(@res_table,["Iterations",iterations])
  @results_html_file.add_row_to_table(@res_table,["Coremark",coremark])
  
  @perfData << {'name' => "Ticks", 'value' => ticks , 'units' => 'ticks'}
  @perfData << {'name' => "Time", 'value' => time , 'units' => 'seconds'}
  @perfData << {'name' => "Its/sec", 'value' => itsPerSec , 'units' => ''}
  @perfData << {'name' => "Iterations", 'value' => iterations , 'units' => 'iterations'}
  @perfData << {'name' => "Coremark", 'value' => coremark , 'units' => ''}
  
  puts "Ticks:#{ticks} Time:#{time} Its/sec:#{itsPerSec} Iterations:#{iterations} Coremark:#{coremark}"
end