require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end

def setup_connect_equipment
  @force_telnet_connect = true              #this variable, set as true, is required to run this script with the CEPC PC
end

def run_collect_performance_data
  puts "\n cetk_test::run_collect_performance_data"
end

def run_determine_test_outcome
  puts "\n cetk_test::run_determine_test_outcome"
  result, comment = [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
  File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line| 
    # n, v, u = line.strip.split(' ')
    # perf_data << {'name' => n, 'value' => v, 'units' => u}
    if line =~ /\*\*\*\s*passed:\s+1/i then
      puts "-----------test passed---------"
      result, comment = [FrameworkConstants::Result[:pass], "This test pass."]
    end
  }
  return result, comment

end

