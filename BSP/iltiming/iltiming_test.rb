require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

def run_get_script_output
  sleep (30)   # Wait before serial data becomes available in the serial port 
  super
end

def run_collect_performance_data
  puts "Test specific  collect_performance_data logic"
end

def clean_delete_binary_files
end

# def run_determine_test_outcome
  # puts "Test specific determine_test_outcome logic"
  # puts "\nSTD OUTPUT:\n#{get_std_output}\n"
  # puts "\nSTD ERROR:\n#{get_std_error}\n"
  # puts "\nSERIAL OUTPUT:\n#{get_serial_output}\n"
  # [FrameworkConstants::Result[:pass], "This test pass"]
# end

