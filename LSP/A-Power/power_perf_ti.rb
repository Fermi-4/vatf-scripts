require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/ti_meter_power'
require 'gnuplot.rb'

include LspTestScript
include TiMeterPower

def setup
  #puts "\n====================\nPATH=#{ENV['PATH']}\n"
  super
  # Connect to multimeter
  @equipment['ti_multimeter'].connect({'type'=>'serial'})
end

def run
  # Set DUT in appropriate state
  if @test_params.params_chan.cpufreq[0] != '0'
        puts "\n\n======= Current CPU Frequency =======\n"
        @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)

        @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        supported_frequencies = @equipment['dut1'].response.split(/\s+/)
        #raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
        # mount debugfs
        @equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        @equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        #if @test_params.params_chan.cpufreq[0] != 0
        @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /debug/pm_debug/sleep_while_idle", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        @equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.0/sleep_timeout", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        @equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.1/sleep_timeout", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        @equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.2/sleep_timeout", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
        #end

        # put device in available OPP states
        @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.dvfs_freq[0]} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  end

  if @test_params.params_chan.instance_variable_defined?(:@suspend)
      @equipment['dut1'].send_cmd("echo mem > /sys/power/state", @equipment['dut1'].prompt, 10) if @test_params.params_chan.suspend[0] == '1'
  end
  sleep 10

  read_time =  @test_params.params_control.read_time[0].to_i
  perf = []
  perf = get_ti_meter_power_perf(read_time, @equipment['ti_multimeter'])

  puts "\n\n======= Power Domain states info =======\n"
  @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  puts "\n\n======= Current CPU Frequency =======\n"
  @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  puts "\n\n======= Power Domain transition stats =======\n"
  @equipment['dut1'].send_cmd(" cat /debug/pm_debug/count", @equipment['dut1'].prompt, 1)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)


  #puts "\n\n======= Power Domain states info =======\n" + send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state")
  #puts "\n\n======= Current CPU Frequency =======\n" +  send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
  #puts "\n\n======= Power Domain transition stats =======\n" + send_adb_cmd("shell cat /debug/pm_debug/count") 
  #dutThread.join if dutThread
ensure
  if perf.size > 0
    set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get Power Performance data")
  end
end







