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
    params['dut'].send_cmd("tar -C #{params['mmc_fs_mnt_point']} #{tar_options} #{fs_tarball_src}", params['dut'].prompt, 1200)
    params['dut'].send_cmd("echo $?", /^0[\0\n\r]+/m, 2)
    raise "There is error when untar rootfs tarball #{fs_tarball_src} to #{params['mmc_fs_mnt_point']}; Updating MMC rootfs failed; The content of MMC P2 was being deleted and you will not be able to boot rootfs from MMC. Sorry! Please check why untar failed and re-try again " if params['dut'].timeout?

    flush_to_mmc(params['mmc_fs_mnt_point'])

    # save signature after mmc rootfs is successfully updated 
    params['mmc_boot_mnt_point'] = find_mmc_mnt_point('boot')
    save_signature(fs_signature, params['mmc_boot_mnt_point']+"/#{FS_MD5_FILE}")
  end

  def setup_ti_test_gadget(params)
    sd_switch_info = params['dut'].params['microsd_switch'].keys[0]
    if !@equipment.has_key? 'ti_test_gadget'
      report_msg "Setting up ti_test_gadget ..."
      add_equipment('ti_test_gadget') do |log_path|
        Object.const_get(sd_switch_info.driver_class_name).new(sd_switch_info,log_path)
      end
      @equipment['ti_test_gadget'].connect({'type'=>'serial'})
    end
  end
  
  # Check if create partition is needed
  def check_partition(boot_partition,params,boot_mnt_point,host_node,num_partitions)
    mount_partition(boot_partition, boot_mnt_point, 'vfat', params)
    partition_file = "#{boot_mnt_point}/partition_info.txt"
    if(@test_params.instance_variable_defined?(:@var_partition_info))
      a = @test_params.var_partition_info
    else
      #write default values if var_partition_info isnt defined
      a = "10#boot#vfat#y,40#rootfs#ext4#n,50#data#ext4#n"
    end
    # No partition_info file 
    if !File.file?(partition_file)
      unmount_partition(boot_partition,params)
      create_partition(host_node)    
      mount_partition(boot_partition,boot_mnt_point,'vfat',params)
      params['server'].send_sudo_cmd("sh -c 'echo #{a} > #{boot_mnt_point}/partition_info.txt'", params['server'].prompt, 60)
    # Partition_info file exists
    else    
      line = File.open("#{boot_mnt_point}/partition_info.txt") {|f| f.readline}
      if(line.strip().downcase() != a.strip().downcase() || a.split(',').length != num_partitions)
        unmount_partition(boot_partition,params)
        create_partition(host_node)  
        mount_partition(boot_partition,boot_mnt_point,'vfat',params)
        params['server'].send_sudo_cmd("sh -c 'echo #{a} > #{boot_mnt_point}/partition_info.txt'", params['server'].prompt, 60)
      end
    end
  end

  def create_partition(host_node)
    if(@test_params.instance_variable_defined?(:@var_partition_info))
      a = @test_params.var_partition_info
      tot_part = a.count(",") + 1
      part_arr = a.split(",")
      i=0
      size_arr = Array.new(4)
      part_str = "SYMNAME #{host_node}" 
      while i < tot_part
        if(part_arr[i].count("#") != 3)
          raise "Invalid var_partition_info input"
        end
        temp = part_arr[i].split("#") 
        part_str << " size #{temp[0]} name #{temp[1]} type #{temp[2]} bootflg #{temp[3]}"
        size_arr[i] = temp[0]
        i += 1
      end
    else
      part_str = "SYMNAME #{host_node} size 10 size 40 size 50 name boot name rootfs name data type vfat type ext4 type ext4 bootflg y bootflg n bootflg n"
      size_arr = [10,40,50]
    end
    tot_size = size_arr.map(&:to_i).reduce(:+)
    if tot_size.to_i > 100
      raise "Partition size cannot be greater than 100%!"
    end
    report_msg "Creating partition with #{part_str}"
    my_staf_handle = STAFHandle.new("my_staf")
    staf_req = my_staf_handle.submit("local","PARTITION",part_str)
    if(staf_req.rc == 0)
      tmc_machine = staf_req.result
    else
      tmc_machine = nil
      raise "Could not resolve PARTITION. Make sure that STAF is running and the TEE is reqistered with TMC Dispatcher"
    end
  end


  def flash_sd_card_from_host(params)
      report_msg "Going to flash SD card from host if required ..."
      boot_mnt_point = File.join(@linux_temp_folder, 'mnt', 'boot')
      rootfs_mnt_point = File.join(@linux_temp_folder, 'mnt', 'rootfs')
      params['dut'].connect({'type'=>'serial'}) if !params['dut'].target.serial
      params['dut'].poweroff(params) if params['dut'].at_prompt?({'prompt'=>params['dut'].prompt})
      params['dut'].disconnect('serial')

      #Resolve symlink and get nodes
      host_node = params['dut'].params['microsd_host_node']
      if File.symlink?(host_node)
        node = "/dev/#{File.readlink(host_node)}"
      else
        node = host_node
      end
      node = node.strip.sub(/\d*$/, '') # only keep base node like sdb not sdb1.
      setup_ti_test_gadget(params)
      @equipment['ti_test_gadget'].set_interfaces(params['dut'].params)

    begin
      report_msg "Switching to host"
      @equipment['ti_test_gadget'].switch_microsd_to_host(params['dut'])
      sleep 2 
      20.times {
        params['server'].send_cmd("ls #{node}[[:digit:]]*; echo $?", /^0[\0\n\r]+/im, 2)
        if params['server'].timeout?
          sleep 2
        else
          break
        end
      }
      params['server'].send_sudo_cmd("partprobe -s", params['server'].prompt, 30)
      params['server'].send_cmd("ls #{node}[[:digit:]]*; echo $?", /^0[\0\n\r]+/im, 2)
      raise "Failed to switch to host" if params['server'].timeout?
      nodes = params['server'].response.split("\n")
      sleep 1

      # Temporally comment out check_partition to skip partition creation part
      #check_partition(nodes[0],params,boot_mnt_point,host_node,nodes.length)

      params['server'].send_cmd("ls #{node}[[:digit:]]*", params['server'].prompt, 10)
      nodes = params['server'].response.split("\n")
      if nodes.size < 2
        raise "SD card needs at least two partitions!"
      end
      params = flash_sd_boot_partition_from_host(nodes[0], boot_mnt_point, params)
      params = flash_sd_rootfs_partition_from_host(nodes[1], rootfs_mnt_point, params)
      return params

    rescue Exception => e
      raise e
    ensure
      if nodes
        unmount_partition(nodes[0], params)
        unmount_partition(nodes[1], params)
      end
      report_msg "Switching to DUT..."
      @equipment['ti_test_gadget'].switch_microsd_to_dut(params['dut'])
      params['server'].send_sudo_cmd("eject #{params['dut'].params['microsd_host_node']}",params['server'].prompt, 60)
      sleep 5
    end

  end

  def mount_partition(partition, mnt_point, type, params)
    # skip mount if already mounted
    params['server'].send_cmd("mount |grep #{partition}", params['server'].prompt,10)
    return if params['server'].response.match(/#{partition}\s+on\s+#{mnt_point}/i)

    params['server'].send_cmd("mkdir -p #{mnt_point}", params['server'].prompt, 10)
    params['server'].send_sudo_cmd("mount -t #{type} #{partition} #{mnt_point}", params['server'].prompt, 90)
    raise "Could not mount #{partition} on host PC" if ! system "mount | grep #{partition}"
  end

  def unmount_partition(partition, params)
    # unmount all mount points for this partition
    count = 0 # Using count to prevent while-loop stuck
    while count < 10 
      params['server'].send_cmd("mount |grep #{partition}; echo $?", /^0[\0\n\r]+/im, 30)
      break if params['server'].timeout?
      params['server'].send_sudo_cmd("umount -l #{partition}", params['server'].prompt, 300)
      sleep 1
      count += 1
    end
    raise "Could not umount #{partition} on host PC" if system "mount | grep #{partition}"
  end

  def need_update_mmcbootloader_from_host?(boot_partition, mnt_point, params)
    mount_partition(boot_partition,mnt_point,'vfat',params)
    signature_file = "#{mnt_point}/#{PRIMARY_BOOLOADER_MD5_FILE}"
    return true if ! system "ls #{signature_file}"
    old_signature = read_signature(signature_file, params['server'])
    new_signature = @test_params.instance_variable_defined?(:@var_primary_bootloader_md5) ? @test_params.var_primary_bootloader_md5 : calculate_signature(params['primary_bootloader'])
    params['mlo_signature'] = new_signature
    (old_signature != new_signature)
  end

  def need_update_rootfs_from_host?(rootfs_partition, mnt_point, params)
    mount_partition(rootfs_partition, mnt_point, 'ext4', params)
    signature_file = "#{mnt_point}/#{FS_MD5_FILE}"
    return true if ! system "ls #{signature_file}"
    old_signature = read_signature(signature_file, params['server'])
    new_signature = @test_params.instance_variable_defined?(:@var_fs_md5) ? @test_params.var_fs_md5 : calculate_signature(params['fs'])
    params['fs_signature'] = new_signature
    (old_signature != new_signature)
  end

  def flash_sd_boot_partition_from_host(boot_partition, mnt_point, params)
    if params.has_key?('primary_bootloader') && params.has_key?('secondary_bootloader') &&
     need_update_mmcbootloader_from_host?(boot_partition, mnt_point, params)
      report_msg "Updating bootloader in MMC from host ..."
      mlo_signature = params.has_key?('mlo_signature') ? params['mlo_signature'] : calculate_signature(params['primary_bootloader'])
      params['server'].send_sudo_cmd("cp -f #{params['primary_bootloader']} #{mnt_point}/MLO", params['server'].prompt, 30)
      raise "Could not copy primary_bootloader to SD card" if !cmd_exit_zero?(params['server'])
      params['server'].send_sudo_cmd("cp -f #{params['secondary_bootloader']} #{mnt_point}/u-boot.img", params['server'].prompt, 30)
      raise "Could not copy secondary_bootloader to SD card" if !cmd_exit_zero?(params['server'])
      save_signature(mlo_signature, mnt_point+"/#{PRIMARY_BOOLOADER_MD5_FILE}", true, params['server'])
    end
    return params
  end

  def flash_sd_rootfs_partition_from_host(root_partition, mnt_point, params)
    if params.has_key?('fs') && params['fs'] != ''
      if need_update_rootfs_from_host?(root_partition, mnt_point, params)
        report_msg "Updating rootfs in MMC from host ..."
        fs_signature = params.has_key?('fs_signature') ? params['fs_signature'] : calculate_signature(params['fs'])
        params['server'].send_sudo_cmd("rm -rf #{mnt_point}/*", params['server'].prompt, 120)
        raise "Could not remove old filesystem from SD card" if !cmd_exit_zero?(params['server'])
        tar_options = get_tar_options(params['fs'], params)
        params['server'].send_sudo_cmd("tar -C #{mnt_point}/ #{tar_options} #{params['fs']}", params['server'].prompt, 2400)
        raise "Could not untar rootfs to SD card" if !cmd_exit_zero?(params['server'])
        save_signature(fs_signature, mnt_point+"/#{FS_MD5_FILE}", true, params['server'])
      end
    end
    return params
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
  def save_signature(signature, dst, sudo=false, device=@equipment['dut1'])
    report_msg("Writing signature to #{dst}")
    if sudo
      device.send_sudo_cmd("sh -c 'echo #{signature} > #{dst}'", device.prompt, 5)
      device.send_cmd("cat #{dst} |grep #{signature}", device.prompt, 5)
    else
      device.send_cmd("echo #{signature} > #{dst}", device.prompt, 5)
      device.send_cmd("cat #{dst} |grep #{signature}", device.prompt, 5)
    end
    raise "Failed to save signature to #{dst}" if !cmd_exit_zero?(device)
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
    @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 300)
    @equipment['dut1'].send_cmd("echo 3 > /proc/sys/vm/drop_caches", @equipment['dut1'].prompt, 60)
  end

  def find_mmc_mnt_point(part)
    mmc_basenode = find_mmc_basenode
    raise "Failed to find mmc_basenode" if ! /mmcblk/.match(mmc_basenode)

    p = part == "boot" ? "p1" : part == "fs" ? "p2" : ""
    raise "#{part} is not supported! 'boot' or 'fs' are valid partition name" if p==""

    @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 20)
    @equipment['dut1'].send_cmd("mount |grep #{mmc_basenode}#{p} ", @equipment['dut1'].prompt, 10)
    mnt_point_match = /#{mmc_basenode}#{p}\s+on\s+([\w\/]+)\s+/im.match(@equipment['dut1'].response)
    raise "Failed to find mmc mount point for #{part}" if mnt_point_match == nil
    return mnt_point_match.captures[0] 
  end

  def find_mmc_basenode()
    @equipment['dut1'].send_cmd("ls /dev/mmcblk*", @equipment['dut1'].prompt, 10)
    m = @equipment['dut1'].response.scan(/\/dev\/mmcblk[0-9]/im)
    raise "find_mmc_basenode:No match being found for mmcblk" if m.count == 0
    m.each do |basenode|
      @equipment['dut1'].send_cmd("ls #{basenode}* ", @equipment['dut1'].prompt, 10)
      next if /#{basenode}boot/.match(@equipment['dut1'].response)
      return basenode
    end 
  end

end
