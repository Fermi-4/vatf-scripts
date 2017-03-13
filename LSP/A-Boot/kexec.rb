require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def run
  begin
    # set crashkernel in bootargs if required to collect crash traces.  For example:
    # root@k2g-evm:~# export cmdline_opts=`cat /proc/cmdline`" crashkernel=64M@"`cat /proc/iomem |egrep 'Kernel data' |egrep -o '[[:digit:]]+' |head -n 1`
    # root@k2g-evm:~# echo $cmdline_opts
    # console=ttyS0,115200n8 root=PARTUUID=00000000-02 rw rootfstype=ext4 rootwait crashkernel=64M@801000000
    # kexec -d --append=$cmdline_opts -p /boot/zImage
    # echo 'c' > /proc/sysrq-trigger

    @equipment['dut1'].send_cmd("zcat /proc/config.gz | grep KEXEC", /CONFIG_KEXEC=y/, 3)
    if @equipment['dut1'].timeout?
      set_result(FrameworkConstants::Result[:ns], "Test skipped. Optional CONFIG_KEXEC config option not set as expected")
      return
    end

    kexec_image = @test_params.instance_variable_defined?(:@var_kexec_image) ? @test_params.var_kexec_image : '/boot/zImage'
    @equipment['dut1'].send_cmd("kexec -d -l #{kexec_image}", @equipment['dut1'].prompt)

    boot_timeout = @test_params.instance_variable_defined?(:@var_boot_timeout) ? @test_params.var_boot_timeout.to_i : 210
    @equipment['dut1'].send_cmd('kexec -e', @equipment['dut1'].login_prompt, boot_timeout)

    if @equipment['dut1'].timeout?
      set_result(FrameworkConstants::Result[:fail], "KEXEC did not execute new kernel image as expected")
      return
    end

    3.times {
      @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 40)
      break if !@equipment['dut1'].timeout?
    }

    if @equipment['dut1'].timeout?
      set_result(FrameworkConstants::Result[:fail], "Error login in after loading kernel image using KEXEC")
      return
    end

    set_result(FrameworkConstants::Result[:pass], "KEXEC loaded new kernel image")

  rescue Exception => e
    puts e.message
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Exception trying to load image using KEXEC")
  end
end