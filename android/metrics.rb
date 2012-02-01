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
  
  def Metrics.collect_virtual_memory_stats()
    #USER     PID   PPID  VSIZE  RSS     WCHAN    PC         NAME                    
    #root      1     0     316    176   c00cd5b4 0000875c S /init  
    stat_string = yield 'ps' #send_adb_cmd('shell ps')
    stat_arr = stat_string.split(/[\n\r]+/)
    mem_stats = {}
    stat_arr.each do |current_stat|
      stat = current_stat.split(/[:\s]+/)
      mem_stats[stat[-1]]=stat[3].to_f
    end
    total = 0
    mem_stats.values.each {|v| total+=v}
    mem_stats['total'] = total
    mem_stats
  end
  
  def Metrics.parse_virtual_memory_stats(data_array)
    mem_usage = []
    0.upto(data_array.length - 2) do |i|
      mem_usage << data_array[i+1]['total']
    end
    {'name' => 'virtual_mem_usage', 'value'=> mem_usage, 'units' => "bytes"}
  end
  
  # Generic function to collect top query
def get_android_top_stats(cpu_load_samples,process_name,time)
    top_stats = Hash.new
    top_result = Array.new 
    top_stats['process_cpu_loads'] = Array.new
    top_stats['process_mem_usage_rss'] = Array.new
    process_cpu_loads = Array.new
    process_mem_usage_rss = Array.new
    cpu_info = ''
    delay = [time.to_i/cpu_load_samples,1].max
    #cpu_info = send_adb_cmd("shell top -d #{delay} -n #{cpu_load_samples-1}") # this is not working for now I have to get back to it
    puts "Start collecting samples now please wait ........."
    #cpu_info = `adb shell top -d #{delay} -n #{cpu_load_samples-1}`
    cpu_info = send_adb_cmd("shell top -d #{delay} -n #{cpu_load_samples-1}")   
    top_result = cpu_info.scan(/(\d+)%\s+[SR]\s+\d+\s+\d+K\s+(\d+)K\s+fg.*#{process_name}/i)  
    #extract stat
    top_result.each{|t|
     process_cpu_loads <<  t[0]
     process_mem_usage_rss <<  t[1] 
    }
   top_stats['process_cpu_loads'] = process_cpu_loads
   top_stats['process_mem_usage_rss'] = process_mem_usage_rss
   return top_stats
end 

# for certain process name we pass metrics and its process id
def get_android_process_meminfo(metrics,pid)
    puts "GETTING MEMINFO"
    meminfos = Hash.new()
    #cmd = "logcat  -d -s ProcessMemoryInfoService"
    #response = send_adb_cmd cmd
    #response = `adb logcat  -d -s ProcessMemoryInfoService`
    response = send_adb_cmd("logcat  -d -s ProcessMemoryInfoService")
    local_metrics = metrics
    local_metrics = [metrics] if !metrics.kind_of?(Array)
    local_metrics.each{|metric|
    metric_values = Array.new
    meminfo  = response.scan(/#{get_android_meminfo_regex(pid,metric)}/)
    meminfo.each{|info|
    metric_values <<  info[0] 
    } 
    meminfos[metric]  = metric_values
    }
    meminfos
end 

def get_android_meminfo_regex(pid,metric_name)
regexs = Hash.new 
regexs["dalvik_private_dirty"] =  "pid\\s+=\\s+#{pid}\\s+dalvik\\s+private\\s+dirty\\s+(\\d+)"
regexs["dalvik_pss"] = "pid\\s+=\\s+#{pid}\\s+delvid\\s+pss\\s+(\\d+)"
regexs["dalvik_shared_dirty"] = "pid\\s+=\\s+#{pid}\\s+delivik\\s+shared\\s+dirty\\s+(\\d+)"
regexs["native_private_dirty"] = "pid\\s+=\\s+#{pid}\\s+native\\s+private\\s+dirty\\s+(\\d+)"
regexs["native_pss"] = "pid\\s+=\\s+#{pid}\\s+native\\s+pss\\s+(\\d+)"
regexs["native_shared_dirty"] = "pid\\s+=\\s+#{pid}\\s+native\\s+shared\\s+dirty\\s+(\\d+)"
regexs["other_private_dirty"] = "pid\\s+=\\s+#{pid}\\s+other\\s+private\\s+dirty\\s+(\\d+)"
regexs["other_pss"] = "pid\\s+=\\s+#{pid}\\s+other\\s+pss\\s+(\\d+)"
regexs["other_shared_dirtyl"] = "pid\\s+=\\s+#{pid}\\s+other\\s+shared\\s+dirtyl\\s+(\\d+)"
regexs["total_PrivateDirty"] = "pid\\s+=\\s+#{pid}\\s+Total\\s+PrivateDirty\\s+(\\d+)"
regexs["total_pss"] = "pid\\s+=\\s+#{pid}\\s+total\\s+pss\\s+(\\d+)"
regexs[metric_name]

end 


def get_fps 
fps_values = Array.new()
cmd  = "logcat -d "
response = send_adb_cmd cmd 
 response.split("\n").each{|line|
 if line.include?("FPS")
  line = line.scan(/([0-9]*\.[0-9]+)/)
  fps_values << line[0][0]
 end  
 }
 fps_values.delete_at(0)
 return fps_values
end 

def get_android_process_pids(process_names)
    processes = Hash.new()
    pids = "" 
    #cpu_info =  `adb shell top -n 1`
    cpu_info = send_adb_cmd("shell top -n 1")
    process_names.each{|process|    
    processes[process] = cpu_info.scan(/(\d+)\s+\d+%\s+[SR]\s+\d+\s+\d+K\s+\d+K\s+fg.*#{process}/i)[0][0].to_s
    puts "PIDS PIDS #{processes[process]}"
    pids = processes[process]+","
    }
   processes["pids"] = pids
   processes
end 

  
  DEFAULT_METRICS = {
    'cpu' => {'collect' => self.method(:collect_cpu_stats),  'parse' => self.method(:parse_cpu_stats)}, 
    'sys_vmem' => {'collect' => self.method(:collect_virtual_memory_stats),  'parse' => self.method(:parse_virtual_memory_stats)}, 
    
  }
  
end
