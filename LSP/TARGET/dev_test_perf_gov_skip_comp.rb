require File.dirname(__FILE__)+'/dev_test_perf_gov'

# Do not compare performance against historical data
# This is useful for test cases with performance metrics
# that are not reliable and that can not be modified.
def skip_perf_comparison
  puts "Skipping performance comparison"
end
