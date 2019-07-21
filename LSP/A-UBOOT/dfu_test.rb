# -*- coding: ISO-8859-1 -*-
# This script is to test DFU by updating MLO/u-boot.img via DFU
#  
# Currently, this script only support update MMC and eMMC. But it can be extended to update NAND via DFU as well

require File.dirname(__FILE__)+'/../default_test_module'
   
include LspTestScript   

def setup
	@equipment['dut1'].set_api('psp')
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  install_dfu_util()
  install_crc32() if @test_params.params_chan.media[0].downcase == 'ram'
end

def run
  result = 0
  params = {}
  params['initial_bootloader'] = @test_params.instance_variable_defined?(:@initial_bootloader) ? @test_params.initial_bootloader : ''
  params['initial_bootloader_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@initial_bootloader_src_dev) ? @test_params.params_chan.initial_bootloader_src_dev[0] : 'eth'
  params['sysfw'] = @test_params.instance_variable_defined?(:@sysfw) ? @test_params.sysfw : ''
  params['sysfw_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@sysfw_src_dev) ? @test_params.params_chan.sysfw_src_dev[0] : 'eth'
  params['primary_bootloader'] = @test_params.instance_variable_defined?(:@primary_bootloader) ? @test_params.primary_bootloader : ''
  params['primary_bootloader_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_src_dev) ? @test_params.params_chan.primary_bootloader_src_dev[0] : 'eth'
  params['secondary_bootloader'] = @test_params.instance_variable_defined?(:@secondary_bootloader) ? @test_params.secondary_bootloader : ''
  params['secondary_bootloader_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_src_dev) ? @test_params.params_chan.secondary_bootloader_src_dev[0] : 'eth'
  if params['secondary_bootloader'].strip == '' 
    raise "Bootloaders are not provided"
  end

  translated_boot_params = setup_host_side(params)
  translated_boot_params.each{|k,v| puts "#{k}:#{v}"}
  
  usb_controller = get_usb_gadget_number(@test_params.platform)

  # media options: fat-mmc, raw-mmc, fat-emmc, raw-emmc, nand, qspi etc
  media = @test_params.params_chan.instance_variable_defined?(:@media) ? @test_params.params_chan.media[0].downcase : 'fat-mmc'
  use_uboot_env = @test_params.params_chan.instance_variable_defined?(:@use_uboot_env) ? @test_params.params_chan.use_uboot_env[0].downcase : 'yes' 
  case media
  when /mmc/
    if @test_params.platform =~ /am654x/
      #dfu_alt_info_emmc=rawemmc raw 0 0x1000000 mmcpart 1;rootfs part 0 1 mmcpart 0;tiboot3.bin.raw raw 0x0 0x400 mmcpart 1;tispl.bin.raw raw 0x400 0x1000 mmcpart 1;u-boot.img.raw raw 0x1400 0x2800 mmcpart 1;u-env.raw raw 0x3c00 0x100 mmcpart 1;sysfw.itb.raw raw 0x3d00 0x300 mmcpart 1
      #dfu_alt_info_mmc=boot part 1 1;rootfs part 1 2;tiboot3.bin fat 1 1;tispl.bin fat 1 1;u-boot.img fat 1 1;uEnv.txt fat 1 1;sysfw.itb fat 1 1
      alt_name_sysfw_fat = "sysfw.itb"
      alt_name_initial_bootloader_fat = "tiboot3.bin"
      alt_name_primary_bootloader_fat = "tispl.bin"
      alt_name_secondary_bootloader_fat = "u-boot.img"
      alt_name_sysfw_raw = "sysfw.itb.raw"
      alt_name_initial_bootloader_raw = "tiboot3.bin.raw"
      alt_name_primary_bootloader_raw = "tispl.bin.raw"
      alt_name_secondary_bootloader_raw = "u-boot.img.raw"
      dfu_alt_info_fat_mmc = "\"#{alt_name_initial_bootloader_fat} fat 1 1;#{alt_name_sysfw_fat} fat 1 1;#{alt_name_primary_bootloader_fat} fat 1 1;#{alt_name_secondary_bootloader_fat} fat 1 1\""
      dfu_alt_info_raw_mmc = "\"#{alt_name_initial_bootloader_raw} raw 0x0 0x400 mmcpart 1;#{alt_name_primary_bootloader_raw} raw 0x400 0x1000 mmcpart 1;#{alt_name_secondary_bootloader_raw} raw 0x1400 0x2800 mmcpart 1;#{alt_name_sysfw_raw} raw 0x3d00 0x300 mmcpart 1\" "
    else
      alt_name_primary_bootloader_fat = "MLO"
      alt_name_secondary_bootloader_fat = "u-boot.img"
      alt_name_primary_bootloader_raw = "MLO.raw"
      alt_name_secondary_bootloader_raw = "uboot.img.raw"
      dfu_alt_info_fat_mmc = "\"#{alt_name_primary_bootloader_fat} fat 0 1;#{alt_name_secondary_bootloader_fat} fat 0 1\""
      case @test_params.platform 
        when /am43xx/
          dfu_alt_info_raw_mmc = "\"#{alt_name_primary_bootloader_raw} raw 0x0 0x200;#{alt_name_secondary_bootloader_raw} raw 0x300 0x1000\" "
        else
          dfu_alt_info_raw_mmc = "\"#{alt_name_primary_bootloader_raw} raw 0x100 0x200;#{alt_name_secondary_bootloader_raw} raw 0x300 0x1000\" "
      end
    end

    if use_uboot_env == 'yes'
      dfu_alt_info_fat_mmc = "\"${dfu_alt_info_mmc}\" "
      dfu_alt_info_raw_mmc = "\"${dfu_alt_info_emmc}\" "
    end

  when /spi/
    if @test_params.platform =~ /am654x/
      #dfu_alt_info_ospi=tiboot3.bin raw 0x0 0x080000;tispl.bin raw 0x080000 0x200000;u-boot.img raw 0x280000 0x500000;u-boot-env raw 0x780000 0x020000;sysfw.itb raw 0x7a0000 0x060000;rootfs raw 0x800000 0x3800000
      alt_name_sysfw_raw = "sysfw.itb"
      alt_name_initial_bootloader_raw = "tiboot3.bin"
      alt_name_primary_bootloader_raw = "tispl.bin"
      alt_name_secondary_bootloader_raw = "u-boot.img"
    else
      alt_name_primary_bootloader_raw = "MLO"
      alt_name_secondary_bootloader_raw = "u-boot.img"
    end
    case @test_params.platform 
      when /dra7|am57/
        dfu_alt_info_raw_spi = "\"#{alt_name_primary_bootloader_raw} raw 0x0 0x20000;#{alt_name_secondary_bootloader_raw} raw 0x40000 0x100000\" "
        dfu_alt_info_raw_spi = " \"${dfu_alt_info_qspi}\" " if use_uboot_env == 'yes'
      when /am654/
        dfu_alt_info_raw_spi = "\"#{alt_name_sysfw_raw} raw 0x7a0000 0x60000;#{alt_name_initial_bootloader_raw} raw 0x0 0x80000;#{alt_name_primary_bootloader_raw} raw 0x80000 0x200000;#{alt_name_secondary_bootloader_raw} raw 0x280000 0x500000\" "
        dfu_alt_info_raw_spi = " \"${dfu_alt_info_ospi}\" " if use_uboot_env == 'yes'
      else
        raise "No dfu_alt_info being defined for QSPI/OSPI/SPI for #{@test_params.platform}"
    end
  when /ram/
    # generate testfile in host
    filesize = @test_params.params_chan.filesize[0]  # filesize in decimal
    filesize_hex = filesize.to_i.to_s(16)
    size_in_k = (filesize.to_i / 1024).to_s
    filename_ram = "#{@equipment['server1'].tftp_path}/dfu_ram_testfile"
    @equipment['server1'].send_cmd("dd if=/dev/urandom of=#{filename_ram} bs=1K count=#{size_in_k}", @equipment['server1'].prompt, 600)
    @equipment['server1'].send_cmd("crc32 #{filename_ram}", @equipment['server1'].prompt, 600)
    crc32_srcfile = @equipment['server1'].response.match(/^(\h+)/).captures[0]
    puts "crc32_srcfile:"+crc32_srcfile
    dfu_alt_info_ram = "\"ram_testimage ram ${loadaddr} 0x#{filesize_hex}\""
  end

  case media
  when /-mmc/
    interface = 'mmc'
    if @equipment['dut1'].name =~ /am654x/
      dev = 1
    else
      dev = 0
    end
  when /-emmc/
    interface = 'mmc'
    if @equipment['dut1'].name =~ /am654x/
      dev = 0
    else
      dev = 1
    end
  when /qspi/
    interface = 'sf 0:0'
  when /ram/
    interface = 'ram'
    dev = 0
  else
    interface = media
    dev = 0
  end
  if media == "raw-mmc" || media == "raw-emmc"
    dfu_alt_info = dfu_alt_info_raw_mmc
    alt_name_sysfw = alt_name_sysfw_raw if alt_name_sysfw_raw
    alt_name_initial_bootloader = alt_name_initial_bootloader_raw if alt_name_initial_bootloader_raw
    alt_name_primary_bootloader = alt_name_primary_bootloader_raw
    alt_name_secondary_bootloader = alt_name_secondary_bootloader_raw
  elsif media == "fat-mmc" || media == "fat-emmc"
    dfu_alt_info = dfu_alt_info_fat_mmc
    alt_name_sysfw = alt_name_sysfw_fat if alt_name_sysfw_fat
    alt_name_initial_bootloader = alt_name_initial_bootloader_fat if alt_name_initial_bootloader_fat
    alt_name_primary_bootloader = alt_name_primary_bootloader_fat
    alt_name_secondary_bootloader = alt_name_secondary_bootloader_fat
  elsif media == "qspi"
    dfu_alt_info = dfu_alt_info_raw_spi
    alt_name_sysfw = alt_name_sysfw_raw if alt_name_sysfw_raw
    alt_name_initial_bootloader = alt_name_initial_bootloader_raw if alt_name_initial_bootloader_raw
    alt_name_primary_bootloader = alt_name_primary_bootloader_raw
    alt_name_secondary_bootloader = alt_name_secondary_bootloader_raw
  elsif media == "ram"
    dfu_alt_info = dfu_alt_info_ram
  else
    raise "Not supported media #{media}. The supported media are fat-mmc, raw-mmc, fat-emmc, raw-emmc."
  end

  # boot to uboot prompt if it is not in uboot prompt
  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    @equipment['dut1'].boot_to_bootloader(translated_boot_params)
  end

  # set dfu env 
  @equipment['dut1'].send_cmd("version", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("gpt write mmc #{dev} ${partitions}", @equipment['dut1'].boot_prompt, 10) if media == "raw-emmc"
  @equipment['dut1'].send_cmd("setenv dfu_alt_info #{dfu_alt_info}", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("print dfu_alt_info", @equipment['dut1'].boot_prompt, 5)

  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  images_dir = File.join(@equipment['server1'].tftp_path, tmp_path)

  if media == "ram"
   
    # download primary_bootloader
    start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
      host_dfu_download_image("#{filename_ram}", "ram_testimage")
    end
    # send ctrl+c to back to uboot prompt
    @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)

    sleep 1

    # check crc32 to see if it match the src file
    @equipment['dut1'].send_cmd("crc32 ${loadaddr} #{filesize_hex}", @equipment['dut1'].boot_prompt, 600)
    crc32_dstfile = @equipment['dut1'].response.match(/==>\s*(\h+)/i).captures[0]
    puts "crc32_dstfile:"+crc32_dstfile

    if (crc32_dstfile != crc32_srcfile)
      set_result(FrameworkConstants::Result[:fail], "Ram download: crc32 of dstfile is not the same as srcfile")
    end
    
  else
    if @test_params.platform =~ /am654x/
      # download sysfw
      start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
        host_dfu_download_image("#{images_dir}/#{File.basename(translated_boot_params['sysfw_image_name'])}", alt_name_sysfw)
      end
      # send ctrl+c to back to uboot prompt
      @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)

      sleep 1
      # download initial_bootloader
      start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
        host_dfu_download_image("#{images_dir}/#{File.basename(translated_boot_params['initial_bootloader_image_name'])}", alt_name_initial_bootloader)
      end
      # send ctrl+c to back to uboot prompt
      @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)
    end

    sleep 1
    # download primary_bootloader
    start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
      host_dfu_download_image("#{images_dir}/#{File.basename(translated_boot_params['primary_bootloader_image_name'])}", alt_name_primary_bootloader)
    end
    # send ctrl+c to back to uboot prompt
    @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)

    sleep 1
    # download secondary_bootloader
    start_dfu_on_target("dfu #{usb_controller} #{interface} #{dev}", /.*/, /download.*ok/i) do
      host_dfu_download_image("#{images_dir}/#{File.basename(translated_boot_params['secondary_bootloader_image_name'])}", alt_name_secondary_bootloader)
    end
    # send ctrl+c to back to uboot prompt
    @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].boot_prompt, 5)

    # check if new bootloaders work
    begin
      @equipment['dut1'].boot_loader = nil
      case media
      when /qspi/
        translated_boot_params['primary_bootloader_dev'] = 'qspi'
      when /-mmc/
        translated_boot_params['primary_bootloader_dev'] = 'mmc'
      when /emmc/
        translated_boot_params['primary_bootloader_dev'] = 'emmc'
      end
      @equipment['dut1'].boot_to_bootloader(translated_boot_params)

    rescue Exception => e
      @equipment['dut1'].reset_sysboot(translated_boot_params['dut'])
      set_result(FrameworkConstants::Result[:fail], "Test Failed: The board could not boot using the updated MLO/uboot")
    end
  end

  set_result(FrameworkConstants::Result[:pass], "Test Pass")
end

def clean
  puts "cleaning..."
  @equipment['dut1'].reset_sysboot(@equipment['dut1'])
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
  dfu_serial = @equipment['server1'].response.match(/Found\s+DFU:.*serial=\"(\h+)\"/i).captures[0]
  @equipment['server1'].send_sudo_cmd("dfu-util -D #{image} -a #{alt_name} -S #{dfu_serial}", "Done!", 120)
  raise "Downloading data from PC to DFU device failed!" if ! @equipment['server1'].response.match(/(Starting\s+download:.*finished!)|(Download\s+done)/i)
end

# install dfu-util if it is not in host
def install_dfu_util()
  @equipment['server1'].send_cmd("which dfu-util; echo $?", /^0[\0\n\r]+/im, 2)
  @equipment['server1'].send_sudo_cmd("apt-get install dfu-util", @equipment['server1'].prompt, 600) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("which dfu-util; echo $?", /^0[\0\n\r]+/im, 5)
  raise "dfu-util is not installed!" if @equipment['server1'].timeout?
end

# install crc32 if it is not in host
def install_crc32()
  @equipment['server1'].send_cmd("crc32 -h", @equipment['server1'].prompt, 5)
  if @equipment['server1'].response.match(/not\s+found/i)
    @equipment['server1'].send_sudo_cmd("sudo apt-get install libarchive-zip-perl", @equipment['server1'].prompt, 600) 
    @equipment['server1'].send_cmd("which crc32", @equipment['server1'].prompt, 5) 
  end
end


