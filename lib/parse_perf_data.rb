# Module that includes methods to process execution logs and capture/collect
# performance data embedded in the logs.

module ParsePerfomance
  # Return array of performance data that comply w/ set_result method defined by atf_session_runner
  # logs can be either a log file path or the actual string with the execution data.
  # perf_metrics is an array that describes the performance data to collect.
  # Each array element is a hash with following key,value pairs:
  #  name: Performance metric's name
  #  regex: regular expression used to capture perf metric value
  #  units: Performance metric's units
  #  adj: Optional hash used to escale capture value to appropriate units. It has following key,value pairs:
  #        val_index: index of capture value in regex above
  #        unit_index: index of capture units in regex above
  #        val_adj: hash of regex:val. The capture unit value will be check agains regex key, if match value is adjusted by val.
  # For example, the entry below will capture values in us (microseconds). Values in nano or miliseconds will be adjusted accordingly.
  # {'name' => 'lat_pagefault',
  #  'regex' => '^\|TEST\sSTART\|lat_pagefault\|.+?Pagefaults\son\s.+?:\s+([\d\.]+)\s+(\w+)',
  #  'adj' => {'val_index' => 0, 'units_index' => 1, 'val_adj' => {/nano/ => 0.001, /micro/ => 1.0, /mili/ => 1000.0}},
  #  'units' => 'us',
  # }
  def get_performance_data(logs, perf_metrics)
    return nil if !perf_metrics  # check that perf_metrics is not nil
    perfdata = []
    data = logs
    if File.file? logs
      data = File.new(logs,'r').read
    end
    perf_metrics.each {|metric|
      begin
        values = []
        if metric.has_key?('adj')
          data.scan(/#{metric['regex']}/m) {|vals|
            val = vals[metric['adj']['val_index']].to_f
            adj_factor = (metric['adj']['val_adj'].select {|k,v| k.match(vals[metric['adj']['units_index']])}).values[0]
            val = val * adj_factor
            values << val
          }
        else  
          data.scan(/#{metric['regex']}/m) {|val|
            values << val[0].to_f
          }
        end
        perfdata << {'name' => metric['name'], 'value' => values, 'units' => metric['units']}
      rescue Exception => e
        puts e.backtrace.to_s
        next
      end
    }
    perfdata 
  end
end #end of module