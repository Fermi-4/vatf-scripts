require File.dirname(__FILE__)+'/../../default_target_test'

include LspTargetTestScript

def setup_connect_equipment
  puts "Test specific connect_equipment logic"
end

def run_collect_performance_data
  puts "Test specific  collect_performance_data logic"
end

def run_determine_test_outcome
  puts "Test specific determine_test_outcome logic"
  puts "\nSTD OUTPUT:\n#{get_std_output}\n"
  puts "\nSTD ERROR:\n#{get_std_error}\n"
  [FrameworkConstants::Result[:pass], "This test pass"]
end

