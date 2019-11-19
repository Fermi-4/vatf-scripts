# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  
require File.dirname(__FILE__)+'/../A-Jailhouse/jh_helpers'

include LspTargetTestScript

def run
  emmc_root_part = setup_jailhouse_emmc_rootfs()
  #Reboot board with jailhouse and display sharing dtbos
  jh_boot_params = {'dtbo_0' => @test_params.jh_dtbo,
                    'dtbo_0_dev' => 'eth',
                    'dtbo_1' => @test_params.disp_dtbo,
                    'dtbo_1_dev' => 'eth'}
  setup_boards('dut1', jh_boot_params)
  #Start inmate with emmc fs
  @equipment['dut1'].send_cmd('jailhouse enable /usr/share/jailhouse/cells/k3-j721e-evm.cell', @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("jailhouse cell linux -a arm64 -d /usr/share/jailhouse/inmate-k3-j721e-evm.dtb -c \"console=ttyS1,115200n8 root=#{emmc_root_part} rw rootfstype=ext4 rootwait\" /usr/share/jailhouse/cells/k3-j721e-evm-linux-demo.cell /boot/Image", @equipment['dut1'].prompt, 120)
  jh_send_cmd("",@equipment['dut1'].login_prompt, 240)
  jh_send_cmd("root",@equipment['dut1'].prompt, 240)
  jh_send_cmd("cat /var/log/weston.log",@equipment['dut1'].prompt, 240)
  jh_send_cmd("cd /opt/ltp",@equipment['dut1'].prompt, 20)
  tout, resp = jh_send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/rgx -s 'RGX_S_FUNC_GLES2 '",@equipment['dut1'].prompt, 90)
  if resp.match(/RGX_S_FUNC_GLES2\s+PASS/m)
    set_result(FrameworkConstants::Result[:pass], "Jailhouse GFX test passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Jailhouse GFX test failed")
  end
end
