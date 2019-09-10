require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def run

  #initialize function pointers based on the platform type
  func_ptr = func_platform_map(@equipment['dut1'].name)
        
  #set test firmware links and get the number of remoteproc to test
  num_rproc = func_ptr["set_test_fw_link"].call()
        
  #go to test directory
  @equipment['dut1'].send_cmd("pushd /usr/bin/ipc/examples/ex02_messageq/release/", @equipment['dut1'].prompt)

  #get test argument
  @equipment['dut1'].send_cmd("./app_host -l", @equipment['dut1'].prompt)
  test_args = @equipment['dut1'].response.scan(/\=\D[^\s]+/im)
        
  #loop through each remoteproc test
  set_result(FrameworkConstants::Result[:pass], "IPC example test passed.")
  test_count = 0
  test_args.each do |arg|
    if test_count < num_rproc
      @equipment['dut1'].send_cmd("./app_host #{arg.sub("\=","")}", @equipment['dut1'].prompt)
      test_dmesg_send = @equipment['dut1'].response.scan(/sending.*message/)
      test_dmesg_receive = @equipment['dut1'].response.scan(/message.*received/)
      if((test_dmesg_send.length != test_dmesg_receive.length) && (test_dmesg_receive.length == 0))
        set_result(FrameworkConstants::Result[:fail], "IPC example test of #{arg.sub("\=","")} failed.")
      end
    end
    test_count += 1
  end
        
  #exit from test directory
  @equipment['dut1'].send_cmd("popd", @equipment['dut1'].prompt)
              
  #test to verify system is still up after 20 consecutive re-boot
  iteration = 20
  if (func_ptr["consecutive_reboot_test"].call(iteration) ==0)
    set_result(FrameworkConstants::Result[:fail], "consecutive reboot test failed.")
  end
  
  #restore firmware link
  func_ptr["restore_fw_link"].call()

end

# funtion pointer table 
def func_platform_map(dut)
  return case dut
    when /am6.*/
    {
      "set_test_fw_link" => method(:set_test_fw_link_am6),
      "restore_fw_link" => method(:restore_fw_link_am6),
      "consecutive_reboot_test" => method(:consecutive_reboot_test_am6),
    }
    when /am5.*/,/dra7.*/
    {
      "set_test_fw_link" => method(:set_test_fw_link_am5),
      "restore_fw_link" => method(:restore_fw_link_am5),
      "consecutive_reboot_test" => method(:consecutive_reboot_test_am5),
    }
    else
      raise "Unsupported dut type"
  end
end 

#link IPC firmware to test examples
def set_test_fw_link_am5()
  #list all remoteprocs
  @equipment['dut1'].send_cmd("ls /sys/class/remoteproc/", @equipment['dut1'].prompt)
  rprocs = @equipment['dut1'].response.scan(/remoteproc\d+/i)
  
  num_rproc = 1 #./app_host HOST is always aviable
  rprocs.each do |rp|
    @equipment['dut1'].send_cmd("cat /sys/class/remoteproc/#{rp}/firmware", @equipment['dut1'].prompt)
    fw = @equipment['dut1'].response.match(/sys\/class\/remoteproc\/#{rp}\/firmware[\r\n]+([^\r\n]+)/im).captures[0].strip()
    if (fw.match(/dra7.*/))
      #stop remoteproc
      @equipment['dut1'].send_cmd("echo stop > /sys/class/remoteproc/#{rp}/state", @equipment['dut1'].prompt) 
      #remove fw link before change the link to example test
      @equipment['dut1'].send_cmd("rm /lib/firmware/#{fw}", @equipment['dut1'].prompt)  
      #set fw to test examples
      @equipment['dut1'].send_cmd("ln -sf /usr/bin/ipc/examples/ex02_messageq/release/#{fw.sub("dra7-","server_").sub("-fw.x",".x")} /lib/firmware/#{fw}", @equipment['dut1'].prompt)  
      #start remoteproc
      @equipment['dut1'].send_cmd("echo start > /sys/class/remoteproc/#{rp}/state", @equipment['dut1'].prompt)
      #increase the number of remoteproc to be tested
      num_rproc += 1
    end   
  end
  return num_rproc
end

def set_test_fw_link_am6()
  #list all remoteprocs
  @equipment['dut1'].send_cmd("ls /sys/class/remoteproc/", @equipment['dut1'].prompt)
  rprocs = @equipment['dut1'].response.scan(/remoteproc\d+/i)

  num_rproc = 1 #./app_host HOST is always aviable
  rprocs.each do |rp|
    @equipment['dut1'].send_cmd("cat /sys/class/remoteproc/#{rp}/firmware", @equipment['dut1'].prompt)
    fw = @equipment['dut1'].response.match(/sys\/class\/remoteproc\/#{rp}\/firmware[\r\n]+([^\r\n]+)/im).captures[0].strip()
    if (fw.match(/am65x\-mcu\-.*/))
      #stop remoteproc
      @equipment['dut1'].send_cmd("echo stop > /sys/class/remoteproc/#{rp}/state", @equipment['dut1'].prompt)      
      #remove fw link before change the link to example test
      @equipment['dut1'].send_cmd("rm /lib/firmware/#{fw}", @equipment['dut1'].prompt)  
      #set fw to test examples
      @equipment['dut1'].send_cmd("ln -sf /usr/bin/ipc/examples/ex02_messageq/release/#{fw.sub("am65x-mcu-r5f0_","server_r5f-").sub("-fw",".xer5f")} /lib/firmware/#{fw}", @equipment['dut1'].prompt)        
      #start remoteproc
      @equipment['dut1'].send_cmd("echo start > /sys/class/remoteproc/#{rp}/state", @equipment['dut1'].prompt) 
      #increase the number of remoteproc to be tested
      num_rproc += 1
    end   
  end
  return num_rproc
end

#restore IPC firmare to default settings
def restore_fw_link_am5()
  @equipment['dut1'].send_cmd("cat /sys/class/remoteproc/remoteproc*/firmware", @equipment['dut1'].prompt)
  fw_links = @equipment['dut1'].response.scan(/(dra7-(.*?)\.[^\s]+)/im)

  @equipment['dut1'].send_cmd("pushd /lib/firmware/", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("ls dra7*opencl*; ls dra7*ipumm*", @equipment['dut1'].prompt)
  default_links = @equipment['dut1'].response.scan(/(dra7-(.*?)\.[^\s]+)/im)
  @equipment['dut1'].send_cmd("popd", @equipment['dut1'].prompt)

  fw_links.each do |fw_link, fw_kw|
    default_links.each do |default_link, default_kw|
      if fw_kw == default_kw
        #remove fw link before change the link to example test
        @equipment['dut1'].send_cmd("rm /lib/firmware/#{fw_link}", @equipment['dut1'].prompt) 
        #restore fw link to default 
        @equipment['dut1'].send_cmd("ln -sf /lib/firmware/#{default_link} /lib/firmware/#{fw_link}", @equipment['dut1'].prompt)
      end
    end  
 end
end

def restore_fw_link_am6()
  @equipment['dut1'].send_cmd("ls /lib/firmware/am65x-mcu*", @equipment['dut1'].prompt)
  fw_links=@equipment['dut1'].response.scan(/\/lib\/firmware\/am65x-mcu-[^\s]+/im)

  @equipment['dut1'].send_cmd("ls /lib/firmware/ipc/", @equipment['dut1'].prompt)
  default_links = @equipment['dut1'].response.scan(/ti[^\s]+/im)

  fw_links.each_with_index do |fw_link, fw_index|
    default_links.each_with_index do |default_link, default_index|
      if default_index == fw_index
        #remove fw link before change the link to example test
        @equipment['dut1'].send_cmd("rm #{fw_link}", @equipment['dut1'].prompt) 
        #restore fw link to default 
        @equipment['dut1'].send_cmd("ln -sf /lib/firmware/ipc/#{default_link} #{fw_link}", @equipment['dut1'].prompt)
      end
    end  
  end
end

# run consecutive re-boot
def consecutive_reboot_test_am5(iteration)
  translated_boot_params = setup_host_side()
  while iteration > 0 do
    iteration -= 1
    #boot system
    boot_dut(translated_boot_params)
    connect_to_equipment('dut1')
    check_dut_booted({})
    #check boot result
    @equipment['dut1'].send_cmd("dmesg | grep dsp", @equipment['dut1'].prompt)
    result = @equipment['dut1'].response.scan(/dsp.*up/) 
  end 
  return result.length
end
def consecutive_reboot_test_am6(iteration)
  translated_boot_params = setup_host_side()
  while iteration > 0 do
    iteration -= 1
    #boot system
    boot_dut(translated_boot_params)
    connect_to_equipment('dut1')
    check_dut_booted({})
    #check boot result
    @equipment['dut1'].send_cmd("dmesg | grep mcu", @equipment['dut1'].prompt)
    result = @equipment['dut1'].response.scan(/am65x\-mcu\-r5f0_0\-fw/) 
  end 
  return result.length
end

def clean
  if !is_uut_up?(@equipment['dut1'])
    translated_boot_params = setup_host_side()
    @equipment['dut1'].boot(translated_boot_params)
  end
  func_platform_map(@equipment['dut1'].name)["restore_fw_link"].call()
  super
end
