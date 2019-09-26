# 

require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript


def setup
  super
end

def run

  @equipment['dut1'].send_cmd("ls /dev/bsg/ufs-bsg", @equipment['dut1'].prompt, 5)
  if @equipment['dut1'].response.match(/No\s*such\s*file/i)
    raise "There is no UFS support in kernel"
  end

  @equipment['dut1'].send_cmd("which ufs-tool; echo $?", /^0[\0\n\r]+/im, 5)
  raise "ufs-tool is not in rootfs" if @equipment['dut1'].timeout?

  ufs_config_file = "config_desc_data_ind_1"
  @equipment['dut1'].send_cmd("wget http://10.218.103.34/anonymous/tmp/yan/#{ufs_config_file}", @equipment['dut1'].prompt, 20)

  @equipment['dut1'].send_cmd("ls -l #{ufs_config_file}", @equipment['dut1'].prompt, 10)
  if @equipment['dut1'].response.match(/No\s+such\s+file/i)
    raise "Could not wget #{ufs_config_file} file"
  end

  @equipment['dut1'].send_cmd("ls -l /dev/disk/by-path/", @equipment['dut1'].prompt, 10)
  if @equipment['dut1'].response.match(/ufs-scsi/i)
    puts "UFS is already being provisioned, so skip"
  else
    puts "Do not see ufs-scsi in /dev/disk/by-path, so start provision UFS flash"
    @equipment['dut1'].send_cmd("ufs-tool desc -t 1 -w #{ufs_config_file} -p /dev/bsg/ufs-bsg", @equipment['dut1'].prompt, 10)
  end

  # Reset dut
  setup

  @equipment['dut1'].send_cmd("ls -l /dev/disk/by-path/", @equipment['dut1'].prompt, 10)
  if @equipment['dut1'].response.match(/ufs-scsi/i)
    set_result(FrameworkConstants::Result[:pass], "This test passed.")
  else
    set_result(FrameworkConstants::Result[:fail], "Still not see 'ufs-scsi' in /dev/disk/by-path/ !!")
  end

end
