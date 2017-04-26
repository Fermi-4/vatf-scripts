require File.dirname(__FILE__)+'/../../default_test_module'
include LspTestScript

def run
  filenames = ['hello.c', 'hello.cpp']
  begin
    dut_ip = get_ip_addr()
    @equipment['dut1'].send_cmd("cd /tmp", @equipment['dut1'].prompt)
    filenames.each {|filename|
      scp_push_file(dut_ip, File.join(File.dirname(__FILE__), '..', filename), File.join('/tmp', filename))
      compiler = filename.match(/\.c$/) ? "gcc" : "g++"
      if ! check_cmd?("#{compiler} #{filename} -o hello")
        set_result(FrameworkConstants::Result[:fail], "#{compiler} could not compile #{filename}")
        return
      end
      if ! check_cmd?('./hello')
        set_result(FrameworkConstants::Result[:fail], "Error executing compiled hello program")
        return
      end
    }
    set_result(FrameworkConstants::Result[:pass], "gcc/g++ successfully compile files in DUT")

  rescue Exception => e
    puts e.message
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Exception trying to test gcc in DUT")
  end
end