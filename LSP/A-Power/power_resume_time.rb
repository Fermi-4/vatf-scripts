# This script is used to measure the resume time after suspend/standby
# The resume time will be saved into performance table

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/power_functions' 

include LspTestScript
include PowerFunctions

def setup
  self.as(LspTestScript).setup
end

def run
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'

  @equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("cd /debug/omap_mux/board", @equipment['dut1'].prompt, 10)
  
  # dut will be suspend with random suspend time
  max_s_time = @test_params.params_chan.max_suspend_time[0].to_i
  max_resume_time = 60
  test_loop = @test_params.params_control.test_loop[0].to_i
  resume_time = []

  enable_pm_debug_messages()

  i = 0
  while i < test_loop do
    power_wakeup_configuration(wakeup_domain, power_state)
    suspend_time = rand(max_s_time-1) + 30   # Adding 30 seconds to make sure that alarm event happens on suspend state
    @equipment['dut1'].log_info("Random suspend time: #{suspend_time}\n")
    puts "Random suspend time: #{suspend_time}\n"
    
    # Suspend
    start_time = Time.now
    suspend(wakeup_domain, power_state, suspend_time)

    # Resmue
    elapsed_time = Time.now - start_time
    sleep (suspend_time - elapsed_time) if elapsed_time < suspend_time and wakeup_domain == 'rtc'
    response = resume(wakeup_domain, max_resume_time)
    if wakeup_domain != 'rtc_only'
      time_captures = /PM:\s+resume\s+of\s+devices\s+complete\s+after\s+([0-9\.]+)/i.match(response)
      resume_time << time_captures[1]
      # here assume the printed unit is same for all iterations
      unit = time_captures.size > 2 ? time_captures[2] : 'msecs'
    end
    i += 1
    sleep 5
    # wait until 30 seconds (3 * 10) for board prompt
    if ! @equipment['dut1'].at_prompt?({'prompt' => @equipment['dut1'].prompt, 'wait' => 10})
      msg = "Board did not return to prompt"
      @equipment['dut1'].log_info(msg)
      raise msg
    end
  end # end of while

  puts "unit: " + unit.to_s
  puts "resume time: " + resume_time.to_s 
  if !resume_time.empty?
    perf_data = {'name' => "Resume_time", 'value' => resume_time, 'units' => unit}  
    set_result(FrameworkConstants::Result[:pass], "Resume time is captured: "+resume_time.to_s, perf_data)
  elsif wakeup_domain == 'rtc_only'
    set_result(FrameworkConstants::Result[:pass], "Board successfully resumed from rtc_only #{test_loop} times")
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get resume time!")
  end # end of if

end

