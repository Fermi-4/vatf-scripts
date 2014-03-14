# This script is used to measure the resume time after suspend/standby
# The resume time will be saved into performance table

require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

def setup
  self.as(LspTestScript).setup

  # Add multimeter to result logs
  add_equipment('multimeter1') do |log_path|
    KeithleyMultiMeterDriver.new(@equipment['dut1'].params['multimeter1'],log_path)
  end
  # Connect to multimeter
  @equipment['multimeter1'].connect({'type'=>'serial'})
end

def run
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'

  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name))

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

  test_loop = @test_params.params_control.test_loop[0].to_i
  params = {'platform' => @equipment['dut1'].name}
  @equipment['dut1'].send_cmd('uname -r', @equipment['dut1'].prompt)
  params['version'] = @equipment['dut1'].response.match(/^([\d\.]+)/i).captures[0]
  expected_volt_reductions = get_expected_volt_reductions(params)
  if !expected_volt_reductions
    set_result(FrameworkConstants::Result[:pass], "Nothing to validate. If required define requirement at evms_data.rb file") 
    return
  end

  i = 0
  resume_wtime = 60
  while i < test_loop do
    puts "GOING TO SUSPEND DUT"
    @equipment['dut1'].send_cmd("sync; echo #{power_state} > /sys/power/state", /Freezing remaining freezable tasks/, 120, false)
    if @equipment['dut1'].timeout?
      puts "Timeout while waiting to suspend"
      raise "DUT took more than 120 seconds to suspend"
    end
    sleep 2 # Let system reach deep sleep state
    #Measure voltage
    volt_readings = @equipment['multimeter1'].get_multimeter_output(3, @test_params.params_equip.timeout[0].to_i)
    #Compare measured against expected
    expected_volt_reductions.each {|domain,volt|
      # Allows 2.5% deviation from theoretical value
      max_measured_volt = volt_readings["domain_" + domain  + "_volt_readings"].max
      if  max_measured_volt > (volt*1.025)
        set_result(FrameworkConstants::Result[:fail], "On iteration #{i}, Measured voltage #{max_measured_volt} for #{domain} domain is higher than expected #{volt}")
        @equipment['dut1'].send_cmd("\n", @equipment['dut1'].prompt, resume_wtime)  
        return
      end
    }

    # Resume from console
    puts "GOING TO RESUME DUT"
    @equipment['dut1'].send_cmd("\n", @equipment['dut1'].prompt, resume_wtime)  
    if @equipment['dut1'].timeout?
      raise "DUT took more than #{resume_wtime} seconds to resume"
    end
    sleep 2 # Stay awake couple of seconds

    i += 1
  end # end of while
  set_result(FrameworkConstants::Result[:pass], "Expected voltage reductions achieved")

end

