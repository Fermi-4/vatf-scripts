# The functions used to collect statistics MUST yield the command STRING 
# to send to DUT to collect the stats.
require File.dirname(__FILE__)+'/../lib/sys_stats'

module Metrics
  include SystemStats
  
  def start_collecting_stats(stats, interval=-1)
    return if !stats
    local_stats = (stats.kind_of?(String) || stats.kind_of?(Hash)) ? [stats] : stats  
    start_collecting_system_stats(get_function_pointers('collect', local_stats), interval) {|cmd| yield cmd}
  end
  
  def stop_collecting_stats(stats)
    return if !stats
    local_stats = (stats.kind_of?(String) || stats.kind_of?(Hash)) ? [stats] : stats 
    stop_collecting_system_stats(get_function_pointers('parse', local_stats)) {|cmd| yield cmd}
  end
  
  def get_function_pointers(type, stats)
    fp = {}
    stats.each {|stat|
      if stat.kind_of?(String) && DEFAULT_METRICS.has_key?(stat)
        fp[stat]= DEFAULT_METRICS[stat][type]
      elsif stat.kind_of? Hash
        fp.merge!(stat)
      else
        puts "WARNING: Invalid metric type #{stat.to_s} passed to start_collecting_stats"
      end
    }
    fp
  end
  
	def Metrics.parse_cpu_stats(data_array)
    cpu_load = []
    0.upto(data_array.length - 2) do |i|
      end_cpu = data_array[i+1]
      start_cpu = data_array[i]
      total = end_cpu['total'] - start_cpu['total']
      idle_time = end_cpu['idle'] + end_cpu['iowait'] - start_cpu['idle'] - start_cpu['iowait']
      cpu_load << (1-idle_time/total)*100
    end
    {'name' => 'cpu_load' , 'value' => cpu_load, 'units' => '%'} 
  end

  def Metrics.collect_cpu_stats()
    stat_string = (yield 'cat /proc/stat').match(/cpu.*/im)[0]
    stat_arr = stat_string.split(/[\n\r]+/)
    cpu_stats = stat_arr[0].split(/\s+/)
    cpu_hash = {'user'=> cpu_stats[1].to_f, 'nice'=> cpu_stats[2].to_f, 'system' => cpu_stats[3].to_f, 'idle'=> cpu_stats[4].to_f, 'iowait' => cpu_stats[5].to_f, 'irq' => cpu_stats[6].to_f, 'softirq'=> cpu_stats[7].to_f}
    total = 0
    cpu_hash.values.each {|v| total+=v}
    cpu_hash['total'] = total
    cpu_hash
  end
  
  DEFAULT_METRICS = {
    'cpu' => {'collect' => self.method(:collect_cpu_stats),  'parse' => self.method(:parse_cpu_stats)},
    
  }
  
end
