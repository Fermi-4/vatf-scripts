# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_test_module'

include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  test_result = 0 # '0' is pass; else fail
  result_msg = 'this test pass'
  is_do_erase = '1'
  is_do_erase = @test_params.params_chan.is_do_erase[0] if @test_params.params_chan.instance_variable_defined?(:@is_do_erase)
  fs_type = @test_params.params_chan.fs_type[0]
  mnt_point = @test_params.params_chan.mnt_point[0]
  device_node = @test_params.params_chan.device_node[0]
  
  #====== populate fs in nand/nor if needed =====
  if is_do_erase == '1' then
    @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 20)
 
    test_result, result_msg = run_cmds('cmd_flasheraseall', '')
    if test_result != 0 then
      set_result(FrameworkConstants::Result[:fail], result_msg)
      return
    end

  end
  test_result, result_msg = run_cmds('cmd_mount', '')
  if test_result != 0 then
    set_result(FrameworkConstants::Result[:fail], result_msg)
    return
  end

  @equipment['dut1'].send_cmd("ls #{mnt_point} -l", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("df -h", @equipment['dut1'].prompt, 20)
  
  # populate filesystem if there is no working fs there
  if is_do_erase == '1' then
    target_reduced_fs_tarball = @view_drive+  @test_params.params_chan.target_reduced_fs[0].to_s
    target_reduced_fs_tarball_name = File.basename(target_reduced_fs_tarball)
    # copy this fs to target
    test_folder = "/test/#{@tester}/#{@test_params.target.downcase}/#{@test_params.platform.downcase}"
    #dst_folder = "#{LspTestScript.nfs_root_path}#{test_folder}"
	dst_folder = "#{LspTestScript.samba_root_path}#{test_folder.gsub('/',"\\")}"
    #dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}\\#{@tester}\\#{@test_params.target.downcase}"
    puts "dst_folder is #{dst_folder}"
    BuildClient.copy(target_reduced_fs_tarball, dst_folder+"\\"+File.basename(target_reduced_fs_tarball))
    fs_location_target = "/#{@tester}/#{@test_params.target.downcase}"
    if File.extname(target_reduced_fs_tarball) == '.tar' 
      untar_option = '-xf'
    elsif File.extname(target_reduced_fs_tarball) == '.gz'
      untar_option = '-xzf'
    else
      raise "#{target_reduced_fs_tarball_name}: unsupported tarball format!"
    end
    current_time = Time.now.mon.to_s.rjust(2, '0') + Time.now.day.to_s.rjust(2, '0') + Time.now.hour.to_s.rjust(2, '0') + 
                    Time.now.min.to_s.rjust(2, '0') + Time.now.year.to_s.rjust(4, '0')
    @equipment['dut1'].send_cmd("cd #{mnt_point}", @equipment['dut1'].prompt, 20)
    @equipment['dut1'].send_cmd("date #{current_time}", @equipment['dut1'].prompt, 20)
    @equipment['dut1'].send_cmd("tar #{untar_option} #{test_folder}/#{target_reduced_fs_tarball_name}", @equipment['dut1'].prompt, 120)
    # catch the tar error if any
    if /(fail)|(no\s+such\s+file)/i =~ @equipment['dut1'].response then
      raise "tar #{untar_option} #{test_folder}/#{target_reduced_fs_tarball_name} had error!"
    end
       
    @equipment['dut1'].send_cmd("ls #{mnt_point}", @equipment['dut1'].prompt, 20)
    @equipment['dut1'].send_cmd("df -h", @equipment['dut1'].prompt, 20)
    @equipment['dut1'].send_cmd("cd -", @equipment['dut1'].prompt, 20)
  end
  
  #===== run sanity read write test for nand/nor when rootfs is nfs =====
  test_result, result_msg = run_cmds('cmd_write', '')
  if test_result != 0 then
    set_result(FrameworkConstants::Result[:fail], "rootfs=nfs: #{result_msg}")
    return
  end
  test_result, result_msg = run_cmds('cmd_read', '')
  if test_result != 0 then
    set_result(FrameworkConstants::Result[:fail], "rootfs=nfs: #{result_msg}")
    return
  end
 # @equipment['dut1'].send_cmd("rm -f /mnt/testfile")    
  @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 20)
  #umount_mtd(mnt_point)
  
  #===== run test when nand/nor as rootfs =====
  # reboot dut to bootprompt
  params = {}
  params['dut']    = @equipment['dut1'] 
  params['apc']    = @equipment['apc1']
  #boot_to_bootloader(params)
  @equipment['dut1'].boot_to_bootloader

  # set bootargs to this fs and boot
  bootargs_mtd = @test_params.params_chan.bootargs_mtd[0]
  @equipment['dut1'].send_cmd("setenv bootargs #{bootargs_mtd}",@equipment['dut1'].boot_prompt, 30)
  raise 'Unable to set bootargs' if @equipment['dut1'].timeout?
  @equipment['dut1'].send_cmd("saveenv",@equipment['dut1'].boot_prompt, 10)
  @equipment['dut1'].send_cmd('boot', @equipment['dut1'].login_prompt, 180)
  #raise 'Unable to boot platform' if @equipment['dut1'].timeout?
  if @equipment['dut1'].timeout?
    set_result(FrameworkConstants::Result[:fail], "rootfs=#{fs_type}: Unable to boot platform.")
    return    
  end
  @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10) # login to the unit
  raise 'Unable to login' if @equipment['dut1'].timeout?

  #not necessary for mount since it is already in nand
=begin
  test_result, result_msg = run_cmds('cmd_mount', '')
  if test_result != 0 then
    set_result(FrameworkConstants::Result[:fail], result_msg)
    return
  end
=end
  # do sanity read write testing when mtd as rootfs. here mnt_point is just a location used to test; it is not mount point. I can make use the same cmd_write and cmd_read as when rootfs is nfs.
  test_result, result_msg = do_rw(mnt_point)
  if test_result != 0 then
    set_result(FrameworkConstants::Result[:fail], result_msg)
    return
  end
  
  # remove testfile which was written when mtd as rootfs
  run_cmds('cmd_rm_testfile_mp', '')
  run_cmds('cmd_rm_testfile', '')

  times_to_reboot = '5'
  is_soft_reboot = '1'
  booting_log = ''
  times_to_reboot = @test_params.params_chan.times_to_reboot[0] if @test_params.params_chan.instance_variable_defined?(:@times_to_reboot)
  is_soft_reboot = @test_params.params_chan.is_soft_reboot[0] if @test_params.params_chan.instance_variable_defined?(:@is_soft_reboot)
  times_to_reboot.to_i.times {|i|
    puts "times to reboot is #{i+1}"
    # doing softreboot by pass 1. if hardreboot, pass 0
    booting_log = reboot_dut(is_soft_reboot.to_i)
    # make sure the rootfs is yaffs2 or jffs2
    regex = Regexp.new("(#{fs_type} filesystem)")
    if !regex.match(booting_log) then
      set_result(FrameworkConstants::Result[:fail], "Mounted rootfs is not #{fs_type} at #{i+1}-th times")
      return
    end
    
    # do read write test again after reboot
    test_result, result_msg = do_rw(mnt_point)
    if test_result != 0 then
      set_result(FrameworkConstants::Result[:fail], result_msg)
      return
    end
  }
  #umount_mtd(mnt_point)
  set_result(FrameworkConstants::Result[:pass], result_msg)
end

def clean
  self.as(LspTestScript).clean
  puts 'child clean'
  
  # set back the filesystem to nfs
  params = {}
  params['dut']    = @equipment['dut1'] if !params['dut']
  params['apc']    = @equipment['apc1'] if !params['apc']
  params['server'] = @equipment['server1'] if !params['server']
  dut = @equipment['dut1']
  boot_args = SiteInfo::Bootargs[@test_params.platform.downcase.strip]

  #boot_to_bootloader(params)
  @equipment['dut1'].boot_to_bootloader
  dut.send_cmd("setenv nfs_root_path #{LspTestScript.nfs_root_path()}",/setenv.+#{dut.boot_prompt}/im, 30)
  raise 'Unable to set nfs root path' if dut.timeout?
  dut.send_cmd("setenv bootargs #{boot_args}",/setenv.+#{dut.boot_prompt}/im, 30)
  raise 'Unable to set bootargs' if dut.timeout?
  dut.send_cmd("saveenv",/saveenv.+#{dut.boot_prompt}/im, 10)
  raise 'Unable save environment' if dut.timeout?
  dut.send_cmd('boot', /login/, 200)
  raise 'Unable to boot platform' if dut.timeout?
  dut.send_cmd(dut.login, dut.prompt, 10) # login to the unit
  raise 'Unable to login' if dut.timeout?
  
  # todo: remove the testfile which was written from nand/nor when roofs is nfs
	run_cmds('cmd_mount', '')
	run_cmds('cmd_rm_testfile_mp', '')
	run_cmds('cmd_rm_testfile', '')
	run_cmds('cmd_umount', '')
end

def run_cmds(cmd_name, ensure_cmd_name)
  test_result = 0
  result_msg = "this test pass"
  
  commands = ensure_commands = ""
  commands = parse_cmd(cmd_name) if @test_params.params_chan.instance_variable_defined?("@#{cmd_name}")
  ensure_commands = parse_cmd(ensure_cmd_name) if @test_params.params_chan.instance_variable_defined?("@#{ensure_cmd_name}") 
  result, cmd = execute_cmd(commands)
  if result == 0 
      #set_result(FrameworkConstants::Result[:pass], "Test Pass.")
      test_result = 0
      result_msg = "This test pass"
  elsif result == 1
      test_result = 1
      result_msg = "Timeout executing cmd: #{cmd.cmd_to_send}"            
      #set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
  elsif result == 2
      #set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
      test_result = 2
      result_msg = "Fail message received executing cmd: #{cmd.cmd_to_send}"
  else
      set_result(FrameworkConstants::Result[:nry])
  end
  ensure 
      result, cmd = execute_cmd(ensure_commands) if ensure_commands !=""
        
  return [test_result, result_msg]
end

# power cycle and then login to dut
def reboot_dut(is_soft_reboot)
  if is_soft_reboot != 0 then
    #@equipment['dut1'].send_cmd('reboot', @equipment['dut1'].login_prompt, 180)
    @equipment['dut1'].send_cmd('reboot', @equipment['dut1'].boot_prompt, 180)
  else
    @equipment['apc1'].reset(@equipment['dut1'].power_port.to_s)
    #@equipment['dut1'].send_cmd('', @equipment['dut1'].login_prompt, 180)
    @equipment['dut1'].send_cmd('', @equipment['dut1'].boot_prompt, 180)
  end
  @equipment['dut1'].send_cmd('boot', @equipment['dut1'].login_prompt, 180)
  raise 'Unable to boot platform' if @equipment['dut1'].timeout?
  booting_log = @equipment['dut1'].response
  @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 20) # login to the unit
  raise 'Unable to login' if @equipment['dut1'].timeout?
  
  return booting_log
end

def do_rw(mnt_point)
  test_result = 0
  result_msg = "read write test pass"
  
  @equipment['dut1'].send_cmd("mkdir -p #{mnt_point}",@equipment['dut1'].prompt, 10)  
  test_result, result_msg = run_cmds('cmd_write', '')
  if test_result != 0 then
    return [test_result, result_msg]
    # set_result(FrameworkConstants::Result[:fail], result_msg)
    # return
  end
  test_result, result_msg = run_cmds('cmd_read', '')
  if test_result != 0 then
    return [test_result, result_msg]
    # set_result(FrameworkConstants::Result[:fail], result_msg)
    # return
  end
    
  return [test_result, result_msg]
end
=begin
def remove_testfile(mnt_point)
  @equipment['dut1'].send_cmd("rm #{mnt_point}/testfile", @equipment['dut1'].prompt, 60)
end
=end