# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def setup
  #super
  puts 'timer setup.'
  self.as(LspTestScript).setup
end

def run
  dut_prompt = @equipment['dut1'].prompt
  result = 0
  time_pre = 0
  sleep_time = 5
  is_set_time = true
  
  # test set time
  is_set_time = @test_params.params_chan.is_set_time[0]=='0' ? false : true
  
  if is_set_time then
    #set_time_cnt = @test_params.params_chan.set_time_cnt[0].to_i
    time_now = Time.now.to_i
    @equipment['dut1'].send_cmd("st_parser timer set_sec #{time_now.to_s}", dut_prompt, 10 )
    time_set = /Time\s*=(\d+)/i.match(@equipment['dut1'].response).captures[0].to_i
    if time_set != time_now then result = 2 end
    time_pre = time_now # for get time test.
  end
  
  # test get time
  get_time_cnt = 3
  get_time_cnt = @test_params.params_chan.get_time_cnt[0].to_i if @test_params.params_chan.instance_variable_defined?(:@get_time_cnt)
  get_time_cnt.times do |x|
    sleep sleep_time
    @equipment['dut1'].send_cmd("st_parser timer get_sec", dut_prompt, 10 )
    time_cur = /Time\s*=(\d+)/i.match(@equipment['dut1'].response).captures[0].to_i
    if (time_cur-time_pre) < sleep_time then 
      result = 1
      break 
    end
    time_pre = time_cur
  end  
  
 	if result == 0
		set_result(FrameworkConstants::Result[:pass], "Test Pass.")
  elsif result == 1
		set_result(FrameworkConstants::Result[:fail], "The timer is not ticking.")
  elsif result == 2
		set_result(FrameworkConstants::Result[:fail], "The timer can not be set correctly.")
 	else
		set_result(FrameworkConstants::Result[:nry])
  end

end

def clean
  self.as(LspTestScript).clean
  #super
  puts 'timer cleanup'
end


