module SystemStats    
  
  def start_collecting_system_stats(metrics, interval=-1)
     @system_metrics = metrics.clone
     @system_stats = Hash.new { |hash, key| hash[key] = [] }

     @stats_thread = nil
     if(interval > 0)
       @stats_thread = Thread.new() {
         Thread.pass
         Thread.current["stop"]=false
         while(!Thread.current["stop"])
           @system_metrics.each {|k,v|
             @system_stats[k] << v.call {|cmd| yield cmd}
           }
           sleep interval
         end
       }
     else
       @system_metrics.each {|k,v|
         @system_stats[k] << v.call {|cmd| yield cmd}
       }
     end
  end
  
  def stop_collecting_system_stats(parsers)
    results = []
    if @stats_thread
      @stats_thread["stop"]=true
    else
      @system_metrics.each {|k,v|
        @system_stats[k] << v.call {|cmd| yield cmd}
      }
    end
    parsers.each {|k,v|
      if @system_stats[k].length < 1
        puts "WARNING: Metric #{k} was not passed to start_collecting_system_stats"
        next
  end
      results << v.call(@system_stats[k])
    } 
    results
 end 
end  # End of module

