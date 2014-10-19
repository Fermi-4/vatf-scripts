# This script will measure the below time 
#
#   "Boottime-LoadSPL": from powercycle to 'SPL'
#   "Boottime-LoadUboot": from 'U-boot SPL' to 'U-boot'
#   "Boottime-LoadKernel": from 'boot' cmd to 'Starting Linux...'
#   "Boottime-InitKernel": from 'Starting' to 'INIT: Version'
#   "Boottime-InitFS": from 'INIT:" to 'login'
#   "Boottime-Total": all the time together
#
#
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

$stage1_bootdelay = {'am387x-evm' => 3}

def setup
  @equipment['dut1'].set_api('psp')
end

def run
  res = 0
  perf_data = []

  boottimes_load_spl = []     # from powercycle to 'SPL'
  boottimes_load_uboot = []   # from 'U-boot SPL' to 'U-boot'
  boottimes_load_kernel = []  # from 'boot' cmd to 'Starting Linux...'
  boottimes_initialize_kernel = []  # from 'Starting' to 'INIT: Version'
  boottimes_initialize_fs = []  # from 'INIT' to 'login'
  boottimes_total = []

  regex_spl = /U-Boot\s+SPL|SPL:/
  regex_uboot = /U-Boot\s+[\d.]+/
  regex_startkernel = /Starting\s+kernel/
  regex_startfs = /INIT:\s+version/
  regex_doneboot = /sh[\d+.-]+\s*#|login:/

  delay = $stage1_bootdelay.include?(@test_params.platform) ? $stage1_bootdelay[@test_params.platform] : 0
  skip_bootloader_time = @test_params.params_control.instance_variable_defined?(:@skip_bootloader_time) ? @test_params.params_control.skip_bootloader_time[0].downcase : 'no'

  translated_boot_params = setup_host_side()
  bootargs_append = translated_boot_params.has_key?('bootargs_append') ? translated_boot_params['bootargs_append'] : ''
  skip_fs = bootargs_append.include?("init=") ? true : false 

  #Start booting  
  begin 
  loop_count = @test_params.params_control.loop_count[0].to_i
  for i in (1..loop_count)  

    @equipment['dut1'].power_cycle(translated_boot_params)
    connect_to_equipment('dut1')
  
    if skip_bootloader_time == 'no'
      time_start = Time.now
      #@equipment['dut1'].log_info( "-----------------------time_start is: "+time_start.to_s)
      @equipment['dut1'].send_cmd("", regex_spl, 60)
      
      if !@equipment['dut1'].timeout?
        time_spl = Time.now
        puts ( "---------------------------time_spl is: "+time_spl.to_s)
        #@equipment['dut1'].log_info( "---------------------------time_spl is: "+time_spl.to_s)
      else
        res += 1
        break
      end

      @equipment['dut1'].send_cmd("", regex_uboot, 60)

      if !@equipment['dut1'].timeout?
        time_uboot = Time.now
        puts ( "---------------------------time_uboot is: "+time_uboot.to_s)
        #@equipment['dut1'].log_info( "---------------------------time_uboot is: "+time_uboot.to_s)
      else
        res += 1
        break
      end
    end
    @equipment['dut1'].stop_boot()
    set_uboot_env(translated_boot_params)

    time_bootcmd = Time.now
    #@equipment['dut1'].log_info( "-----------------------time_bootcmd is: "+time_bootcmd.to_s)
    @equipment['dut1'].send_cmd("boot", regex_startkernel, 30)
    if !@equipment['dut1'].timeout?
      time_initkernel = Time.now
      #@equipment['dut1'].log_info( "---------------------------time_initkernel is: "+time_initkernel.to_s)
    else
      res += 1
      break
    end

    if !skip_fs 
      @equipment['dut1'].wait_for(regex_startfs,60)
      if !@equipment['dut1'].timeout?
        time_initfs = Time.now
        #@equipment['dut1'].log_info( "---------------------------time_initfs is: "+time_initfs.to_s)
      else
        res += 1
        break
      end
    end

    @equipment['dut1'].wait_for(regex_doneboot,60)
    if !@equipment['dut1'].timeout?
      time_doneboot = Time.now
      #@equipment['dut1'].log_info( "---------------------------time_doneboot is: "+time_doneboot.to_s)
    else
      res += 1
      break
    end

    if res == 0   
      if skip_bootloader_time == 'no'
        boottimes_load_spl << time_spl - time_start
        boottimes_load_uboot << time_uboot - time_spl
      end
      boottimes_load_kernel << time_initkernel - time_bootcmd
      if skip_fs
        boottimes_initialize_kernel << time_doneboot - time_initkernel
      else
        boottimes_initialize_kernel << time_initfs - time_initkernel
        boottimes_initialize_fs << time_doneboot - time_initfs
      end

      stage1_delay = $stage1_bootdelay.include?(@test_params.platform) ? $stage1_bootdelay[@test_params.platform] : 0
      #@equipment['dut1'].log_info( "---------------------------stage1_delay is: " + stage1_delay.to_s)

      
      if skip_bootloader_time == 'no'
        boottimes_total << (time_doneboot - time_bootcmd) + (time_uboot - time_start) - stage1_delay
      else
        boottimes_total << (time_doneboot - time_bootcmd)
      end
    end
  end

  end
  
  if skip_bootloader_time == 'no'
    @equipment['dut1'].log_info( "Boottime-LoadSPL  is #{boottimes_load_spl}")
    @equipment['dut1'].log_info( "Boottime-LoadUboot  is #{boottimes_load_uboot}")
  end
  @equipment['dut1'].log_info( "Boottime-LoadKernel  is #{boottimes_load_kernel}")
  @equipment['dut1'].log_info( "Boottime-InitKernel  is #{boottimes_initialize_kernel}")
  @equipment['dut1'].log_info( "Boottime-InitFS  is #{boottimes_initialize_fs}") if !skip_fs
  @equipment['dut1'].log_info( "Boottime-Total is #{boottimes_total}")
  if res == 0
    if skip_bootloader_time == 'no'
      perf_data <<  {'name' => "Boottime-LoadSPL", 'value' => boottimes_load_spl, 'units' => "sec"}
      perf_data <<  {'name' => "Boottime-LoadUboot", 'value' => boottimes_load_uboot, 'units' => "sec"}
    end
    perf_data <<  {'name' => "Boottime-LoadKernel", 'value' => boottimes_load_kernel, 'units' => "sec"}
    perf_data <<  {'name' => "Boottime-InitKernel", 'value' => boottimes_initialize_kernel, 'units' => "sec"}
    perf_data <<  {'name' => "Boottime-InitFS", 'value' => boottimes_initialize_fs, 'units' => "sec"} if !skip_fs
    perf_data <<  {'name' => "Boottime-Total", 'value' => boottimes_total, 'units' => "sec"}
    set_result(FrameworkConstants::Result[:pass], "Boot Time are collected. Total is #{boottimes_total}. ",perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get boot time.")
  end

end 

# Set uboot env variable through systemloader and add extraargs if needed
def set_uboot_env(params)
    params.each{|k,v| puts "#{k}:#{v}"}

    params['bootargs'] = @equipment['dut1'].boot_args if !params['bootargs']
    @equipment['dut1'].set_systemloader(params) if !@equipment['dut1'].system_loader
    @equipment['dut1'].system_loader.remove_step('boot')
    @equipment['dut1'].system_loader.run params

end
