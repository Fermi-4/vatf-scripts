require File.dirname(__FILE__)+'/dev_test2'

def run
  @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do echo performance > /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)

  self.as(LspTargetTestScript).run
end

