# The functions used to collect statistics MUST yield the command STRING 
# to send to DUT to collect the stats.
require File.dirname(__FILE__)+'/../lib/sys_stats'

module Metrics
  include SystemStats
  
  def start_collecting_stats(stats, interval=-1)
    return if !stats
    local_stats = (stats.kind_of?(String) || stats.kind_of?(Hash)) ? [stats] : stats  
    start_collecting_system_stats(get_function_pointers('collect', local_stats), interval) {|cmd, stat| yield cmd, stat}
  end
  
  def stop_collecting_stats(stats)
    return if !stats
    local_stats = (stats.kind_of?(String) || stats.kind_of?(Hash)) ? [stats] : stats 
    stop_collecting_system_stats(get_function_pointers('parse', local_stats)) {|cmd, stat| yield cmd, stat}
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

  def Metrics.collect_cpu_stats()
    stat_string = yield 'dumpsys cpuinfo'
    cpu_stats = {}
    load_string = stat_string.match(/(\w+\s*:\s*[\d\.\/\s]+)/i).captures[0]
    load_arr = load_string.split(/[\s\/:]+/)
    1.upto(load_arr.length - 1) do |idx|
      load_time = case idx
                    when 1
                      '1'
                    when 2
                      '5'
                    else
                      '15'
                  end
      cpu_stats['cpu_' + load_arr[0] + '_' + load_time] = {'val' => load_arr[idx].to_f, 'units' => '1'}
    end

    proc_loads = stat_string.scan(/[\d\.]+%\s*[\d\/]*[^:]+[:\d]+\s*[\d\.]+%*\s*\w+\s*\+\s*[\d\.]+%*\s*\w+.*/)
    proc_loads[0..-2].each do |current_load|
      total, units, name, type1_val, type1_name, type2_val, type2_name, extra, extra_val, extra_type = current_load.match(/([\d\.]+)(%)\s*[\d\/]*([^:]+[:\d]+)\s*([\d\.]+)%*\s*(\w+)\s*\+\s*([\d\.]+)%*\s*(\w+)\W*(\w*)[\s:]*(\d*)\s*(\w*)/).captures
      metric_name = name.gsub(/:$/,'').gsub(/[:\/]+/,'_')
      metric_name = metric_name[(metric_name.length - 19)..-1] if metric_name.length > 19
      cpu_stats['cpu_' + metric_name + '_total'] = {'val' => total.to_f, 'units' => units}
      cpu_stats['cpu_' + metric_name + '_' + type1_name] = {'val' => type1_val.to_f, 'units' => units}
      cpu_stats['cpu_' + metric_name + '_' + type2_name] = {'val' => type2_val.to_f, 'units' => units}
      if extra.to_s.strip() != ''
        cpu_stats['cpu_' + metric_name + '_' + extra] = {'val' => extra_val.to_f, 'units' => extra_type}
      end
    end
    totals = proc_loads[-1].scan(/([\d\.]+)([^\s]+)\s*(\w+)/)
    total_name_base = 'cpu_'+totals[0][2]
    cpu_stats[total_name_base] = {'val' => totals[0][0].to_f, 'units' => totals[0][1]}
    totals[1..-1].each do |current_total|
      cpu_stats[total_name_base + '_' + current_total[2]] = {'val' => current_total[0].to_f, 'units' => current_total[1]}
    end
    cpu_stats
  end
  
  def Metrics.collect_memory_stats()  
    stat_string = yield 'dumpsys meminfo '
    sections = stat_string.scan(/^Total\s*PSS.*?:/i)
    mem_stats = {}
    0.upto(sections.length - 2) do |idx|
      next if sections[idx].downcase.include?('process')
      current_metric = 'mem_' + sections[idx].gsub('by','').gsub(/[\s:]+/,'_').gsub('adjustment','adj').gsub('category','cat')
      section_data = stat_string.match(/#{Regexp.escape(sections[idx])}(.*)#{Regexp.escape(sections[idx+1])}/m).captures[0]
      data_lines = section_data.split(/[\r\n]+/)
      data_lines.each do |current_line|
        next if current_line.include?('(pid') || !current_line.match(/\s*(\d+)\s*(\w+)\s*:\s+(.+)/)
        size, units, metric = current_line.match(/\s*(\d+)\s*(\w+)\s*:\s+(.+)/).captures
        mem_metric = current_metric + metric.gsub(/[\s]+/,'_')
        mem_stats[mem_metric] = {'val'=>size.to_f, 'units'=>units}
      end
    end
    total_metric, total_pss_size, total_pss_units = stat_string.match(/(#{Regexp.escape(sections[-1])})\s*(\d+)\s*(\w+)/).captures
    mem_stats['mem_' + total_metric[0..-2].gsub(/\s+/,'_')] = {'val'=>total_pss_size.to_f, 'units'=>total_pss_units}
    mem_stats
  end

  def Metrics.collect_proc_memory_stats()
    stat_string = yield 'dumpsys meminfo '
    sections=stat_string.scan(/^\s{0,1}[^\s].*/)
    mem_stats = {}
    units = sections[0].match(/.*?\((\w+)\)/).captures[0]
    prefix = 'proc_mem'
    2.upto(sections.length - 1) do |idx|
      if idx >= sections.length - 1
        section_data = stat_string.match(/#{Regexp.escape(sections[-1])}(.*)/m).captures[0]
      else
        section_data = stat_string.match(/#{Regexp.escape(sections[idx])}(.*)#{Regexp.escape(sections[idx+1])}/m).captures[0]
      end
      if idx == 2
        mem_type, mem_dat = section_data.split(/(?:\s*------)+/)
        types_l1, types_l2 = mem_type.strip().split(/\s*[\r\n]+\s*/)
        types_l1 = types_l1.split(/\s+/)
        types_l2 = types_l2.split(/\s+/)
        types_l1.insert(0,nil)
        mem_types = []
        types_l1.each_index do |i|
          mem_types[i] = prefix
          mem_types[i] += '_' + types_l1[i] if types_l1[i]
          mem_types[i] += '_' + types_l2[i] if types_l2[i]
        end
        mem_data = mem_dat.strip().split(/\s*[\r\n]+\s*/)
        mem_data.each do |current_data|
          current_data_name = current_data.match(/^([^\d]+)/).captures[0].strip.gsub(/\s+/,'_')
          current_data_vals = current_data.scan(/\d+/)
          current_data_vals.each_index do |j|
            mem_stats[mem_types[j] + '_' + current_data_name] = {'val'=>current_data_vals[j].to_f, 'units'=>units}
          end
        end
      else
        sections[idx]
        section_data.scan(/\w+\s*\w*:\s*\d+/).each do |current_data|
          name, value = current_data.split(/:\s*/)
          mem_stats[prefix + '_' + sections[idx].strip() + '_' + name.gsub(/\s+/,'_')] = {'val'=>value.to_f, 'units'=>units}
        end
      end
    end
    mem_stats
  end
  
  def Metrics.parse_stats(data_array)
    data = {}
    data_array.each do |current_info|
      current_info.keys.each do |metric|
          if !data[metric]
            data[metric] = {'vals' => [], 'units' => current_info[metric]['units']}
          end
            data[metric]['vals'] << current_info[metric]['val'].to_f
      end
    end
    result = []
    data.each do |k,v|
      result << {'name' => k, 'value'=> v['vals'], 'units' => v['units']}
    end
    result
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

  
  DEFAULT_METRICS = {
    'cpu' => {'collect' => self.method(:collect_cpu_stats),  'parse' => self.method(:parse_stats)}, 
    'sys_mem' => {'collect' => self.method(:collect_memory_stats),  'parse' => self.method(:parse_stats)}, 
    'proc_mem' => {'collect' => self.method(:collect_proc_memory_stats),  'parse' => self.method(:parse_stats)},
  }
  
end
