require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

def run_collect_performance_data
  puts "\n osbench_test::run_collect_performance_data"
  log = get_serial_output
  perf_data = []   
  log.scan(/\|\s+(\d+\.\d+)\s+\|\s+IP\s+=\s+(\w+)\s+\|\s+CS\s+=\s+(\w+).+?Max\s+Time\s+=\s+(\d+\.\d+)\s+(\w+).+?Min\s+Time\s+=\s+(\d+\.\d+)\s+(\w+).+?Avg\s+Time\s+=\s+(\d+\.\d+)\s+(\w+)/m) {|d|
    perf_data << {'name' => "#{d[0]}_ip#{d[1]}_cs#{d[2]}_MAX", 'value' => "#{d[3]}", 'units' => "#{d[4]}"}
    perf_data << {'name' => "#{d[0]}_ip#{d[1]}_cs#{d[2]}_MIN", 'value' => "#{d[5]}", 'units' => "#{d[6]}"}
    perf_data << {'name' => "#{d[0]}_ip#{d[1]}_cs#{d[2]}_AVG", 'value' => "#{d[7]}", 'units' => "#{d[8]}"}
  }
  perf_data
end

def run_determine_test_outcome
  puts "\n osbench_test::run_determine_test_outcome"
  perf_data = run_collect_performance_data
  if perf_data.length > 1
    [FrameworkConstants::Result[:pass], "Performace data was collected", perf_data]
  else
    [FrameworkConstants::Result[:fail], "Performance data was not collected"]
  end
end

