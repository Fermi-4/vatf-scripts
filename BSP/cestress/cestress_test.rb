require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end

def run_collect_performance_data
  puts "\n cetk_test::run_collect_performance_data"
end

def run_determine_test_outcome
  puts "\n cetk_test::run_determine_test_outcome"
  result, comment = [FrameworkConstants::Result[:fail], "This test has to be run manually."]
  return result, comment
end

def clean_delete_binary_files
    puts "\n WinceTestScript from cestress module::clean_delete_binary_files"    
end
