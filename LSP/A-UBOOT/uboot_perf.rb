# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript
include PlatformSpecificVarNames

def setup
	@equipment['dut1'].set_api('psp')

end

def run
  result_msg = ''
  perfs = []

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?

  @equipment['dut1'].send_cmd("help time", @equipment['dut1'].boot_prompt, 5)
  if @equipment['dut1'].response.match("Unknown command")
    raise " 'time' command needs to be enabled in uboot. Please enable CONFIG_CMD_TIME. "
  end

  # valid device names: 'raw-ufs', 'nand', 'hflash', 'spi', 'qspi', 'raw-mmc', 'raw-emmc', 'fat-mmc', 'fat-emmc', 'fat-usb'
  # since we don't want to corrupt the SD card if there is partition there, we only
  # do read when device is 'raw-mmc'
  device = @test_params.params_chan.device[0]
  mmcdev_nums = get_uboot_mmcdev_mapping()
  mmcdev = mmcdev_nums['emmc'] if device == "raw-emmc" || device == "fat-emmc"
  mmcdev = mmcdev_nums['mmc'] if device == "raw-mmc" || device == "fat-mmc"

  case device.downcase

  when /raw-ufs/
    #testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000", "0x4000000"] # [4M, 8M, 16M, 32M, 64M]
    testsizes = ["0x400000", "0x1000000", "0x2000000", "0x4000000"] # [4M, 16M, 32M, 64M]

    @equipment['dut1'].send_cmd("ufs init", @equipment['dut1'].boot_prompt, 10)
    if ! @equipment['dut1'].response.match(/Device\s+at\s+ufs@\h+\s+up/i)
      raise "UFS device was not able to be initialized"
    end

=begin
    # boot to kernel to create/format partition 
    create_format_partition translated_boot_params, 'fat-ufs'
    translated_boot_params['dut'].boot_to_bootloader translated_boot_params
    @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
    @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
    raise 'Failed to stop at bootloader prompt after format sata partition in kernel' if @equipment['dut1'].timeout?
    @equipment['dut1'].send_cmd("ufs init", @equipment['dut1'].boot_prompt, 10)
    if ! @equipment['dut1'].response.match(/Device\s+at\s+ufs@\h+\s+up/i)
      raise "UFS device was not able to be initialized"
    end
=end

    @equipment['dut1'].send_cmd("scsi scan", @equipment['dut1'].boot_prompt, 10)
    if ! @equipment['dut1'].response.match(/Capacity:/i)
      raise "Could not see UFS device by scsi scan"
    end

    testdev,devsize = get_scsi_biggest_dev @equipment['dut1'].response

    @equipment['dut1'].send_cmd("scsi device #{testdev}", @equipment['dut1'].boot_prompt, 10)
    #@equipment['dut1'].send_cmd("ext4ls scsi 1:2", @equipment['dut1'].boot_prompt, 10)

    @equipment['dut1'].send_cmd("ls scsi #{testdev}:2", @equipment['dut1'].boot_prompt, 10)
    #raise "Unrecognized filesystem type in usb" if @equipment['dut1'].response.match(/Unrecognized\s+filesystem/i)

    #ufs_test_addr = PlatformSpecificVarNames.translate_var_name(@equipment['dut1'].name,'ufs_test_addr')
    ufs_test_addr = '0'

    testsizes.each do |testsize_hex|
      loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."

      testfile = "#{@linux_temp_folder}/perf_testfile"
      @equipment['server1'].send_cmd("dd if=/dev/urandom of=#{testfile} bs=1M count=#{testsize_hex.to_i(16) / 1048576}", @equipment['server1'].prompt, 120)
      tftp_testfile_to_dut(testfile)

      cnt = get_blk_cnt(testsize_hex, 4096)

      # write to UFS 
      @equipment['dut1'].send_cmd("time scsi write ${loadaddr} #{ufs_test_addr} #{cnt}", @equipment['dut1'].boot_prompt, 300)
      #@equipment['dut1'].send_cmd("time mtd write nor0 ${loadaddr} #{hflash_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "UFS raw write failed with size #{testsize_hex.to_i(16)};"
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Write #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      # read the data from UFS to loadaddr2
      @equipment['dut1'].send_cmd("time scsi read #{loadaddr2} #{ufs_test_addr} #{cnt}", @equipment['dut1'].boot_prompt, 300)
      #@equipment['dut1'].send_cmd("time mtd read nor0 ${loadaddr2} #{hflash_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "UFS raw read failed with size #{testsize_hex.to_i(16)};"
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/!=/i)
        result_msg = result_msg + "#{device}: cmp failed for size #{testsize_hex}; "
        set_result(FrameworkConstants::Result[:fail], result_msg)
      end
    end


  when /hflash/

    testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000"] # [4M, 8M, 16M, 32M]
    @equipment['dut1'].send_cmd("help mtd", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("mtd list", @equipment['dut1'].boot_prompt, 10)

    hflash_test_addr = PlatformSpecificVarNames.translate_var_name(@equipment['dut1'].name,'hflash_test_addr')

    testsizes.each do |testsize_hex|
      loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."

      testfile = "#{@linux_temp_folder}/perf_testfile"
      @equipment['server1'].send_cmd("dd if=/dev/urandom of=#{testfile} bs=1M count=#{testsize_hex.to_i(16) / 1048576}", @equipment['server1'].prompt, 120)
      tftp_testfile_to_dut(testfile)

      # write to hflash
      @equipment['dut1'].send_cmd("time mtd erase nor0 #{hflash_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "hflash erase failed with size #{testsize_hex.to_i(16)};"
        next
      end
      @equipment['dut1'].send_cmd("time mtd write nor0 #{loadaddr} #{hflash_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "hflash write failed with size #{testsize_hex.to_i(16)};"
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Write #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      # read the data from hflash to loadaddr2
      @equipment['dut1'].send_cmd("time mtd read nor0 #{loadaddr2} #{hflash_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "hflash read failed with size #{testsize_hex.to_i(16)};"
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/!=/i)
        result_msg = result_msg + "#{device}: cmp failed for size #{testsize_hex}; "
        set_result(FrameworkConstants::Result[:fail], result_msg)
      end
    end
    @equipment['dut1'].send_cmd("mtd list ", @equipment['dut1'].boot_prompt, 10)

  when /spi/

    # Find out the (Q)SPI size, then run test using 1/2, 1/4, ... and so on to test
    test_addr = device.downcase == 'qspi'? 
      PlatformSpecificVarNames.translate_var_name(@test_params.platform,'qspi_test_addr') :
      PlatformSpecificVarNames.translate_var_name(@test_params.platform,'spi_test_addr')

    key = device.downcase == 'qspi'? "qspi_sf_probe" : "spi_sf_probe"
    sf_probe_cmd = CmdTranslator::get_uboot_cmd({'cmd'=>key, 'version'=>"0.0", 'platform'=>@equipment['dut1'].name})
    @equipment['dut1'].send_cmd(sf_probe_cmd, @equipment['dut1'].boot_prompt, 10)
    max_testsize_dec = @equipment['dut1'].response.match(/SF:.*total\s+([\d]+)\s+MiB/i).captures[0].to_i * 1048576
    erasesize_dec = @equipment['dut1'].response.match(/erase\s*size\s+([0-9]+)\s*KiB,/im).captures[0].to_i * 1024

    cnt = 4 # number of testsizes to test
    i = 0
    while i < cnt do
      puts "i=#{i}"

      testsize_hex = (max_testsize_dec.to_i/2).to_s(16)
      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."
      roundup_size = (testsize_hex.to_i(16).to_f / erasesize_dec.to_f).ceil * erasesize_dec.to_f
      roundup_size = roundup_size.to_i.to_s(16)

      testfile = "#{@linux_temp_folder}/perf_testfile"
      @equipment['server1'].send_cmd("dd if=/dev/urandom of=#{testfile} bs=1M count=#{testsize_hex.to_i(16) / 1048576}", @equipment['server1'].prompt, 120)

      # erase spi
      @equipment['dut1'].send_cmd("time sf erase #{test_addr} #{roundup_size}", @equipment['dut1'].boot_prompt, 300)
      raise "There is error when do sf erase!" if @equipment['dut1'].response.match(/error/i)
      tftp_testfile_to_dut(testfile)
      @equipment['dut1'].send_cmd("time sf write ${loadaddr} #{test_addr} #{testsize_hex}", @equipment['dut1'].boot_prompt, 300)
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Write 0x#{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}
      
      loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
      @equipment['dut1'].send_cmd("time sf read #{loadaddr2} #{test_addr} #{testsize_hex}", @equipment['dut1'].boot_prompt, 300)
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read 0x#{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      # verify read write ok
      @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/!=/i)
        result_msg = result_msg + "#{device}: cmp failed for size 0x#{testsize_hex}; "
        set_result(FrameworkConstants::Result[:fail], result_msg)
      end

      max_testsize_dec = testsize_hex.to_i(16)
      i += 1
    end

  when /raw-e*mmc/
    @equipment['dut1'].send_cmd("mmc dev #{mmcdev}", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("mmcinfo", @equipment['dut1'].boot_prompt, 10)
    test_blks = ["0x10000", "0x20000", "0x40000", "0x80000", "0x100000"] # [32M, 64M, 128M, 256M, 512M]
    half_dram = get_dram_size().to_i(16) / 2
    test_blks.each do |test_blknum_hex|
      testsize_hex = (test_blknum_hex.to_i(16) * 512).to_s(16)
      # skipping 512M if dram is 1G since no room to compare
      next if testsize_hex.to_i(16) >= half_dram 

      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."
      # read mmc contents to loadaddr
      @equipment['dut1'].send_cmd("time mmc read ${loadaddr} 0x0 #{test_blknum_hex}", @equipment['dut1'].boot_prompt, 300)
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read 0x#{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}
      # since we don't want to corrupt the SD card if there is partition there, we only
      # do read when device is 'raw-mmc'
      if device == 'raw-emmc'
        loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
        # write contents in ${loadaddr} to mmc
        @equipment['dut1'].send_cmd("time mmc write ${loadaddr} 0x0 #{test_blknum_hex}", @equipment['dut1'].boot_prompt, 300)
        this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
        perfs << {'name' => "#{device.upcase} Write 0x#{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}
        # read back from mmc to #{loadaddr2} then compare 
        @equipment['dut1'].send_cmd("time mmc read #{loadaddr2} 0x0 #{test_blknum_hex}", @equipment['dut1'].boot_prompt, 300)
        @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
        if @equipment['dut1'].response.match(/!=/i)
          result_msg = result_msg + "#{device}: cmp failed for size 0x#{testsize_hex}; "
          set_result(FrameworkConstants::Result[:fail], result_msg)
        end

      end

    end

  when /fat-mmc/
    #testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000", "0x4000000"] # [4M, 8M, 16M, 32M, 64M]
    testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000"] # [4M, 8M, 16M, 32M, 64M]
    @equipment['dut1'].send_cmd("mmc dev #{mmcdev}", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("mmcinfo", @equipment['dut1'].boot_prompt, 10)

    testsizes.each do |testsize_hex|
      loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."
      # write 'test' file to mmc fat partition from loadaddr
      @equipment['dut1'].send_cmd("time fatwrite mmc #{mmcdev_nums['mmc']} ${loadaddr} test #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/overflow|no\s*space\s*left/i)
        report_msg "MMCSD first fat partition do not have enough space for the #{testsize_hex.to_i(16)} file, so skip it."
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Write #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      # read back 'test' file from mmc to loadaddr2
      @equipment['dut1'].send_cmd("time fatload mmc #{mmcdev_nums['mmc']} #{loadaddr2} test ", @equipment['dut1'].boot_prompt, 300)
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}
      
      @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/!=/i)
        result_msg = result_msg + "#{device}: cmp failed for size #{testsize_hex}; "
        set_result(FrameworkConstants::Result[:fail], result_msg)
      end
      @equipment['dut1'].send_cmd("test ", @equipment['dut1'].boot_prompt, 30)
    end
    @equipment['dut1'].send_cmd("time fatwrite mmc #{mmcdev_nums['mmc']} ${loadaddr} test 0 ", @equipment['dut1'].boot_prompt, 10)

  when /fat-usb/
    #testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000", "0x4000000"] # [4M, 8M, 16M, 32M, 64M]
    testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000"] # [4M, 8M, 16M, 32M, 64M]
    @equipment['dut1'].send_cmd("usb start", @equipment['dut1'].boot_prompt, 10)
    if ! @equipment['dut1'].response.match(/[1-9]+\s+Storage\s+Device.*found/i)
      raise "No usb storage device being detected"
    end
    @equipment['dut1'].send_cmd("usb storage", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("usb tree", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("usb info", @equipment['dut1'].boot_prompt, 10)

    # boot to kernel to create/format partition 
    create_format_partition translated_boot_params,"usb"
    translated_boot_params['dut'].boot_to_bootloader translated_boot_params
    @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
    @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
    raise 'Failed to stop at bootloader prompt after format sata partition in kernel' if @equipment['dut1'].timeout?

    @equipment['dut1'].send_cmd("usb start", @equipment['dut1'].boot_prompt, 10)
    if ! @equipment['dut1'].response.match(/[1-9]+\s+Storage\s+Device.*found/i)
      raise "No usb storage device being detected"
    end
    @equipment['dut1'].send_cmd("ls usb 0", @equipment['dut1'].boot_prompt, 10)
    raise "Unrecognized filesystem type in usb" if @equipment['dut1'].response.match(/Unrecognized\s+filesystem/i)

    testsizes.each do |testsize_hex|
      loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."
      # write 'test' file to usb fat partition from loadaddr
      @equipment['dut1'].send_cmd("time fatwrite usb 0 ${loadaddr} test #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/overflow/i)
        report_msg "USB first fat partition do not have enough space for the #{testsize_hex.to_i(16)} file, so skip it."
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Write #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      # read back 'test' file from mmc to loadaddr2
      @equipment['dut1'].send_cmd("time fatload usb 0 #{loadaddr2} test ", @equipment['dut1'].boot_prompt, 300)
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}
      
      @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/!=/i)
        result_msg = result_msg + "#{device}: cmp failed for size #{testsize_hex}; "
        set_result(FrameworkConstants::Result[:fail], result_msg)
      end
      @equipment['dut1'].send_cmd("test ", @equipment['dut1'].boot_prompt, 30)
    end
    @equipment['dut1'].send_cmd("time fatwrite usb 0 ${loadaddr} test 0 ", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("usb stop; usb stop", @equipment['dut1'].boot_prompt, 10)

  when /nand/
    testsizes = ["0x400000", "0x800000", "0x1000000", "0x2000000", "0x4000000"] # [4M, 8M, 16M, 32M, 64M]
    @equipment['dut1'].send_cmd("help nand", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("nand info", @equipment['dut1'].boot_prompt, 10)

    nand_test_addr = PlatformSpecificVarNames.translate_var_name(@equipment['dut1'].name,'nand_test_addr')

    testsizes.each do |testsize_hex|
      loadaddr, loadaddr2 = get_loadaddres(testsize_hex)
      report_msg "===Testing size #{testsize_hex.to_i(16).to_s} ..."
      # read the data from Nand
      @equipment['dut1'].send_cmd("time nand read ${loadaddr} #{nand_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "Nand read failed with size #{testsize_hex.to_i(16)};"
        next
      end
      @equipment['dut1'].send_cmd("time nand erase #{nand_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "Nand erase failed with size #{testsize_hex.to_i(16)};"
        next
      end
      # write the data just read back to Nand
      @equipment['dut1'].send_cmd("time nand write ${loadaddr} #{nand_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      if @equipment['dut1'].response.match(/error|fail/i)
        report_msg "Nand write failed with size #{testsize_hex.to_i(16)};"
        next
      end
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Write #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}

      # read back from Nand to loadaddr2
      @equipment['dut1'].send_cmd("time nand read #{loadaddr2} #{nand_test_addr} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 600)
      this_perf = calculate_perf(@equipment['dut1'].response, testsize_hex)
      perfs << {'name' => "#{device.upcase} Read #{testsize_hex}", 'value' => this_perf, 'units' => 'KB/S'}
      
      @equipment['dut1'].send_cmd("cmp.b #{loadaddr} #{loadaddr2} #{testsize_hex} ", @equipment['dut1'].boot_prompt, 300)
      if @equipment['dut1'].response.match(/!=/i)
        result_msg = result_msg + "#{device}: cmp failed for size #{testsize_hex}; "
        set_result(FrameworkConstants::Result[:fail], result_msg)
      end
    end
    @equipment['dut1'].send_cmd("nand info ", @equipment['dut1'].boot_prompt, 10)

  else
    raise "Measuring RW performance for device #{device} is not supported"
  end

  if perfs.size > 0 and result_msg == ""
    set_result(FrameworkConstants::Result[:pass], "Uboot read write test pass and throughput data collected. ", perfs)
  elsif perfs.size > 0 and result_msg != ""
    set_result(FrameworkConstants::Result[:fail], "Throughput data collected; but " + result_msg, perfs)
  else
    set_result(FrameworkConstants::Result[:fail], "Failed to collect throughput data")
  end

end

def clean
  	#self.as(LspTestScript).clean
    puts "clean..."
end

def create_format_partition(params, dev='usb')
  # first boot to kernel
  params['bootargs'] = @equipment['dut1'].boot_args
  @equipment['dut1'].system_loader.run params
  # format partition
  # run ltp-ddt test; by default ltp-ddt format partition as vfat 
  if dev == 'usb'
    cmd = "./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_dd_rw_vfat -s \"USBHOST_L_FUNC_VFAT_DD_RW_0001\" "
  elsif dev == 'fat-ufs'
    cmd = "./runltp -P #{@equipment['dut1'].name} -f ddt/ufs_dd_rw -s \"UFS_S_FUNC_DD_RW_10M\" "
  end
  @equipment['dut1'].send_cmd("cd /opt/ltp; #{cmd}", @equipment['dut1'].prompt, 600)
  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2, false)
  raise "ltp-ddt #{dev} test failed and failed to format partitions" if @equipment['dut1'].timeout?
end

# The throughput will be in KBytes/sec
def calculate_perf(response, test_size)
  time_captures = response.match(/time:\s*(?:(\d+)\s+minutes,){0,1}\s+([\d+\.]+)\s+seconds/i).captures
  min = time_captures[0]
  sec = time_captures[1]
  time_taken = 60*min.to_i + sec.to_f 
  perf = (test_size.to_i(16).to_f / time_taken.to_f) /1024
  report_msg "===Perf for #{test_size.to_s} is: " + perf.to_s + "KB/S"
  return perf.to_f.round(2)
end

# get loadaddr and loadaddr2 which is loadaddr+testsize
def get_loadaddres(testsize_hex)
  loadaddr = nil
  loadaddr2 = nil
  # when read, read to a different location instead of ${loadaddr} so we can compare read write
  @equipment['dut1'].send_cmd("print loadaddr", @equipment['dut1'].boot_prompt, 10)
  # ex: loadaddr=0x82000000
  loadaddr = @equipment['dut1'].response.match(/loadaddr=0x(\h+)/i).captures[0]
  # Since 0x90000000 to 0xb0000000 is reseved_memory for j7, do not use them.
  # loadaddr = 0x80080000, add 3000000 becomes 0xc0080000 which is outside of the above 
  loadaddr = ( loadaddr.to_i(16) + "0x30000000".to_i(16) ).to_s(16)
  loadaddr2 = ( loadaddr.to_i(16) + testsize_hex.to_i(16) ).to_s(16)
  raise "Failed to get loadaddr and loadaddr2" if (loadaddr == nil or loadaddr2 == nil)
  return [loadaddr, loadaddr2]
end

# return in hex format like 80000000 (2GiB)
# get DRAM size
def get_dram_size()
  @equipment['dut1'].send_cmd("bdinfo", @equipment['dut1'].boot_prompt, 10)
  dram_size = @equipment['dut1'].response.match(/DRAM\s+bank\s*=\s*0x[0]+\s*->\s*start\s*=\s*0x\h+\s*->\s*?size\s*=\s*0x(\h+)/im).captures[0]
  return dram_size
end

# transfer data from linux host to ${loadaddr} in dut
def tftp_testfile_to_dut(testfile)
  # copy testfile to tftpboot
  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  dst_dir = File.join(@equipment['server1'].tftp_path, tmp_path)
  copy_asset(@equipment['server1'], testfile, dst_dir)
  # tftp to dut
  @equipment['dut1'].send_cmd("setenv serverip #{@equipment['server1'].telnet_ip}", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("setenv autoload no", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("dhcp", @equipment['dut1'].boot_prompt, 30)
  @equipment['dut1'].send_cmd("tftp ${loadaddr} #{tmp_path}/#{File.basename(testfile)}", @equipment['dut1'].boot_prompt, 120)
  raise "Could not tftp testfile to dut" if !@equipment['dut1'].response.match(/Bytes\s+transferred/im)
end

def get_scsi_biggest_dev(response)
  # parse the output of 'scsi scan' and get the biggest device for testing
  mat = response.scan(/Device\s+(\d+):.*?Capacity:\s+([0-9\.]+)\s+MB/im)

  puts mat.to_s
  puts mat.length
  puts mat[0][1]
  puts mat[1][1]

  i=0
  max_cap = 0
  while i < mat.length
    if mat[i][1].to_f > max_cap
      max_cap = mat[i][1].to_f
      testdev = i
    end
    i += 1
  end

  puts max_cap.to_s
  puts testdev.to_s
  return testdev, max_cap  
end

# filesize: in hex
# blk_len: in decimal
# return: in hex
def get_blk_cnt(filesize_hex, blk_len_dec)
  b = (filesize_hex.to_i(16).to_f / blk_len_dec.to_f).ceil
  cnt_hex = "0x" + b.to_s(16)
  return cnt_hex
end

