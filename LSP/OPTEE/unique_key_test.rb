# This test requires secure_hello_world app compiled for appropriate architecture
# For details about how to compile for other archs, please refer to secure_storage_test
# repository hosted by TI's bitbucket server.

require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

# Returns true if command return value is 0
def check_cmd?(cmd, equip=@equipment['dut1'], timeout=10)
  equip.send_cmd("#{cmd}", equip.prompt, timeout)
  equip.send_cmd("echo $?",/^0[\n\r]*/m, 2)
  return !equip.timeout?
end

def run
  begin
    dut_ip = get_ip_addr()
    @equipment['dut1'].send_cmd("cd /tmp", @equipment['dut1'].prompt)

    # Copy required files to run the tests
    filenames = Dir.entries(File.dirname(__FILE__)).select{|f| f.match(/(secure_hello_world_|\.sh$)/)}
    filenames.each {|filename|
      scp_push_file(dut_ip, File.join(File.dirname(__FILE__), filename), File.join('/tmp', filename))
      @equipment['dut1'].send_cmd("chmod +x ./#{filename}", @equipment['dut1'].prompt)
    }

    # Run tests
    filenames=filenames.select{|f| f.match(/\.sh$/)}
    filenames.each {|filename|
      if ! check_cmd?("./#{filename}", @equipment['dut1'], 60)
        set_result(FrameworkConstants::Result[:fail], "Test #{filename} returned non-zero value")
        return
      end
    }

    set_result(FrameworkConstants::Result[:pass], "OPTEE Secure Storage unique key tests ran successfully")

  rescue Exception => e
    puts e.message
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Exception running OPTEE Secure Storage unique key tests")
  end
end