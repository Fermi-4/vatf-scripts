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

  bs = @test_params.params_chan.instance_variable_get("@bs")[0]
  count = @test_params.params_chan.instance_variable_get("@count")[0].to_i
  puts "Starting dd write followed by sync"
  params = ["dd-write","write-sync"]
  combined = 0
  if @test_params.params_chan.instance_variable_defined?("@if")
    @equipment['dut1'].send_cmd("time dd if=#{@test_params.params_chan.instance_variable_get("@if")[0]} of=file bs=#{bs} count=#{count} ; time sync",@equipment['dut1'].prompt,120)
  else
    @equipment['dut1'].send_cmd("time dd if=/dev/zero of=file bs=#{bs} count=#{count} ; time sync",@equipment['dut1'].prompt,120)
  end
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
    combined = combined + time[0].to_f
    add_result("#{value}",time)
  }
  add_result("dd-write combined",combined)
  
  puts "Starting read"
  combined = 0
  params = ["dd-read","read-sync"]
  @equipment['dut1'].send_cmd("time dd if=file of=/dev/null bs=#{bs} count=#{count}; time sync",@equipment['dut1'].prompt,120)
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
    combined = combined + time[0].to_f
    add_result("#{value}",time)
  }
  add_result("dd-read combined",combined)
  
  set_result(test_done_result,comment,@perfData)
end

def clean

end

def get_time(param,string)
  valueArr = []

  case param
  when "dd-read","dd-write"  
    timeStr = string.scan(/.*?real\s+(\d+m\s+\d+\.\d+s)/)[0].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
    timeStr = string.scan(/.*?user\s+(\d+m\s+\d+\.\d+s)/)[0].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
    timeStr = string.scan(/.*?sys\s+(\d+m\s+\d+\.\d+s)/)[0].to_s
    valueArr << timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[0].to_f*60 + timeStr.match(/(\d+)m\s+(\d+\.\d+)s/).captures[1].to_f
  when "write-sync","read-sync"
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
  if (value.kind_of?(Array))
    @results_html_file.add_row_to_table(@res_table,["Real","#{value[0]}"])
    @results_html_file.add_row_to_table(@res_table,["User","#{value[1]}"])
    @results_html_file.add_row_to_table(@res_table,["Sys","#{value[2]}"])
    @perfData << {'name' => "#{label} real", 'value' => value[0] , 'units' => 'seconds'}
    @perfData << {'name' => "#{label} user", 'value' => value[1] , 'units' => 'seconds'}
    @perfData << {'name' => "#{label} sys", 'value' => value[2] , 'units' => 'seconds'}
  else
     @results_html_file.add_row_to_table(@res_table,[label,"#{value}"])
     @perfData << {'name' => "#{label}", 'value' => value , 'units' => 'seconds'}
  end
end