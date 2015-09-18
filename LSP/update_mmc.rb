# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../lib/utils'
require File.dirname(__FILE__)+'/lsp_helpers'

module UpdateMMC   

  include LspHelpers    
  PRIMARY_BOOLOADER_MD5_FILE = "primary_bootloader.md5"
  FS_MD5_FILE = "fs.md5"

  # Check mlo's signature and if mlo signature is different, we update both mlo and uboot
  def need_update_mmcbootloader?(params)
    params['mmc_boot_mnt_point'] = find_mmc_mnt_point('boot')
    signature_file = "#{params['mmc_boot_mnt_point']}/#{PRIMARY_BOOLOADER_MD5_FILE}"
    return true if !dut_dir_exist?(signature_file)
    old_signature = read_signature(signature_file)
    new_signature = @test_params.instance_variable_defined?(:@var_primary_bootloader_md5) ? @test_params.var_primary_bootloader_md5 : calculate_signature(params['primary_bootloader'])
    params['mlo_signature'] = new_signature
    (old_signature != new_signature)
  end

  def update_mmcbootloader(params)
    mlo_signature = params.has_key?('mlo_signature') ? params['mlo_signature'] : calculate_signature(params['primary_bootloader'])
    # copy mlo and uboot.img to mmc boot partition
    transfer_file_to_dut(params['primary_bootloader'], params['mmc_boot_mnt_point']+"/MLO")
    transfer_file_to_dut(params['secondary_bootloader'], params['mmc_boot_mnt_point']+"/u-boot.img")
    flush_to_mmc(params['mmc_boot_mnt_point']) 
    save_signature(mlo_signature, params['mmc_boot_mnt_point']+"/#{PRIMARY_BOOLOADER_MD5_FILE}")
  end

  def need_update_mmcfs?(params)
    params['mmc_boot_mnt_point'] = find_mmc_mnt_point('boot') if !params.has_key?('mmc_boot_mnt_point')
    signature_file = "#{params['mmc_boot_mnt_point']}/#{FS_MD5_FILE}"
    return true if !dut_dir_exist?(signature_file)
    old_signature = read_signature(signature_file)
    new_signature = @test_params.instance_variable_defined?(:@var_fs_md5) ? @test_params.var_fs_md5 : calculate_signature(params['fs'])
    params['fs_signature'] = new_signature
    (old_signature != new_signature)
  end

  def update_mmcfs(params)
    fs_signature = params.has_key?('fs_signature') ? params['fs_signature'] : calculate_signature(params['fs'])

    # boot from nfs, then update mmc rootfs
    boot_from_nfs(params) 

    params['nfs_root'] = find_nfsroot

    # transfer the rootfs tarball to nfs root directory
    fs_tarball_src = "/#{File.basename(params['fs'])}"
    fs_tarball_path = params['nfs_root'].sub("#{params['server'].telnet_ip}:","")+fs_tarball_src
    params['server'].send_sudo_cmd("rm -f #{fs_tarball_path}", params['server'].prompt, 60)
    params['server'].send_sudo_cmd("cp #{params['fs']} #{fs_tarball_path}", params['server'].prompt, 120)
    raise "Failed to copy fs tarball from #{params['fs']} to nfsroot: #{fs_tarball_path}" if !cmd_exit_zero?(params['server'])
    params['mmc_fs_mnt_point'] = find_mmc_mnt_point('fs')

    # remove everything in mmc p2 before extract rootfs tarball
    raise "MMC is used for rootfs, rootfs partition can not be deleted and updated!" if mmc_rootfs?
    params['dut'].send_cmd("rm -rf #{params['mmc_fs_mnt_point']}/*", params['dut'].prompt, 120)
    # populate the fs tarball into mnt_fs_mnt_point
    tar_options = get_tar_options(params['fs'], params)
    params['dut'].send_cmd("tar -C #{params['mmc_fs_mnt_point']} #{tar_options} #{fs_tarball_src}", params['dut'].prompt, 600)
    params['dut'].send_cmd("echo $?", /^0[\0\n\r]+/m, 2)
    raise "There is error when untar rootfs tarball #{fs_tarball_src} to #{params['mmc_fs_mnt_point']}; Updating MMC rootfs failed; The content of MMC P2 was being deleted and you will not be able to boot rootfs from MMC. Sorry! Please check why untar failed and re-try again " if params['dut'].timeout?

    flush_to_mmc(params['mmc_fs_mnt_point'])

    # save signature after mmc rootfs is successfully updated 
    params['mmc_boot_mnt_point'] = find_mmc_mnt_point('boot')
    save_signature(fs_signature, params['mmc_boot_mnt_point']+"/#{FS_MD5_FILE}")
  end

  def check_mmc_update_inputs(params, key)
    if !params.has_key?(key) ||  params[key] == ""
      raise "#{key} is needed for updating mmc card; please provide it!"
    end
  end

  def boot_from_nfs(params)
    # setup nfs in tee
    params['fs_type'] = 'nfs'
    params.delete('var_nfs') if params.has_key?('var_nfs')
    setup_nfs params
    # copy boot/zImage and dtb to tftpboot
    kernel_name = "zImage"
    dtb_name = get_dtb_name(params['dut'].name)
    nfs_base_dir = params['nfs_path'].sub("#{params['server'].telnet_ip}:","")
    kernel_path = nfs_base_dir + "/boot/" + kernel_name
    if !File.exist?(kernel_path)
      Dir.chdir("#{nfs_base_dir}/boot")
      kernel_name = Dir.glob('zImage-*')[0]
      kernel_path = nfs_base_dir + "/boot/" + kernel_name
    end
    dtb_path = nfs_base_dir + "/boot/" + dtb_name
    raise "#{kernel_name} or #{dtb_name} is not found in rootfs; Those files are needed for updating rootfs in MMC." if !File.exist?(kernel_path) || !File.exist?(dtb_path)
    tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
    copy_asset(params['server'], kernel_path, File.join(params['server'].tftp_path, tmp_path))
    copy_asset(params['server'], dtb_path, File.join(params['server'].tftp_path, tmp_path))

    params['kernel_image_name'] = File.join(tmp_path, kernel_name)
    params['dtb_image_name'] = File.join(tmp_path, dtb_name)
    params['kernel_src_dev'] = 'eth'
    params['dtb_src_dev'] = 'eth'
    params['fs_type'] = 'nfs'
    params.delete('var_use_default_env') if params.has_key?('var_use_default_env')
    params['dut'].system_loader = nil
    params['dut'].boot(params)
  end

  def mmc_rootfs?
    @equipment['dut1'].send_cmd("cat /proc/cmdline")
    return true if /root=\/dev\/mmcblk.*/.match(@equipment['dut1'].response) 
    return false
  end
 
  def calculate_signature(file, device=@equipment['server1'])
    device.send_cmd("md5sum #{file}", device.prompt, 60)
    signature = /^(\h{32,}).*/m.match(device.response).captures[0]
    raise "Failed to get md5sum for #{file}" if !signature
    return signature
  end

  # save signature to dst file
  def save_signature(signature, dst, device=@equipment['dut1'])
    device.send_cmd("echo #{signature} > #{dst}", device.prompt, 5) 
    device.send_cmd("cat #{dst} |grep #{signature}", device.prompt, 5)
    device.send_cmd("echo $?", /^0[\0\n\r]+/m, 2)
    raise "Failed to save sigature to #{dst}" if device.timeout?
  end

  def read_signature(file, device=@equipment['dut1'])
    device.send_cmd("cat #{file}", device.prompt, 5)

    m = /^(\h{32,})/.match(device.response)
    if m == nil
      raise "Failed to read signature from #{file}; Maybe the signature is not 32char md5? The output of cat is as below: \n#{device.response}"
    end

    return m.captures[0].strip
  end

  def transfer_file_to_dut(src, dst)
    scp_push_file(get_ip_addr(), src, dst)
  end

  def flush_to_mmc(mnt_point)
    @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 120)
    @equipment['dut1'].send_cmd("echo 3 > /proc/sys/vm/drop_caches", @equipment['dut1'].prompt, 60)
  end

  def find_mmc_mnt_point(part)
    mmc_basenode = find_mmc_basenode
    raise "Failed to find mmc_basenode" if ! /mmcblk/.match(mmc_basenode)

    p = part == "boot" ? "p1" : part == "fs" ? "p2" : ""
    raise "#{part} is not supported! 'boot' or 'fs' are valid partition name" if p==""

    @equipment['dut1'].send_cmd("mount |grep #{mmc_basenode}#{p} ")
    mnt_point_match = /#{mmc_basenode}#{p}\s+on\s+([\w\/]+)\s+/im.match(@equipment['dut1'].response)
    raise "Failed to find mmc mount point for #{part}" if mnt_point_match == nil
    return mnt_point_match.captures[0] 
  end

  def find_mmc_basenode()
    @equipment['dut1'].send_cmd("ls /dev/mmcblk*", @equipment['dut1'].prompt, 10)
    m = @equipment['dut1'].response.scan(/\/dev\/mmcblk[0-9]/im)
    raise "find_mmc_basenode:No match being found for mmcblk" if m.count == 0
    m.each do |basenode|
      @equipment['dut1'].send_cmd("ls #{basenode}* ")
      next if /#{basenode}boot/.match(@equipment['dut1'].response)
      return basenode
    end 
  end

end
