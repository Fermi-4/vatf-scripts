require File.dirname(__FILE__)+'/dev_test2'

def run
  # Preserve current governor
  @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
  previous_govs = @equipment['dut1'].response.scan(/^\w+\s*$/)
  #Change to performance governor
  @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do echo -n performance > /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
  raise "performance governor is not available" if @equipment['dut1'].timeout?
  @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
  # Run the test
  self.as(LspTargetTestScript).run

  # Restore previous governor
  previous_govs.each_with_index{|v,i| 
    v.gsub!(/\s*/,'')
    @equipment['dut1'].send_cmd("echo -n #{v} > /sys/devices/system/cpu/cpu#{i}/cpufreq/scaling_governor", @equipment['dut1'].prompt)
  }
end

