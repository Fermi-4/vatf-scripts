require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def run
  @default_remoteproc_fw_config

  #Get remoteproc link and name information 
  rprocs_firmware_info = rprocs_initial_info(@equipment['dut1'].name)

  #Clear existing links before setting new links for the tests
  save_firmware(rprocs_firmware_info.values())
  rprocs_firmware_info.values().each do |info|
	@equipment['dut1'].send_cmd("rm /lib/firmware/#{info['link']}", @equipment['dut1'].prompt)
  end

  #Parse remoteproc test configuration
  default_test = @test_params.params_chan.default_test[0]
  lockstep_procs = @test_params.instance_variable_defined?(:@var_lockstep_procs) ? @test_params.var_lockstep_procs[0].split(',') : []

  #spl_procs/uboot_procs/kernel_procs arrays element syntax <proc_key>:[<test_name>], if test_name is not specified default_test is used
  spl_procs_tests = @test_params.params_chan.instance_variable_defined?(:@spl_procs) ? @test_params.params_chan.spl_procs : []
  spl_procs = filter_rprocs(rprocs_firmware_info, spl_procs_tests)
  spl_procs_tests.each { |spl| get_fw_path(spl, default_test, spl_procs) }
  uboot_procs_tests = @test_params.params_chan.instance_variable_defined?(:@uboot_procs) ? @test_params.params_chan.uboot_procs : []
  uboot_procs = filter_rprocs(rprocs_firmware_info, uboot_procs_tests, spl_procs)
  uboot_procs_tests.each { |ub| get_fw_path(ub, default_test, uboot_procs) }
  kernel_procs = filter_rprocs(rprocs_firmware_info, ['.*'], uboot_procs.merge(spl_procs), lockstep_procs)
  kernel_procs.keys().each { |k| get_fw_path(k, default_test, kernel_procs) }
  kernel_procs_tests = @test_params.params_chan.instance_variable_defined?(:@kernel_procs) ? @test_params.params_chan.kernel_procs : []
  kernel_procs_tests.each { |k| get_fw_path(k, default_test, kernel_procs) }

  #Setting links for spl and uboot loaded remote procs
  set_fw_links(spl_procs)
  set_fw_links(uboot_procs)
  set_fw_links(kernel_procs)
  translated_boot_params = setup_host_side()
  if translated_boot_params['fs'] == 'nfs'
    @equipment['dut1'].send_cmd("mkdir -p /run/media/mmcblk1p2/lib/firmware", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("rm -rf /run/media/mmcblk1p2/lib/firmware/*", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cp -rf /lib/firmware/* /run/media/mmcblk1p2/lib/firmware/", @equipment['dut1'].prompt, 120)
  end
  @equipment['dut1'].boot_to_bootloader(translated_boot_params)

  #Check that SPL remoteprocs booted
  if spl_procs.length > 0
    spl_check = @equipment['dut1'].response.match(/Remoteproc\s*#{spl_procs.length}\s*started\s*successfully/im)
    raise "#{spl_procs_tests} were not booted by SPL #{@equipment['dut1'].response}" if !spl_check 
  end

  #Boot remoteproc via Uboot, if any
  rproc_uboot_config = ''
  if uboot_procs.length > 0
    @equipment['dut1'].send_cmd("rproc init", @equipment['dut1'].boot_prompt)
    @equipment['dut1'].send_cmd("rproc list", @equipment['dut1'].boot_prompt)
    set_uboot_ids(uboot_procs, @equipment['dut1'].response)
    uboot_procs.values().each { |v| rproc_uboot_config += " #{v['id']} /lib/firmware/#{v['link']}" }
  end
  @equipment['dut1'].send_cmd("setenv rproc_fw_binaries #{rproc_uboot_config}", @equipment['dut1'].boot_prompt)

  #Boot the board
  @equipment['dut1'].system_loader.run(translated_boot_params)

  #Set the sysfs id for each remoteproc
  sysfs_ids = get_sysfs_ids()
  set_sysfs_id(spl_procs, sysfs_ids)
  set_sysfs_id(uboot_procs, sysfs_ids)
  set_sysfs_id(kernel_procs, sysfs_ids)

  proc_failures = {}
  #Validate spl booted remoteprocs
  spl_procs.each do |rp_k, rp|
    rp_res, test_info, initial_info = self.send(rp['test_app'], rp)
    proc_failures[rp_k] = {'test_trace'=>test_info, 'initial_trace'=> initial_info} if !rp_res
  end

  #Validate uboot booted remoteprocs
  uboot_procs.each do |rp_k, rp|
    rp_res, test_info, initial_info = self.send(rp['test_app'], rp)
    proc_failures[rp_k] = {'test_trace'=>test_info, 'initial_trace'=> initial_info} if !rp_res
  end

  #Validate kernel booted remoteprocs
  kernel_procs.each do |rp_k, rp|
    rp_res, test_info, initial_info = self.send(rp['test_app'], rp)
    proc_failures[rp_k] = {'test_trace'=>test_info, 'initial_trace'=> initial_info} if !rp_res
  end

  if (!spl_procs.empty? || !uboot_procs.empty? || !kernel_procs.empty?) && proc_failures.empty?
    set_result(FrameworkConstants::Result[:pass], "IPC test passed.")
  else
    failure_message = "IPC test failed for:"
    proc_failures.each{ |rp, f_info| failure_message += "\n\n======= #{rp} ======\n#{f_info['test_trace']}\n====== end ======\n\n" } 
    set_result(FrameworkConstants::Result[:fail], failure_message)
  end
end

def set_fw_links(rprocs)
  rprocs.each do |rp, info|
    @equipment['dut1'].send_cmd("ln -sf #{info['path'].strip} /lib/firmware/#{info['link'].strip}", @equipment['dut1'].prompt)
  end
end

def get_sysfs_ids()
  result = {}
  @equipment['dut1'].send_cmd("ls /sys/class/remoteproc/", @equipment['dut1'].prompt)
  rprocs = @equipment['dut1'].response.scan(/remoteproc\d+/i)
  rprocs.each do |rp|
    @equipment['dut1'].send_cmd("cat /sys/class/remoteproc/#{rp}/firmware", @equipment['dut1'].prompt)
    fw = @equipment['dut1'].response.match(/sys\/class\/remoteproc\/#{rp}\/firmware[\r\n]+([^\r\n]+)/im).captures[0].strip()
    result[fw] = rp
  end
  result
end

def set_sysfs_id(rprocs, sysfs_ids)
  rprocs.each { |k,v| v['sysfs'] = sysfs_ids[v['link']] if sysfs_ids[v['link']] }
end

def set_uboot_ids(uboot_procs, dut_response)
  info = dut_response.scan(/(\d+)\s*-\s*Name:'(.*?)'\s*(type[^\r\n]+)/i)
  info.each do |p_info|
    uboot_procs.each do |k,v| 
      if v["name"].split('.')[0] == p_info[1].split('@')[-1]
        v["id"] = p_info[0].to_i
        v["info"] = p_info[2]
      end
    end
  end
end

def clean
  #if !is_uut_up?(@equipment['dut1'])
  #  translated_boot_params = setup_host_side()
  #  @equipment['dut1'].boot(translated_boot_params)
  #end
  #restore_firmware()
  #super
end

def fw2linux_map()
  {
    "mcu1_0" => "mcu-r5f0_0",
    "mcu1_1" => "mcu-r5f0_1",
    "mcu2_0" => "main-r5f0_0",
    "mcu2_1" => "main-r5f0_1",
    "mcu3_0" => "main-r5f1_0",
    "mcu3_1" => "main-r5f1_1",
    "c66xdsp_1" => "c66_0",
    "c66xdsp_2" => "c66_1",
    "c7x_1" => "c71_0",
  }
end

def get_fw_path(test_info, default_test, rprocs_info)
  test_apps = Hash.new
  test_apps['ipc_echo_test'] = :ipc_echo_test
  test_apps['ipc_echo_testb'] = test_apps['ipc_echo_test']

  info_arr = test_info.split(/:/)
  rproc = info_arr[0]
  test_name = info_arr.length > 1 ? info_arr[1] : default_test
  f2l_map = fw2linux_map()
  l2f_map = f2l_map.invert()
  @equipment['dut1'].send_cmd("find /lib/firmware -type f -name '#{test_name}_*' | grep -v -e '\.map$' -e _debug -e '\.strip\.'", @equipment['dut1'].prompt, 20)
  raise "Unable to obtain firmware paths" if @equipment['dut1'].timeout?
  rprocs_info[rproc]['path'] = @equipment['dut1'].response.match(/.*?\/#{test_name}_.*?#{l2f_map[rproc]}.*release\..*/)[0].strip()
  rprocs_info[rproc]['test_app'] = test_apps[test_name]
end

def ipc_echo_test(rp)
  @equipment['dut1'].send_cmd("dmesg -c", @equipment['dut1'].prompt, 60)
  initial_dmesg = @equipment['dut1'].response
  @equipment['dut1'].send_cmd("modprobe -r rpmsg_client_sample", @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd("modprobe rpmsg_client_sample", @equipment['dut1'].prompt, 60)
  sleep(10)
  @equipment['dut1'].send_cmd("dmesg -c", @equipment['dut1'].prompt, 120)
  test_dmesg = @equipment['dut1'].response
  @equipment['dut1'].send_cmd("ls -d /sys/class/remoteproc/#{rp['sysfs']}/virtio*/virtio*", @equipment['dut1'].prompt)
  virtio = @equipment['dut1'].response.match(/\/sys\/class\/remoteproc\/#{rp['sysfs']}\/virtio\d+\/(virtio[^\r\n]+)/im).captures[0]
  test = test_dmesg.match(/rpmsg_client_sample\s*#{virtio}[^:]*:\s*goodbye!/) && test_dmesg.match(/rpmsg_client_sample\s*#{virtio}[^:]*:\s*incoming\s*msg\s*100/)
  rescue Exception => e
    test_dmesg += e.to_s
    test = false
  ensure
    return [test, test_dmesg, initial_dmesg]
end

def filter_rprocs(rprocs, rproc_match_list=[], rproc_exclude={}, lock_step_procs = [])
  rp = []
  ls_procs = []
  rproc_match_list.each { |v| rp << v.split(':')[0].strip() }
  rproc_exclude.each { |k,v| ls_procs << v["lockstep"] if lock_step_procs.include?(k) || lock_step_procs.include?(v["lockstep"]) }
  rproc_match_list.each { |k| ls_procs << rprocs[k]["lockstep"] if rprocs.keys().include?(k) && (lock_step_procs.include?(k) || lock_step_procs.include?(rprocs[k]["lockstep"])) }
  return rprocs.select{ |k,v| rp.include?(k) && !rproc_exclude.include?(k) && !ls_procs.include?(k) }
end

def rprocs_initial_info(dut)

  return case dut
      #device pattern => device info (link, uboot name) 
    when /j7*/
      {
         "mcu-r5f0_0" => {"link" => "j7-mcu-r5f0_0-fw",
                          "name" => "41000000.r5f",
                          "lockstep" => "mcu-r5f0_1"},
         "mcu-r5f0_1" => {"link" => "j7-mcu-r5f0_1-fw",
                          "name" => "41400000.r5f",
                          "lockstep" => "mcu-r5f0_0"},
         "main-r5f0_0" => {"link" => "j7-main-r5f0_0-fw",
                           "name" => "5c00000.r5f",
                           "lockstep" => "main-r5f0_1"},
         "main-r5f0_1" => {"link" => "j7-main-r5f0_1-fw",
                           "name" => "5d00000.r5f",
                           "lockstep" => "main-r5f0_0"},
         "main-r5f1_0" => {"link" => "j7-main-r5f1_0-fw",
                           "name" => "5e00000.r5f",
                           "lockstep" => "main-r5f1_1"},
         "main-r5f1_1" => {"link" => "j7-main-r5f1_1-fw",
                           "name" => "5f00000.r5f",
                           "lockstep" => "main-r5f1_0"},
         "c66_0" => {"link" => "j7-c66_0-fw",
                     "name" => "4d80800000.dsp"},
         "c66_1" => {"link" => "j7-c66_1-fw",
                     "name" => "4d81800000.dsp"},
         "c71_0" => {"link" => "j7-c71_0-fw",
                     "name" => "64800000.dsp"},
      }
    when /am6*/
      {
         "mcu-r5f0_0" => {"link" => "am65x-mcu-r5f0_0-fw",
                          "name" => "41000000.r5f",
                          "lockstep" => "mcu-r5f0_1"},
         "mcu-r5f0_1" => {"link" => "am65x-mcu-r5f0_1-fw",
                          "name" => "41400000.r5f",
                          "lockstep" => "mcu-r5f0_0"},
      }
    else
      raise "Unsupported dut type #{dut}"
  end
end

def save_firmware(links_info, e=@equipment['dut1'])
  @firmware_links = {}
  links_info.each do |info|
    e.send_cmd("ls -l /lib/firmware/#{info['link']}", e.prompt)
    l_match = e.response.match(/\/lib\/firmware\/#{info['link']}\s*->\s*(.*)/)
    @firmware_links[l_match.captures[0]] = "/lib/firmware/#{info['link']}" if l_match
  end
end

def restore_firmware(e=@equipment['dut1'])
  @firmware_links.each {|k,v|
     e.send_cmd("ln -sf #{k.strip} #{v.strip}", e.prompt)
  }
end
