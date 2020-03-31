#  [@name: VATF two duts example script
#   @requirements: 12345
#   @params: packages=ti-test, message=hello world
#   @description: VATF test script with two duts. Showcasing a simple Linux
#   test flow, that relies in the default_test_module script to boot the
#   duts to the linux prompt, installs package ti-test, then echos hello world
#   and checks that hello world is printed in the console in both duts.
#   @setup_requires: dut1=["<platform>",linux];server1=["linuxserver"];dut2=["<platform2>",linux]
#   @pass_criteria: hello world is seen in console on both
#   @steps: Power cycle the duts
#           Boot to console the duts
#           Install ti-test package duts
#           echo hello world in the duts
#  ]

# load helper script to reuse boot logic. When using this file as a
# starting poing make sure the path is valid with respect to the
# location of the script.
require File.dirname(__FILE__)+'/../LSP/default_test_module'

include LspTestScript #include module defined in default_test_module

# By default reusing setup function from default_test_module.
# Uncomment this section to explicitly call the setup function from
# default_test_module.
# def setup
#   self.as(LspTestScript).setup
# end

# Boards have booted to prompt and ti-test package is installed
# during setup function. Now show multiple ways to check that hello
# world is echoed
def run
  # Getting testcase parameter "message" (test case parameters variables are arrays hence the [] indexing)
  # defaults to "hello world" if the parameter does not exist
  message = @test_params.params_chan.instance_variable_defined?(:@message) ? @test_params.params_chan.message[0] : "hello world"

  # Case 1: send echo wait 5 sec for prompt and check that hello world is included in the dut's response
  @equipment['dut1'].send_cmd("echo '#{message}'", @equipment['dut1'].prompt, 5)
  result = !@equipment['dut1'].timeout? # Checking that prompt was recevied after 5 sec
  result &= @equipment['dut1'].response.match(/[\r\n]+hello world[\r\n]+#{@equipment['dut1'].prompt}/im) # Checking that hello world is in the dut's response

  # Case 2: send echo and use the send_cmd regexp parameter in send_cmd to check for response. Use the default 10 sec timeout
  @equipment['dut2'].send_cmd("echo '#{message}'", /[\r\n]+hello world[\r\n]+#{@equipment['dut2'].prompt}/im)
  result &= !@equipment['dut2'].timeout?

  # Case 3: send echo and use the rc code
  @equipment['dut1'].send_cmd("echo '#{message}'", @equipment['dut1'].prompt)
  result &= !@equipment['dut1'].timeout?
  @equipment['dut1'].send_cmd('echo $?', /^0[\r\n]+#{@equipment['dut1'].prompt}/im)
  result &= !@equipment['dut1'].timeout?

  # Set the result for the test. Test must use set_result to provide a result
  # or the framework will set the result to fail.
  if result
    set_result(FrameworkConstants::Result[:pass], "Test Pass.")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end
end

# Calling clean function explicitly. Comment out this function to
# implicitly use the clean function from default_test_module
def clean
  self.as(LspTestScript).clean
end
