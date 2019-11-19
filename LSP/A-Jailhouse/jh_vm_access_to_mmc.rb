require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/jh_helpers'

include LspTestScript

def setup
    self.as(LspTestScript).setup
end

def run
    begin
        jh_host_test()
        set_result(FrameworkConstants::Result[:pass], "Test Passed.")
    rescue Exception => e
        set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
    end
end

def clean
    self.as(LspTestScript).clean
    jh_send_cmd("rm a", @equipment['dut1'].params['secondary_serial_prompt'])
    jh_send_cmd("rm b", @equipment['dut1'].params['secondary_serial_prompt'])
end

def get_emmc_dev()
    tout, resp = jh_send_cmd("ls -d /sys/class/block/mmcblk[0-9]", @equipment['dut1'].params['secondary_serial_prompt'])
    mmc_devs = resp.scan(/(.*?(mmcblk\d+))/)
    raise "Unable to detect mmc devices:\n #{@equipment['dut1'].response}" if mmc_devs.empty?
    #Find EMMC block device
    emmc_dev = nil
    mmc_devs.each do |dev|
        tout, resp = jh_send_cmd("cat #{dev[0]}/device/name", @equipment['dut1'].prompt)
        # J721E eMMC device ID
        if resp.match(/S0J56X/)
            emmc_dev = dev[1]
            break
        end
    end
    return emmc_dev
end

def jh_host_test()
    start_linux_demo()
    jh_send_cmd("root", @equipment['dut1'].params['secondary_serial_prompt'])
    emmc_dev = get_emmc_dev()
    if emmc_dev.nil?
        raise "Did not find eMMC device matching S0J56X"
    end
    jh_send_cmd("dd if=/dev/urandom of=a bs=1M count=1", @equipment['dut1'].params['secondary_serial_prompt'])
    jh_send_cmd("dd if=a of=/dev/#{emmc_dev} bs=1M", @equipment['dut1'].params['secondary_serial_prompt'])
    jh_send_cmd("dd if=/dev/#{emmc_dev} of=b bs=1M count=1", @equipment['dut1'].params['secondary_serial_prompt'])
    tout, resp = jh_send_cmd("cmp a b", @equipment['dut1'].params['secondary_serial_prompt'])
    #Files a and b should exist and be identical
    if resp =~ /a b differ/ || resp =~ /No such file or directory/
        raise "Failure comparing files a and b"
    end
end
