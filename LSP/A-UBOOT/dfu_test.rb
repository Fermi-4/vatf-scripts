# -*- coding: ISO-8859-1 -*-
# This script is to test DFU by updating MLO/u-boot.img via DFU
#  
# Currently, this script only support update MMC and eMMC. But it can be extended to update NAND via DFU as well

require File.dirname(__FILE__)+'/../default_test_module'
   
include LspTestScript   

def connect_to_extra_equipment
  usb_switch1 = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usbclient_port'].keys[0]]
  if usb_switch1.respond_to?(:serial_port) && usb_switch1.serial_port != nil
    usb_switch1.connect({'type'=>'serial'})
  else
    raise "Something wrong with usb switch connection for usbclient. Please check your setup"
  end
end

def setup
	@equipment['dut1'].set_api('psp')
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  connect_to_extra_equipment()
  install_dfu_util()
end

def run
  result = 0
  params = {}
  params['primary_bootloader_mmc'] = @test_params.instance_variable_defined?(:@primary_bootloader_mmc) ? @test_params.primary_bootloader_mmc : ''
  params['primary_bootloader_mmc_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_mmc_src_dev) ? @test_params.params_chan.primary_bootloader_mmc_src_dev[0] : 'eth'
  params['secondary_bootloader_mmc'] = @test_params.instance_variable_defined?(:@secondary_bootloader_mmc) ? @test_params.secondary_bootloader_mmc : ''
  params['secondary_bootloader_mmc_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_mmc_src_dev) ? @test_params.params_chan.secondary_bootloader_mmc_src_dev[0] : 'eth'

  translated_boot_params = setup_host_side(params)
  translated_boot_params.each{|k,v| puts "#{k}:#{v}"}
  
  alt_name_mlo_fat = "MLO"
  alt_name_uboot_fat = "u-boot.img"
  alt_name_mlo_raw = "MLO.raw"
  alt_name_uboot_raw = "uboot.img.raw"
  dfu_alt_info_fat_mmc = "\"#{alt_name_mlo_fat} fat 0 1;#{alt_name_uboot_fat} fat 0 1\""
  dfu_alt_info_raw_mmc = "\"#{alt_name_mlo_raw} raw 0x100 0x100;#{alt_name_uboot_raw} raw 0x300 0x400\" "

  usb_controller = get_usb_gadget_number(@test_params.platform)

  # media options: fat-mmc, raw-mmc, fat-emmc, raw-emmc, nand etc
  media = @test_params.params_chan.instance_variable_defined?(:@media) ? @test_params.params_chan.media[0].downcase : 'fat-mmc'
  case media
  when /-mmc/
    interface = 'mmc'
    dev = 0
  when /-emmc/
    interface = 'mmc'
    dev = 1
  else
    interface = media
    dev = 0
  end
  if media == "raw-mmc" || media == "raw-emmc"
    dfu_alt_info = dfu_alt_info_raw_mmc
    alt_name_mlo = alt_name_mlo_raw
    alt_name_uboot = alt_name_uboot_raw
  elsif media == "fat-mmc" || media == "fat-emmc"
    dfu_alt_info = dfu_alt_info_fat_mmc
    alt_name_mlo = alt_name_mlo_fat
    alt_name_uboot = alt_name_uboot_fat
  else
    raise "Not supported media #{media}. The supported media are fat-mmc, raw-mmc, fat-emmc, raw-emmc."
  end

  # boot to uboot prompt if it is not in uboot prompt
  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    if @test_params.platform.downcase == "beaglebone-black"
      puts "Disconnect usb cable; otherwise, BBB won't reboot"
      @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])
    end
    @equipment['dut1'].boot_to_bootloader(translated_boot_params)
  end
  # connect usb port to pc  
  @usb_switch_handler.select_input(@equipment['dut1'].params['usbclient_port'])

  # check if dfu env is exist
  @equipment['dut1'].send_cmd("version", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("setenv dfu_alt_info #{dfu_alt_info}", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("print dfu_alt_info", @equipment['dut1'].boot_prompt, 5)

  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  images_dir = File.join(@equipment['server1'].tftp_path, tmp_path)

  # download mlo
  start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /usb_dnload/, /download.*ok/i) do
    host_dfu_download_image("#{images_dir}/#{File.basename(translated_boot_params['primary_bootloader_mmc_image_name'])}", alt_name_mlo)
  end
  # send ctrl+c to back to uboot prompt
  @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)

  sleep 1
  # download u-boot.img
  start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /usb_dnload/, /download.*ok/i) do
    host_dfu_download_image("#{images_dir}/#{File.basename(translated_boot_params['secondary_bootloader_mmc_image_name'])}", alt_name_uboot)
  end
  # send ctrl+c to back to uboot prompt
  @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)

  # check if new bootloaders work
  begin
    @equipment['dut1'].boot_to_bootloader(translated_boot_params)
  rescue
    set_result(FrameworkConstants::Result[:fail], "Test Failed: The board could not boot using the updated MLO/uboot")
  end

  set_result(FrameworkConstants::Result[:pass], "Test Pass")
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
  @equipment['server1'].send_sudo_cmd("dfu-util -D #{image} -a #{alt_name}", "Done!", 120)
  raise "Downloading data from PC to DFU device failed!" if ! @equipment['server1'].response.match(/Starting\s+download:.*finished!/i)
end

# install dfu-util if it is not in host
def install_dfu_util()
  @equipment['server1'].send_cmd("which dfu-util", @equipment['server1'].prompt, 5)
  @equipment['server1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
  @equipment['server1'].send_sudo_cmd("apt-get install dfu-util", @equipment['server1'].prompt, 60) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("dfu-util -h", @equipment['server1'].prompt, 5)
  @equipment['server1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
  raise "Could not install dfu-util!" if @equipment['server1'].timeout?
end


