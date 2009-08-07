# -*- coding: ISO-8859-1 -*-
   
include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  @equipment['dut1'].send_cmd("ln -s /dev/rtc0 /dev/rtc", @equipment['dut1'].prompt, 20)
  self.as(LspTestScript).run
end

def clean
  #super
  self.as(LspTestScript).clean
end





