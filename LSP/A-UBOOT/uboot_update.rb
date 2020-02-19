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
      this_boot_params['dut'].send_cmd("env default -a -f", boot_params['dut'].boot_prompt, 10)
      this_boot_params['dut'].send_cmd("setenv bootdelay 5", boot_params['dut'].boot_prompt, 10)
      this_boot_params['dut'].send_cmd("saveenv", boot_params['dut'].boot_prompt, 10)
    end

    puts "=============boot params============="
    boot_params.each{|k,v| puts "#{k}:#{v}"}

    mmcdev_nums = get_uboot_mmcdev_mapping()
    boot_params['mmcdev'] = boot_params['primary_bootloader_dev'] == 'mmc'? "#{mmcdev_nums['mmc']}" : "#{mmcdev_nums['emmc']}"
    boot_params['dut'].set_systemloader(boot_params.merge({'systemloader_class' => SystemLoader::UbootFlashBootloaderSystemLoader}))
    boot_params['dut'].system_loader.run(boot_params)

    # For J7, write 2 firmwares to <rootfs>/lib/firmware in SD card
    # j7-main-r5f0_0-fw and j7-mcu-r5f0_0-fw
    if boot_params['dut'].name =~ /j7/ and boot_params['fs'] != ''
      f1 = "j7-main-r5f0_0-fw"
      f2 = "j7-mcu-r5f0_0-fw"
      tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
      untar_path = File.join(boot_params['server'].tftp_path, tmp_path)
      untar_dir(boot_params, boot_params['fs'], '/lib/firmware', untar_path)
      fix_symlink(boot_params, "#{untar_path}/lib/firmware", f1)
      f1_size = tftp_file(boot_params, "#{tmp_path}/lib/firmware/#{f1}")
      ext4write_to_mmc(boot_params, mmcdev_nums['mmc'], f1, f1_size)
      fix_symlink(boot_params, "#{untar_path}/lib/firmware", f2)
      f2_size = tftp_file(boot_params, "#{tmp_path}/lib/firmware/#{f2}")
      ext4write_to_mmc(boot_params, mmcdev_nums['mmc'], f2, f2_size)
    end
  
    # For J6/am5, write firmwares to boot partition in SD card
    # dra7-ipu1-fw.xem4
    if boot_params['dut'].name =~ /dra7|am5/ and boot_params['fs'] != ''
      f1 = "dra7-ipu1-fw.xem4"
      tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
      untar_path = File.join(boot_params['server'].tftp_path, tmp_path)
      untar_dir(boot_params, boot_params['fs'], '/lib/firmware', untar_path)
      fix_symlink(boot_params, "#{untar_path}/lib/firmware", f1)
      f1_size = tftp_file(boot_params, "#{tmp_path}/lib/firmware/#{f1}")
      fatwrite_to_mmc(boot_params, mmcdev_nums['mmc'], f1, f1_size)
      boot_params['dut'].send_cmd("ls mmc #{mmcdev_nums['mmc']}", boot_params['dut'].boot_prompt, 10)
    end

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

def ext4write_to_mmc(params, mmcdev, f, size)
  params['dut'].send_cmd("ext4write mmc #{mmcdev}:2 ${loadaddr} /lib/firmware/#{f} #{size}", params['dut'].boot_prompt, 60)
  raise "Failed to ext4write #{f} to mmcdev #{mmcdev}" if !params['dut'].response.match(/written/i)
end

# fatwrite <interface> <dev[:part]> <addr> <filename> [<bytes> [<offset>]]
def fatwrite_to_mmc(params, mmcdev, f, size)
  params['dut'].send_cmd("fatwrite mmc #{mmcdev}:1 ${loadaddr} #{f} #{size}", params['dut'].boot_prompt, 60)
  raise "Failed to fatwrite #{f} to mmcdev #{mmcdev}" if !params['dut'].response.match(/written/i)
end

def fix_symlink(params, dir, f)
  if File.symlink?("#{dir}/#{f}")
    #params['server'].send_cmd("cd #{dir}", params['server'].prompt, 5)
    syml = File.readlink("#{dir}/#{f}").sub("/lib/firmware/", "")
    params['server'].send_cmd("cd #{dir}; ln -sf #{syml} #{f}; ls -l #{f}", params['server'].prompt, 10)
    #params['server'].send_cmd("ls -l #{f}", params['server'].prompt, 10)
    params['server'].send_cmd("cd -", params['server'].prompt, 5)
    raise "The file #{dir}/#{f} does not have valid symlink" if !File.exist?("#{dir}/#{f}")
  end 
end

def untar_dir(params, tarball, dir, dst_dir)
  tar_options = get_tar_options(tarball, params)
  #tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  params['server'].send_cmd("rm -rf #{dst_dir}#{dir}", params['server'].prompt, 120)
  params['server'].send_cmd("tar -C #{dst_dir} #{tar_options} #{tarball} .#{dir}", params['server'].prompt, 120)
  raise "Error extracting tarball" if params['server'].response.match(/tar:.*error/i)
  params['server'].send_cmd("ls -l #{dst_dir}#{dir}", params['server'].prompt, 10)
end

def tftp_file(params, filepath_in_tftp)
  params['dut'].send_cmd("setenv serverip #{params['server'].telnet_ip}", params['dut'].boot_prompt, 5)
  params['dut'].send_cmd("setenv autoload no", params['dut'].boot_prompt, 5)
  3.times {
    params['dut'].send_cmd("dhcp", /DHCP client bound to address.*#{params['dut'].boot_prompt}/im, 30)
    break if !params['dut'].timeout?
  }

  params['dut'].send_cmd("tftp ${loadaddr} #{filepath_in_tftp}", params['dut'].boot_prompt, 300)
  raise "Could not tftp file to dut" if !params['dut'].response.match(/Bytes\s+transferred/im)
  params['dut'].send_cmd("print filesize", params['dut'].boot_prompt, 10)
  size = /filesize\s*=\s*(\h+)/im.match(@equipment['dut1'].response).captures[0]
  return size
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

    new_params['initial_bootloader'] = new_params['pre_initial_bootloader'] ? new_params['pre_initial_bootloader'] :
                             @test_params.instance_variable_defined?(:@pre_initial_bootloader) ? @test_params.pre_initial_bootloader :
                             ''
    new_params['initial_bootloader_dev']   = new_params['pre_initial_bootloader_dev'] ? new_params['pre_initial_bootloader_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pre_initial_bootloader_dev) ? @test_params.params_chan.pre_initial_bootloader_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pre_initial_bootloader_dev) ? @test_params.var_pre_initial_bootloader_dev : "mmc"

    new_params['initial_bootloader_image_name'] = new_params['pre_initial_bootloader_image_name'] ? new_params['pre_initial_bootloader_image_name'] :
                             @test_params.instance_variable_defined?(:@var_pre_initial_bootloader_image_name) ? @test_params.var_pre_initial_bootloader_image_name :
                             new_params['initial_bootloader'] != '' ? File.basename(new_params['initial_bootloader']) : 'tiboot3.bin'

    new_params['sysfw'] = new_params['pre_sysfw'] ? new_params['pre_sysfw'] :
                             @test_params.instance_variable_defined?(:@pre_sysfw) ? @test_params.pre_sysfw :
                             ''
    new_params['sysfw_dev']   = new_params['pre_sysfw_dev'] ? new_params['pre_sysfw_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pre_sysfw_dev) ? @test_params.params_chan.pre_sysfw_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pre_sysfw_dev) ? @test_params.var_pre_sysfw_dev : "mmc"

    new_params['sysfw_image_name'] = new_params['pre_sysfw_image_name'] ? new_params['pre_sysfw_image_name'] :
                             @test_params.instance_variable_defined?(:@var_pre_sysfw_image_name) ? @test_params.var_pre_sysfw_image_name :
                             new_params['sysfw'] != '' ? File.basename(new_params['sysfw']) : 'sysfw.itb'

    new_params
end
