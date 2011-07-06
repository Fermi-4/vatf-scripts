# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
  
def setup
  super
end

def run
  @perfData = []
  @equipment['dut1'].send_cmd("uname -a",@equipment['dut1'].prompt, 30)
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  @results_html_file.add_paragraph("")
  params = ["dd","sync"]
  bs = @test_params.params_chan.instance_variable_get("@bs")[0]
  count = @test_params.params_chan.instance_variable_get("@count")[0].to_i

  @equipment['dut1'].send_cmd("time dd if=/dev/zero of=file bs=#{bs} count=#{count} ; time sync",@equipment['dut1'].prompt,120)
  params.each { |value|
    @res_table = @results_html_file.add_table([["#{value} bs:#{bs} count:#{count} (in seconds)",{:bgcolor => "blue", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
    time = get_time(value,@equipment['dut1'].response)
    if !time.length 
      test_done_result = FrameworkConstants::Result[:fail]
      comment = "dd failed"
    else
      test_done_result = FrameworkConstants::Result[:pass]
      comment = "Test Pass"
    end
    add_result("#{value}",time)
  }
  
  set_result(test_done_result,comment,@perfData)
end

def clean

end

def get_time(param,string)
  valueArr = []
  case param
  when "dd" 
    timeStr = string.scan(/.*?real\s+(\d+m\s+\d+\.\d+s)/)[0].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
    timeStr = string.scan(/.*?user\s+(\d+m\s+\d+\.\d+s)/)[0].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
    timeStr = string.scan(/.*?sys\s+(\d+m\s+\d+\.\d+s)/)[0].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
  when "sync" 
    timeStr = string.scan(/.*?real\s+(\d+m\s+\d+\.\d+s)/)[1].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
    timeStr = string.scan(/.*?user\s+(\d+m\s+\d+\.\d+s)/)[1].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
    timeStr = string.scan(/.*?sys\s+(\d+m\s+\d+\.\d+s)/)[1].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
  end
  valueArr

end

def add_result(label,value)
	@results_html_file.add_row_to_table(@res_table,["Real","#{value[0]}"])
  @results_html_file.add_row_to_table(@res_table,["User","#{value[1]}"])
  @results_html_file.add_row_to_table(@res_table,["Sys","#{value[2]}"])
  @perfData << {'name' => "#{label} real", 'value' => value[0] , 'units' => 'seconds'}
  @perfData << {'name' => "#{label} user", 'value' => value[0] , 'units' => 'seconds'}
  @perfData << {'name' => "#{label} sys", 'value' => value[0] , 'units' => 'seconds'}
end