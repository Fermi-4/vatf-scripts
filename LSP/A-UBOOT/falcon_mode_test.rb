# -*- coding: ISO-8859-1 -*-
# This application can be used to test block device boot including qspi, spi, mmc, emmc, usbhost etc
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/utils'
   
include LspTestScript   

def setup
	@equipment['dut1'].set_api('psp')
  install_fdtput()
end

def run
  result = 0
  result_msg = ''
  # boot_media: fat-mmc raw-emmc qspi
  boot_media = @test_params.params_chan.boot_media[0].downcase
  raise "This boot_media: #{boot_media} is not supported" if (boot_media != "fat-mmc" && boot_media != "raw-emmc" && boot_media != "qspi")
  
  this_params = {}
  set_bootloader_devs(this_params, boot_media)
  bparams = setup_host_side(this_params)
  bparams.each{|k,v| puts "#{k}:#{v}"}
  if bparams['secondary_bootloader'].strip == '' 
    raise "Bootloaders are not provided"
  end
  if bparams['dtb'].strip == '' 
    raise "DTB is not provided"
  end
  if bparams['kernel'].strip == ''
    raise "Kernel uImage is not provided"
  end

  # modify dtb to add needed bootargs
  @equipment['server1'].send_cmd("fdtput -v -t s #{File.join(@equipment['server1'].tftp_path, bparams['dtb_image_name'])} \"/chosen\" bootargs #{bparams['dut'].boot_args} ")

  puts "Updating bootloader, kernel and dtb..."

  bparams['primary_bootloader_dev'] = 'mmc' # So the board just power cycle
  puts "=============boot params for bootloader============="
  bparams.each{|k,v| puts "#{k}:#{v}"}
  bparams['dut'].set_bootloader(bparams)
  bparams['dut'].boot_loader.run(bparams)

  use_dfu = @test_params.params_chan.instance_variable_defined?(:@use_dfu) ? @test_params.params_chan.use_dfu[0].downcase : '0'
  if use_dfu == '1'
    load_images_to_media_via_dfu(bparams, boot_media)
    if boot_media == 'fat-mmc'
      bparams['dut'].send_cmd("setenv falcon_image_file spl-os-image", bparams['dut'].boot_prompt, 5)
      bparams['dut'].send_cmd("setenv falcon_args_file spl-os-args", bparams['dut'].boot_prompt, 5)
    end
  else
    set_bootloader_devs(bparams, boot_media)
    puts "=============boot params for systemloader============="
    bparams.each{|k,v| puts "#{k}:#{v}"}
    bparams['dut'].set_systemloader(bparams.merge({'systemloader_class' => SystemLoader::UbootFlashBootloaderKernelSystemLoader}))
    bparams['dut'].system_loader.run(bparams)
  end

  bparams['dut'].send_cmd("setenv boot_os 1", bparams['dut'].boot_prompt, 5)
  bparams['dut'].send_cmd("saveenv", bparams['dut'].boot_prompt, 5)
  #By now, all images should be flashed into qspi. 
  # Change to qspi boot, then power cycle
  begin

    # Verify if the board can boot using the updated bootloader
    sleep 2
    boot_media_name = translate_boot_media(boot_media)
    bparams['dut'].set_sysboot(bparams['dut'], boot_media_name)
    bparams['dut'].power_cycle(bparams)
    bparams['dut'].connect({'type'=>'serial'})
    bparams['dut'].wait_for(/Booting\s+linux.*kernel\s+command\s+line:.*/im)
    raise "The DUT did not boot to kernel" if bparams['dut'].timeout?
    raise "Should not go to UBoot in Falcon mode." if bparams['dut'].response.match(/Hit\s+any\s+key\s+to\s+stop\s+autoboot/i)
    bparams['dut'].wait_for(bparams['dut'].login_prompt, 5) # just to collect more log; do not expect to see login prompt

  ensure

    # reset the board while keeping 'c' key so the board can enter u-boot
    bparams['dut'].reset_sysboot(bparams['dut'])
    bparams['dut'].power_cycle(bparams)
    bparams['dut'].connect({'type'=>'serial'})

    60.times {
      bparams['dut'].send_cmd("c", bparams['dut'].boot_prompt, 0.5)
      break if !bparams['dut'].timeout?
    }

    #bparams['dut'].boot_loader = nil
    #bparams['primary_bootloader_dev'] = 'mmc' # So the board just power cycle
    #bparams['dut'].set_bootloader(bparams)
    #bparams['dut'].boot_loader.run(bparams)

    bparams['dut'].send_cmd("setenv boot_os 0", bparams['dut'].boot_prompt, 5)
    bparams['dut'].send_cmd("saveenv", bparams['dut'].boot_prompt, 5)
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test fail! "+result_msg)
  end  

end 

def translate_boot_media(boot_media)
  case boot_media
    when /emmc/
      name = "emmc"
    when /fat-mmc|raw-mmc/i
      name = "mmc"
    else
      name = boot_media
  end
  name
end

def load_images_to_media_via_dfu(params, boot_media)
  usb_controller = get_usb_gadget_number(params['dut'].name)
  interface, dev = get_dfu_interface(boot_media) 

  alt_name_mlo, alt_name_uboot, alt_name_dtb, alt_name_kernel = get_dfu_alt_names(boot_media)

  # set dfu env 
  params['dut'].send_cmd("version", params['dut'].boot_prompt, 5)
  params['dut'].send_cmd("setenv dfu_alt_info ${dfu_alt_info_mmc}", params['dut'].boot_prompt, 5) if boot_media.match(/-mmc/i)
  # since typically eMMC doesn't have partitions, so if setting dfu-alt_info to dfu_alt_info_emmc which has "boot part 1 1;rootfs part 1 2", 
  # there would cause 'dfu configuration fail'. So set it to only contain raw info
  if boot_media.match(/raw-emmc/i)
    dfu_alt_info_rawemmc = "\"MLO.raw raw 0x100 0x100;u-boot.img.raw raw 0x300 0x1000;u-env.raw raw 0x1300 0x200;spl-os-args.raw raw 0x1500 0x200;spl-os-image.raw raw 0x1700 0x6900\""
    params['dut'].send_cmd("setenv dfu_alt_info #{dfu_alt_info_rawemmc}", params['dut'].boot_prompt, 5) 
  end
  params['dut'].send_cmd("setenv dfu_alt_info ${dfu_alt_info_qspi}", params['dut'].boot_prompt, 5) if boot_media.match(/qspi/i)
  params['dut'].send_cmd("print dfu_alt_info", params['dut'].boot_prompt, 5)


  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  images_dir = File.join(@equipment['server1'].tftp_path, tmp_path)

  # download mlo
  start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
    host_dfu_download_image("#{images_dir}/#{File.basename(params['primary_bootloader_image_name'])}", alt_name_mlo)
  end
  # send ctrl+c to back to uboot prompt
  params['dut'].send_cmd("\x3", params['dut'].boot_prompt, 5)

  sleep 1
  # download u-boot.img
  start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
    host_dfu_download_image("#{images_dir}/#{File.basename(params['secondary_bootloader_image_name'])}", alt_name_uboot)
  end
  # send ctrl+c to back to uboot prompt
  params['dut'].send_cmd("\x3", params['dut'].boot_prompt, 5)

  sleep 1
  # download spl-os-args which is dtb
  start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
    host_dfu_download_image("#{images_dir}/#{File.basename(params['dtb_image_name'])}", alt_name_dtb)
  end
  # send ctrl+c to back to uboot prompt
  params['dut'].send_cmd("\x3", params['dut'].boot_prompt, 5)

  sleep 1
  # download spl-os-image which is kernel
  start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
    host_dfu_download_image("#{images_dir}/#{File.basename(params['kernel_image_name'])}", alt_name_kernel)
  end
  # send ctrl+c to back to uboot prompt
  params['dut'].send_cmd("\x3", params['dut'].boot_prompt, 5)
end

def clean
  puts "cleaning..."
  #@equipment['dut1'].reset_sysboot(@equipment['dut1'])
end


def set_bootloader_devs(params, media)
  bootloader_dev = media 
  params['primary_bootloader_dev'] = bootloader_dev
  params['secondary_bootloader_dev'] = bootloader_dev
  params['dtb_dev'] = bootloader_dev
  params['kernel_dev'] = bootloader_dev
end

# dfu related

# alt_names comes from the uboot env variables. See below example
  #dfu_alt_info_emmc=rawemmc raw 0 3751936;boot part 1 1;rootfs part 1 2;MLO fat 1 1;MLO.raw raw 0x100 0x100;u-boot.img.raw raw 0x300 0x1000;u-env.raw raw 0x1300 0x200;spl-os-args.raw raw 0x1500 0x200;spl-os-image.raw raw 0x1700 0x6900;spl-os-args fat 1 1;spl-os-image fat 1 1;u-boot.img fat 1 1;uEnv.txt fat 1 1
  #dfu_alt_info_mmc=boot part 0 1;rootfs part 0 2;MLO fat 0 1;MLO.raw raw 0x100 0x100;u-boot.img.raw raw 0x300 0x1000;u-env.raw raw 0x1300 0x200;spl-os-args.raw raw 0x1500 0x200;spl-os-image.raw raw 0x1700 0x6900;spl-os-args fat 0 1;spl-os-image fat 0 1;u-boot.img fat 0 1;uEnv.txt fat 0 1
  #dfu_alt_info_qspi=MLO raw 0x0 0x040000;u-boot.img raw 0x040000 0x0100000;u-boot-spl-os raw 0x140000 0x080000;u-boot-env raw 0x1C0000 0x010000;u-boot-env.backup raw 0x1D0000 0x010000;kernel raw 0x1E0000 0x800000
def get_dfu_alt_names(media)
  case media
    when "fat-mmc", "qspi"
      alt_name_mlo = "MLO"
      alt_name_uboot = "u-boot.img"
      alt_name_dtb = "spl-os-args"
      alt_name_kernel = "spl-os-image"
    when "raw-emmc"
      alt_name_mlo = "MLO.raw"
      alt_name_uboot = "u-boot.img.raw"
      alt_name_dtb = "spl-os-args.raw"
      alt_name_kernel = "spl-os-image.raw"
    else
      raise "There is no defined alt_name for media: #{media}"
  end
  [alt_name_mlo, alt_name_uboot, alt_name_dtb, alt_name_kernel]

end

def get_dfu_interface(media)
  case media
  when /-mmc/
    interface = 'mmc'
    dev = 0
  when /-emmc/
    interface = 'mmc'
    dev = 1
  when /qspi/
    interface = 'sf 0:0'
  when /ram/
    interface = 'ram'
    dev = 0
  else
    interface = media
    dev = 0
  end
  [interface, dev]
end

def start_dfu_on_target(cmd, exp1, exp2)
  Thread.abort_on_exception = true
  thr = Thread.new {
    @equipment['dut1'].send_cmd(cmd, exp1, 20)
    raise "DFU could not be started, Check if the usb cable was connected to host pc." if @equipment['dut1'].timeout?
    @equipment['dut1'].wait_for(exp2, 120)
    raise "Did not get expected string; Downloading failed" if @equipment['dut1'].timeout?
    @equipment['dut1'].response
  }
  yield
  rtn = thr.value
end

def host_dfu_download_image(image, alt_name)
  sleep 10 #make sure the target thread dfu command was executed
  raise "host_dfu_download_image: File #{image} doesn't exist" if ! File.exist?(image)
  @equipment['server1'].send_sudo_cmd("dfu-util -l", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("dfu-util -D #{image} -a #{alt_name}", "Done!", 120)
  raise "Downloading data from PC to DFU device failed!" if ! @equipment['server1'].response.match(/(Starting\s+download:.*finished!)|(Download\s+done)/i)
end

# install dfu-util if it is not in host
def install_dfu_util()
  @equipment['server1'].send_cmd("which dfu-util; echo $?", /^0[\0\n\r]+/im, 2)
  @equipment['server1'].send_sudo_cmd("apt-get install dfu-util", @equipment['server1'].prompt, 600) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("which dfu-util; echo $?", /^0[\0\n\r]+/im, 5)
  raise "dfu-util is not installed!" if @equipment['server1'].timeout?
end

# install  if it is not in host
def install_fdtput()
  @equipment['server1'].send_cmd("which fdtput; echo $?", /^0[\0\n\r]+/im, 2)
  @equipment['server1'].send_sudo_cmd("apt-get install device-tree-compiler", @equipment['server1'].prompt, 600) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("which fdtput; echo $?", /^0[\0\n\r]+/im, 5)
  raise "fdtput is not installed!" if @equipment['server1'].timeout?
end

def copy_with_path(src, dst)
  if File.exist?(src)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  else
    raise "File: #{src} doesn't exist"
  end
end

