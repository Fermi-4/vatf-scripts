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
  duration = ['30','30m']
  nanosleep = ['s','n']
  @equipment['dut1'].send_cmd("cd /opt", @equipment['dut1'].prompt, 10)
  duration.each { |time|
    nanosleep.each { |ns|
      @equipment['dut1'].send_cmd("./cyclictest -D #{time} -q -#{ns}", @equipment['dut1'].prompt, 2000)
      parse_results(@equipment['dut1'].response,time,ns)
    }
  }
  if !@equipment['dut1'].timeout? 
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  set_result(test_done_result,comment,@perfData)
end

def clean

end

def parse_results(string,time,ns)
  label = "cyclictest -D #{time} -q -#{ns}"
  min = string.scan(/Min:\s*(\d+)\s+Act:\s*(\d+)\s+Avg:\s*(\d+)\s+Max:\s*(\d+)/)[0][0].to_i
  act = string.scan(/Min:\s*(\d+)\s+Act:\s*(\d+)\s+Avg:\s*(\d+)\s+Max:\s*(\d+)/)[0][1].to_i
  avg = string.scan(/Min:\s*(\d+)\s+Act:\s*(\d+)\s+Avg:\s*(\d+)\s+Max:\s*(\d+)/)[0][2].to_i
  max = string.scan(/Min:\s*(\d+)\s+Act:\s*(\d+)\s+Avg:\s*(\d+)\s+Max:\s*(\d+)/)[0][3].to_i
  
  @res_table = @results_html_file.add_table([["#{label} (in microseconds)",{:bgcolor => "blue", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
  @results_html_file.add_row_to_table(@res_table,["Min",min])
  @results_html_file.add_row_to_table(@res_table,["Act",act])
  @results_html_file.add_row_to_table(@res_table,["Avg",avg])
  @results_html_file.add_row_to_table(@res_table,["Max",max])
  
  @perfData << {'name' => "#{label} min", 'value' => min , 'units' => 'microseconds'}
  @perfData << {'name' => "#{label} act", 'value' => act , 'units' => 'microseconds'}
  @perfData << {'name' => "#{label} avg", 'value' => avg , 'units' => 'microseconds'}
  @perfData << {'name' => "#{label} max", 'value' => max , 'units' => 'microseconds'}
  
  puts "Min:#{min} Act:#{act} Avg:#{avg} Max:#{max}"
end