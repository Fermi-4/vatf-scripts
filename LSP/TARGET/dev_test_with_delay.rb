require File.dirname(__FILE__)+'/dev_test2'

def run
  # Since omapl138 is slow, add delay before running tests
  if @equipment['dut1'].name == "omapl138-lcdk"
    sleep 60
  end

  # Run the test
  self.as(LspTargetTestScript).run

end

