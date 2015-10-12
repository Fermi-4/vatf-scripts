# Module that includes methods to process execution logs and capture/collect
# performance data embedded in the logs.

module ParsePerfomance
  # Return array of performance data that comply w/ set_result method defined by atf_session_runner
  # logs can be either a log file path or the actual string with the execution data.
  # perf_metrics is an array that describes the performance data to collect.
  # Each array element is a hash with following key,value pairs:
  #  name: Performance metric's name
  #  regex: regular expression or Array of regular expressions used to capture perf metric value
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
        if metric.has_key?('adj')
          values = parse_data(metric['regex'], data, metric['adj'])
        else  
          values = parse_data(metric['regex'], data)
        end
        perfdata << {'name' => metric['name'], 'value' => values, 'units' => metric['units']}
      rescue Exception => e
        puts e.backtrace.to_s
        next
      end
    }
    perfdata 
  end

  # Helper function to parse performance data, it allows using an array of
  # regexs to parse the data by sequetially applying each regex to the
  # data parsed in a previous regex scan.
  # Takes:
  #   regex : String or arrays of string defining the regexs to apply
  #   data: The raw data to be parsed
  #   adj: Adjustment hash as defined by the 'adj'=> <> key value pair of
  #        the perf_metric parameter in the get_performance_data function
  def parse_data(regex, data, adj=nil)
    m_regex = Array(regex)
    m_data = Array(data).flatten()
    values = []
    if m_regex.length > 0 
      m_data.each {|d| values += parse_data(m_regex[1..-1],d.scan(/#{m_regex[0]}/m), adj)}
    else
      if adj
        m_data.each_slice(2) { |vals|
          val = vals[adj['val_index']].to_f
          adj_factor = (adj['val_adj'].select {|k,v| k.match(vals[adj['units_index']])}).values[0]
          val = val * adj_factor
          values << val
        }
      else
        m_data.each{ |d| values << d.to_f }
      end
    end
    values
  end

end #end of module
