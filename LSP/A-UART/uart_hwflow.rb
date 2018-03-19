# This test is currently specific to Beaglebone-black boards with special
# setup to loopback uart1-cts/rts signals on P9-19 and p9-20 pins.
# The test also requires a special build that disables i2c2 and enables uart1
# because uart1 cts/rts pins are muxed in, instead of i2c2 scl and sda pins.
# uarthwflow must be defined in the bench file to identify relay that control
# the rts/cts loopback, for example:
#   dut = EquipmentInfo.new("beaglebone-black", "linux_uarthwflow")
#   dut.params = {'uarthwflow' => {'rly16.192.168.0.40' => 5}}


require File.dirname(__FILE__)+'/../TARGET/dev_test2'


def enable_uart_hw_loopback
  if @equipment['dut1'].params.has_key?('uarthwflow')
    @equipment['dut1'].send_cmd("cat /proc/device-tree/ocp/i2c\@4802a000/status", "disabled")
    if @equipment['dut1'].timeout?
      raise "Test can only be run on boards with uarthwflow parameter defined in the bench file"
    else
      # enable hw loopback
      @power_handler.switch_off(@equipment['dut1'].params['uarthwflow'])
    end

  else
    raise "Test can only be run on boards with uarthwflow parameter defined in the bench file"
  end
end

def disable_uart_hw_loopback
  if @equipment['dut1'].params.has_key?('uarthwflow')
    @power_handler.switch_on(@equipment['dut1'].params['uarthwflow'])
  end
end

def setup
  self.as(LspTargetTestScript).setup
  enable_uart_hw_loopback
end

def clean
  disable_uart_hw_loopback
  self.as(LspTargetTestScript).clean
end
