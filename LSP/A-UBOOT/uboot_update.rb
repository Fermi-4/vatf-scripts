# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript   
#include PlatformSpecificVarNames

def setup
  #self.as(LspTestScript).setup
	@equipment['dut1'].set_api('psp')
end

def run
  result = 0
  boot_params = setup_host_side()
  boot_params.each{|k,v| puts "#{k}:#{v}"}

  flash_bootloader = @test_params.params_chan.instance_variable_defined?(:@flash_bootloader) ? @test_params.params_chan.flash_bootloader[0].downcase :
                     @test_params.instance_variable_defined?(:@var_flash_bootloader) ? @test_params.var_flash_bootloader :  'no'
  flash_kernel = @test_params.params_chan.instance_variable_defined?(:@flash_kernel) ? @test_params.params_chan.flash_kernel[0].downcase : 'no'
  flash_fs = @test_params.params_chan.instance_variable_defined?(:@flash_fs) ? @test_params.params_chan.flash_fs[0].downcase : 'no'
  verify_fs_ok = @test_params.instance_variable_defined?(:@var_verify_fs_ok) ? @test_params.var_verify_fs_ok.downcase : 'no'
  pre_boot = @test_params.instance_variable_defined?(:@var_pre_boot) ? @test_params.var_pre_boot.downcase : 'no'

  if flash_bootloader == 'yes'
    this_boot_params = boot_params
    if pre_boot != 'no'
      this_boot_params = set_pre_params(boot_params)
      puts "=============preboot params============="
      this_boot_params.each{|k,v| puts "#{k}:#{v}"}
    end

    this_boot_params['dut'].set_bootloader(this_boot_params) 
    this_boot_params['dut'].boot_loader.run(this_boot_params)

    if pre_boot != 'no'
      #this_boot_params['dut'].send_cmd("env default -a -f", boot_params['dut'].boot_prompt, 10)
      this_boot_params['dut'].send_cmd("setenv bootdelay 5", boot_params['dut'].boot_prompt, 10)
      this_boot_params['dut'].send_cmd("saveenv", boot_params['dut'].boot_prompt, 10)
    end

    puts "=============boot params============="
    boot_params.each{|k,v| puts "#{k}:#{v}"}

    mmcdev_nums = get_uboot_mmcdev_mapping()
    boot_params['mmcdev'] = boot_params['primary_bootloader_dev'] == 'mmc'? "#{mmcdev_nums['mmc']" : "#{mmcdev_nums['emmc']"
    boot_params['dut'].set_systemloader(boot_params.merge({'systemloader_class' => SystemLoader::UbootFlashBootloaderSystemLoader}))
    boot_params['dut'].system_loader.run(boot_params)
  
    # Verify if the board can boot using the updated bootloader
    10.times {puts "Please change the switch setting to boot from #{boot_params['primary_bootloader_dev']}!!!"}
    sleep 10
    # powercycle or reset the board to check
    boot_params['dut'].boot_loader = nil
    boot_params['dut'].boot_to_bootloader(boot_params)
    boot_params['dut'].send_cmd("env default -a -f", boot_params['dut'].boot_prompt, 10)
    boot_params['dut'].send_cmd("setenv bootdelay 5", boot_params['dut'].boot_prompt, 10)
    boot_params['dut'].send_cmd("saveenv", boot_params['dut'].boot_prompt, 10)
    boot_params['dut'].send_cmd("version", boot_params['dut'].boot_prompt, 10)
    result += 1 if boot_params['dut'].timeout? 
  end 
  
  if flash_kernel == 'yes'
    boot_params['dut'].system_loader = nil
    boot_params['dut'].update_kernel(boot_params)
  end

  if flash_fs == 'yes'
    boot_params['dut'].system_loader = nil
    boot_params['dut'].update_fs(boot_params)
  end
  
  # check if dut bootup ok using updated kernel or fs
  if verify_fs_ok == 'yes'
    if flash_kernel == 'yes' or flash_fs == 'yes'
      boot_params['fs_dev'] = ''  # to prevent fs got flashed again when calling 'boot'
      boot_params['dut'].system_loader = nil
      boot_params['dut'].boot(boot_params)

      # check if the kernel boot up ok.
      boot_params['dut'].send_cmd("uname -a", boot_params['dut'].prompt, 10)
      result += 1 if boot_params['dut'].timeout?
    end
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test fail")
  end  

end 

def set_pre_params(params)
    new_params = params.clone
    new_params['primary_bootloader'] = new_params['pre_primary_bootloader'] ? new_params['pre_primary_bootloader'] :
                             @test_params.instance_variable_defined?(:@pre_primary_bootloader) ? @test_params.pre_primary_bootloader :
                             ''
    new_params['secondary_bootloader'] = new_params['pre_secondary_bootloader'] ? new_params['pre_secondary_bootloader'] :
                             @test_params.instance_variable_defined?(:@pre_secondary_bootloader) ? @test_params.pre_secondary_bootloader :
                             ''
    new_params['primary_bootloader_dev']   = new_params['pre_primary_bootloader_dev'] ? new_params['pre_primary_bootloader_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pre_primary_bootloader_dev) ? @test_params.params_chan.pre_primary_bootloader_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pre_primary_bootloader_dev) ? @test_params.var_pre_primary_bootloader_dev : "mmc"
    new_params['secondary_bootloader_dev']   = new_params['pre_secondary_bootloader_dev'] ? new_params['pre_secondary_bootloader_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pre_secondary_bootloader_dev) ? @test_params.params_chan.pre_secondary_bootloader_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pre_secondary_bootloader_dev) ? @test_params.var_pre_secondary_bootloader_dev : "mmc"
    new_params['primary_bootloader_src_dev']   = new_params['pre_primary_bootloader_src_dev'] ? new_params['pre_primary_bootloader_src_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pre_primary_bootloader_src_dev) ? @test_params.params_chan.pre_primary_bootloader_src_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pre_primary_bootloader_src_dev) ? @test_params.var_pre_primary_bootloader_src_dev :
                             new_params['primary_bootloader'] != '' ? 'eth' : 'none'

    new_params['secondary_bootloader_src_dev']   = new_params['pre_secondary_bootloader_src_dev'] ? new_params['pre_secondary_bootloader_src_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pre_secondary_bootloader_src_dev) ? @test_params.params_chan.pre_secondary_bootloader_src_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pre_secondary_bootloader_src_dev) ? @test_params.var_pre_secondary_bootloader_src_dev :
                             new_params['secondary_bootloader'] != '' ? 'eth' : 'none'

    new_params['primary_bootloader_image_name'] = new_params['pre_primary_bootloader_image_name'] ? new_params['pre_primary_bootloader_image_name'] :
                             @test_params.instance_variable_defined?(:@var_pre_primary_bootloader_image_name) ? @test_params.var_pre_primary_bootloader_image_name :
                             new_params['primary_bootloader'] != '' ? File.basename(new_params['primary_bootloader']) : 'MLO'

    new_params['secondary_bootloader_image_name'] = new_params['pre_secondary_bootloader_image_name'] ? new_params['pre_secondary_bootloader_image_name'] :
                             @test_params.instance_variable_defined?(:@var_pre_secondary_bootloader_image_name) ? @test_params.var_pre_secondary_bootloader_image_name :
                             new_params['secondary_bootloader'] != '' ? File.basename(new_params['secondary_bootloader']) : 'u-boot.img'


    new_params
end
