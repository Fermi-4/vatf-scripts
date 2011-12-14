require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

$console = {"am389x-evm" => "ttyO2,115200n8","am387x-evm" => "ttyO0,115200n8"}
$stage1_bootdelay = {'am387x-evm' => 3}
$bootcmd_mmc = {}
$bootargs_mmc = {}

def setup
  $bootdelay = @equipment['dut1'].instance_variable_defined?(:@power_port) ? 3 : 0   
  # param 'kernel_from_tftp' means kernel is getting from tftp and rootfs is NFS. 
  # if kernel is not getting from tftp, then skip the default booting part. 
  # if boot media is other media other than MMCSD, more params need to be added to database to 
  #   differeniate different media such as 'kernel_fs_from_mmc','kernel_fs_from_usb',etc.
  if @test_params.params_control.kernel_from_tftp[0] == '1'
    super
  else 
    @equipment['dut1'].set_api('psp')
    connect_to_equipment('dut1')
  end
end

def run
  delay = $stage1_bootdelay.include?(@test_params.platform) ? $stage1_bootdelay[@test_params.platform] : 0
  console = $console.include?(@test_params.platform) ? $console[@test_params.platform] : "ttyO2,115200n8" 
  bootcmd_mmc = $bootcmd_mmc.include?(@test_params.platform) ? $bootcmd_mmc[@test_params.platform] : 'mmc init;fatload mmc 0 0x82000000 uImage;bootm 0x82000000'
  bootargs_mmc = $bootargs_mmc.include?(@test_params.platform) ? $bootargs_mmc[@test_params.platform] : "console=#{console}" + ' root=/dev/mmcblk0p2 rootfstype=ext3 mem=128M rootwait' 
  res = 0
  perf_data = []
  boottimes_readkernel = []
  boottimes_bootkernel = []
  boottimes_total = []

  # TODO: put them into hash mapping table for variation between different platforms or release
  #bootcmd_mmc = 'mmc init;fatload mmc 0 0x82000000 uImage;bootm 0x82000000'
  bootargs_mmc = "#{bootargs_mmc}" + ' init=/bin/sh'
  regexp1 = get_readkernel_regexp
  regexp2 = /##\s*Booting\s*kernel/
  regexp3 = /\/\s*#|login:/
 
  loop_count = @test_params.params_control.loop_count[0].to_i
  for i in (1..loop_count)  
    # set bootdelay so that it can be deducted from total boottime
    @equipment['dut1'].boot_to_bootloader(@power_handler)
    @equipment['dut1'].send_cmd("setenv bootdelay #{$bootdelay}", @equipment['dut1'].boot_prompt, 10)
    if @test_params.params_control.kernel_from_tftp[0] == '0'
      @equipment['dut1'].get_boot_cmd({'image_path' => 'mmc'}).each {|cmd|
        @equipment['dut1'].send_cmd("#{cmd}",@equipment['dut1'].boot_prompt, 10)
        raise "Timeout waiting for bootloader prompt #{@equipment['dut1'].boot_prompt}" if @equipment['dut1'].timeout?
      }
      #@equipment['dut1'].send_cmd("setenv bootcmd \'#{bootcmd_mmc}\'", @equipment['dut1'].boot_prompt, 10)
      #@equipment['dut1'].send_cmd("setenv bootargs \'#{bootargs_mmc}\'", @equipment['dut1'].boot_prompt, 10)
    end
    @equipment['dut1'].send_cmd("saveenv", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("printenv", @equipment['dut1'].boot_prompt, 10)
  
    #@power_handler.switch_off(@equipment['dut1'].power_port)
    #sleep 3
    #@power_handler.switch_on(@equipment['dut1'].power_port)
    @equipment['dut1'].send_cmd("boot", /.*/, 1, false)
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

    @equipment['dut1'].wait_for(regexp3,100)
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
      boottimes_total << time3 - time0 - $bootdelay -stage1_delay
    end
    @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10) # login to the unit
    raise 'Unable to login' if @equipment['dut1'].timeout?
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
  tftp_kernel = @test_params.params_control.kernel_from_tftp[0]
  if tftp_kernel == '1'
    rtn = /TFTP\s*from\s*server/
  else
    rtn = /reading\s*uImage/
  end
  rtn
end



