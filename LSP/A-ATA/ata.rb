# -*- coding: ISO-8859-1 -*-
include LspFSTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  self.as(LspTestScript).run
end

def clean
  self.as(LspTestScript).clean
  puts 'ata child clean'
  # if the power mode is sleep, dut need reboot so ata can be functional.
  if @test_params.params_chan.power_mode == 'sleep' then 
    @equipment['apc1'].reset(@equipment['dut1'].power_port)
    sleep 30
  end
end


