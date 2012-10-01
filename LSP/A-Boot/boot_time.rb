# The time measured by this script is time from issuing the 'boot' command
#   to seeing 'login' prompt when booting from MMCSD.
# The reason we use 'boot' instead of power cycle the board is that we want to
#   preserve the uboot env settings accross the boards in case the settings 
#   can not be saved. It is also because auto power cycle can not be performed
#   on certain board like bone.
# If we need measure the time from powercycle, we need revisit this script.
# Keeping setting bootdelay in case we need measure the time starting from 
#   powercycle.
# If the time from powercycle is not needed, then 'bootdelay' related code
#   could not removed.
#
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

$stage1_bootdelay = {'am387x-evm' => 3}


def setup
  # if boot media is other media other than MMCSD, more params need to be added to database to 
  #   differeniate different media such as 'kernel_fs_from_mmc','kernel_fs_from_usb',etc.
  @equipment['dut1'].set_api('psp')
  $bootdelay = @equipment['dut1'].instance_variable_defined?(:@power_port) ? 3 : 0
end

def run
  delay = $stage1_bootdelay.include?(@test_params.platform) ? $stage1_bootdelay[@test_params.platform] : 0
  res = 0
  perf_data = []
  boottimes_readkernel = []
  boottimes_bootkernel = []
  boottimes_total = []

  regexp1 = get_readkernel_regexp
  regexp2 = /##\s*Booting\s*kernel/
  regexp3 = /\/\s*#|login:/
 

  translated_boot_params = setup_host_side()

  #Start booting  
  begin 
  loop_count = @test_params.params_control.loop_count[0].to_i
  for i in (1..loop_count)  
      @equipment['dut1'].set_boot_cmd(translated_boot_params)
      @equipment['dut1'].send_cmd("boot", /.*/, 1)
      connect_to_equipment('dut1')
      
    time0 = Time.now
    puts "-----------------------time0 is: "+time0.to_s

    @equipment['dut1'].wait_for(regexp1,30)
    if !@equipment['dut1'].timeout?
      time1 = Time.now
      puts "-----------------------time1 is: "+time1.to_s
    else
      res += 1
      break
    end

    @equipment['dut1'].wait_for(regexp2,60)
    if !@equipment['dut1'].timeout?
      time2 = Time.now
      puts "---------------------------time2 is: "+time2.to_s
    else
      res += 1
      break
    end

    @equipment['dut1'].wait_for(regexp3,600)
    if !@equipment['dut1'].timeout?
      time3 = Time.now
      puts "---------------------------time3 is: "+time3.to_s
    else
      res += 1
      break
    end

    if res == 0   
      boottimes_readkernel <<  time2 - time1 
      boottimes_bootkernel <<  time3 - time2
      stage1_delay = $stage1_bootdelay.include?(@test_params.platform) ? $stage1_bootdelay[@test_params.platform] : 0
      puts "---------------------------stage1_delay is: " + stage1_delay.to_s
      # don't need minus bootdelay since we call 'boot' to boot instead of power cycle
      #boottimes_total << time3 - time0 - $bootdelay - stage1_delay
      boottimes_total << time3 - time0 - stage1_delay
    end
    @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10) # login to the unit
    raise 'Unable to login' if @equipment['dut1'].timeout?
  end

  end
  
  puts "Boottime-LoadKernel  is #{boottimes_readkernel}"
  puts "Boottime-BootKernel  is #{boottimes_bootkernel}"
  puts "Boottime-Total is #{boottimes_total}"
  if res == 0
    perf_data <<  {'name' => "Boottime-LoadKernel", 'value' => boottimes_readkernel, 'units' => "sec"}
    perf_data <<  {'name' => "Boottime-BootKernel", 'value' => boottimes_bootkernel, 'units' => "sec"}
    perf_data <<  {'name' => "Boottime-Total", 'value' => boottimes_total, 'units' => "sec"}
    set_result(FrameworkConstants::Result[:pass], "Boot Time are collected. Total is #{boottimes_total}",perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get boot time.")
  end

end 

def get_readkernel_regexp()
  rtn = /TFTP\s*from\s*server|reading\s*uImage/
  rtn
end



