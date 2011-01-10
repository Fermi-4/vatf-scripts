require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

def run
  monkey_cmd = 'monkey'
  if @test_params.params_chan.instance_variable_defined?(:@black_list)
    begin
      black_list_pkgs = '#Monkey black list'
      black_list_file = 'monkey_blk_lst.txt'
      @test_params.params_chan.black_list.each {|pkg| black_list_pkgs += "\n#{pkg}"}
      send_host_cmd("cat << EOF > #{black_list_file}\n#{black_list_pkgs}\nEOF")
      send_adb_cmd("push #{black_list_file} /#{black_list_file}")
      monkey_cmd += " --pkg-blacklist-file /#{black_list_file}"
    ensure
      send_host_cmd("rm -rf #{black_list_file}")
    end
  end
  if @test_params.params_chan.instance_variable_defined?(:@flags)
    @test_params.params_chan.flags.each {|flg| monkey_cmd += " #{flg}"}  
  end
  monkey_cmd += " #{@test_params.params_chan.event_count[0]}"
  monkey_string = send_adb_cmd("shell #{monkey_cmd}")
  sys_crashes = monkey_string.scan(/\/+\s*CRASH:\s*(.*?)\s*\((.*?)\).*?Long\s*Msg:\s*(.*?)\s+/im)
  no_response = monkey_string.scan(/\/+\s*NOT\s*RESPONDING:\s*(.*?)\s*\((.*?)\).*?ANR\s*in.*?\((.*?)\).*?Reason:\s*(.*?)\s+/im)
  events_injected = monkey_string.match(/Events\s*injected:\s*(\d+)/i)
  if !events_injected
    set_result(FrameworkConstants::Result[:fail], "Problem occured while trying to run monkey test")
  elsif sys_crashes.empty? && no_response.empty? && events_injected.captures[0].to_i == @test_params.params_chan.event_count[0].to_i
    set_result(FrameworkConstants::Result[:pass], "No problems reported during #{@test_params.params_chan.event_count[0]} events")
  else
    puts "Crash(es) reported #{sys_crashes.to_s}"
    puts "No response(s) reported #{no_response.to_s}"
    set_result(FrameworkConstants::Result[:fail], "Crash(es) reported for #{sys_crashes}\nNo response(s) reported #{no_response.to_s}")
  end
ensure
  send_adb_cmd("shell rm /#{black_list_file}") if @test_params.params_chan.instance_variable_defined?(:@black_list)
end