require File.dirname(__FILE__)+'/../../default_test_module'
include LspTestScript

def run
  commands = ['mkdir ./myproject', 'cd ./myproject', 'git init .', 'touch hello',
              'git add hello', 'git config user.email "tester@ti.com"',
              'git config user.name "tester"', 'git commit -s -m "test commit"', 'git status']
  begin
    dut_ip = get_ip_addr()
    @equipment['dut1'].send_cmd("cd /tmp", @equipment['dut1'].prompt)
    commands.each {|cmd|
      if ! check_cmd?(cmd)
        set_result(FrameworkConstants::Result[:fail], "Error executing #{cmd}")
        return
      end
    }
    set_result(FrameworkConstants::Result[:pass], "All git commands ran successfully")

  rescue Exception => e
    puts e.message
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Exception trying to test git in DUT")
  end
end