# -*- coding: ISO-8859-1 -*-
# This script flash kernel/dtb/rootfs to nand and then boot them from nand
# So, softasset kernel, dtb and nand_rootfs_img needs to be passed through test_params.
# If run from Testlink, build description needs have these defined.
# If volume_name in ubi image is different from default one 'rootfs', use 'var_volume_name' to set

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/utils'

include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run

  test_result = 0 # '0' is pass; else fail
  params = {}
  result_msg = 'this test pass'
  test_loop = @test_params.params_chan.test_loop[0] if @test_params.params_chan.instance_variable_defined?(:@test_loop)
  times_to_reboot = @test_params.params_chan.times_to_reboot[0] if @test_params.params_chan.instance_variable_defined?(:@times_to_reboot)

  params['use_ubiformat'] = @test_params.params_chan.instance_variable_defined?(:@use_ubiformat) ? @test_params.params_chan.use_ubiformat[0] : "1"
  params['fstype'] = @test_params.params_chan.instance_variable_defined?(:@fstype) ? @test_params.params_chan.fstype[0] : "ubifs"
  params['device_type'] = @test_params.params_chan.instance_variable_defined?(:@device_type) ? @test_params.params_chan.device_type[0] : "nand"
  params['ubi_device'] = @test_params.params_chan.instance_variable_defined?(:@ubi_device) ? @test_params.params_chan.ubi_device[0] : "ubi0"
 
  params['volume_name'] = @test_params.instance_variable_defined?(:@var_volume_name) ? @test_params.var_volume_name : "rootfs"

  # get test related params (partition numbers and pagesize etc) from ltp-ddt
  params = get_mtd_params(params)
  params.each{|k,v| puts "#{k}:#{v}"}

  # write kernel and rootfs images to nand
  write_images_to_nand(params)

  # do extra mount to test ubifs filesystem or other filesystem can still be recovered =====
  mount_rootfs = '0'
  mount_rootfs = @test_params.params_chan.instance_variable_defined?(:@mount_rootfs) ? @test_params.params_chan.mount_rootfs[0] : '0'
  if mount_rootfs == '1'
    do_extra_mount(params)
  end

  # run test using nand as rootfs =====
  booting_log = ''
  diff_cnt = 0

  times_to_reboot.to_i.times {|i|

    translated_boot_params = setup_host_side()
    @equipment['dut1'].boot_to_bootloader(translated_boot_params)

    if i == 0
      raise "nandboot was not defined in uboot" if ! nandboot_defined?
      raise "nandroot does not contain valid info" if ! nandroot_valid?(params)
    end

    @equipment['dut1'].send_cmd("run nandboot", @equipment['dut1'].login_prompt, 300)
    booting_log = @equipment['dut1'].response
    if @equipment['dut1'].timeout?
      set_result(FrameworkConstants::Result[:fail], "rootfs=#{params['fstype']}: Unable to boot platform.")
      return
    else 
      # make sure the rootfs is the right one
      regex = Regexp.new("(#{params['fstype']} filesystem)")
      if !regex.match(booting_log) then
        set_result(FrameworkConstants::Result[:fail], "Mounted rootfs is not #{params['fstype']} at #{i+1}-th times")
        return
      end
      @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10) # login to the unit
    end

   sleep 5

    # do read write test under nand filesystem
    test_loop.to_i.times {|j|
      puts "=========read write test loop: #{j}\n"
      #sleep 1
      @equipment['dut1'].send_cmd("df -h", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("dd if=/dev/urandom of=/testfile1 bs=1M count=1", @equipment['dut1'].prompt, 60)
      # IMPORTANT: without this sync after the 1st ubifs bootup, recovery would fail on the successive boot.
      @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("echo 3 > /proc/sys/vm/drop_caches", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("dd if=/testfile1 of=/testfile2 bs=1M count=1", @equipment['dut1'].prompt, 60)
      @equipment['dut1'].send_cmd("diff /testfile1 /testfile2", @equipment['dut1'].prompt, 60)
      @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
      if @equipment['dut1'].timeout?
        diff_cnt = diff_cnt + 1
      end
      @equipment['dut1'].send_cmd("rm /testfile1 /testfile2", @equipment['dut1'].prompt, 20)
    } #test_loop

    @equipment['dut1'].log_info("===boot_loop: #{i+1}: diff cnt is #{diff_cnt}===") 

  } #reboot_loop

  if diff_cnt != 0 
    set_result(FrameworkConstants::Result[:fail], "rootfs=#{params['fstype']}: Data corruption #{diff_cnt} times.")
  else
    set_result(FrameworkConstants::Result[:pass], result_msg)
  end

end


def clean
  self.as(LspTestScript).clean
  puts 'child clean'
  # Force reboot on next test case so the next test case would not be affected by this one
  @old_keys = ''
  #self.as(LspTestScript).setup
end

# get partition number based on partition name from ltp-ddt
def get_mtd_part(device_type, part_name)
  @equipment['dut1'].send_cmd("source 'mtd_common.sh' ", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("get_partnum_from_name #{device_type} #{part_name}", @equipment['dut1'].prompt, 20)
  if !@equipment['dut1'].response.match(/^[0-9]+/)
    raise "Failed to find partition number for #{part_name}"
  end
  rtn = @equipment['dut1'].response.match(/^[0-9]+/)[0]
  puts "rtn from get_mtd_part:#{rtn}"
  rtn
end

# get the type of partition from ltp-ddt
def get_mtd_info(type, part)
  @equipment['dut1'].send_cmd("source 'mtd_common.sh' ", @equipment['dut1'].prompt, 10)
  devnode = "/dev/mtd#{part}"
  case type
  when "page_size"
    @equipment['dut1'].send_cmd("get_pagesize #{devnode} ", @equipment['dut1'].prompt, 10)
  when "subpage_size"
    @equipment['dut1'].send_cmd("get_subpagesize #{devnode} ", @equipment['dut1'].prompt, 10)
  else
    raise "Unknown mtd info type input. Could not get mtdinfo for it"
  end

  if !@equipment['dut1'].response.match(/^[0-9]+/)
    raise "Failed to get mtdinfo for mtd partition #{part}"
  end
  @equipment['dut1'].response.match(/^[0-9]+/)[0]
end

def get_mtd_params(params={})
  begin
    new_params = params.clone
    dut_orig_path = save_dut_orig_path()
    export_ltppath()
    
    new_params['kernel_part'] = get_mtd_part(params['device_type'], CmdTranslator.get_linux_cmd({'cmd'=>'nand_kernel_part_name', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version}) )
    new_params['dtb_part'] = get_mtd_part(params['device_type'], CmdTranslator.get_linux_cmd({'cmd'=>'nand_dtb_part_name', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version}) )
    new_params['rootfs_part'] = get_mtd_part(params['device_type'], CmdTranslator.get_linux_cmd({'cmd'=>'nand_rootfs_part_name', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version}) )

    new_params['page_size'] = get_mtd_info("page_size", new_params['rootfs_part'])
    new_params['subpage_size'] = get_mtd_info("subpage_size", new_params['rootfs_part'])

    restore_dut_path(dut_orig_path)
    new_params

  rescue Exception => e
    restore_dut_path(dut_orig_path)
    puts e.message
    puts e.backtrace
    raise "There is errors when getting mtd params"
  end

end


def write_images_to_nand(params)

  # copy the files to dut
  kernel_img = "/kernel.img"
  dtb_img = "/dtb.img"
  rootfs_img = "/rootfs.img"
  if !@test_params.instance_variable_defined?(:@kernel) || !@test_params.instance_variable_defined?(:@dtb) || !@test_params.instance_variable_defined?(:@nand_rootfs_img)
    raise "One of these soft assets {kernel, dtb, nand_rootfs_img} are not defined"
  else
    scp_push_file(get_ip_addr, @test_params.kernel, kernel_img)
    scp_push_file(get_ip_addr, @test_params.dtb, dtb_img)
    scp_push_file(get_ip_addr, @test_params.nand_rootfs_img, rootfs_img)
  end

  device_node_kernel = "/dev/mtd#{params['kernel_part']}"
  device_node_dtb = "/dev/mtd#{params['dtb_part']}"
  device_node_rootfs = "/dev/mtd#{params['rootfs_part']}"

  # flash kernel and dtb to nand
  nandwrite_image(device_node_kernel, kernel_img)
  nandwrite_image(device_node_dtb, dtb_img)

  # populate fs in nand 
  if params['use_ubiformat'] == '1'
    ubiformat_image(params, device_node_rootfs, rootfs_img)
  else
    nandwrite_image(device_node_rootfs, rootfs_img)
  end
  if /error/i.match(@equipment['dut1'].response)
    raise "Error occurs when write rootfs image to nand"
  end

end

def nandwrite_image(device_node, img)
  raise "#{img} doesn't exist" if !dut_dir_exist?(img)
  
  @equipment['dut1'].send_cmd("flash_erase -q #{device_node} 0 0", @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd("nandwrite -p #{device_node} #{img}", @equipment['dut1'].prompt, 60)
  if /error/i.match(@equipment['dut1'].response)
    raise "Error occurs when writing image to nand"
  end
end

def ubiformat_image(params, device_node, img)
  page_size = params['page_size']
  subpage_size = params['subpage_size']
  @equipment['dut1'].send_cmd("flash_erase -q #{device_node} 0 0", @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd("ubidetach -p #{device_node}", @equipment['dut1'].prompt, 60) 
  # using ubiformat to write img
  @equipment['dut1'].send_cmd("ubiformat #{device_node} -q -f #{img} -s #{subpage_size} -O #{page_size}", @equipment['dut1'].prompt, 60)
end

def nandboot_defined?
  @equipment['dut1'].send_cmd("print nandboot", @equipment['dut1'].boot_prompt, 10)
  ! @equipment['dut1'].response.match(/not\s+defined/)
end

def nandroot_valid?(params)
  rootfs_part = params['rootfs_part']
  page_size = params['page_size']
  volume_name = params['volume_name']
  ubi_device = params['ubi_device']
  fstype = params['fstype']

  rtn = false
  @equipment['dut1'].send_cmd("print nandroot", @equipment['dut1'].boot_prompt, 10)
  case fstype
  when 'ubifs'
    # check if vid_header_oset and volume name is correct in uboot
    vn = @equipment['dut1'].response.match(/#{ubi_device}:(.*?)\s+/)[1]
    ps = @equipment['dut1'].response.match(/ubi\.mtd=.*,([0-9]+)/)[1]
    if ps == page_size && vn == volume_name
      rtn = true
    end
  else
    # For now just return true for other fstype; don't validate nandroot
    rtn = true
  end
    
  rtn
end

def do_extra_mount(params)
  fstype = params['fstype']
  rootfs_part = params['rootfs_part']
  page_size = params['page_size']
  ubi_device = params['ubi_device']
  volume_name = params['volume_name']

  @equipment['dut1'].send_cmd("mkdir -p /mnt/nand_#{fstype}", @equipment['dut1'].prompt, 60)
  mnt_point = "/mnt/nand_#{fstype}"
  if fstype == 'ubifs'
    @equipment['dut1'].send_cmd("ubiattach /dev/ubi_ctrl -m #{rootfs_part} -O #{page_size}", @equipment['dut1'].prompt, 60)
    @equipment['dut1'].send_cmd("mount -t ubifs #{ubi_device}:#{volume_name} #{mnt_point}", @equipment['dut1'].prompt, 60)
  else
    @equipment['dut1'].send_cmd("mount -t #{fstype} /dev/mtdblock#{rootfs_part} #{mnt_point}", @equipment['dut1'].prompt, 60)
  end
end
