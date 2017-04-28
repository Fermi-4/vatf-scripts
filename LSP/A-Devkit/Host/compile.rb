require File.dirname(__FILE__)+'/../../default_test_module'
include LspTestScript

def setup
  puts "No need to boot DUT"
end

def run_and_check_cmd(cmd, equip, response, timeout=60)
  begin
    if equip.send_cmd(cmd, response, timeout)
      set_result(FrameworkConstants::Result[:fail], "Error executing #{cmd}")
      return true
    end
    return false
  rescue Exception => e
    puts e.message
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Exception trying to execute #{cmd}")
    return true
  end
end

def run
  equip = @equipment['server1']
  toolchains_url = 'http://lcpd.gt.design.ti.com/toolchains'
  arch = @test_params.params_control.arch[0]
  download_cmd =  "cd ~ && wget -A xz -m -p -E -k -K -np #{toolchains_url}/#{arch}/ && echo 'DOWNLOADPASSED'"
  return if run_and_check_cmd(download_cmd, equip, /DOWNLOADPASSED/)
  toolchain_filename = Dir.entries("#{Dir.home()}/#{toolchains_url.sub('http://','')}/#{arch}")[-1]
  toolchain_dirname = File.basename(toolchain_filename, ".tar.xz")
  if equip.send_sudo_cmd("tar xvf ~/#{toolchains_url.sub('http://','')}/#{arch}/#{toolchain_filename} -C /opt && echo 'INSTALLATIONPASSED'", /INSTALLATIONPASSED/, 120)
    set_result(FrameworkConstants::Result[:fail], "Error trying to install toolchain")
    return
  end
  compile_test = File.join(File.dirname(__FILE__), 'compile.sh')
  toolchain_path = "/opt/#{toolchain_dirname}/bin"
  devkit_url =  @test_params.var_devkit_url
  c_app_path = File.join(File.dirname(__FILE__), '..', 'hello.c')
  cpp_app_path = File.join(File.dirname(__FILE__), '..', 'hello.cpp')
  pthread_app_path = File.join(File.dirname(__FILE__), '..', 'thread-ex.c')

  test_cmd ="#{compile_test} #{toolchain_path} #{devkit_url} " \
            "#{File.join(File.dirname(__FILE__), '..', 'hello.c')} " \
            "#{File.join(File.dirname(__FILE__), '..', 'hello.cpp')} " \
            "#{File.join(File.dirname(__FILE__), '..', 'thread-ex.c')}"
  return if run_and_check_cmd(test_cmd, equip, /All host-side devkit checks passed/, 900)
  set_result(FrameworkConstants::Result[:pass], "Host-side devkit passed all tests")
end