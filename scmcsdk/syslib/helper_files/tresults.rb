
require 'win32ole'
require 'find'
require 'ftools'
require 'pathname'

# constants
DO_NOT_GENERATE_DIRECTORY_NAME = false
GENERATE_DIRECTORY_NAME = true

#do not touch the below constants since they index arrays they must be 0 through 5
FIRST_FILE = 0
SECOND_FILE = 1
NOTES_FILE = 2
FIRST_FILE_PARA = 3
SECOND_FILE_PARA = 4
FIRST_FILE_BARE = 5
SECOND_FILE_BARE = 6
NOTES_FILE_BARE = 7
STAT_PASS = 0
STAT_FAIL = 1
STAT_NOCODE = 2
#do not touch the above constants since they index arrays they must be 0 through 5

DATE_TIME_SUBSTITUTION = "@@date_time@@"
PROJECT_SUBSTITUTION = "@@project_name@@"
WORKSPACE_SUBSTITUTION = "@@workspace@@"
CCXML_SUBSTITUTION = "@@ccxml@@"

RESULTS_DIRECTORY_BASE_DEFAULT = "c:\\tresults\\#{DATE_TIME_SUBSTITUTION}\\"
RESULTS_DIRECTORY_RESULTS_SUFFIX = ""

EXTENSIONS_ALLOWED = ".txt .log .csv "

SPACES_PER_TAB = 4

class Progress
  def initialize
    @run_indicator_position = 0
    @run_indicator_counter = 0
    @run_indicator_step = 13
    @first_start = true
  end
  def indicate(string)
    @run_indicator_counter += 1
    if (@run_indicator_counter >= @run_indicator_step or @first_start)
      print string
      case @run_indicator_position.to_s
        when "0", "4" then print "\|"
        when "1", "5" then print "/"
        when "2", "6" then print "-"
        when "3", "7" then print "\\"
        else
          @run_indicator_position = 0
          print "\|"
      end
      if string == ""
        print "\b"
      else
        print "\r"
      end
      @run_indicator_position += 1
      @run_indicator_counter = 0
      @first_start = false
    end
  end
  def run_indicator_step(step_count)
     @run_indicator_step = step_count
  end
end

class Logging
  def initialize
    @log_file = ""
    @out_text_file_string = ""
  end
  def open_log_file(log_filename)
    begin
      @log_file = File.new(log_filename, "w")
    rescue
      $stderr.print "Log file IO failed: " + $!
      raise
    end
  end
  def display_write(string)
    print string
    @out_text_file_string = @out_text_file_string + string
  end
  def display_write_log_only(string)
    @out_text_file_string = @out_text_file_string + string
  end
  def finish_writing_logfile()
    if @log_file != ""
      @log_file.puts("\r\n\r\n")
      @log_file.puts("#{@out_text_file_string}")
    end
  end
end

class Statistics
  def initialize
    @show_completion_stats = true
  end
  def set_completions_stats_to_do_not_show
    @show_completion_stats = false
  end
  def set_completions_stats_to_show
    @show_completion_stats = true
  end
  def show_completion_stats
    @show_completion_stats
  end
end

class Results
  def initialize
    @results_buffer = Array.new
    @results_buffer.clear
    @raw_buffer = Array.new
    @raw_buffer.clear
    @current_file_name = ""
    @previous_file_name = ""
    @write_trigger = false
    @file_num = 0
    @hash_tbl = Hash.new
    @csv_fixed_items = Array.new
  end
  def translate_simulator_name(raw_string)
    temp = raw_string.sub("TARGET:","")
    temp = temp.tr(" ", "")
    temp = temp.tr("\n", "")
    temp = temp.tr("\r", "")
    if temp == ""
      temp_array.push("Unk-Unknown-Un")
    else
      temp = temp.sub("desc=","")
      temp = temp.sub("Nyquist","Nyq")
      temp = temp.sub("Device","-D")
      temp = temp.sub("Cycle","C")
      temp = temp.sub("Approximate","A")
      temp = temp.sub("Functional", "F")
      temp = temp.sub("Simulator","S")
      temp = temp.sub(",","")
      temp = temp.sub("Little","-L")
      temp = temp.sub("Big","-B")
      temp = temp.sub("Endian_0","E")
      temp = temp.sub("Endian","E")
      temp = temp.sub("TexasInstruments","TI-")
      temp = temp.sub("PCIEmulator_0","-PCIEmu")
    end
    return(temp)
  end
  def get_module_name(raw_string)
    temp = ""
    temp_array = Array.new
    temp_array2 = Array.new
    temp = raw_string.sub("testEnv.outFile:","")
    temp = temp.tr("\\","/")
    temp = temp.tr(" ", "")
    temp_array = temp.split("/")
    temp_array2 = temp_array[temp_array.length-1].split("_")
    temp = temp_array2[0]
    if temp_array2.length > 2
      if temp.downcase == "Cgem0".downcase
        temp = "#{temp}_#{temp_array2[1]}"
      end
    end
    return(temp)
  end
  def file_write_check(sim_name, module_name, file_name, execution_options)
    file_items = Array.new
    platform_name = "Nyquist"
    platform_name_short = "Nyq"
    endianess = "LE"
    #derived_file_name = "#{platform_name}_#{module_name}_Test_#{platform_name_short}-#{sim_name}-#{endianess}_raw"
    derived_file_name = "#{platform_name}_#{module_name}_Test_#{sim_name}_raw"
    #puts("\n Derived file name: #{derived_file_name}\n Current file name: #{@current_file_name}\n")
    #puts("\r\n file_name: #{file_name}, current_file_name: #{@current_file_name}\r\n")
    if @current_file_name == ""
      # if module name not present or sim_name not present then keep @current_file_name blank as this is probably the start of the file.
      if module_name != "" and sim_name != ""
        @current_file_name = derived_file_name
      end
    else
      if @current_file_name != derived_file_name
        file_items = file_name.split("/")
        #derived_file_name = file_name.sub(file_items[file_items.length-1], derived_file_name)
        write_results(file_name, @current_file_name, execution_options)
        #puts("\r\n file_name: #{file_name}, current_file_name: #{@current_file_name}\r\n")
        @results_buffer.clear
        @current_file_name = derived_file_name
      end
    end
  end
  def get_fault_result(string)
  end
  def get_results(file_name, execution_options)
    temp = Array.new
    running1 = Progress.new
    sim_name = ""
    module_name = ""
    derived_file_name = ""
    @results_buffer.clear
    fault_line = ""
    @raw_buffer.each  do |rb_item|
      if execution_options.do_fault
        if (rb_item.downcase.include?("fault status_post") and !rb_item.downcase.include?("far: 0x0 fid:"))
          fault_line = "#{rb_item}" 
          temp = fault_line.split(" ")
          fault_line = ",FAILED: #{temp[0]} fault exception at #{temp[4]}!"
        end
      end
      running1.indicate(" Files Processed: ")
      if @results_buffer.length == 0
        @results_buffer.push("TEST CASE ID,TEST CASE RESULT,FUNCTION EXECUTION TIME\n")
      end
      if rb_item.include?("TARGET:")
        sim_name = translate_simulator_name(rb_item)
      end
      if rb_item.include?("testEnv.outFiles:")
        module_name = get_module_name(rb_item)
      end
      file_write_check(sim_name, module_name, file_name, execution_options)
      if rb_item.include?("main_")
        if (not rb_item.include?(" main_")) and (not rb_item.include?("idx:"))
          temp_rb_item = ((fault_line != "") ? rb_item.sub(",PASS,", ",FAIL,") : rb_item)
          @results_buffer.push("#{temp_rb_item.tr("\n","")}#{fault_line.tr("\n","")}\n")
          fault_line = ""
        end
      else
        if rb_item.include?("CSL version:")
          @results_buffer.push(rb_item)
        end
      end
    end
    file_write_check("", "", file_name, execution_options)
  end
  def is_end_of_set_dio(string)
    returnValue = false
    items = string.split("\t")
    if (items[2] == "5.000" and items[6] == "8192")
      returnValue = true
    end
    return returnValue;
  end
  def is_end_of_set(string)
    returnValue = false
    items = string.split("\t")
    if (items[2] == "5.000" and items[4].downcase == "type-11" and items[6] == "4096")
      returnValue = true
    end
    if (items[2] == "5.000" and items[4].downcase == "dio_nw" and items[6] == "8192")
      returnValue = true
    end
    if (items[2] == "5.000" and items[4].downcase == "type-2_nr" and items[6] == "8192")
      returnValue = true
    end
    return returnValue;
  end
  def get_array_index(string, num_sections_per_type, logs)
    index = 0
    items = string.split("\t")

    # Array start index bassed on message type
    case items[4].downcase
      when "type-11"
        index = 0
      when "dio_nw", "memmapw", "mmcpuwr", "mmdmawr", "mcpuhwr", "lcpuhwr", "dcpuhwr", "mdmahwr", "ldmahwr", "ddmahwr"
        index = 1 * num_sections_per_type
      when "dio_nr", "memmapr", "mmcpurd", "mmdmard", "mcpuhrd", "lcpuhrd", "dcpuhrd", "mdmahrd", "ldmahrd", "ddmahrd"
        index = 2 * num_sections_per_type
      else
        index = 0
    end
    
   # Array index adjustment based on number of lanes
    case items[1]
      when "1"
        index += 0
      when "2"
        index += 3
      when "4"
        index += 6
      else
        index = 0
    end
    
    # Array index adjustment based on rx, tx or latency
    if (items[6] == "100")
      index += 2
    else
      index += 1 if (items[0] == "1")
    end

    logs.display_write_log_only("#{index}, #{string}")

    return index
  end
  def get_test_info(string, curr_test_info)
    return_string = curr_test_info
    if (return_string == "")
      if (string.downcase.include?("throughput:") or string.downcase.include?("latency:"))
        if (string.include?("1.250"))
          return_string = string.gsub("1.250GBaud, ", "")
          return_string = return_string.gsub(", tab delimited", "")
        end
      end
    else
      if (string.downcase.include?("numpkts"))
          return_string += string
      end
    end
    return return_string
  end
  def get_tput_results(file_name, execution_options, logs)
    number_of_sections = 3 * 3 # (rx +  tx + latency) * (1X + 2X + 4X)
    number_of_types = 3 # (type-11 + dio_nw + dio_nr)
    total_combinations = number_of_sections * number_of_types
    save_results = Array.new
    (0..total_combinations).each do |index|
      save_results[index] = Array.new
    end
    current_string = ""
    tput_rx_string_IDs = Array.new
    tput_tx_string_IDs = Array.new
    tput_rx_string_IDs = ["0\t1\t1.250", "0\t1\t2.500", "0\t1\t3.125", "0\t1\t5.000", "0\t1\t6.250", "0\t1\t7.500", "0\t1\t10.000", "0\t1\t12.500",
                          "0\t2\t1.250", "0\t2\t2.500", "0\t2\t3.125", "0\t2\t5.000", "0\t2\t6.250", "0\t2\t7.500", "0\t2\t10.000", "0\t2\t12.500",
                          "0\t4\t1.250", "0\t4\t2.500", "0\t4\t3.125", "0\t4\t5.000", "0\t4\t6.250", "0\t4\t7.500", "0\t4\t10.000", "0\t4\t12.500"]
    tput_tx_string_IDs = ["1\t1\t1.250", "1\t1\t2.500", "1\t1\t3.125", "1\t1\t5.000", "1\t1\t6.250", "1\t1\t7.500", "1\t1\t10.000", "1\t1\t12.500",
                          "1\t2\t1.250", "1\t2\t2.500", "1\t2\t3.125", "1\t2\t5.000", "1\t2\t6.250", "1\t2\t7.500", "1\t2\t10.000", "1\t2\t12.500",
                          "1\t4\t1.250", "1\t4\t2.500", "1\t4\t3.125", "1\t4\t5.000", "1\t4\t6.250", "1\t4\t7.500", "1\t4\t10.000", "1\t4\t12.500"]
    running1 = Progress.new
    @results_buffer.clear
    (0..total_combinations).each do |index|
      save_results[index].clear
    end
    test_info = ""
    # Get the results from the log file
    @raw_buffer.each  do |rb_item|
      test_info = get_test_info(rb_item, test_info)
      if (rb_item.include?("1.250") or rb_item.include?("2.500") or rb_item.include?("3.125") or rb_item.include?("5.000") or rb_item.include?("6.250") or rb_item.include?("7.500") or rb_item.include?("10.000") or rb_item.include?("12.500"))
        tput_rx_string_IDs.each do |rx_line_id|
          if (rb_item.include?("#{rx_line_id}"))
            save_results[get_array_index(rb_item, number_of_sections, logs)].push(test_info) if (test_info != "")
            save_results[get_array_index(rb_item, number_of_sections, logs)].push(rb_item)
            test_info = ""
          end
        end
        tput_tx_string_IDs.each do |tx_line_id|
          if (rb_item.include?("#{tx_line_id}"))
            save_results[get_array_index(rb_item, number_of_sections, logs)].push(test_info) if (test_info != "")
            save_results[get_array_index(rb_item, number_of_sections, logs)].push(rb_item)
            test_info = ""
          end
        end
      end
      running1.indicate(" Lines Processed: ")
    end
    (0..total_combinations).each do |index|
      @results_buffer.push("#{save_results[index]}\n\n\n") if (save_results[index].length != 0)
    end
    puts("File name: #{file_name}\n")
    # Write the results to the output file
    file_write_check("", "", file_name, execution_options)
  end
  def hash_add(main_id, item_id, value)
    @hash_tbl["#{main_id}#{item_id}"] = "#{value}"
  end
  def hash_get(main_id, item_id)
    return_string = @hash_tbl["#{main_id}#{item_id}"]
    if return_string == nil
      return_string = ""
    end
    #return @hash_tbl["#{main_id}#{item_id}"] #.gsub("=> ", "")
    return return_string
  end
  TEST_SUITE = 0
  TEST_CASE = 1
  BUILD_NAME = 2
  METRIC_NAME = 3
  METRIC_UNITS = 4
  SAMPLE_COUNT = 5
  METRIC_MIN = 6
  METRIC_MAX = 7
  METRIC_MEAN = 8
  METRIC_STDDEV = 9
  
  def csv_split_fixer(array_in)
    @csv_fixed_items.clear
    array_index = 0
    new_array_index = 0
    array_in.each do |array_item|
      if array_index >= new_array_index
        item = array_item
        if item.include?("\"")
          item += ","
          for index in ((array_index + 1)..(array_in.length - 1)) 
            item += array_in[index] + ","
            new_array_index = index + 1
            #puts(" item: #{item}, new_array_index: #{new_array_index}, index: #{index}\r\n")
            break if array_in[index].include?("\"")
          end
        end
        #puts(" pushed item: #{item}, array_index: #{array_index}, new_array_index: #{new_array_index}, array_in_length: #{array_in.length}\r\n")
        @csv_fixed_items.push(item)
      end
      array_index += 1
    end
    #puts(" new_array_length: #{@csv_fixed_items.length}, @csv_fixed_items:\r\n")
    #@csv_fixed_items.each do |temp|
    #  puts(" item: \"#{temp}\"\r\n")
    #end
    return @csv_fixed_items
  end
  def get_tlperf_results(file_name, execution_options, logs)
    orig_header_names = Array.new
    orig_header_names = ["Test Suite", "Test Case", "Build Name", "Metric Name", "Units", "Count", "MIN", "MAX", "MEAN", "STDDEV"]
    display_header_names = Array.new
    display_header_names = ["Test Suite", "Test Case", "MBits/Second", "CPU Load %", "Datagram Count", "Jitter ms", "Packet Loss %"]
    hash_value_names = ["udp_bandwidthMbits/sec", "cpu_load%", "udp_datagramsdatagrams", "udp_jitterms", "udp_packetloss%"]
    perf_ids = Array.new
    current_main_id = ""
    header_string = ""
    result_string = ""
    running1 = Progress.new
    #Test Suite,Test Case,Build Name,Metric Name,Units,Count,MIN,MAX,MEAN,STDDEV
    @raw_buffer.each  do |rb_item|
      items = rb_item.split(",")
      #csv_split_fixer(items)
      items = csv_split_fixer(items)
      main_id = items[TEST_SUITE].gsub(" ", "")
      main_id = "#{main_id.gsub("/", "-")}@@#{items[TEST_CASE]}"
      item_id = "#{items[METRIC_NAME]}#{items[METRIC_UNITS]}"
      value = items[METRIC_MEAN]
      #puts(" main_id: \"#{main_id}\", item_id: \"#{item_id}\", value_item: \"#{value}\"\r\n")
      #recombine things that were separated but were within double quotes
      if value.include?("\"")
        value = value.gsub("\"", "")
        value = value.gsub(".00", "")
      #  for index in ((METRIC_MEAN + 1)..(@csv_fixed_items.length - 1)) 
      #    value += items[index]
      #    break if items[index].include?("\"")
      #  end
      end
      if main_id != current_main_id
        perf_ids.push(main_id)
        current_main_id = main_id
      end
      if !main_id.include?("Test Case")
        #puts(" main_id: \"#{main_id}\", item_id: \"#{item_id}\", value_item: \"#{value}\"\r\n")
        #puts(" main_id: \"#{main_id}\"\r\n")
        hash_add(main_id, item_id, value)
      end
      running1.indicate(" Lines Processed: ")
    end
    column_separator = ""
    display_header_names.each do |header_name|
      header_string += column_separator
      header_string += header_name
      column_separator = ", "
    end
    header_string += "\n"
    @results_buffer.clear
    @results_buffer.push(header_string)
    perf_ids.each do |perf_id|
      column_separator = ""
      result_string = ""
      if !perf_id.include?("Test Case")
        title_items = perf_id.split("@@")
        title_items.each do |t_item|
          result_string += column_separator
          result_string += t_item
          column_separator = ", "
        end
        hash_value_names.each do |value_item|
          result_string += column_separator
          #puts(" perf_id: \"#{perf_id}\", value_item: \"#{value_item}\"\r\n")
          result_string += hash_get(perf_id, value_item)
          column_separator = ", "
          running1.indicate(" Lines Processed: ")
        end
        result_string += "\n"
        @results_buffer.push(result_string)
        running1.indicate(" Lines Processed: ")
      end
    end
    puts("File name: #{file_name}\n")
    # Write the results to the output file
    file_write_check("", "", file_name, execution_options)
  end
  TEST_SUITE_ID = 0
  BUILD_ID = 1
  TESTER_NAME = 2
  TEST_TIME = 3
  TEST_STATUS = 4
  TEST_DATA = 5
  TEST_CASE = 0
  INGRESS_BW = 1
  EGRESS_BW = 2
  PKT_SIZE = 3
  CPU_IDLE = 4
  CPU_UTIL = 4
  def get_test_data_value(string, index)
    return_value = ""
    #puts("\r\n get_test_data_value string: \"#{string}\"\r\n")
    #exit
    if (string == "") || (string == nil)
      return return_value
    end
    items = string.split(",")
    values = Array.new
    items.each do |item|
      #puts("\r\n item: #{item}\r\n")
      temp_value = item.split(":")
      #puts(" temp_value: \"#{temp_value[1]}\"\r\n")
      if temp_value.length >= 2
        new_value = temp_value[1].gsub(" ", "")
        new_value = new_value.gsub("Mbits/sec", "")
        #new_value = new_value.gsub("[Idle%", "")
        new_value = new_value.gsub("[CPU_Util%", "")
        #temp_value2 = new_value.split("[Idle%")
        #values.push(temp_value2[0])
        values.push(new_value)
        if temp_value.length >= 3
          new_value2 = temp_value[2].split("]")[0]
          new_value2 = new_value2.gsub(" ", "")
          values.push(new_value2)
        end
      end
      #puts("\r\n")
      #temp_idx = 0
      #values.each do |temp|
      #  puts(" values[#{temp_idx}]: #{temp}\r\n")
      #  temp_idx += 1
      #end
      #puts("\r\n")
    end
    #puts(" index: #{index}, values[#{index}]: #{values[index]}\r\n")
    #exit
    #puts("\r\n values[#{values.length}]: \"#{values}\"\r\n")
    values.push("")
    #puts("\r\n index: #{index}, string: \"#{string}\"\r\n") 
    if (values.length - 1) >= index
      return_value = values[index]
    end
    return return_value
  end
  def get_stat_from_string(string)
    puts("\r\n string: #{string}\r\n")
    stat = ""
    string_items = string.split("_")
    trigger = false
    string_items.each do |item|
      trigger = true if item.downcase.include?("ethernet")
      if trigger
        stat = item
        break
      end
      trigger = true if item.downcase.include?("ipsec")
    end
    puts("\r\n stat: #{stat}\r\n")
    #exit
    return stat
  end
  def get_stat_type(stat_array, string_to_match)
    puts("\r\n string_to_match: #{string_to_match}\r\n")
    stat_string = ""
    stat_array.each do |item|
      if string_to_match.downcase.include?(item.downcase)
        stat_string = item
        break
      end
    end
    puts("\r\n #{stat_string}\r\n")
    return stat_string
  end
  def is_filter_match(string_to_check, filter)
    matched = false
    if filter != ""
      if filter.include?(";")
        items = filter.split(";")
        items.each do |item|
          if string_to_check.downcase.include?(item.downcase)
            matched = true
            break
          end
        end
      else
        matched = true if string_to_check.downcase.include?(filter.downcase)
      end
    end
    return matched
  end
  def pseudo_days(date_string, date_style)
    days = 0
    this_date_string = date_string.tr("-", "/")
    this_date_style = date_style.tr("-", "/")
    date_items = date_string.split("/")
    if date_items.length >= 3
      date0 = date_items[0].to_i
      date1 = date_items[1].to_i
      date2 = date_items[2].to_i
      case date_style
        when "mm/dd/yyyy"
          days = date2 * 365
          days += date0 * 30
          days += date1
        when "yyyy/mm/dd"
          days = date0 * 365
          days += date1 * 30
          days += date2
      end
    end
    return days
  end
  def date_comparer(date_variable, date_input, is_greater)
    
  end
  def add_post_pend(filename, post_pend)
    count = 0
    new_file_name = ""
    if filename.include?(".")
      items = filename.split(".")
      items.each do |item|
        new_file_name += (count == 0 ? "#{item}_#{post_pend}" : ".#{item}")
        count = 1
      end
    else
      new_file_name = "#{filename}_#{post_pend}"
    end
    return new_file_name
  end
  def get_tl_ipsec_perf_results(file_name, execution_options, logs)
    t = Time.new
    stat_types = Array.new
    stat_types = ["Inflow", "Sideband", "Software", "Pass-through", "Eth-only"]
    @results_buffer.clear
    packet_size = "512"
    header_perf_measures = "ingress-mbw Mbps / egress-mbw Mbps / cpu util %"
    #header_perf_stat = "Throughput #{packet_size} byte packets"
    header_perf_stat = "Throughput"
    #stat1 = "Inflow Crypto #{header_perf_stat} #{header_perf_measures}"
    #stat2 = "Sideband Crypto #{header_perf_stat} #{header_perf_measures}"
    #stat3 = "Software Crypto #{header_perf_stat} #{header_perf_measures}"
    stat1 = "Inflow Crypto #{header_perf_stat}"
    stat2 = "Sideband Crypto #{header_perf_stat}"
    stat3 = "Software Crypto #{header_perf_stat}"
    test_plan = ""
    test_data_start_date = "12/31/9999"
    test_data_end_date = "1/1/0000"
    #@results_buffer.push(",Test Scenario,Inflow Crypto Throughput Measurements,,,Sideband Crypto Throughput Measurements,,,\n")
    #@results_buffer.push(",Protocol_Encryption_Authentication_ingress-tbw_egress-tbw_packet-bytes,Ingress Mbps,Egress Mbps,CPU Utilization %,Ingress Mbps,Egress Mbps,CPU Utilization %\n")
    scenario_header = "Item,Throughput Scenario"
    info_header = "#,Protocol_Encryption_Authentication_ingress-tbw_egress-tbw_packet-bytes"
    info_columns = "Ingress Mbps,Egress Mbps,CPU Utilization %"
    orig_header_names = Array.new
    orig_header_names = ["Test Suite", "Test Case", "Build Name", "Metric Name", "Units", "Count", "MIN", "MAX", "MEAN", "STDDEV"]
    display_header_names = Array.new
    display_header_names = ["", "Protocol_Encryption_Authentication_ingress-tbw_egress-tbw_packet-bytes", "#{stat1}", "#{stat2}"]
    hash_value_names = ["count", "inflow_ingress", "inflow_egress", "inflow_cpu_idle%", "sideband_ingress", "sideband_egress", "sideband_cpu_idle%"]
    main_hash_ids = Array.new
    item_hash_ids = Array.new
    current_main_hash_id = ""
    current_item_hash_id = ""
    header_string = ""
    result_string = ""
    date_style = "mm/dd/yyyy"
    running1 = Progress.new
    previous_line = ""
    previous_previous_line = ""
    area = ""
    #Test Suite,Test Case,Build Name,Metric Name,Units,Count,MIN,MAX,MEAN,STDDEV
    @raw_buffer.each  do |rb_item|
      if rb_item.downcase.include?("#test cases")
        area = previous_previous_line
      end
      if rb_item.downcase.include?("test plan")
        test_plan_items = rb_item.split(",")
        if test_plan_items.length > 2
          test_plan = test_plan_items[2]
        end
      end
      previous_previous_line = previous_line
      previous_line = rb_item
      line_to_check = "#{rb_item}, #{area}"
      if rb_item.downcase.include?("scmc-") && is_filter_match(line_to_check, execution_options.filter) && !is_filter_match(line_to_check, execution_options.negative_filter)
        #puts(" rb_item: \"#{rb_item}\"\r\n")
        items = rb_item.split(",")
        #csv_split_fixer(items)
        items = csv_split_fixer(items)
        test_data_date = items[TEST_TIME].split(" ")[0]
        test_data_start_date = test_data_date if pseudo_days(test_data_date, date_style) < pseudo_days(test_data_start_date, date_style) 
        test_data_end_date = test_data_date if pseudo_days(test_data_date, date_style) > pseudo_days(test_data_end_date, date_style) 
        #main_id = items[TEST_SUITE_ID].gsub(" ", "")
        #main_id = (main_id.downcase.include?("inflow") ? stat1 : stat2)
        #main_id = (main_id.downcase.include?("software") ? stat3 : main_id)
        main_id = get_stat_type(stat_types, get_stat_from_string(items[TEST_SUITE_ID].gsub(" ", "")))
        puts(" main_id: \"#{main_id}\"\r\n")
        #temp_data = "#{items[TEST_DATA].chomp}"
        temp_data = "#{items[TEST_DATA].chomp}"
        #puts(" temp_data: \"#{temp_data}\"\r\n")
        item_id = "#{get_test_data_value(temp_data, TEST_CASE)}"
        if item_id.downcase.include?("ingress") and item_id.downcase.include?("egress")
          puts("\r\n ingress and egress\r\n")
          item_id += "_#{get_test_data_value(temp_data, PKT_SIZE)}"
          #value = "#{get_test_data_value(temp_data, INGRESS_BW)} / #{get_test_data_value(temp_data, EGRESS_BW)} / #{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE).to_f)}"
          value = "#{get_test_data_value(temp_data, INGRESS_BW)},#{get_test_data_value(temp_data, EGRESS_BW)},#{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE).to_f)}"
        else
          item_id += "_#{get_test_data_value(temp_data, PKT_SIZE - 1)}"
          if item_id.downcase.include?("ingress")
            puts("\r\n ingress\r\n")
            #value = "#{get_test_data_value(temp_data, INGRESS_BW)} / #{get_test_data_value(temp_data, EGRESS_BW)} / #{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
            value = "#{get_test_data_value(temp_data, INGRESS_BW)},,#{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
          else
            puts("\r\n egress\r\n")
            #value = "#{get_test_data_value(temp_data, INGRESS_BW)} / #{get_test_data_value(temp_data, EGRESS_BW)} / #{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
            value = ",#{get_test_data_value(temp_data, INGRESS_BW)},#{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
          end  
        end
        item_id += "Bytes"
        #puts(" main_id: \"#{main_id}\", item_id: \"#{item_id}\", value_item: \"#{value}\"\r\n")
        #recombine things that were separated but were within double quotes
        if value.include?("\"")
          value = value.gsub("\"", "")
          value = value.gsub(".00", "")
        #  for index in ((METRIC_MEAN + 1)..(@csv_fixed_items.length - 1)) 
        #    value += items[index]
        #    break if items[index].include?("\"")
        #  end
        end
        if main_id != current_main_hash_id
          main_hash_ids.push(main_id)
          current_main_hash_id = main_id
        end
        if item_id != current_item_hash_id
          item_hash_ids.push(item_id)
          current_item_hash_id = item_id
        end
        if !main_id.downcase.include?("ipsec_")
          #puts(" main_id: \"#{main_id}\", item_id: \"#{item_id}\", value_item: \"#{value}\"\r\n")
          #puts(" main_id: \"#{main_id}\"\r\n")
          #puts("\r\n main_id: \"#{main_id}\", \r\ntest_id: \"#{item_id}\"\r\n")
          hash_add(main_id, item_id, value)
        end
      end
      running1.indicate(" Lines Processed: ")
    end
    @results_buffer.push("\"Test Plan: #{test_plan}\"\n")
    #@results_buffer.push("\"Data Collection Period: #{t.year}-#{'%02d' % t.mon}-#{'%02d' % t.day}\"\n")
    @results_buffer.push("\"Data Collection Period: #{test_data_start_date} - #{test_data_end_date}\"\n")
    @results_buffer.push("\"Linux PC: Ubuntu 12.0.4 with StrongSwan 5.0.0\"\n")
    @results_buffer.push("\"EVM: StrongSwan 5.0.0\"\n")
    @results_buffer.push("\"Test Scenario: [Linux PC, iperf -c & iperf -s] --> [Gigabit Switch] --> [EVM, iperf -s & iperf -c]  (measurement is run for 60 seconds)\"\n")
    @results_buffer.push("\"Mbps = Megabits per second, tbw = tested bandwidth, Pass-through = IPSEC running but shunted, Eth-only = IPSEC not running, abwd = auto bandwidth detection\"\n")
    @results_buffer.push("\n")
    # Finish creating scenario header
    stat_types.each do |item|
      if get_stat_type(main_hash_ids, item) != ""
        #scenario_header += ",#{item} #{header_perf_stat},,"
        scenario_header += ",#{item},,"
      end
    end
    scenario_header += "\n"
    # Finish creating measurement info header
    @results_buffer.push(scenario_header)
    stat_types.each do |item|
      if get_stat_type(main_hash_ids, item) != ""
        info_header += ",#{info_columns}"
      end
    end
    info_header += "\n"
    @results_buffer.push(info_header)
    
    column_separator = ""
    #display_header_names.each do |header_name|
    #  header_string += column_separator
    #  header_string += header_name
    #  column_separator = ", "
    #end
    #header_string += "\n"
    @results_buffer.push(header_string)
    item_hash_ids.uniq!
    main_hash_ids.uniq!
    counter = 1
    item_hash_ids.each do |item_hash_id|
      column_separator = ""
      result_string = "#{counter}, #{item_hash_id}, "
      #display_header_names.each do |main_hash_id|
      stat_types.each do |main_hash_id|
        #if main_hash_id.downcase.include?(header_perf_stat.downcase)
        if get_stat_type(main_hash_ids, main_hash_id) != ""
          result_string += column_separator
          result_temp = hash_get("#{main_hash_id}", item_hash_id)
          puts("\r\n result_temp: #{result_temp}\r\n")
          result_string += (result_temp == "" ? ",," : result_temp)
          column_separator = ", "
          running1.indicate(" Lines Processed: ")
        end
      end
      result_string += "\n"
      @results_buffer.push(result_string)
      counter += 1
      #puts(" \r\n result_string: #{result_string}\r\n")
    end
    #perf_ids.each do |perf_id|
    #  column_separator = ""
    #  result_string = ""
    #  if !perf_id.downcase.include?("ipsec_")
    #    title_items = perf_id.split("@@")
    #    title_items.each do |t_item|
    #      result_string += column_separator
    #      result_string += t_item
    #      column_separator = ", "
    #    end
    #    hash_value_names.each do |value_item|
    #      result_string += column_separator
    #      #puts(" perf_id: \"#{perf_id}\", value_item: \"#{value_item}\"\r\n")
    #      result_string += hash_get(perf_id, value_item)
    #      column_separator = ", "
    #      running1.indicate(" Lines Processed: ")
    #    end
    #    result_string += "\n"
    #    @results_buffer.push(result_string)
    #    running1.indicate(" Lines Processed: ")
    #  end
    #end
    puts("File name: #{add_post_pend(file_name, execution_options.post_pend)}\n")
    # Write the results to the output file
    #file_write_check("", "", add_post_pend(file_name, execution_options.post_pend), execution_options)
    #file_write_check("", "", file_name, execution_options)
  end
  PROTOCOL_FIELD = 0
  ENCYRPTION_FIELD = 1
  AUTHENTICATION_FIELD = 2
  DIRECTION_FIELD = 3
  PKT_SIZE_FIELD = 4
  def get_modified_results_string(string)
    return_string = ""
    puts("\r\n get_modified_results_string string: #{string}\r\n")
    items = string.split("_")
    if items.length >= 5
      pkt_size_fld = PKT_SIZE_FIELD
      direction = items[DIRECTION_FIELD].split("-")[0]
      if string.downcase.include?("ingress") && string.downcase.include?("egress")
        pkt_size_fld += 1
        direction = "both"
      end
      pkt_size = items[pkt_size_fld].gsub("Bytes","")
      #return_string = "#{pkt_size}, #{items[PROTOCOL_FIELD]}, #{direction}, #{items[ENCYRPTION_FIELD]}, #{items[AUTHENTICATION_FIELD]}, " 
      return_string = "#{pkt_size}, #{direction}, #{items[PROTOCOL_FIELD]}, #{items[ENCYRPTION_FIELD]}, #{items[AUTHENTICATION_FIELD]}, " 
    end
    return return_string
  end
  def get_t2_ipsec_perf_results(file_name, execution_options, logs)
    t = Time.new
    stat_types = Array.new
    stat_types = ["Inflow", "Sideband", "Software", "Pass-through", "Eth-only", "Ethernet", "Ethernet0", "Ethernet1", "Ethernet2", "Ethernet4"]
    @results_buffer.clear
    packet_size = "512"
    header_perf_measures = "ingress-mbw Mbps / egress-mbw Mbps / cpu util %"
    #header_perf_stat = "Throughput #{packet_size} byte packets"
    header_perf_stat = "Throughput"
    #stat1 = "Inflow Crypto #{header_perf_stat} #{header_perf_measures}"
    #stat2 = "Sideband Crypto #{header_perf_stat} #{header_perf_measures}"
    #stat3 = "Software Crypto #{header_perf_stat} #{header_perf_measures}"
    stat1 = "Inflow Crypto #{header_perf_stat}"
    stat2 = "Sideband Crypto #{header_perf_stat}"
    stat3 = "Software Crypto #{header_perf_stat}"
    test_plan = ""
    test_data_start_date = "12/31/9999"
    test_data_end_date = "1/1/0000"
    #@results_buffer.push(",Test Scenario,Inflow Crypto Throughput Measurements,,,Sideband Crypto Throughput Measurements,,,\n")
    #@results_buffer.push(",Protocol_Encryption_Authentication_ingress-tbw_egress-tbw_packet-bytes,Ingress Mbps,Egress Mbps,CPU Utilization %,Ingress Mbps,Egress Mbps,CPU Utilization %\n")
    #scenario_header = "Item,Throughput Scenario"
    #scenario_header = "Throughput Scenario"
    scenario_header = "Throughput Scenario,,,,"
    #info_header = "#,Protocol_Encryption_Authentication_ingress-tbw_egress-tbw_packet-bytes"
    info_header = "Pkt_Size,Direction,Protocol,Encryption,Authentication"
    info_columns = "Ingress Mbps,Egress Mbps,CPU Utilization %"
    orig_header_names = Array.new
    orig_header_names = ["Test Suite", "Test Case", "Build Name", "Metric Name", "Units", "Count", "MIN", "MAX", "MEAN", "STDDEV"]
    display_header_names = Array.new
    display_header_names = ["", "Protocol_Encryption_Authentication_ingress-tbw_egress-tbw_packet-bytes", "#{stat1}", "#{stat2}"]
    hash_value_names = ["count", "inflow_ingress", "inflow_egress", "inflow_cpu_idle%", "sideband_ingress", "sideband_egress", "sideband_cpu_idle%"]
    main_hash_ids = Array.new
    item_hash_ids = Array.new
    current_main_hash_id = ""
    current_item_hash_id = ""
    header_string = ""
    result_string = ""
    date_style = "mm/dd/yyyy"
    running1 = Progress.new
    previous_line = ""
    previous_previous_line = ""
    area = ""
    build_id = ""
    eth_port = ""
    #Test Suite,Test Case,Build Name,Metric Name,Units,Count,MIN,MAX,MEAN,STDDEV
    @raw_buffer.each  do |rb_item|
      if rb_item.downcase.include?("#test cases")
        area = previous_previous_line
        if area.downcase.include?("eth")
          items = area.split("_")
          items.each do |item|
            if item.include?("eth") && !item.include?("ethe")
              eth_port = item.gsub("eth", "")
            end
          end
        end
      end
      if rb_item.downcase.include?("test plan")
        test_plan_items = rb_item.split(",")
        if test_plan_items.length > 2
          test_plan = test_plan_items[2]
        end
      end
      previous_previous_line = previous_line
      previous_line = rb_item
      line_to_check = "#{rb_item}, #{area}"
      if rb_item.downcase.include?("scmc-") && is_filter_match(line_to_check, execution_options.filter) && !is_filter_match(line_to_check, execution_options.negative_filter)
        puts(" rb_item: \"#{rb_item}\"\r\n")
        puts("\r\n area: #{area}\r\n")
        puts("\r\n eth_port: #{eth_port}\r\n")
        error_fixed_rb_item = rb_item.gsub("[ERROR: iperf measurement is incomplete]", "0")
        puts(" error_fixed_rb_item: \"#{error_fixed_rb_item}\"\r\n")
        #exit
        #items = rb_item.split(",")
        items = error_fixed_rb_item.split(",")
        #csv_split_fixer(items)
        items = csv_split_fixer(items)
        test_data_date = items[TEST_TIME].split(" ")[0]
        test_data_start_date = test_data_date if pseudo_days(test_data_date, date_style) < pseudo_days(test_data_start_date, date_style) 
        test_data_end_date = test_data_date if pseudo_days(test_data_date, date_style) > pseudo_days(test_data_end_date, date_style) 
        #main_id = items[TEST_SUITE_ID].gsub(" ", "")
        #main_id = (main_id.downcase.include?("inflow") ? stat1 : stat2)
        #main_id = (main_id.downcase.include?("software") ? stat3 : main_id)
        main_id = get_stat_type(stat_types, get_stat_from_string(items[TEST_SUITE_ID].gsub(" ", "")))
        main_id += eth_port
        puts(" main_id: \"#{main_id}\"\r\n")
        #exit
        build_id = items[BUILD_ID].gsub(" ", "")
        puts(" build_id: \"#{build_id}\"\r\n")
        #temp_data = "#{items[TEST_DATA].chomp}"
        temp_data = "#{items[TEST_DATA].chomp}"
        #puts(" temp_data: \"#{temp_data}\"\r\n")
        item_id = "#{get_test_data_value(temp_data, TEST_CASE)}".gsub("10000M", "1000M")
        puts(" item_id: \"#{item_id}\"\r\n")
        if item_id.downcase.include?("ingress") and item_id.downcase.include?("egress")
          puts("\r\n ingress and egress\r\n")
          item_id += "_#{get_test_data_value(temp_data, PKT_SIZE)}"
          #value = "#{get_test_data_value(temp_data, INGRESS_BW)} / #{get_test_data_value(temp_data, EGRESS_BW)} / #{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE).to_f)}"
          #value = "#{get_test_data_value(temp_data, INGRESS_BW)},#{get_test_data_value(temp_data, EGRESS_BW)},#{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE).to_f)}"
          value = "#{get_test_data_value(temp_data, INGRESS_BW)},#{get_test_data_value(temp_data, EGRESS_BW)},#{'%.2f' % get_test_data_value(temp_data, CPU_IDLE).to_f}"
        else
          item_id += "_#{get_test_data_value(temp_data, PKT_SIZE - 1)}"
          if item_id.downcase.include?("ingress")
            puts("\r\n ingress\r\n")
            #value = "#{get_test_data_value(temp_data, INGRESS_BW)} / #{get_test_data_value(temp_data, EGRESS_BW)} / #{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
            #value = "#{get_test_data_value(temp_data, INGRESS_BW)},,#{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
            value = "#{get_test_data_value(temp_data, INGRESS_BW)},,#{'%.2f' % get_test_data_value(temp_data, CPU_UTIL - 1).to_f}"
          else
            puts("\r\n egress\r\n")
            #value = "#{get_test_data_value(temp_data, INGRESS_BW)} / #{get_test_data_value(temp_data, EGRESS_BW)} / #{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
            #value = ",#{get_test_data_value(temp_data, INGRESS_BW)},#{'%.2f' % (100 - get_test_data_value(temp_data, CPU_IDLE - 1).to_f)}"
            value = ",#{get_test_data_value(temp_data, INGRESS_BW)},#{'%.2f' % get_test_data_value(temp_data, CPU_UTIL - 1).to_f}"
          end  
        end
        #exit
        item_id += "Bytes"
        #puts(" main_id: \"#{main_id}\", item_id: \"#{item_id}\", value_item: \"#{value}\"\r\n")
        #recombine things that were separated but were within double quotes
        if value.include?("\"")
          value = value.gsub("\"", "")
          value = value.gsub(".00", "")
        #  for index in ((METRIC_MEAN + 1)..(@csv_fixed_items.length - 1)) 
        #    value += items[index]
        #    break if items[index].include?("\"")
        #  end
        end
        if main_id != current_main_hash_id
          main_hash_ids.push(main_id)
          current_main_hash_id = main_id
        end
        if item_id != current_item_hash_id
          item_hash_ids.push(item_id)
          current_item_hash_id = item_id
        end
        if !main_id.downcase.include?("ipsec_")
          #puts(" main_id: \"#{main_id}\", item_id: \"#{item_id}\", value_item: \"#{value}\"\r\n")
          #puts(" main_id: \"#{main_id}\"\r\n")
          #puts("\r\n main_id: \"#{main_id}\", \r\ntest_id: \"#{item_id}\"\r\n")
          hash_add(main_id, item_id, value)
        end
      end
      running1.indicate(" Lines Processed: ")
    end
    @results_buffer.push("\"Test Plan: #{test_plan}\"\n")
    #@results_buffer.push("\"Data Collection Period: #{t.year}-#{'%02d' % t.mon}-#{'%02d' % t.day}\"\n")
    @results_buffer.push("\"Data Collection Period: #{test_data_start_date} - #{test_data_end_date}\"\n")
    @results_buffer.push("\"Linux PC: Ubuntu 12.0.4 with StrongSwan 5.0.0\"\n")
    @results_buffer.push("\"EVM: StrongSwan 5.0.0\"\n")
    @results_buffer.push("\"Test Scenario: [Linux PC] --> [10 Gigabit/1 Gigabit Switch] --> [EVM]  (measurement is run for 60 seconds)\"\n")
    @results_buffer.push("\"Iperf Server Side Command (UDP): iperf -s -u\"\n")
    @results_buffer.push("\"Iperf Client Side Command (UDP): iperf -c {server_side_ip_address} -P 2 --format m -u -b {bandwidth/2}M --len {packet_size_in_bytes} -t 60\"\n")
    @results_buffer.push("\"Iperf Server Side Command (TCP): iperf -s\"\n")
    @results_buffer.push("\"Iperf Client Side Command (TCP): iperf -c {server_side_ip_address} -P 2 --format m -M {packet_size_in_bytes} -w 128K -t 60\"\n")
    #@results_buffer.push("\"Mbps = Megabits per second, tbw = tested bandwidth, Pass-through = IPSEC running but shunted, Eth-only = IPSEC not running, abwd = auto bandwidth detection\"\n")
    @results_buffer.push("\n")
    # Finish creating scenario header
    stat_types.each do |item|
      if get_stat_type(main_hash_ids, item) != ""
        #scenario_header += ",#{item} #{header_perf_stat},,"
        scenario_header += ",#{item},,"
      end
    end
    scenario_header += "\n"
    # Finish creating measurement info header
    @results_buffer.push(scenario_header)
    stat_types.each do |item|
      if get_stat_type(main_hash_ids, item) != ""
        info_header += ",#{info_columns}"
      end
    end
    #info_header += "\n"
    info_header += ",BRefId\n"
    @results_buffer.push(info_header)
    
    column_separator = ""
    #display_header_names.each do |header_name|
    #  header_string += column_separator
    #  header_string += header_name
    #  column_separator = ", "
    #end
    #header_string += "\n"
    @results_buffer.push(header_string)
    item_hash_ids.uniq!
    main_hash_ids.uniq!
    counter = 1
    item_hash_ids.each do |item_hash_id|
      column_separator = ""
      #result_string = "#{counter}, #{item_hash_id}, "
      result_string = get_modified_results_string(item_hash_id)
      puts("\r\n result_string: \"#{result_string}\"\r\n")
      #exit
      #display_header_names.each do |main_hash_id|
      stat_types.each do |main_hash_id|
        #if main_hash_id.downcase.include?(header_perf_stat.downcase)
        if get_stat_type(main_hash_ids, main_hash_id) != ""
          puts("\r\n main_hash_id: \"#{main_hash_id}\"\r\n")
          puts("\r\n item_hash_id: \"#{item_hash_id}\"\r\n")
          result_string += column_separator
          result_temp = hash_get("#{main_hash_id}", item_hash_id)
          puts("\r\n result_temp: #{result_temp}\r\n")
          result_string += (result_temp == "" ? ",," : result_temp)
          column_separator = ", "
          running1.indicate(" Lines Processed: ")
        end
      end
      #result_string += "\n"
      result_string += ",#{build_id}\n"
      @results_buffer.push(result_string)
      counter += 1
      #puts(" \r\n result_string: #{result_string}\r\n")
    end
    #perf_ids.each do |perf_id|
    #  column_separator = ""
    #  result_string = ""
    #  if !perf_id.downcase.include?("ipsec_")
    #    title_items = perf_id.split("@@")
    #    title_items.each do |t_item|
    #      result_string += column_separator
    #      result_string += t_item
    #      column_separator = ", "
    #    end
    #    hash_value_names.each do |value_item|
    #      result_string += column_separator
    #      #puts(" perf_id: \"#{perf_id}\", value_item: \"#{value_item}\"\r\n")
    #      result_string += hash_get(perf_id, value_item)
    #      column_separator = ", "
    #      running1.indicate(" Lines Processed: ")
    #    end
    #    result_string += "\n"
    #    @results_buffer.push(result_string)
    #    running1.indicate(" Lines Processed: ")
    #  end
    #end
    puts("File name: #{add_post_pend(file_name, execution_options.post_pend)}\n")
    # Write the results to the output file
    #file_write_check("", "", add_post_pend(file_name, execution_options.post_pend), execution_options)
    #file_write_check("", "", file_name, execution_options)
  end
  def get_raw_buffer(file_name)
    in_file_line = ""
    @raw_buffer.clear
    File.open(file_name, "r") do |f|
      while (in_file_line = f.gets)
        #puts("\r\n buffer_line: #{in_file_line}\r\n")
        @raw_buffer.push(in_file_line)
      end
      f.close
    end
  end
  def make_new_file_name(file_name, new_file_name, execution_options)
    if new_file_name != ""
      path_and_new_file_name = ""
      file_name_items = Array.new
      file_name_items = file_name.split("/")
      previous_file_name = file_name_items[(file_name_items.length - 1)]
      path_and_new_file_name = file_name.sub("#{previous_file_name}", "#{new_file_name}")
      path_and_new_file_name = "#{path_and_new_file_name}.csv"
    else
      path_and_new_file_name = file_name.split(".")[0]
      path_and_new_file_name = "#{path_and_new_file_name}_tresults.csv"
    end
    # Change the file extension if this is for tput results
    if execution_options.collect_only_tput_results
      path_and_new_file_name.sub!("tresults", "tput_results")
      path_and_new_file_name.sub!(".csv", ".txt")
    end
    
    #puts("\r\n file_name             : #{file_name}\r\n")
    #puts("\r\n new_file_name         : #{new_file_name}\r\n")
    #puts("\r\n path_and_new_file_name: #{path_and_new_file_name}\r\n")

    return(path_and_new_file_name)
  end
  def save_current_results_file(file_to_save)
    max_count = 999
    backup_count = 0
    save_file_name = ""
    extention = File.extname(file_to_save)
    if (File.exist?(file_to_save))
      while (backup_count <= max_count)
        #save_file_name = file_to_save.sub(".csv", "_save#{'%03d' % backup_count}.csv")
        save_file_name = file_to_save.sub("#{extention}", "_save#{'%03d' % backup_count}.#{extention}")
        if !(File.exist?(save_file_name))
          File.rename(file_to_save, save_file_name)
          break
        end
        backup_count = backup_count + 1
      end
    end
  end
  def write_results(file_name, new_file_name, execution_options)
    backup_count = 0
    save_file = make_new_file_name(file_name, new_file_name, execution_options)
    save_current_results_file(save_file)
    File.open(save_file, "w+") do |file|
      file.write(@results_buffer)
      file.close
    end
    @file_num += 1
    if @file_num > 100
      puts("\n Too many results files being created, there must be a problem. Aborting tresults.\n")
      exit
    end
  end
  def get_results_and_save_to_file(projects, execution_options, file_index, logs)
    file_name = projects.file_list[file_index]
    #puts("\n In file name: #{file_name}\n")
    get_raw_buffer(file_name)
    if execution_options.collect_only_tput_results
      get_tput_results(file_name, execution_options, logs)
    else
      if execution_options.collect_only_tlperf_results 
        get_tlperf_results(file_name, execution_options, logs)
      else
        get_results(file_name, execution_options)
      end
      if execution_options.collect_only_tlperf_ipsec_results 
        #get_t1_ipsec_perf_results(file_name, execution_options, logs)
        get_t2_ipsec_perf_results(file_name, execution_options, logs)
      end
    end
    if @results_buffer.length != 0
      write_results(add_post_pend(file_name, execution_options.post_pend),@current_file_name, execution_options)
    end
  end
end

class Projects
  def initialize
    @file_list = Array.new
    @file_list.clear
    @project_list = Array.new
    @project_list.clear
  end
  def clear_file_list
    @file_list.clear
  end
  def sort_project_array_and_push_to_fileList()
    if @project_list.length != 0
      # fix project names for sort to work properly
      #for aIndex in (0..@project_list.length-1)
      #  @project_list[aIndex].sub!("_0/","_000/")
      #  @project_list[aIndex].sub!("_40/","_040/")
      #  @project_list[aIndex].sub!("_80/","_080/")
      #end
      @project_list.sort!
      # restore original project names
      #for aIndex in (0..@project_list.length-1)
      #  @project_list[aIndex].sub!("_000/", "_0/")
      #  @project_list[aIndex].sub!("_040/","_40/")
      #  @project_list[aIndex].sub!("_080/","_80/")
      #end
      @project_list.each{ |filename| @file_list.push("#{filename}")}
      @project_list.clear
    end
  end
  def get_list_by_recursive_scan_and_display_count(projects, scan_item, execution_options, logs)
    running = Progress.new
    @project_list.clear
    dirs = [scan_item]
    #puts("\r\n dirs: #{dirs}\r\n")
    for dir in dirs
      Find.find(dir) do |project_file|
        running.indicate("")
        if FileTest.directory?(project_file)
          if File.basename(project_file)[0] == ?.
            Find.prune       # Don't look any further into this directory.
          else
            next
          end
        end
        if (is_valid_extension(File.basename(project_file), execution_options.extensions_allowed))
          #puts("project_file: #{project_file}\r\n")
          @project_list.push("#{project_file}")
        end
      end
    end
    sort_project_array_and_push_to_fileList()
  end
  def file_list
    @file_list
  end
end

def display_count_exit_if_zero(count, logs)
  logs.display_write("#{count}\r\n")
  if (count == 0)
    exit
  end
end

def is_valid_extension(file_name, exts_allowed)
  #the built in File.extname does not return the right extention if the file name has nothing before the '.' such as ".project", so this fixes the issue.
  ext_string = (file_name[0,1] == '.' ? file_name : File.extname(file_name))
  puts(" ext_string: #{ext_string}\r\n")
  if (ext_string != "")
    if (exts_allowed.include?(ext_string + " "))
      return true
    end
  end
  return false
end

def exit_without_stats(stats)
  stats.set_completions_stats_to_do_not_show
  exit
end

def create_directory_if_needed(directory_to_create)
  create_dir = directory_to_create.tr("\\","/")
  dir_items = create_dir.split('/')
  if dir_items.length > 1
    create_dir = "#{dir_items[0]}"
    for temp_index in (0..dir_items.length-2)
      create_dir = "#{create_dir}/#{dir_items[temp_index+1]}"
      if (!File.exist?(create_dir))
        Dir.mkdir(create_dir)
      end
    end
  end
end

# copy one file to another file (because of xcopy this only works if the destination file already exists)
def copy_file_file(from_file, to_file)
  copy_status = %x[xcopy \"#{from_file.tr("/","\\")}\" \"#{to_file.tr("/","\\")}\" /h /y /q]
end

def stats_format_print(passed_count, failed_count, nocode_count)
  return_val = "Passed: #{print_in_space(3,"#{passed_count}")} Failed: #{print_in_space(3,"#{failed_count}")} No Code: #{print_in_space(3,"#{nocode_count}")}"
  return_val
end

def current_date_and_time()
  t = Time.new
  temp = "#{t.year}-#{'%02d' % t.mon}-#{'%02d' % t.day} #{'%02d' % t.hour}:#{'%02d' % t.min}:#{'%02d' % t.sec}"
  temp
end

def print_in_space(num_spaces, string)
  sl = string.length
  space_str = ""
  if sl < num_spaces
    for count in (1..(num_spaces - sl))
      space_str = space_str + " "
    end
  end
  string + space_str
end

def startup_display(execution_parameter, logs)
  logs.display_write("\r\n")
  logs.display_write("tresults Execution Details and Statistics:      \r\n")
  logs.display_write("---------------------------------------------- \r\n")
  logs.display_write(" Extention: #{execution_parameter.extensions_allowed}\r\n")
  logs.display_write(" In File  : #{execution_parameter.input_first_file_directory}\r\n")
  logs.display_write(" Log File : #{execution_parameter.log_filename}\r\n")
  logs.display_write("\r\n")
end

def display_simple_usage()
  puts ""
  puts " Usage examples:"
  puts "  tresults C:\\csl_runs\\csl_runner.log"
  puts "  or"
  puts "  tresults C:\\test\\manually.sav -e \".sav\""
  puts ""
  puts " parameters available:"
  puts "  tresults {csl_runner_log_file} [-e \".ext\"]"
  puts ""
  puts " Note: Parameters in \"{}\" are required, parameters in \"[]\" are optional"
  puts "\n"
end

def display_script_command_line_usage_full()
  puts ""
  puts " This script is used to extract results for QT projects from the csl_runner log"
  puts " file, or from the manually saved console output."
  puts " Results for the csl_runner log will be saved to the individual file names"
  puts " derived from the csl_runner log. File name will be similar to:"
  puts "   Nyquist_Aif2_Test_Nyq-DFS-LE_raw.csv"
  puts " Results for the manually saved log will be the input file name plus _tresults"
  puts " and be similar to the following: (with input file: aif2_manual_log.txt)"
  puts "   aif2_manual_log_tresults.txt"
  puts ""
  puts "\n"
  puts " Options:"
  puts ""
  puts " {csl_runner_log_file}       : Path and file name of csl_runner log file"
  puts " {-e \".ext\"}                 : Use to specify a different extension to use"
  puts "                               default extensions are .txt and .log"
  puts ""
  puts ""
  display_simple_usage()
end

class Options
  def initialize
    t = Time.new
    
    @item_list = Array.new
    @item_list[0] = Array.new
    @item_list[1] = Array.new
    @item_list[2] = Array.new
    @required_params = ["", "", ""]
    @log_filename = ""
    @dir_file_mode = GENERATE_DIRECTORY_NAME
    @results_directory_base = RESULTS_DIRECTORY_BASE_DEFAULT
    @results_directory_results_suffix = RESULTS_DIRECTORY_RESULTS_SUFFIX
    @result_directory_date_name = "#{t.year}-#{'%02d' % t.mon}-#{'%02d' % t.day}_#{'%02d' % t.hour}_#{'%02d' % t.min}_#{'%02d' % t.sec}"
    @generate_merged_compare_file = false
    @notes_file_included = false
    @extensions_allowed = EXTENSIONS_ALLOWED
    @do_fault = false
    @collect_only_tput_results = false
    @collect_only_tlperf_results = false
    @collect_only_tlperf_ipsec_results = false
    @filter = ""
    @negative_filter = ""
    non_optional_arg_count = 0
    arg_count = 0
    secondary_arg_count = 0
    get_secondary_arg = ""
    @post_pend = ""
    
    temp_items = Array.new
    
    ARGV.each do |arg_item|
      if arg_item.match(/(.)\*/) != nil
        puts "\r\n Error: No wildcards are accepted for the file or directory names.\r\n\r\n"
        exit
      end
      case arg_item
        when "-e"
          get_secondary_arg = "extentions"
          secondary_arg_count = arg_count
        when "-gmcf"
          @generate_merged_compare_file = true
        when "-addfault"
          @do_fault = true
        when "-tput"
          @collect_only_tput_results = true
        when "-tlperf"
          @collect_only_tlperf_results = true
        when "-tlperf_ipsec"
          @collect_only_tlperf_ipsec_results = true
        when "-filt"
          get_secondary_arg = "filter"
          secondary_arg_count = arg_count
        when "-nfilt"
          get_secondary_arg = "negative_filter"
          secondary_arg_count = arg_count
        when "-postpend"
          get_secondary_arg = "post_pend"
          secondary_arg_count = arg_count
        else
          if arg_item.index("-") == 0
            puts "\r\n"
            puts " Error: option #{arg_item} is not a valid option. Please see usage example below:\r\n"
            display_simple_usage()
            exit
          end
          if secondary_arg_count != (arg_count - 1)
            get_secondary_arg = ""
          end
          if !(get_secondary_arg == "")
            case get_secondary_arg
              when "results_directory"
                @results_directory_base = File.expand_path(arg_item.tr("\\","/"))
                get_secondary_arg = ""
              when "extentions"
                @extensions_allowed = ""
                if arg_item.include?(" ")
                  @extensions_allowed = arg_item
                else
                  temp_items = arg_item.split(".")
                  temp_items.each{ |temp_item| (temp_item != "" ? @extensions_allowed = "#{@extensions_allowed}.#{temp_item} " : false)}
                end
                get_secondary_arg = ""
              when "filter"
                @filter = arg_item
                get_secondary_arg = ""
              when "negative_filter"
                @negative_filter = arg_item
                get_secondary_arg = ""
              when "post_pend"
                @post_pend = arg_item
                get_secondary_arg = ""
            end
          else
            if non_optional_arg_count < 3
              if arg_item.match('@') == nil
                @required_params[non_optional_arg_count] = File.expand_path(arg_item.tr("\\","/"))
              else
                @required_params[non_optional_arg_count] = "@" + "#{File.expand_path(arg_item.tr("@", "")).tr("\\","/")}"
              end
            else
              if non_optional_arg_count > 3
                puts "\r\n"
                puts " Error: at parameter #{arg_item}, too many base parameters. There can only be\r\n"
                puts "        one base parameter specifed: 1=Current Result File, 2=Golden Result File, 3=Notes File\r\n"
                puts "        (Base parameters are those parameters without the hypen prefix)"
                puts "        Please see usage example below:"
                display_simple_usage()
                exit
              end
            end
            non_optional_arg_count += 1
          end
      end
      arg_count += 1
    end
    if @required_params[NOTES_FILE] != ""
      @notes_file_included = true
    end
    @results_directory_base = generate_result_base_directory_name(@dir_file_mode, @results_directory_base, @result_directory_date_name).tr!("\\","/")
    @results_directory_results_suffix.tr!("\\","/")
    @results_directory_output = @results_directory_base + @results_directory_results_suffix
    @log_filename = @results_directory_base + "tresults.log"
    #if @required_params[SECOND_FILE] == "" or @required_params[FIRST_FILE] == "" or @results_directory_output == ""
    #if @required_params[FIRST_FILE] == "" or @required_params[SECOND_FILE] == ""
    if @required_params[FIRST_FILE] == ""
      puts("\n Required parameter not specified\n")
      display_script_command_line_usage_full()
      exit
    end
    set_item_list(FIRST_FILE, @required_params)  # modifies @     
    ##set_item_list(SECOND_FILE, @required_params)  # modifies @item_list
    #if @required_params[NOTES_FILE] != ""
      ##set_item_list(NOTES_FILE, @required_params)  # modifies @item_list
    #end
    #puts("\n extentions allowed: #{@extensions_allowed}\n")
    #exit
  end
  def generate_result_base_directory_name(dir_file_mode, current_directory_base, result_directory_date_name)
    new_directory_base = current_directory_base
    if dir_file_mode == GENERATE_DIRECTORY_NAME
      new_directory_base = new_directory_base.sub(DATE_TIME_SUBSTITUTION,result_directory_date_name)
    end
    return new_directory_base
  end
  def set_item_list(list_to_set, required_params)
    if list_to_set == SECOND_FILE or list_to_set == FIRST_FILE or list_to_set = NOTES_FILE
      if required_params[list_to_set].match('@') == nil
        @item_list[list_to_set].push("#{required_params[list_to_set]}")
      else
        load_item_list_from_file(list_to_set, required_params)
      end
    end
  end
  def load_item_list_from_file(list_to_set, required_params)
    if list_to_set == SECOND_FILE or list_to_set == FIRST_FILE or list_to_set = NOTES_FILE
      input_file = required_params[list_to_set].tr('@','')
      if File.exist?(input_file)
        File.open(input_file, "r") do |file|
          while (in_file_line = file.gets)
            if in_file_line.length > 2
              in_file_line = File.expand_path(in_file_line.tr("\\","/"))
              @item_list[list_to_set].push("#{in_file_line.chop}")
            end
          end
          file.close
        end  
      end
    end
  end
  def first_file_directory
    @item_list[FIRST_FILE]
  end
  def second_file_directory
    @item_list[SECOND_FILE]
  end
  def notes_file_directory
    @item_list[NOTES_FILE]
  end
  def results_directory_base
    @results_directory_base
  end
  def results_directory_output
    @results_directory_output
  end
  def log_filename
    @log_filename
  end
  def item_list
    @item_list
  end
  def input_first_file_directory
    @required_params[FIRST_FILE]
  end
  def input_second_file_directory
    @required_params[SECOND_FILE]
  end
  def notes_file_included
    @notes_file_included
  end
  def extensions_allowed
    @extensions_allowed
  end
  def do_fault
    @do_fault
  end
  def collect_only_tput_results
    @collect_only_tput_results
  end
  def collect_only_tlperf_results
    @collect_only_tlperf_results
  end
  def collect_only_tlperf_ipsec_results
    @collect_only_tlperf_ipsec_results
  end
  def filter
    @filter
  end
  def negative_filter
    @negative_filter
  end
  def post_pend
    @post_pend
  end
end
def dashes(size_of_line)
  temp_str = ""
  for dashes in (1..size_of_line)
    temp_str = temp_str + "-"
  end
  return(temp_str)
end
def display_file_names(file_name_one, file_name_two, file_name_notes, logs)
  file_one_text = " File One  : "
  file_two_text = " File Two  : "
  dash_count = (file_name_one.size >= file_name_two.size ? file_name_one.size : file_name_two.size)
  dash_count = dash_count + (file_one_text.size >= file_two_text.size ? file_one_text.size : file_two_text.size)
  logs.display_write(" #{dashes(dash_count)}\r\n")
  logs.display_write(" File One  : #{file_name_one}\r\n")
  logs.display_write(" File Two  : #{file_name_two}\r\n")
  if file_name_notes != ""
    logs.display_write(" File Notes: #{file_name_notes}\r\n")
  end
  logs.display_write(" #{dashes(dash_count)}\r\n")
end
def is_good_file_counts(execution_options)
  return_value = false
  file_one_length = execution_options.first_file_directory.length
  file_two_length = execution_options.second_file_directory.length
  file_three_length = execution_options.notes_file_directory.length
  #if execution_options.notes_file_included
  #  return_value = (file_one_length == file_two_length and file_one_length == file_three_length ? true : false)
  #else
  #  return_value = (file_one_length == file_two_length ? true : false)
  #end
  return_value = true
end
begin
  projects_to_traverse = 0
  
  # initialize statistics variables
  stats = Statistics.new
  # disable final stats show until logging has beens started
  stats.set_completions_stats_to_do_not_show

  if (ARGV.length < 1) or (ARGV.length > 8)
    puts("\n ARGV.length = #{ARGV.length}\n")
    display_script_command_line_usage_full()
    exit
  end
  # get and store execution parameters from the command line and create result/log directory
  execution_options = Options.new
  
  #puts("\r\njust before creating directory for log files\r\n")
  
  create_directory_if_needed(execution_options.results_directory_output)
  
  # initialize logging variables and open the log file
  logs = Logging.new
  logs.open_log_file(execution_options.log_filename)
  # re-enable final stats show now that the log file is open
  stats.set_completions_stats_to_show
  
  # initialize projects variables
  projects = Projects.new
  
  startup_display(execution_options, logs)

  logs.display_write(" Files Found    : ")

  # populate project run list
  execution_options.first_file_directory.each{ |scan_item| temp_status = projects.get_list_by_recursive_scan_and_display_count(projects, File.expand_path(scan_item), execution_options, logs)}
  display_count_exit_if_zero(projects.file_list.length, logs)

  #puts("\n before Results.new\n")
  file_results = Results.new
  #puts("\n after Results.new\n")
  
  projects_to_traverse = projects.file_list.length
  
  start_time = Time.new
  
  files_processed = 0
  running = Progress.new
  running.run_indicator_step(1)
  files_to_process = execution_options.first_file_directory.length
  file_index = 0
  logs.display_write("\r\n")
  
  #if files_to_process == execution_options.second_file_directory.length and files_to_process == execution_options.notes_file_directory.length
  #puts("\n Before if\n")
  if is_good_file_counts(execution_options)
    #puts("\n After if\n")
    #for file_index in (0..files_to_process - 1)
    for file_index in (0..projects_to_traverse - 1)
      #puts("\n For loop\n")
      files_processed += 1
      running.indicate(" Files Processed: ")
      #display_file_names(execution_options.first_file_directory[file_index], execution_options.second_file_directory[file_index], execution_options.notes_file_directory[file_index], logs)
      #display_file_names(projects.file_list[file_index], execution_options.second_file_directory[0], execution_options.notes_file_directory[0], logs)
      #temp_status = file_compare.compare_files("#{execution_options.first_file_directory[file_index]}", "#{execution_options.second_file_directory[file_index]}", logs)
      #temp_status = file_compare.compare_files(execution_options, file_index, logs)
      #temp_status = file_replace.replace_all_occurances(projects, execution_options, file_index, logs)
      temp_status = file_results.get_results_and_save_to_file(projects, execution_options, file_index, logs)
      projects_to_traverse -= 1
      #logs.display_write("\r\n")
    end
  else
    logs.display_write("\r\n The number of files in the first_file set do not match the number of files in the second file set.\r\n")
  end
  
  stop_time = Time.new
  
 rescue Exception => e
  #no rescue planned, just letting the user know which exception was caused
  if e.message != "" and e.message != "exit"
    if stats.show_completion_stats
      logs.display_write("\r\nException  : #{e.message}\r\n Back Trace: #{e.backtrace.inspect}\r\n")
    else
      puts("\r\nException  : #{e.message}\r\n Back Trace: #{e.backtrace.inspect}\r\n")
    end
    stats.set_completions_stats_to_do_not_show
  else
    if e.message != "exit"
      logs.display_write("\r\n\r\n\r\n *** Application was aborted. Execution and statistics may be incomplete. ***\r\n")
    end
  end
 ensure
  if stats.show_completion_stats
    total_time_secs = stop_time.to_i - start_time.to_i
    total_time_hours = total_time_secs / 3600
    total_time_mins = (total_time_secs  % 3600 ) / 60
    total_time_secs = total_time_secs - (total_time_hours * 3600) - (total_time_mins * 60)
    
    logs.display_write(" Files Processed: #{print_in_space(8,"#{files_processed}")}\r\n")
    #logs.display_write(" Files Modified : #{print_in_space(8,"#{file_replace.files_modified}")}\r\n")
    logs.display_write(" Execution Time : #{'%02d' % total_time_hours}:#{'%02d' % total_time_mins}:#{'%02d' % total_time_secs}\r\n")
    logs.finish_writing_logfile()
  end
 end