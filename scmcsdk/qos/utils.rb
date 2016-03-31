# tree parsing code adapted from http://stackoverflow.com/questions/16408563/efficiently-building-a-file-system-tree-structure-with-nested-hashes
module QosModule

def learn_qos_tree(root,type)
  @equipment['dut1'].send_cmd("cd #{root}",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("find . -name output_rate | grep #{type}",@equipment['dut1'].prompt,10)
  @equipment['dut1'].response.match(/(\.\/.+)\n/m)[0].strip
end

def learn_stats_branches(root,type,stat)
  @equipment['dut1'].send_cmd("cd #{root}",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("find .. -name #{stat} | grep #{type}",@equipment['dut1'].prompt,10)
  @equipment['dut1'].response.match(/(\.\.\/.+)\n/m)[0].strip
end

def learn_node(root,name)
  @equipment['dut1'].send_cmd("cd #{root}",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("find . -name #{name} | grep -v linux | grep -v wifi | grep -v 4g | grep -v 3g",@equipment['dut1'].prompt,10)
  @equipment['dut1'].response.match(/(\.\/.+)\n/m)[0].strip
end

def get_qos_trees(root,name)
  @equipment['dut1'].send_cmd("find #{root} -maxdepth 1 -name \"qos*\"",@equipment['dut1'].prompt,10)
  return @equipment['dut1'].response.match(/.*\/*#{name}\/.*/)
end

def get_shapers_per_interface(interface)
  case interface
  when "eth0"
    @equipment['dut1'].send_cmd("find /sys/devices/ -name \"qos-inputs-0\"",@equipment['dut1'].prompt,10)
    return @equipment['dut1'].response.match(/.*\/qos-inputs-0/)
  when "eth1"
    @equipment['dut1'].send_cmd("find /sys/devices/ -name \"qos-inputs-1\"",@equipment['dut1'].prompt,10)
    return @equipment['dut1'].response.match(/.*\/qos-inputs-1/)
  end
end

def parse_paths(list, depth, out)
  to = 1
  base = list.first[:name][depth]
  while list[to] and list[to][:name][depth] == base do
    to += 1
  end

  if list.first[:name][depth+1]
    out << {name: base, children: []}

    # Common directory found for the first N records; recurse deeper.
    parse_paths(list[0..to-1], depth + 1, out.last[:children])

  else
    # It's a file, we can't go any deeper.
    out << {name: list.first[:name].last }
  end

  if list[to]
    # Recurse in to try find common directories for the deeper records.
    parse_paths(list[to..-1], depth, out)
  end

  nil
end

def traverse_with_path tree, output_tree, path = [], &block
  path += [tree[:name]]
  yield path
  if tree[:children]
    tree[:children].each{|c| traverse_with_path c, output_tree, path, &block} 
  else
    # reached the end, child node you were looking for
    output_tree << path.join("/").sub(/(\/)?/,"")
  end
end

def parse_tree(input_tree,output_tree)
  traverse_with_path input_tree, output_tree do |path|
end
end

def to_tree(txt)
  items = []
  txt.split("\n").each do |line|
    m = line.strip.match(/(.+)/).to_a
    if m[0]
      items << {name: m[0]}
    end 
  end
  puts items.size
  items.each do |item|
    puts item
    item[:name] = item[:name].split("/")
  end

  out = []
  parse_paths(items, 0, out)
  out
end

def get_interface_shaper_name(interface)
  case interface
  when "eth0"
    return "qos-inputs-0"
  when "eth1"
    return "qos-inputs-1"
  end
end

def read_overhead_bytes
  @overhead_bytes_arr.each_index { |i|
    oh_bytes = get_rate(@overhead_bytes_arr[i])
    @overhead_bytes[i] = oh_bytes
  }
end

def configure_qos()
  if (@tree_output_rate != nil)
    puts "Configuring tree output rate"
    configure_tree_output_rate()
  else
    read_tree_output_rate()
  end
  if !(@output_rates.empty?)
    configure_branch_output_rate()
  else
    read_branch_output_rate()
  end 
  if !(@wrr_weights.empty?)
    configure_wrr_weights()
  else
    read_wrr_weights()
  end
  if !(@overhead_bytes.empty?)
    configure_overhead_bytes()
  else
    read_overhead_bytes()
  end
end

def configure_tree_output_rate()
  rate = convert_to_bytes_per_sec(@tree_output_rate)
  set_rate(rate, "output_rate")
end

def configure_branch_output_rate()
  #assumes user will set branch output rate < tree output rate (no check on that)
  @output_rate_arr.each_index { |i|
    if @output_rates[i] != nil 
      set_rate(convert_to_bytes_per_sec(@output_rates[i]), @output_rate_arr[i])
    end
    }
end

def read_branch_output_rate()
  @output_rates = []
  @output_rate_arr.each_index { |i|
    rate = get_rate(@output_rate_arr[i])
    if (rate > convert_to_bytes_per_sec(@tree_output_rate))
      puts "branch output rate > tree output rate, resetting branch output rate to tree output rate"
      @output_rates[i] = @tree_output_rate
    else
      @output_rates[i] = convert_to_mbps(rate)
      @output_rates[i] = @output_rates[i].to_s + "M"
    end
    puts ""
    puts @output_rates[i]
  }
end

def read_tree_output_rate()
    @tree_output_rate = convert_to_mbps(get_rate("output_rate"))
    @tree_output_rate = @tree_output_rate.to_s + "M"
    puts ""
    puts @tree_output_rate
  
end

def read_wrr_weights()
  @output_weight_arr.each_index { |i|
    weight = get_rate(@output_weight_arr[i])
    @wrr_weights[i] = weight
  }
end

def read_packets_forwarded(type)
  @results_html_file.add_paragraph "== Packets forwarded. Queue type: #{type} =="
  @packets_fwd_arr.each_index { |i|
    packets = get_rate(@packets_fwd_arr[i])
    @results_html_file.add_paragraph "#{@packets_fwd_arr[i].match(/#{type}-\w+\d?/)} : #{packets}"
  }
  @results_html_file.add_paragraph "============================================"
end

def read_packets_discarded(type)
  @results_html_file.add_paragraph "== Packets discarded. Queue type: #{type} =="
  @packets_drop_arr.each_index { |i|
    packets = get_rate(@packets_drop_arr[i])
    @results_html_file.add_paragraph "#{@packets_drop_arr[i].match(/#{type}-\w+\d?/)} : #{packets}"
  }
  @results_html_file.add_paragraph "============================================"
end

def configure_wrr_weights()
  @wrr_weights.each_index { |i|
    if @wrr_weights[i] != nil 
      set_rate(@wrr_weights[i], @output_weight_arr[i])
    end
    }
end

def configure_overhead_bytes()
  @overhead_bytes.each_index { |i|
    if @overhead_bytes[i] != nil 
      set_rate(@overhead_bytes[i], @overhead_bytes_arr[i])
    end
    }
end

def set_rate(rate,node)
  get_rate(node)
  @equipment['dut1'].send_cmd("echo #{rate.to_i} > #{node}",@equipment['dut1'].prompt,10) 
  get_rate(node)
end

def get_rate(node)
  @equipment['dut1'].send_cmd("cat #{node}",@equipment['dut1'].prompt,10)
  return @equipment['dut1'].response.match(/^([+|-]?\d+)/).captures[0].to_i
end 

def run_dsmark()
  @equipment['dut1'].send_cmd("tc qdisc del dev #{@interface} root",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("tc qdisc add dev #{@interface} root handle 1 dsmark indices 32 default_index 0", @equipment['dut1'].prompt,10)
  @output_rate_arr.each_index { |i|
    dport = 5000 + i + 1
    queue = i + 1
    @equipment['dut1'].send_cmd("tc filter add dev #{@interface} parent 1:0 \
                    protocol ip prio 1 u32 match ip dport #{dport} 0xffff action skbedit queue_mapping #{queue}", @equipment['dut1'].prompt,10)
   }
end

def is_wrr?(filepath)
  return filepath.include?("wrr")
end

def check_error(error)
  puts "error: #{error} allowed_error_percent: #{@allowed_error_percent}"
  if error > @allowed_error_percent
    puts "Error is greater than allowed"
    return 1
  else
    return 0
  end
end

def query_qos_stats(queue_type)
  read_packets_forwarded(queue_type)
  read_packets_discarded(queue_type)
end

def write_to_log(string)
  puts string
  @results_html_file.add_paragraph(string)
end

def get_expected_data_throughput(rate, overhead_bytes, protocol="udp", data_len=1470)
  if protocol == "udp"
    headers_length = 42 #no vlan
  end
    x,unit_x = split_units(rate)
	((data_len/(data_len+headers_length+overhead_bytes).to_f)*x).to_s + "#{unit_x}"
  end
    
  def common_units?(a,b)
    unit_x = a.match(/\d+(M|G|K)/).captures[0].to_s
    unit_y = b.match(/\d+(M|G|K)/).captures[0].to_s
    if unit_x == unit_y
     true
    else
      false
    end
  end
  
  def split_units(rate)
    x = rate.match(/(\d+.*\d*)[M|G|K]/).captures[0].to_f
    unit_x = rate.match(/\d+(M|G|K)/).captures[0].to_s
	return x,unit_x
  end
  
  def get_values(a,b)
    # returns values in common units, to make comparisons easier. 
    # For example if a=3M,b=5K, will return 3000000,"",5000,""
    # For example if a=3K,b=5K, will return 3,K,5,K
    x, unit_x = split_units(a)
    y, unit_y = split_units(b)
    if common_units?(a,b)
     return x,y,unit_x,unit_y
    else
      return convert_to_bits_per_sec(a),convert_to_bits_per_sec(b),"",""
    end
  end
 
  def get_percent_error(measured_bw,expected_bw)
    x,y,unit_x,unit_y = get_values(measured_bw,expected_bw)
    x = x.abs
    y = y.abs
    puts "x: #{x}"  
    puts "y: #{y}"
    return (((y-x)/y)*100).abs.to_f
  end
end
