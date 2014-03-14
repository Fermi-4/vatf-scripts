# This script is used to measure the resume time after suspend/standby
# The resume time will be saved into performance table

require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'

  # set uart to gpio in standby_gpio_pad_conf so that uart can wakeup from standby
  if power_state == 'standby' && wakeup_domain == 'uart'
    @equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cd /debug/omap_mux/board", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("#{CmdTranslator.get_linux_cmd({'cmd'=>'set_uart_to_gpio_standby', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})}" , @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("#{CmdTranslator.get_linux_cmd({'cmd'=>'get_uart_to_gpio_standby', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})}", @equipment['dut1'].prompt, 10)
  end

  # Work around to enable uart wakeup on some platforms (e.g. J6)
  if wakeup_domain == 'uart' 
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'enable_uart_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})
    @equipment['dut1'].send_cmd(cmd , @equipment['dut1'].prompt) if cmd.to_s != ''
  end

  # dut will be suspend with random suspend time
  max_s_time = @test_params.params_chan.max_suspend_time[0].to_i
  test_loop = @test_params.params_control.test_loop[0].to_i
  resume_time = []

  i = 0
  while i < test_loop do
    suspend_time = rand(max_s_time-1) + 30   # Adding 30 seconds to make sure that alarm event happens on suspend state
    @equipment['dut1'].log_info("Random suspend time: #{suspend_time}\n")
    puts "Random suspend time: #{suspend_time}\n"
    if(@test_params.params_chan.instance_variable_defined?(:@wakeup_domain) && @test_params.params_chan.wakeup_domain[0].to_s == 'rtc')
      @equipment['dut1'].send_cmd( "[ -e /dev/rtc0 ]; echo $?", /^0[\0\n\r]+/m, 2)
      raise "DUT does not seem to support rtc wakeup. /dev/rtc0 does not exist"  if @equipment['dut1'].timeout?
      @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 60)
      @equipment['dut1'].send_cmd("rtcwake -d /dev/rtc0 -m #{power_state} -s #{suspend_time}", /PM:\s+resume\s+of\s+devices\s+complete/i, suspend_time + 60, false)
      if @equipment['dut1'].timeout?
        raise "Timeout while waiting for RTC suspend/resume completion"
      end
    else
      @equipment['dut1'].send_cmd("sync; echo #{power_state} > /sys/power/state", /Freezing remaining freezable tasks/, 120, false)
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting to suspend"
        raise "DUT took more than 120 seconds to suspend"
      end
      sleep suspend_time
      # Resume from console
      puts "GOING TO RESUME DUT"
      resume_wtime = 60
      @equipment['dut1'].send_cmd("\n", @equipment['dut1'].prompt, resume_wtime)  
      if @equipment['dut1'].timeout?
        raise "DUT took more than #{resume_wtime} seconds to resume"
      end
    end # end of if

    time_captures = /PM:\s+resume\s+of\s+devices\s+complete\s+after\s+([0-9\.]+)\s+([umsec]+)/i.match(@equipment['dut1'].response) 
    resume_time << time_captures[1]
    # here assume the printed unit is same for all iterations
    unit = time_captures[2]
    i += 1
  end # end of while

  puts "unit: " + unit
  puts "resume time: " + resume_time.to_s 
  if !resume_time.empty?
    perf_data = {'name' => "Resume_time", 'value' => resume_time, 'units' => unit}  
    set_result(FrameworkConstants::Result[:pass], "Resume time is captured: "+resume_time.to_s, perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get resume time!")
  end # end of if

end

