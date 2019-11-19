def start_linux_demo()
    @equipment['dut1'].send_cmd("modprobe jailhouse",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cd /opt/ltp",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/jailhouse -s \"JAILHOUSE_S_FUNC_LINUX_INMATE \"",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cd",@equipment['dut1'].prompt)
    # Wait for the login prompt
    jh_send_cmd("", @equipment['dut1'].login_prompt)
end

def jh_send_cmd(cmd, expected_match=/.*/, timeout=10, check_cmd_echo=true, append_linefeed=true, conn=@equipment['dut1'].target.secondary_serial)
    puts("Connection: " + cmd)
    conn.send_cmd(cmd, expected_match, timeout, check_cmd_echo, append_linefeed)
    [conn.timeout?, conn.response]
end

def setup_jailhouse_emmc_rootfs()
  @equipment['dut1'].send_cmd("ls -d /sys/class/block/mmcblk[0-9]", @equipment['dut1'].prompt)
  mmc_devs = @equipment['dut1'].response.scan(/(.*?(mmcblk\d+))/)
  raise "Unable to detect mmc devices:\n #{@equipment['dut1'].response}" if mmc_devs.empty?
  #Find EMMC block device
  emmc_dev = nil
  mmc_devs.each do |dev|
    @equipment['dut1'].send_cmd("cat #{dev[0]}/device/name", @equipment['dut1'].prompt)
    if @equipment['dut1'].response.match(/S0J56X/)
      emmc_dev = dev[1]
      break
    end
  end
  raise "Unable to find emmc device" if !emmc_dev
  #Check if EMMC is mounted
  @equipment['dut1'].send_cmd("mount | grep #{emmc_dev}",@equipment['dut1'].prompt)
  emmc_mnt_info = @equipment['dut1'].response.scan(/\/dev\/(#{emmc_dev}[^\s]+)\s*on\s*(.*?)\stype.*?/m).to_h
  if !emmc_mnt_info.empty?
    emmc_mnt_info.each do |d,mnt|
      raise "Emmc is being used for the hypervisor root fs and cannot be used as an inmate root fs" if mnt == '/'
    end
  end
  #Check partitions and labels
  @equipment['dut1'].send_cmd("lsblk -o name,label /dev/#{emmc_dev}",@equipment['dut1'].prompt)
  emmc_label_info = @equipment['dut1'].response.scan(/(#{emmc_dev}p[^\s]+) +([^\r\n]+)/m).to_h
  emmc_root_partition_mnt = nil
  emmc_root_partition = nil
  puts "EMMC mount  info: #{emmc_mnt_info}"
  puts "EMMC label info: #{emmc_label_info}"
  emmc_label_info.each do |p, label|
    if label == 'root'
      emmc_root_partition_mnt = emmc_mnt_info[p]
      emmc_root_partition = "/dev/#{p}"
      if !emmc_root_partition_mnt
        emmc_root_partition_mnt = '/mnt/emmc-rootfs'
        @equipment['dut1'].send_cmd("mkdir #{emmc_root_partition_mnt}",@equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd("mount /dev/#{p} #{emmc_root_partition_mnt}",@equipment['dut1'].prompt)
      end
      break
    end
  end
  #No root partition detected in emmc, create one
  if !emmc_root_partition_mnt
    emmc_mnt_info.each do |d, mnt|
      @equipment['dut1'].send_cmd("kill `fuser #{mnt}`", @equipment['dut1'].prompt)
      @equipment['dut1'].send_cmd("umount /dev/#{d}", @equipment['dut1'].prompt)
    end
    @equipment['dut1'].send_cmd("sfdisk -l /dev/#{emmc_dev}", @equipment['dut1'].prompt)
    dev_data = @equipment['dut1'].response.match(/Disk.*?bytes,\s*(\d+)\s*sectors.*?Units:\s*sectors\s*of.*?=\s*(\d+)\s*bytes/im)
    total_sectors = dev_data.captures[0].to_i
    sector_size = dev_data.captures[1].to_i
    boot_p_sectors = 1 + 50000000/sector_size
    data_p_sectors = (total_sectors - boot_p_sectors)/8
    root_p_sectors = total_sectors - boot_p_sectors - data_p_sectors
    @equipment['dut1'].send_cmd("sfdisk --delete /dev/#{emmc_dev}", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("sfdisk /dev/#{emmc_dev} << EOF")
    @equipment['dut1'].send_cmd(",#{boot_p_sectors},c,*")
    @equipment['dut1'].send_cmd(",#{root_p_sectors},")
    @equipment['dut1'].send_cmd(";")
    @equipment['dut1'].send_cmd("EOF",@equipment['dut1'].prompt, 300)
    @equipment['dut1'].send_cmd("mkfs.ext4 -F -L root /dev/#{emmc_dev}p2",@equipment['dut1'].prompt,300)
    emmc_root_partition_mnt = '/mnt/emmc-rootfs'
    emmc_root_partition = "/dev/#{emmc_dev}p2"
    @equipment['dut1'].send_cmd("mkdir #{emmc_root_partition_mnt}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("mount /dev/#{emmc_dev}p2 #{emmc_root_partition_mnt}",@equipment['dut1'].prompt)
  end
  @equipment['dut1'].send_cmd("ls #{emmc_root_partition_mnt}/lib/modules/`uname -r`", @equipment['dut1'].prompt)
  if @equipment['dut1'].response.match(/No\s*such\s*file\s*or\s*directory/im)
    fs = @test_params.instance_variable_defined?(:@fs) ? @test_params.fs : 
         @test_params.instance_variable_defined?(:@nfs) ? @test_params.nfs : nil
    raise "File system is needed but not specified" if !fs
    @equipment['dut1'].send_cmd("tftp -g -r #{fs.gsub(/^#{@equipment['server1'].tftp_path}\/{0,1}/,'')} -l fs.tar.xz #{@equipment['server1'].telnet_ip}", @equipment['dut1'].prompt, 900)
    @equipment['dut1'].send_cmd("rm -rf #{emmc_root_partition_mnt}/*", @equipment['dut1'].prompt, 900)
    @equipment['dut1'].send_cmd("tar -C #{emmc_root_partition_mnt} -xvf fs.tar.xz", @equipment['dut1'].prompt, 900)
    @equipment['dut1'].send_cmd("sync #{emmc_root_partition_mnt}", @equipment['dut1'].prompt, 900)
  end
  @equipment['dut1'].send_cmd("umount #{emmc_root_partition}", @equipment['dut1'].prompt, 120)
  
  emmc_root_partition
end
