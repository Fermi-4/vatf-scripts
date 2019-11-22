# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'


include LspTestScript

PWM_CHANNELS_MAP = {
  # syntax for each element is [chip, channel]
  # you should have test equipment measure each channel exposed here.
  # The channel order defined here must match the order in the
  # test equipment's params['adc_ports'] defined in the bench file
  'am654x-evm' => [['pwmchip49', 0], ['pwmchip25', 0]],
}
PWM_CHANNELS_MAP['am654x-hsevm'] = PWM_CHANNELS_MAP['am654x-evm']
PWM_CHANNELS_MAP['am654x-idk'] = PWM_CHANNELS_MAP['am654x-evm']


def setup
  check_setup()
  self.as(LspTestScript).setup
end


def run
  dut_name = @equipment['dut1'].name
  @equipment['bbb1'].connect({'type'=>'serial'})
  @equipment['bbb1'].configure_device()
  period = @test_params.params_chan.period[0].to_i
  duty_cycles = [1000, period/2, period-1000]

  @test_params.params_chan.iterations[0].to_i.times do |iter|
    @equipment['dut1'].log_info("Starting interation #{iter}")
    duty_cycles.each_with_index{|duty_cycle, duty_cycle_index|
      PWM_CHANNELS_MAP[dut_name].each_with_index {|channel, channel_index|
        export_channel(channel)
        generate_pwm_on_channel(channel, period, duty_cycle)
        if test_pwm_signal(channel_index, duty_cycle_index)
          set_result(FrameworkConstants::Result[:fail], "Unexpected PWM signal value on channel #{channel}")
          return
        end
      }
    }
    # Stop PWM signals
    PWM_CHANNELS_MAP[dut_name].each_with_index {|channel, channel_index|
      enable_channel(channel, 0)
    }
  end

  set_result(FrameworkConstants::Result[:pass], "PWM channels #{PWM_CHANNELS_MAP[dut_name]} working as expected")
end


def clean
  self.as(LspTestScript).clean
  # Stop PWM signals
  PWM_CHANNELS_MAP[@equipment['dut1'].name].each {|channel|
    enable_channel(channel, 0)
  }
end


def test_pwm_signal(channel_index, duty_cycle_index)
  bbb_channel = @equipment['bbb1'].params['adc_ports'][channel_index]
  adc_value = @equipment['bbb1'].adc_read(bbb_channel)
  case duty_cycle_index
  when 0
    return false if adc_value < 0.3
  when 1
    return false if adc_value > 0.2 and adc_value < 0.75
  when 2
    return false if adc_value > 0.57
  end
  return true # Test failed, voltage read outside expected range
end


def generate_pwm_on_channel(channel, period, duty_cycle)
  set_channel_period(channel, period)
  set_channel_duty_cycle(channel, duty_cycle)
  enable_channel(channel)
end


def export_channel(channel)
  @equipment['dut1'].send_cmd("ls /sys/class/pwm/#{channel[0]}/pwm#{channel[1]} || echo #{channel[1]} > /sys/class/pwm/#{channel[0]}/export", @equipment['dut1'].prompt)
end


def set_channel_period(channel, period)
  @equipment['dut1'].send_cmd("echo #{period} > /sys/class/pwm/#{channel[0]}/pwm#{channel[1]}/period", @equipment['dut1'].prompt)
end


def set_channel_duty_cycle(channel, duty_cycle)
  @equipment['dut1'].send_cmd("echo #{duty_cycle} > /sys/class/pwm/#{channel[0]}/pwm#{channel[1]}/duty_cycle", @equipment['dut1'].prompt)
end


def enable_channel(channel, enable=1)
  @equipment['dut1'].send_cmd("echo #{enable} > /sys/class/pwm/#{channel[0]}/pwm#{channel[1]}/enable", @equipment['dut1'].prompt)
end


def check_setup
  dut_name = @equipment['dut1'].name
  if !PWM_CHANNELS_MAP.has_key?(dut_name)
    raise "Error. Add #{dut_name} to PWM_CHANNELS_MAP in #{__FILE__}"
  end

  if !@equipment['bbb1'].params.has_key?('adc_ports')
    raise "Bench Error. Define adc_ports in the BeagleTester in your bench file"
  end

  num_channels_to_test = PWM_CHANNELS_MAP[dut_name].size
  if @equipment['bbb1'].params['adc_ports'].size < num_channels_to_test
    raise "Bench Error. Add more adc_ports in the BeagleTester in your bench file"
  end
end