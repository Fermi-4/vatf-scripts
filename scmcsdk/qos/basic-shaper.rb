# Test script to test basic QoS shaper

# The test code reads the QoS tree dynamically from the /sys/devices entries, configures / reads 
# traffic output rates, wrr weights, overhead bytes used in QoS counting.
#
# It uses tc to set up a mapping of dscp values to various traffic queues 
# It sends the configured amount of traffic through each queue using iperf
# It checks the iperf reported bandwidth (adjusted to what QoS is counting), compares with expected bw 
# and reports % error, if any, on each queue
# It prints stats for packets sent and packets discarded per queue

require File.dirname(__FILE__)+'/../../LSP/default_test_module' 
include LspTestScript
require File.dirname(__FILE__)+'/utils' 
include QosModule

def setup
  self.as(LspTestScript).setup
  @interface = @test_params.params_control.instance_variable_defined?(:@interface) ? @test_params.params_control.interface[0].to_s : 'eth0'
  @queue_type = @test_params.params_control.instance_variable_defined?(:@queue_type) ? @test_params.params_control.queue_type[0].to_s : 'linux'
  @tree_output_rate = @test_params.params_control.instance_variable_defined?(:@tree_output_rate) ? @test_params.params_control.tree_output_rate[0].to_s : nil
  # max output rate limit per queue
  @output_rates = @test_params.params_control.instance_variable_defined?(:@output_rates) ? @test_params.params_control.output_rates[0].split(":").collect {|x| x == "nil" ? x = nil :  x.to_s } : []
  # weights for each wrr queue
  @wrr_weights = @test_params.params_control.instance_variable_defined?(:@wrr_weights) ? @test_params.params_control.wrr_weights[0].split(":").collect {|x| x == "nil" ? x = nil :  x.to_i } : []
  @overhead_bytes = @test_params.params_control.instance_variable_defined?(:@oh_bytes) ? @test_params.params_control.oh_bytes[0].split(":").collect {|x| x == "nil" ? x = nil : x.to_i } : [-42,-42,-42,-42,-42,-42]
  #@overhead_bytes = @test_params.params_control.instance_variable_defined?(:@oh_bytes) ? @test_params.params_control.oh_bytes[0].split(":").collect {|x| x.to_i } : [24,24,24,24,24,24]
  # traffic to be sent per queue
  @traffic_rates = @test_params.params_control.instance_variable_defined?(:@traffic_rates) ? @test_params.params_control.traffic_rates[0].split(":").collect {|x| x == "nil" ? x = nil : x.to_s } : ["20M", "20M", "40M", "60M", "80M", "30M"]
  @allowed_error_percent = @test_params.params_control.instance_variable_defined?(:@allowed_error_percent) ? @test_params.params_control.allowed_error_percent[0].to_f : 2


  @equipment['dut1'].send_cmd("cd ",@equipment['dut1'].prompt,10)
  @interface_shapers = get_shapers_per_interface(@interface)
  @shaper_name = get_interface_shaper_name(@interface)
  @output_rate_arr = [] #filepaths
  @output_weight_arr = [] #filepaths
  @packets_fwd_arr = [] #filepaths
  @packets_drop_arr = [] #filepaths
  @overhead_bytes_arr = [] #filepaths

  @wrr_weights_sum = 0
  @expected_op_traffic_rate = []
  @reported_throughput = []
  @expected_data_throughput = []
  @qos_active = []
  @test_result_comment = ""
  @test_outcome = FrameworkConstants::Result[:pass]
end


def run()
  if (@interface == "eth1")
    run_dhclient('dut1',@interface)
  end
  server_ip = get_remote_ip(@interface,'dut1','server1')
  # Find qos tree root
  @equipment['dut1'].send_cmd("cd ",@equipment['dut1'].prompt,10)
  @qos_tree_root = get_qos_trees(@interface_shapers,@shaper_name)
  
  # Find qos tree branches we are interested in: wrr weights, stats, overhead bytes
  data = learn_qos_tree(@qos_tree_root,@queue_type)
  wrr_data = learn_node(@qos_tree_root,"weight")
  stats_data_packets_fwd = learn_stats_branches(@qos_tree_root,@queue_type,"packets_forwarded")
  stats_data_packets_drop = learn_stats_branches(@qos_tree_root,@queue_type,"packets_discarded")
  oh_bytes = learn_node(@qos_tree_root,"overhead_bytes")

  
  # Read branch information
  @tree = to_tree(data)
  @wrr_tree = to_tree(wrr_data)
  @stats_tree_pf = to_tree(stats_data_packets_fwd)
  @stats_tree_pd = to_tree(stats_data_packets_drop)
  @oh_bytes_tree = to_tree(oh_bytes)
  parse_tree(@tree[0],@output_rate_arr)
  parse_tree(@oh_bytes_tree[0],@overhead_bytes_arr)
  parse_tree(@wrr_tree[0],@output_weight_arr)
  parse_tree(@stats_tree_pf[0],@packets_fwd_arr)
  parse_tree(@stats_tree_pd[0],@packets_drop_arr)

  configure_qos()
  
  # Write input configuration to logs
  write_to_log "=============  QoS PARAMS  =============="
  write_to_log "QoS tree root: #{@qos_tree_root}"
  write_to_log "tree_output_rate: #{@tree_output_rate}"
  write_to_log "weights: #{@wrr_weights}"
  write_to_log "output_rates: #{@output_rates}"
  write_to_log "traffic_rates: #{@traffic_rates}"
  write_to_log "output_rate_arr: #{@output_rate_arr}"
  write_to_log "output_weight_arr: #{@output_weight_arr}"
  write_to_log "packets_fwd: #{@packets_fwd_arr}"
  write_to_log "packets dropped: #{@packets_drop_arr}"
  write_to_log "overhead_bytes: #{@overhead_bytes}"
  write_to_log "=========================================" 

  
  # Now, start figuring expected output rates on each queue
  @leftover_bw = @tree_output_rate
  
  @total_input_traffic_in_bps = 0
  @traffic_rates.each {|x|
  if x!= nil
    puts "x: #{x}"
    @total_input_traffic_in_bps = @total_input_traffic_in_bps + convert_to_bits_per_sec(x)  
  end
  }

  @wrr_weights.each {|x|
    @wrr_weights_sum = @wrr_weights_sum + x 
  }
  
  @wrr_queues = @wrr_weights.length
  @wrr_weights_sum = @wrr_weights_sum.to_f
  puts "WRR weights sum is #{@wrr_weights_sum}"
  @total_input_traffic_in_mbps = @total_input_traffic_in_bps/1000000
  total_queues = @output_rate_arr.length 
  @available_bw = Array.new(total_queues, nil)
  

  @total_input_traffic_in_mbps = @total_input_traffic_in_mbps.to_s + "M"

  @wrr_index =  @wrr_queues - 1
  @output_rate_arr.reverse.each_with_index {|val, i|
      n = total_queues-i-1
      @leftover_bw = convert_to_bits_per_sec(@leftover_bw)
      if @leftover_bw == 0
        @available_bw[n] = 0
        puts "leftover bw is 0"
      elsif @traffic_rates[n] == nil
        @available_bw[n] = 0
        puts "no traffic on this queue"
      else
        if is_wrr?(val)
          puts "is wrr"
          cir_ratio = convert_to_bits_per_sec(@output_rates[n])/@wrr_weights_sum
          @available_bw[n] = cir_ratio.to_f*@wrr_weights[@wrr_index]
          puts @available_bw[n]
          @wrr_index = @wrr_index - 1
        else
          @available_bw[n] = [(convert_to_bits_per_sec(@traffic_rates[n])).to_f,@leftover_bw].min
        end
        @leftover_bw = @leftover_bw - @available_bw[n]
        if @leftover_bw < 0
          @leftover_bw = 0
        end 
      end
      @leftover_bw = @leftover_bw.to_f/1000000
      @leftover_bw = @leftover_bw.to_s + "M"
      @available_bw[n] = @available_bw[n]/1000000
      @available_bw[n] = @available_bw[n].to_s + "M"     
      n = n-1
    }
  puts "Available bw is #{@available_bw}"
  puts "leftover bw is #{@leftover_bw}"

  # Check if all are over subscribed. If yes, allow only available_bw on each queue
  @all_oversubscribed = true
  @traffic_rates.each_index { |i|
  if (@traffic_rates[i] == nil)
    @expected_data_throughput[i] = nil
  else
    x,y,unit_x,unit_y = get_values(@traffic_rates[i],@available_bw[i])
    if x <= y
      @all_oversubscribed = false
      break
    end
  end
  }
  puts "all_oversubscribed #{@all_oversubscribed}"
  puts "@total_input_traffic_in_mbps: #{@total_input_traffic_in_mbps} tree_output_rate:#{@tree_output_rate}"

  query_qos_stats(@queue_type)
  run_dsmark()
  @equipment['dut1'].send_cmd("killall iperf",@equipment['dut1'].prompt,10) 
  @equipment['server1'].send_cmd("killall iperf",@equipment['server1'].prompt,10) 
  @equipment['dut1'].send_cmd("cd ",@equipment['dut1'].prompt,10) 
  @traffic_rates.each_index { |i|
  dport = 5000 + i + 1   
    if (@traffic_rates[i] == nil)
      # do nothing
    else
      @equipment['server1'].send_cmd_nonblock(get_iperf_cmd("server", nil, "#{dport}", "udp", "4", nil, nil, 300, nil, nil), /.*/,120)
    end
  }
  
     
  @traffic_rates.each_index { |i|
  dport = 5000 + i + 1
    if (@traffic_rates[i] == nil)
      # do nothing
    else
      cmd = get_iperf_cmd("client", server_ip, "#{dport}", "udp", "4", "1470", "#{@traffic_rates[i]}", 300, nil, nil)
      puts "cmd is #{cmd}"
      @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt,10)
    end

  }
  sleep 330
  
  puts "@total_input_traffic_in_mbps: #{@total_input_traffic_in_mbps} tree_output_rate:#{@tree_output_rate}"
  @traffic_rates.each_index { |i|
    dport = 5000 + i + 1
    @expected_op_traffic_rate[i]  = nil
    if (@traffic_rates[i] == nil)
      @reported_throughput[i] = nil
      @qos_active[i] = false
      # Nothing was sent throught this queue, do nothing
    else
      @equipment['dut1'].send_cmd("cat #{dport}.txt", @equipment['dut1'].prompt,10)
      reported_throughput = get_iperf_reported_bw(@equipment['dut1'].response)
      @reported_throughput[i] = convert_to_mbps(convert_to_bytes_per_sec(reported_throughput)).to_s + "M"
      x,y,unit_x,unit_y = get_values(@total_input_traffic_in_mbps,@tree_output_rate)
      if x < y 
        #Total input traffic is < max rate allowed
        write_to_log "Total input traffic is < max rate allowed"
        @expected_op_traffic_rate[i] = @traffic_rates[i]
        @expected_data_throughput[i] = @expected_op_traffic_rate[i]
      elsif x == y 
        #Total input traffic is = max rate allowed
        write_to_log "Total input traffic is = max rate allowed"
        @expected_op_traffic_rate[i] = @traffic_rates[i]
        @qos_active[i] = true
      elsif @all_oversubscribed
        # Each queue is over subscribed, allow only available_bw
        write_to_log "Each queue is over subscribed, allow only available_bw"
        @expected_op_traffic_rate[i] = @available_bw[i]
        @qos_active[i] = true
      else
        x,y,unit_x,unit_y = get_values(@traffic_rates[i],@available_bw[i])
        if (x<=y)
          @expected_op_traffic_rate[i] = @traffic_rates[i]
          @qos_active[i] = true
        else
          puts "TO DO: calculate expected_op_traffic_rate"
          @expected_op_traffic_rate[i] = @traffic_rates[i] # this is incorrect, fix 
          write_to_log "WARNING: expected throughput calculation is approximate"
          @qos_active[i] = true
        end
      end
      if @expected_data_throughput[i] == nil
        @expected_data_throughput[i] = get_expected_data_throughput(@expected_op_traffic_rate[i], @overhead_bytes[i].to_i, "udp", 1470)
      end
      puts "expected_data_throughput is #{@expected_data_throughput[i]} reported_throughput is #{@reported_throughput[i]}"
      error = get_percent_error(@reported_throughput[i], @expected_data_throughput[i])
      puts "Error is #{error}%"
      if check_error(error) == 1
        # fail test 
        puts "Error is greater than allowed - FAIL TEST"
        @test_result_comment = @test_result_comment + "#{error} % error found on queue #{i} \n"
        @test_outcome = FrameworkConstants::Result[:fail]
      else
        # do nothing
      end
      if (@test_outcome == FrameworkConstants::Result[:pass])
        @test_result_comment = "Test Pass"
      end
    end
    }
  write_to_log "reported bw is #{@reported_throughput}"
  @equipment['dut1'].send_cmd("cd #{@qos_tree_root}",@equipment['dut1'].prompt,10) 
  query_qos_stats(@queue_type)
  set_result(@test_outcome,@test_result_comment)
end



def clean
  @equipment['dut1'].send_cmd("killall iperf",@equipment['dut1'].prompt,10) 
  @equipment['server1'].send_cmd("killall iperf",@equipment['server1'].prompt,10) 
end

