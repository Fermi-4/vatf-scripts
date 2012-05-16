require File.dirname(__FILE__)+'/../lib/plot'

include TestPlots

module StarterwareDefault
  
  def setup
    params= {'primary_bootloader'   => @test_params.primary_bootloader,
             'secondary_bootloader' => File.join(@test_params.var_apps_dir, @test_params.params_chan.app[0]),
             'boot_device'          => @test_params.var_boot_device,
             'server'               => @equipment['server1'],
             'power_handler'        => @power_handler,
             'staf_service_name'    => @test_params.staf_service_name.to_s
            }
    @equipment['dut1'].boot(params)
    sleep 3
  end

  def run
    result = 0
    @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
    @test_params.params_chan.commands.each {|cmd|
      send=cmd.split('::')[0]
      expect=cmd.split('::')[1].to_s == '' ? /#{cmd.split('::')[1]}/ : /\|RESULT\|PASS\|/
      timeout= cmd.split('::')[2] ? cmd.split('::')[2].to_i : 10         # default timeout is 10 secs 
      @equipment['dut1'].send_cmd(send+"\r\n", expect, timeout)
      if @equipment['dut1'].timeout?
        result = 1
        set_result(FrameworkConstants::Result[:fail], "Command:#{send} did not return expected text:#{expect.to_s}")
        break
      end
    }
    set_result(FrameworkConstants::Result[:pass], "Test Pass.") if result == 0
  end

  def clean
  end

end
