module SystemStats    
  def start_collecting_system_stats(interval = -1)
     @system_stats = []
     @stats_thread = nil
     if(interval > 0)
       @stats_thread = Thread.new() {
         Thread.pass
         Thread.current["stop"]=false
         while(!Thread.current["stop"])
           @system_stats << {'cpu' => get_cpu_stats() {|cpu_cmd| yield cpu_cmd},    
           'mem' => get_memory_stats {|mem_cmd| yield mem_cmd}}
           sleep interval
         end
       }
     else
       @system_stats = [{'cpu' => get_cpu_stats() {|cpu_cmd| yield cpu_cmd},    
           'mem' => get_memory_stats {|mem_cmd| yield mem_cmd}}]
     end
  end
  
  def stop_collecting_system_stats()
    if @stats_thread
      @stats_thread["stop"]=true
    else
      @system_stats << {'cpu' => get_cpu_stats() {|cpu_cmd| yield cpu_cmd},    
           'mem' => get_memory_stats {|mem_cmd| yield mem_cmd}}
    end
    cpu_load = []
    mem_usage = []
    0.upto(@system_stats.length - 2) do |i|
      end_cpu = @system_stats[i+1]['cpu']
      start_cpu = @system_stats[i]['cpu']
      total = end_cpu['total'] - start_cpu['total']
      idle_time = end_cpu['idle'] + end_cpu['iowait'] - start_cpu['idle'] - start_cpu['iowait']
      cpu_load << (1-idle_time/total)*100
      mem_usage << @system_stats[i+1]['mem']['total']
    end
    [{'name' => 'cpu_load' , 'value' => cpu_load, 'units' => '%'}, {'name' => 'memory_usage', 'value'=> mem_usage, 'units' => "bytes"}]
  end

  def get_cpu_stats()
    stat_string = yield 'cat /proc/stat'
    stat_arr = stat_string.split(/[\n\r]+/)
    cpu_stats = stat_arr[0].split(/\s+/)
    cpu_hash = {'user'=> cpu_stats[1].to_f, 'nice'=> cpu_stats[2].to_f, 'system' => cpu_stats[3].to_f, 'idle'=> cpu_stats[4].to_f, 'iowait' => cpu_stats[5].to_f, 'irq' => cpu_stats[6].to_f, 'softirq'=> cpu_stats[7].to_f}
    total = 0
    cpu_hash.values.each {|v| total+=v}
    cpu_hash['total'] = total
    cpu_hash
  end
 
  def get_memory_stats()
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

end  # End of module

