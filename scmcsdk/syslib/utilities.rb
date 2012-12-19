def display_as_binary(number)
  display_text = ""
  # Displays number as binary with leading zeros
  31.downto(0) do |n|
    display_text += "#{number[n]}"
  end
  return display_text
end

def error_code_bit_breakdown(error_code)
  error_code_text = ""
  if (error_code > 2)
    error_code_text += " Error Code (#{error_code}) bit breakdown: \r\n"
    error_code_text += "   33222222222211111111110000000000\r\n"
    error_code_text += "   10987654321098765432109876543210\r\n"
    error_code_text += "   --------------------------------\r\n"
    error_code_text += "   #{display_as_binary(error_code)}"
  else
    error_code_text += " Error Code: #{error_code}"
  end
  error_code_text += "\r\n"
  return error_code_text
end

class FileUtilities
  # This class holds File and Directory utilities.
  def initialize
    @directory_contents = Array.new
    @file_contents = Array.new
  end
  def clear_directory_contents()
    @directory_contents.clear
  end
  def clear_file_contents()
    @file_contents.clear
  end
  def is_contents_empty(array_to_check)
    is_empty = false
    arr_to_check = array_to_check
    arr_to_check = [array_to_check] if array_to_check.kind_of?(String)
    if (arr_to_check.length == 0)
      is_empty = true
    end
    return is_empty
  end
  def is_directory_contents_empty()
    is_empty = is_contents_empty(@directory_contents)
    return is_empty
  end
  def is_file_contents_empty()
    is_empty = is_contents_empty(@file_contents)
    return is_empty
  end
  def write_file_contents(file_to_write, file_contents)
    output_file = File.expand_path(file_to_write)
    # Write array contents to file
    File.open(output_file, "w") do |f|
      file_contents.each do |line|
        f.write(line)
      end
      f.close
    end
  end
  def get_file_contents(file_to_read)
    clear_file_contents()
    input_file = File.expand_path(file_to_read)
    # Put file lines into an array
    if File.exist?(input_file)
      File.open(input_file, "r") do |f|
        while (in_file_line = f.gets)
          @file_contents.push(in_file_line)
        end
        f.close
      end
    end
  end
  def get_directory_contents_by_recursive_scan(directory_to_scan, filter_text)
    running = Progress.new
    @directory_contents.clear
    dirs = [directory_to_scan]
    for dir in dirs
      Find.find(dir) do |directory_item|
        running.indicate
        if FileTest.directory?(directory_item)
          if File.basename(directory_item)[0] == ?.
            Find.prune       # Don't look any further into this directory.
          else
            next
          end
        end
        if (directory_item.downcase.include?("#{filter_text.downcase}"))
          @directory_contents.push(directory_item)
        end
      end
    end
    @directory_contents.flatten!
  end
  def get_directory_contents(directory_to_scan, filter_text)
    expanded_dir = File.expand_path(directory_to_scan)
    running = Progress.new
    @directory_contents.clear
    dirs = [directory_to_scan]
    for dir in dirs
      Find.find(dir) do |directory_item|
        running.indicate
        if FileTest.directory?(directory_item)
          if File.expand_path(directory_item) != expanded_dir
            Find.prune       # Don't look into any subdirectories
          else
            next
          end
        end
        if (directory_item.include?("#{filter_text}"))
          @directory_contents.push(File.basename(directory_item))
        end
      end
    end
    @directory_contents.flatten!
  end
  def get_directory_contents_only_directories(directory_to_scan, filter_text)
    expanded_dir = File.expand_path(directory_to_scan)
    running = Progress.new
    @directory_contents.clear
    dirs = [directory_to_scan]
    for dir in dirs
      Find.find(dir) do |directory_item|
        running.indicate
        if FileTest.directory?(directory_item)
          if File.expand_path(directory_item) != expanded_dir
            if (directory_item.include?("#{filter_text}"))
              @directory_contents.push(File.expand_path(directory_item))
            end
            Find.prune       # Don't look into any subdirectories
          else
            next
          end
        end
      end
    end
    @directory_contents.flatten!
  end
  def get_directory_contents_files_and_directories(directory_to_scan, filter_text)
    expanded_dir = File.expand_path(directory_to_scan)
    running = Progress.new
    @directory_contents.clear
    dirs = [directory_to_scan]
    for dir in dirs
      Find.find(dir) do |directory_item|
        running.indicate
        if FileTest.directory?(directory_item)
          if File.expand_path(directory_item) != expanded_dir
            if (directory_item.include?("#{filter_text}"))
              @directory_contents.push(File.expand_path(directory_item))
            end
            Find.prune       # Don't look into any subdirectories
          else
            next
          end
        end
        if (directory_item.include?("#{filter_text}"))
          @directory_contents.push(File.basename(directory_item))
        end
      end
    end
    @directory_contents.flatten!
  end
  def create_directory_if_needed(directory_to_create)
    create_dir = directory_to_create.tr("\\","/")
    dir_items = create_dir.split('/')
    if dir_items.length > 1
      create_dir = "#{dir_items[0]}"
      for temp_index in (0..dir_items.length-2)
        create_dir = "#{create_dir}/#{dir_items[temp_index+1]}"
        Dir.mkdir(create_dir) if (!File.exist?(create_dir))
      end
    end
  end
  # copy file to a directory
  def copy_file_file(from_file, to_file)
    temp = "copy \"#{from_file.tr("/","\\")}\" \"#{to_file.tr("/","\\")}\" /y"
    copy_status = %x[#{temp}]
  end
  def get_unique_signature(file_and_path)
    file_signature = ""
    #file_signature += "#{File.basename(file_and_path)}"
    #file_signature += "_#{File.size(file_and_path)}"
    file_signature += "#{File.size(file_and_path)}"
    file_signature += "_#{File.mtime(file_and_path)}"
    file_signature.tr!(" ", "_")
    return file_signature
  end
  def get_directory_less(string, up_count)
    new_dir = ""
    temp_string = string 
    is_dir_backslash = temp_string.include?("\\")
    temp_string.tr!("\\", "/") if is_dir_backslash
    dir_items = string.split("/")
    last_index = (dir_items.length - 1) - up_count
    if last_index >= 0
      for curr_index in (0..last_index)
        new_dir += ((new_dir == "") ? "#{dir_items[curr_index]}" : "/#{dir_items[curr_index]}")
      end
    else
      new_dir = string
    end
    new_dir.tr!("/", "\\") if is_dir_backslash
    return new_dir
  end
  def set_variables_from_file(file_and_path)
  end
  def get_test_list
  end
  def clear_test_list()
    @tests_run_list.clear
  end
  def directory_contents()
    return @directory_contents
  end
  def file_contents()
    return @file_contents
  end
end

class VatfHelperUtilities
  def initialize
    @equipment = ""
    
    # This will be considered the Alpha side
    @vatf_server_ref = 'server1'
    
    # This will be considered the Beta side
    @vatf_dut_ref = 'dut1'
    
    @result = 0
    @is_debug = true
  end
  def clear_result()
    @result = 0
  end
  def set_debug_on()
    @is_debug = true
  end
  def set_debug_off()
    @is_debug = false
  end
  def set_common(equipment, vatf_server_ref, vatf_dut_ref)
    @equipment = equipment if (equipment != "")
    @vatf_server_ref = vatf_server_ref if (vatf_server_ref != "")
    @vatf_dut_ref = vatf_dut_ref if (vatf_dut_ref != "")
  end
  def ALPHA_SIDE()
    return true
  end
  def BETA_SIDE()
    return false
  end
  def bit_to_set(bit)
    return 1 << bit
  end
  def DONT_SET_ERROR_BIT()
    return 9999
  end
  def server_prompt_wait_workaround(equipment_ref, wait_message)
    if equipment_ref.include?("server")
      @equipment[equipment_ref].send_cmd("echo $?",/^0/,5) if (wait_message == "")
    end
  end
  def wait_for(is_alpha_side, wait_string, time_out_secs, error_bit_set)
    equipment_ref = (is_alpha_side ? @vatf_server_ref : @vatf_dut_ref)
    if @is_debug
      puts(" Sending (#{equipment_ref}) normal command: #\r\n")
      #puts("   Waiting for: #{wait_string}, for #{time_out_secs} seconds.\r\n")
    end
    @equipment[equipment_ref].send_cmd("#", /#{wait_string}/, 70000)
    if (@equipment[equipment_ref].timeout?)
      puts("     Command timed out.\r\n") if @is_debug
      @result |= bit_to_set(error_bit_set)
    end
  end
  def log_info(is_alpha_side, info_message)
    equipment_ref = (is_alpha_side ? @vatf_server_ref : @vatf_dut_ref)
    @equipment[equipment_ref].log_info(info_message)
  end
  def smart_send_cmd_wait(is_alpha_side, is_sudo, command_to_send, wait_message, error_bit_set, sleep_before_return, wait_secs)
    equipment_ref = (is_alpha_side ? @vatf_server_ref : @vatf_dut_ref)
    is_sudo_local = (is_alpha_side ? is_sudo : false)
    command_wait_message = (wait_message=="" ? @equipment[equipment_ref].prompt : "#{wait_message}")
    if @is_debug
      puts(" Sending (#{equipment_ref}) #{(is_sudo_local ? "sudo " : "normal ")}command#{(sleep_before_return!=0 ? " (wait: #{sleep_before_return}) " : "")}: #{command_to_send}\r\n")
      #puts("   Waiting for: #{command_wait_message}\r\n")
    end
    if (is_sudo_local)
      #@equipment[equipment_ref].send_sudo_cmd("#{command_to_send} 2>&1", /#{command_wait_message}/, wait_secs)
      @equipment[equipment_ref].send_sudo_cmd("#{command_to_send}", /#{command_wait_message}/, wait_secs)
      server_prompt_wait_workaround(equipment_ref, wait_message)
    else
      #@equipment[equipment_ref].send_cmd("#{command_to_send} 2>&1", /#{command_wait_message}/, wait_secs)
      @equipment[equipment_ref].send_cmd("#{command_to_send}", /#{command_wait_message}/, wait_secs)
      server_prompt_wait_workaround(equipment_ref, wait_message)
    end
    if ( (@equipment[equipment_ref].timeout?) and (error_bit_set != DONT_SET_ERROR_BIT()) )
      puts("     Command timed out.\r\n") if @is_debug
      @result |= bit_to_set(error_bit_set)
    end
    sleep(sleep_before_return) if (sleep_before_return > 0)
    return @equipment[equipment_ref].response
  end
  def smart_send_cmd(is_alpha_side, is_sudo, command_to_send, wait_message, error_bit_set, sleep_before_return)
    return smart_send_cmd_wait(is_alpha_side, is_sudo, command_to_send, wait_message, error_bit_set, sleep_before_return, 20)
  end 
  def result()
    return @result
  end
  def vatf_dut_ref()
    return @vatf_dut_ref
  end
  def vatf_server_ref()
    return @vatf_server_ref
  end
end

class LinuxHelperUtilities
  def initialize
    @vatf_helper = VatfHelperUtilities.new
    
    @equipment = ""
    @chmod_executeable = "777"
    @chmod_writeable = "646"
    @chmod_conf_normal = "644"
    @is_debug = false
    @sudo_cmd = true
    
    @error_bit = 9
    @result = 0
  end
  def clear_result()
    @result = 0
  end
  def result()
    return @result
  end
  def set_error_bit_to_set(error_bit)
    this_error_bit = 0
    min_range = 0
    max_range = 31
    this_error_bit = error_bit.to_i
    this_error_bit = ((this_error_bit <= min_range) ? min_range : this_error_bit)
    this_error_bit = ((this_error_bit >= max_range) ? max_range : this_error_bit)
    @error_bit = this_error_bit
  end
  def set_vatf_equipment(equipment)
    @vatf_helper.set_common(equipment, "", "")
    @equipment = equipment
  end
  def set_vatf_helper(vatf_helper)
    @vatf_helper = vatf_helper
  end
  def set_chmod_executeable(is_alpha_side, file_name_path)
    # Create common certification key
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "chmod #{@chmod_executeable} #{file_name_path}", "", @error_bit, 0)
  end
  def set_chmod_writeable(is_alpha_side, file_name_path)
    # Create common certification key
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "chmod #{@chmod_writeable} #{file_name_path}", "", @error_bit, 0)
  end
  def set_chmod_conf_normal(is_alpha_side, file_name_path)
    # Create common certification key
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "chmod #{@chmod_conf_normal} #{file_name_path}", "", @error_bit, 0)
  end
  def create_writeable_empty_file(is_alpha_side, file_name_path)
    # Create directory structure if needed
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "mkdir -p #{File.dirname(file_name_path)}", "", @error_bit, 0)
    # Create writeable file if it does not already exist
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "touch #{file_name_path}", "", @error_bit, 0)
    set_chmod_writeable(is_alpha_side, file_name_path)
  end
  def create_executeable_empty_file(is_alpha_side, file_name_path)
    # Create directory structure if needed
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "mkdir -p #{File.dirname(file_name_path)}", "", @error_bit, 0)
    # Create writeable file if it does not already exist
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "touch #{file_name_path}", "", @error_bit, 0)
    set_chmod_executeable(is_alpha_side, file_name_path)
  end
  def add_ip_address_to_interface(is_alpha_side, ip_address, interface)
    # Add ip address to interface
    # ip_address = ipv4 or ipv6 ip address
    # interface = eth0, eth1...
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ip addr add #{ip_address} dev #{interface}", "", @error_bit, 0)
  end
  def tftp_file(file, from_path, to_path, host, is_alpha_side)
    from_file = File.join(from_path, file)
    to_file = File.join(to_path, file)
    create_writeable_empty_file(is_alpha_side, to_file)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "tftp -g -r #{from_file} -l #{to_file} #{host}", "", @error_bit, 0)
  end
  def tftp_files(array_of_files, from_path, to_path, host, is_alpha_side)
    array_of_files.each do |file|
      tftp_file(file, from_path, to_path, host, is_alpha_side)
    end
  end
  def tftp_executable(file, from_path, to_path, host, is_alpha_side)
    from_file = File.join(from_path, file)
    to_file = File.join(to_path, file)
    create_executeable_empty_file(is_alpha_side, to_file)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "tftp -g -r #{from_file} -l #{to_file} #{host}", "", @error_bit, 0)
  end
  def tftp_executables(array_of_files, from_path, to_path, host, is_alpha_side)
    array_of_files.each do |file|
      tftp_executable(file, from_path, to_path, host, is_alpha_side)
    end
  end
  def copy_executable(file, from_path, to_path, is_alpha_side)
    from_file = File.join(from_path, file)
    to_file = File.join(to_path, file)
    create_executeable_empty_file(is_alpha_side, to_file)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cp #{from_file} #{to_file}", "", @error_bit, 0)
  end
  def copy_executables(array_of_files, from_path, to_path, is_alpha_side)
    array_of_files.each do |file|
      copy_executable(file, from_path, to_path, is_alpha_side)
    end
  end
  def copy_file(file, from_path, to_path, is_alpha_side)
    from_file = File.join(from_path, file)
    to_file = File.join(to_path, file)
    create_writeable_empty_file(is_alpha_side, to_file)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cp #{from_file} #{to_file}", "", @error_bit, 0)
  end
  def copy_files(array_of_files, from_path, to_path, is_alpha_side)
    array_of_files.each do |file|
      copy_file(file, from_path, to_path, is_alpha_side)
    end
  end
  def get_utc_time()
    # Get current PC time
    curr_time = Time.new
    # Get date tokens ([0]=date, [1]time, [2]utc_diff)
    date_items = curr_time.to_s.split(" ")
    # Get absolute UTC difference
    utc_delta = date_items[2].gsub("-", "").to_i
    # Get UTC hour difference from PC time
    utc_hours_diff = utc_delta / 100
    # Get UTC minute difference from PC time
    utc_mins_diff = utc_delta - (utc_hours_diff * 100)
    # Calculate total UTC difference from PC time
    utc_secs_diff = (utc_hours_diff * (60 * 60)) + (utc_mins_diff * (60))
    # Add or subtract hours/mins difference from PC time to get UTC time for EVM
    if (date_items[2].include?("-"))
      curr_time += utc_secs_diff
    else
      curr_time -= utc_secs_diff
    end
    return curr_time
  end
  def set_evm_date_time(is_alpha_side)
    if (!is_alpha_side)
      # Get current PC time adjusted for UTC
      curr_time = get_utc_time()
      date_items = curr_time.to_s.split(" ")
      set_time = "#{date_items[0]} #{date_items[1]}"
      puts(" curr time: #{set_time}\r\n") if @is_debug
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "date -s \"#{set_time}\"", "", @error_bit, 0)
    end
  end
  def chmod_writeable()
    return @chmod_writeable
  end
  def chmod_conf_normal()
    return @chmod_conf_normal
  end
end

class NashPalTestBenchVatf
  def initialize
    @lnx_helper = LinuxHelperUtilities.new
    @vatf_helper = VatfHelperUtilities.new
    
    # Need to get the @from_path from the directory the vatf uses to transfer the kernel and other files
    @from_path = "gtscmcsdk-systest/scmcsdk-2.0.0.11_cm_ubifs/miw/"
    @to_path = "/usr/bin/"
    @sudo_cmd = true
    @normal_cmd = false
    
    @result = 0
    @error_bit = 1
    @result_text = ""
  end
  def clear_results()
    @lnx_helper.clear_result()
    @vatf_helper.clear_result()
    @result = 0
    @result_text = ""
  end
  def RETURN_ON_FIRST_ERROR()
    return true
  end
  def CONTINUE_ON_ERROR()
    return false
  end
  def result()
    @result |= @vatf_helper.result()
    return @result
  end
  def result_text()
    return @result_text
  end
  def is_failed(is_alpha_side, function_name, error_message)
    location = (is_alpha_side ? "Alpha side" : "Beta side")
    @result_text += "(#{function_name}, #{location}): #{error_message}" if (result() != 0)
    # Merge all available results to @result and return true or false
    return ((result() != 0) ? true : false)
  end
  def set_error_bit_to_set(error_bit)
    this_error_bit = 0
    min_range = 0
    max_range = 31
    this_error_bit = error_bit.to_i
    this_error_bit = ((this_error_bit <= min_range) ? min_range : this_error_bit)
    this_error_bit = ((this_error_bit >= max_range) ? max_range : this_error_bit)
    @error_bit = this_error_bit
  end
  def set_helpers(lnx_helper, vatf_helper)
    @lnx_helper = lnx_helper
    @vatf_helper = vatf_helper
  end
  def set_paths(from_tftp_path, to_path)
    @from_path = from_tftp_path
    @to_path = to_path
  end
  def get_file_from_array(array_of_files, string)
    array_of_files.each do |file|
      return file if file.include?(string)
    end
    return ""
  end
  def transfer_files_to_evm(array_of_files, from_path, to_path, host)
    @lnx_helper.tftp_executables(array_of_files, from_path, to_path, host, @vatf_helper.BETA_SIDE())
  end
  def run_executable(array_of_files, pre_params, string, post_params, path, cmd_wait_string, is_alpha_side, wait_secs)
    file_to_run = get_file_from_array(array_of_files, string)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cd #{path}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#{pre_params} ./#{file_to_run} #{post_params}", cmd_wait_string, @error_bit, wait_secs)
  end
  def run_executable_on_arm(array_of_files, pre_params, string, post_params, path, wait_string, wait_secs)
    run_executable(array_of_files, pre_params, string, post_params, path, wait_string, @vatf_helper.BETA_SIDE(), wait_secs)
  end
  def run_executable_on_linux_pc(array_of_files, pre_params, string, post_params, path, wait_string, wait_secs)
    run_executable(array_of_files, pre_params, string, post_params, path, wait_string, @vatf_helper.ALPHA_SIDE(), wait_secs)
  end
  def run_router_and_miw_arm_executeables(array_of_files, path, is_ms5_or_greater)
    miw_wait = 2
    run_executable_on_arm(array_of_files, "", "msgrouter", "-n 3 -a 0x0c016000 -v &", path, "", 2)
    run_executable_on_arm(array_of_files, "", "boam", "&", path, "MW_msgQueueFind", miw_wait)
    run_executable_on_arm(array_of_files, "", "iubl", "&", path, "MW_msgQueueFind", miw_wait)
    if is_ms5_or_greater
      run_executable_on_arm(array_of_files, "", "pma", "&", path, "listening", miw_wait)
    end
    #exit
  end
  def run_DSP_executeables(test_secs)
    is_alpha_side = @vatf_helper.ALPHA_SIDE()
    dss_dir = "/home/gtscmcsdk-systest/ti/ccsv5/ccs_base/scripting/bin"
    load_ti_dir = "#{File.dirname(__FILE__)}/dsploadrun/loadti"
    ccxml_dir = "#{File.dirname(__FILE__)}/dsploadrun/ccxmls"
    dsp_files_dir = "/home/gtscmcsdk-systest/tempdown/temp_MS5_dsp_executeables"
    load_ti_parameters = ""
    execution_setup_time = 90 # Approximate maximum time it will take to get the test apps loaded and run. Actual time will vary from run to run. 
    #load_ti_parameters += "-gtl \"#{ccxml_dir}/evmtci6614.gel\""
    #load_ti_parameters += " -gftr \"Global_Default_Setup()\""
    dsp_test_milisecs = (test_secs.to_i + execution_setup_time) * 1000
    #load_ti_parameters += " -v -sfpc -t #{dsp_test_milisecs} -ctr 3"
    load_ti_parameters += " -v -sfpc -t #{dsp_test_milisecs} -ctr 4"
    load_ti_parameters += " -c \"#{ccxml_dir}/C6614_Mezzanine_511_33.ccxml\""
    load_ti_parameters += " \"#{dsp_files_dir}/ms5_core0.out\"+"
    load_ti_parameters += "\"#{dsp_files_dir}/ms5_core1.out\"+"
    load_ti_parameters += "\"#{dsp_files_dir}/ms5_core2.out\"+"
    load_ti_parameters += "\"#{dsp_files_dir}/ms5_core3.out\""
    #load_ti_parameters += " 2>&1"
    #load_ti_parameters += " &"
    cmd_wait_string = "core3.out"
    
    dsp_run_command = "export LOADTI_PATH=#{load_ti_dir} ; cd #{load_ti_dir} ; #{dss_dir}/dss.sh #{load_ti_dir}/main.js #{load_ti_parameters}"
    @vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), "DSP run command: #{dsp_run_command}")
    start_thread = true
    # Load DSP .out file using DSS
    if start_thread
      dsp_thread = Thread.new {
        #system "export LOADTI_PATH=#{load_ti_dir} ; cd #{load_ti_dir} ; #{dss_dir}/dss.sh #{load_ti_dir}/main.js #{load_ti_parameters}"
        system dsp_run_command
      }
      sleep(5)
      # Up the priority of the dss.sh task to make it faster
      task_name = "dss.sh"
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "renice -10 -p `ps -ef | grep #{task_name} | grep -v grep | awk '{print $2}'`", "", @vatf_helper.DONT_SET_ERROR_BIT(), 2, 2)
      # Up the priority of the java task associated with the dss.sh task to make it faster
      task_name = "DXPCOM"
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "renice -10 -p `ps -ef | grep #{task_name} | grep -v grep | awk '{print $2}'`", "", @vatf_helper.DONT_SET_ERROR_BIT(), 2, 2)
    else
      puts("\r\n\r\n Manually start DSP files...............\r\n\r\n")
    end
    # Wait for DSP communication message from ARM on EVM to continue
    @vatf_helper.smart_send_cmd_wait(@vatf_helper.BETA_SIDE(), @normal_cmd, "#", "0.0.0.0:22220", @error_bit, 2, 80)
    sleep(5)
    return dsp_thread
  end
  def run_femto_logger(evm_ip)
    is_alpha_side = @vatf_helper.ALPHA_SIDE()
    logger_dir = "/home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger"
    femto_logger = "#{logger_dir}/femto_logger.pl"
    parameters = "-v #{evm_ip} --port=22225"
    parameters += " --dir /home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger --logfile logger_out.txt"
    parameters += " 2>&1"
    cmd_wait_string = ""
    femto_thread = Thread.new {
      system "cd #{logger_dir} ; ./femto_logger.pl #{parameters}"
    }
    return femto_thread
  end
  def get_policy_id(equipment, direction_type)
    is_alpha_side = @vatf_helper.BETA_SIDE()
    get_index_command = "echo `ip -s xfrm policy | grep \"dir #{direction_type}\" | grep -v grep | awk '{print $6}'`"
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, get_index_command, "", @error_bit, 0)
    policy_index = equipment[@vatf_helper.vatf_dut_ref].response.split("\n")[2].to_i
    puts(" Policy Index (#{direction_type}): #{policy_index}\r\n")
    return policy_index
  end
  def run_snooper(array_of_files, path)
    is_alpha_side = @vatf_helper.BETA_SIDE()
    run_executable_on_arm(array_of_files, "source", "setup_snooper", "", path, "", 2)
    run_executable_on_arm(array_of_files, "", "ipsecsnooper", "", path, "", 2)
    sleep(5)
  end
  def run_nefpproxy(path)
    is_alpha_side = @vatf_helper.BETA_SIDE()
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cd #{path} ; ./netfpproxy.out -v -p /usr/lib/libnetfpproxy_plugin.so", "", @error_bit, 0)
    #run_executable_on_arm(array_of_files, "source", "setup_snooper", "", path, "", 2)
    #run_executable_on_arm(array_of_files, "", "ipsecsnooper", "", path, "", 2)
    sleep(5)
  end
  def run_echopkt(path, evm_ip, echopkt_log_file)
    is_alpha_side = @vatf_helper.ALPHA_SIDE()
    rx_port = "22238"
    tx_port = "22228"
    echopkt_run_command = "cd #{path} ; ./echoPkt.out #{evm_ip} #{rx_port} #{tx_port} > #{echopkt_log_file}"
    @vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), "echoPkt run command: #{echopkt_run_command}")
    echopkt_thread = Thread.new {
      #system "cd #{path} ; ./echoPkt.out #{evm_ip} #{rx_port} #{tx_port}"
      system echopkt_run_command
    }
    sleep(2)
    return echopkt_thread
  end
  def run_offloader(array_of_files, path, policy_index_in, policy_index_out, is_fatal)
    is_alpha_side = @vatf_helper.BETA_SIDE()
    error_text = ""
    run_executable_on_arm(array_of_files, "source", "setup_shell", "", path, "", 2)
    run_executable_on_arm(array_of_files, "", "ipsecmgr_cmd", "",path, "IPSECMGR-CFG>", 2)
    sleep(2)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "offload_sp --sp_id #{policy_index_in}", "SUCCESS", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#", "SUCCESS", @error_bit, 0) if (result() == 0)
    if (result() != 0)
      @result_text += " Offload command failed for policy index : #{policy_index_in}\r\n"
      return if is_fatal
    end
    sleep(2)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "offload_sp --sp_id #{policy_index_out}", "SUCCESS", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#", "SUCCESS", @error_bit, 0) if (result() == 0)
    if (result() != 0)
      @result_text += " Offload command failed for policy index : #{policy_index_out}\r\n"
      return if is_fatal
    end
    sleep(5)
  end
  def run_offloader_new(array_of_files, path, policy_index_in, policy_index_out, is_fatal)
    is_alpha_side = @vatf_helper.BETA_SIDE()
    error_text = ""
    array_of_files.push("cmd_shell.out")
    run_executable_on_arm(array_of_files, "", "cmd_shell", "", path, "NETFP-PROXY>", 2)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "offload_sp --sp_id #{policy_index_in}", "SUCCESS", @error_bit, 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#", "SUCCESS", @error_bit, 0) if (result() == 0)
    if (result() != 0)
      @result_text += " Offload command failed for policy index : #{policy_index_in}\r\n"
      return if is_fatal
    end
    #sleep(2)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "offload_sp --sp_id #{policy_index_out}", "SUCCESS", @error_bit, 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#", "SUCCESS", @error_bit, 0) if (result() == 0)
    if (result() != 0)
      @result_text += " Offload command failed for policy index : #{policy_index_out}\r\n"
      return if is_fatal
    end
    sleep(5)
  end
  def kill_task(is_alpha_side, task_name)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "kill `ps -ef | grep #{task_name} | grep -v grep | awk '{print $2}'`", "", @error_bit, 0)
  end
  def is_same_or_one_different(count_1, count_2)
    is_good = false
    if (count_1 == count_2)
      is_good = true
    else
      if (count_1 == count_2 + 1) or (count_2 == count_1 + 1)
        is_good = true
      end
    end
    return is_good
  end
  def validate_results(file_to_check, is_ms5_or_greater)
    puts(" File to check: #{file_to_check}\r\n")
    fileUtils = FileUtilities.new
    stat_types = Array.new
    stat_counts = Array.new
    stat_holder_array = Array.new
    
    @vatf_helper.smart_send_cmd(@vatf_helper.ALPHA_SIDE(), @normal_cmd, "cat #{file_to_check}", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), " ")
    
    stat_types = ["DSP - BOAM:", "DSP - IUBL:", "NETFP:", "core0:", "core1:", "core2:", "core3:"]
    stat_counts = ["recvCnt:", "sentCnt:", "recvLoss:", "wrong payload:", "not sent:"]
    st_index = 0
    sc_index = 0
    is_passed = true
    temp_result_text = ""
    
    # Add arrays for all stat types needed
    st_index = 0
    stat_types.each do |st|
      stat_holder_array[st_index] = Array.new
      st_index += 1
    end
    
    # Get contents of log file
    fileUtils.get_file_contents(file_to_check)
    
    # Gather statistics from file
    fileUtils.file_contents.each do |fileitem|
      #puts(" File line: #{fileitem}\r\n")
      #@vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), fileitem)
      file_line = fileitem.downcase
      st_index = 0
      stat_types.each do |st|
        break if (file_line.include?(st.downcase))
        st_index += 1
      end
      #puts(" st_index: #{st_index}\r\n")
      if (file_line.length > 0)
        # Only deal with lines that have recvCnt in them
        if (file_line.include?("recvcnt:"))
          # Isolate only the relevant part of the line
          file_line = file_line.split("recvcnt:")[1]
          # Remove all spaces from line
          file_line.gsub!(" ", "")
          # Remove count headers from line. At this point counts will be accessed by position as shown in the stat_counts array.
          stat_counts.each do |sc|
            file_line.gsub!(sc.downcase.gsub(" ",""), "")
          end
          #puts(" File line: #{file_line}\r\n")
          # Isolate each count
          count_items = file_line.split(",")
          # Place counts into the proper array
          sc_index = 0
          # Since the femto logger file could have incomplete stats at the end of the file make sure that the statistics are complete before saving the counts..
          if (count_items.length == stat_counts.length)
            count_items.each do |citem|
              #puts(" st_index: #{st_index}, sc_index: #{sc_index}, citem: #{citem}\r\n")
              #stat_holder_array[st_index] = [stat_holder_array[st_index]] if stat_holder_array[st_index].kind_of?(String)
              if (stat_holder_array[st_index] == nil) or (stat_holder_array[st_index].length != stat_counts.length)
                # Add stat count to array
                stat_holder_array[st_index].push(citem.to_i)
              else
                # Modify existing stat count
                stat_holder_array[st_index][sc_index]=citem.to_i
              end
              sc_index += 1
            end
          end
        end
      end
    end
    
    st_index = 0
    this_passed = true
    temp_result_text += " Log Ending Statistics: \r\n"
    stat_types.each do |stat_type|
      temp_text = ""
      temp_text += "  #{stat_type}\r\n"
      temp_text += "  "
      sc_index = 0
      r_count = 0
      stat_counts.each do |stat_count|
        temp_stat_count = stat_holder_array[st_index][sc_index].to_i
        temp_text += " #{stat_count} #{temp_stat_count}#{(sc_index < stat_counts.length-1 ? "," : "")}"
        case sc_index
          when 0
            if is_ms5_or_greater
              # Make sure that the recvCnt is not zero. Core2 does not do any tests so it can be zero for MS5 and greater
              if ( (temp_stat_count == 0) and !stat_type.include?(stat_types[5]) )
                this_passed = false
              end
            else
              # Make sure that the recvCnt is not zero
              if (temp_stat_count == 0)
                this_passed = false
              end
            end
            r_count = temp_stat_count
          when 1
            # Since counts are done on the fly there can easily be a case where one count lags the other by 1, but no greater than 1
            this_passed = (is_same_or_one_different(temp_stat_count, r_count) ? this_passed : false)
            #if ( stat_type.include?(stat_types[0]) or stat_type.include?(stat_types[1]) )
            #  # Make sure sendCnt is one less than the recvCnt
            #  this_passed = false if (temp_stat_count != (r_count + 1))
            #else
            #  # Make sure sendCnt is equal to the recvCnt
            #  this_passed = false if (temp_stat_count != r_count )
            #end
          else
            # Make sure all other counts are zero
            this_passed = false if (temp_stat_count != 0)
        end
        sc_index += 1
      end
      if (!this_passed)
        temp_text = "##-FAIL-##  " + temp_text + "  ##-FAIL-##"
        is_passed = false
        this_passed = true
      end
      temp_result_text += temp_text
      temp_result_text += "\r\n"
      st_index += 1
    end
    puts(temp_result_text)
    @result_text += temp_result_text.gsub(":\r\n", ":")
    @result |= @vatf_helper.bit_to_set(@error_bit) if (!is_passed)
  end
  def kill_dss_sh(dsp_thread)
    dss_sh_base_process_id = "LOADTI_PATH"
    dss_sh_java_process_id = "DXPCOM.RUNTIME"
    
    Thread.kill(dsp_thread)
    dsp_thread.exit
    kill_task(@vatf_helper.ALPHA_SIDE(), dss_sh_base_process_id)
    kill_task(@vatf_helper.ALPHA_SIDE(), dss_sh_java_process_id)
    sleep(10)
  end
  def kill_femto_logger(femto_thread)
    femto_logger_process_id = "femto_logger"
    
    Thread.kill(femto_thread)
    femto_thread.exit
    kill_task(@vatf_helper.ALPHA_SIDE(), femto_logger_process_id)
  end
  def kill_echopkt(echopkt_thread)
    echopkt_process_id = "echoPkt"
    
    Thread.kill(echopkt_thread)
    echopkt_thread.exit
    kill_task(@vatf_helper.ALPHA_SIDE(), echopkt_process_id)
  end
  def info_header(planned_run_secs, actual_run_secs, is_pass_through)
    @result_text += "Planned Run Seconds: #{planned_run_secs}\r\n"
    @result_text += "Actual Run Seconds: #{actual_run_secs}\r\n"
    @result_text += "IPSEC Connection: #{(is_pass_through ? "Pass-through" : "IPSEC tunnel")}\r\n"
    @result_text += ".\r\n"
  end
  def set_static_arps()
    @vatf_helper.smart_send_cmd(@vatf_helper.ALPHA_SIDE(), @sudo_cmd, "arp -s 192.168.1.51 00:18:31:7E:3E:41", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(@vatf_helper.BETA_SIDE(), @normal_cmd, "arp -s 192.168.1.102 00:04:23:e0:44:56", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
  end
  def get_route_xfrm_info(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "netstat -rn", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route -n", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "arp -a", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    if !is_alpha_side
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /proc/net/xfrm_stat", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    end
  end
  def get_net_stats(is_alpha_side)
    if !is_alpha_side
      # On EVM get out of the cmd_shell
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "exit", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    end
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "netstat -rn", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route -n", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "arp -a", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    get_route_xfrm_info(is_alpha_side)
    if !is_alpha_side
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /var/log/netfp_proxy.log", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
      #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /proc/net/xfrm_stat", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    end
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /proc/sys/net/ipv4/route/gc_timeout", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ip -s xfrm policy", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ip -s xfrm state", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec status", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec statusall", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
  end
  def run_nash_pal_test_bench(equipment, test_secs, is_pass_through, ipsecVatf)
    array_of_arm_files = Array.new
    @vatf_helper.set_common(equipment, "", "")
    @lnx_helper.set_vatf_equipment(equipment)
    policy_index_in = 0
    policy_index_out = 0
    is_pass = false
    #is_run_executables = true
    is_run_executables = true
    is_ms5_or_greater = true
    scripts_root = File.dirname(__FILE__)
    start_time = Time.now
    echopkt_log_file = "~/tempdown/echoPkt.log"
    fatal_error = false

    clear_results()
    
    #set_static_arps()
    
    # Get the Server IP (Linux PC) and EVM IP addresses for transferring the executables from the Linux PC to the EVM
    server_ip = equipment[@vatf_helper.vatf_server_ref].telnet_ip
    dut_ip = equipment[@vatf_helper.vatf_dut_ref].telnet_ip

    # Set the trigger phrases to be used for determining if the test is running properly
    bad_dsp_arm_communication_phrase = "size: 100,"
    dsp_started_phrase = "BOAM com test"
    bad_recv_count_phrase = "recvCnt: 0,"
    
    femto_logger_log_file = "/home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger/logger_out.txt"
    # The next two lines are debug code. Remove when code is working.
    #validate_results(femto_logger_log_file, is_ms5_or_greater)
    #return
    
    # Set files to be used transferred and used on ARM
    array_of_arm_files.push("miw_utest_iubl")
    array_of_arm_files.push("miw_utest_boam")
    if is_ms5_or_greater
      array_of_arm_files.push("miw_utest_pma")
      transfer_files_to_evm(array_of_arm_files, @from_path, @to_path, server_ip)
      # This file will not be transfered since it is already on the file system in MS5 or greater, but it needs to be used
      array_of_arm_files.push("msgrouter.out")
    else
      array_of_arm_files.push("msgrouter.out")
      array_of_arm_files.push("setup_snooper_env.sh")
      array_of_arm_files.push("ipsecsnooper.out")
      array_of_arm_files.push("setup_shell_env.sh")
      array_of_arm_files.push("ipsecmgr_cmd_shell.out")
      transfer_files_to_evm(array_of_arm_files, @from_path, @to_path, server_ip)
    end
    
    connection_type = (is_pass_through ? ipsecVatf.PASS_THROUGH : ipsecVatf.IPSEC_CONN)
    ipsecVatf.ipsec_typical_start(ipsecVatf.IPV4, connection_type)
    @result |= ipsecVatf.result

    # Start logging the DUT's console output for the entire test run
    Thread.new {
      evm_status = equipment[@vatf_helper.vatf_dut_ref].read_for(test_secs + 120)
    }
    
    # Get policy IDs from IPSEC connection and use offload
    policy_index_in = get_policy_id(equipment, "in")
    policy_index_out = get_policy_id(equipment, "out")
        
    if (is_run_executables)
      run_router_and_miw_arm_executeables(array_of_arm_files, @to_path, is_ms5_or_greater)
      sleep(5)
      dsp_thread = run_DSP_executeables(test_secs)
      # Check to see if the DSP and ARM are communicating with each other.
      temp_result = @vatf_helper.smart_send_cmd(@vatf_helper.BETA_SIDE(), @normal_cmd, "#", bad_dsp_arm_communication_phrase, @vatf_helper.DONT_SET_ERROR_BIT(), 0)
      if temp_result.include?(bad_dsp_arm_communication_phrase) or !temp_result.include?(dsp_started_phrase)
        # Test has failed so kill the DSP thread and cut the test short.
        temp_message = "\r\n\r\n ERROR: DSP <-> ARM communication is NOT working.\r\n\r\n\r\n"
        puts(temp_message)
        @result_text += temp_message
        @result |= @vatf_helper.bit_to_set(@error_bit)
        kill_dss_sh(dsp_thread) if temp_result.include?(dsp_started_phrase)
      else
        temp_message = "\r\n\r\n SUCCESS: DSP <-> ARM communication is working!\r\n\r\n\r\n"
        puts(temp_message)
        @vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), temp_message)
        
        echopkt_thread = run_echopkt("#{File.join(scripts_root,"helper_files")}", dut_ip, echopkt_log_file)
        #run_snooper(array_of_arm_files, @to_path)
        run_nefpproxy("/usr/bin/")
        get_route_xfrm_info(@vatf_helper.BETA_SIDE())
        get_route_xfrm_info(@vatf_helper.ALPHA_SIDE())
        #run_offloader(array_of_arm_files, @to_path, policy_index_in, policy_index_out, RETURN_ON_FIRST_ERROR)
        if is_ms5_or_greater
          run_offloader_new(array_of_arm_files, @to_path, policy_index_in, policy_index_out, CONTINUE_ON_ERROR())
          sleep(30)
        else
          run_offloader(array_of_arm_files, @to_path, policy_index_in, policy_index_out, CONTINUE_ON_ERROR())
        end
        
        # Start test timer
        start_time = Time.now
        
        if !fatal_error
          temp_result = `cat #{echopkt_log_file}`
          #temp_result = @vatf_helper.smart_send_cmd_wait(@vatf_helper.ALPHA_SIDE(), @normal_cmd, "cat #{echopkt_log_file}", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 20)
          puts("\r\n cat result: #{temp_result}\r\n")
          if temp_result.downcase.include?("transmitted successfully")
            temp_message = "\r\n\r\n SUCCESS: echoPkt is working!\r\n\r\n\r\n"
            puts(temp_message)
          else
            fatal_error = true
          end
          temp_result = ""
        end
        
        # Start femto logger.
        femto_thread = run_femto_logger(dut_ip)
        sleep(10)

        #if !fatal_error
        #  # Check to see if there are any zero recvCnts.
        #  temp_result = `cat #{femto_logger_log_file}`
        #  #temp_result = @vatf_helper.smart_send_cmd_wait(@vatf_helper.ALPHA_SIDE(), @normal_cmd, "#", bad_recv_count_phrase, @vatf_helper.DONT_SET_ERROR_BIT(), 0, 30)
        #  puts("\r\n zero recvCnts check result: #{temp_message}\r\n")
        #  if temp_result.include?(bad_recv_count_phrase)
        #    fatal_error = true
        #  else
        #    temp_message = "\r\n\r\n SUCCESS: femto logger is working!\r\n\r\n\r\n"
        #    puts(temp_message)
        #  end
        #  temp_result = ""
        #end
        
        if fatal_error
          # If here there is a recvCnt that is zero and the test has already failed so cut the test short.
          @result |= @vatf_helper.bit_to_set(@error_bit)
          kill_dss_sh(dsp_thread)
          kill_femto_logger(femto_thread)
          kill_echopkt(echopkt_thread)
        else
          # Need progress check here so that test does not run for hours if test has already failed
          bogus_phrase = "not going to find this phrase 7777"
          verify_secs = 60
          count_reps = test_secs / verify_secs
          count_reps = 1 if (count_reps <= 0)
          fail_out = false
          #(0..count_reps).each do |count_index|
          #  puts(" Verification Count Down: #{count_reps - count_index}\r\n")
          #  temp_result = @vatf_helper.smart_send_cmd_wait(@vatf_helper.ALPHA_SIDE(), @normal_cmd, "#", bogus_phrase, @vatf_helper.DONT_SET_ERROR_BIT(), 0, verify_secs)
          #  ##if temp_result.include?(bad_recv_count_phrase)
          #  @vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), "\r\n\r\nVerify Check String (#{count_reps - count_index}):\r\n \"#{temp_result.to_s}\"\r\n\r\n")
          #  if fail_out
          #    break
          #  end
          #end
          
          if fail_out
            kill_dss_sh(dsp_thread)
          else
            # If here then everything is going well so wait for the DSP thread to finish and then stop the femto logger and then validate the femto logger result file to determine test pass or fail.
            dsp_thread.join
            while dsp_thread.alive?
              sleep(1)
              puts(" Waiting on dsp thread to finish\r\n")
            end
          end
          stop_time = Time.now
          kill_femto_logger(femto_thread)
          kill_echopkt(echopkt_thread)
          info_header(test_secs, (stop_time.to_i - start_time.to_i), is_pass_through)
          validate_results(femto_logger_log_file, is_ms5_or_greater)
        end
      end
    else
      run_router_and_miw_arm_executeables(array_of_arm_files, @to_path, is_ms5_or_greater)
    end
    get_net_stats(@vatf_helper.BETA_SIDE())
    get_net_stats(@vatf_helper.ALPHA_SIDE())
    #@vatf_helper.smart_send_cmd_wait(@vatf_helper.ALPHA_SIDE(), @normal_cmd, "cat #{echopkt_log_file}", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 75)
    puts(" Nash PAL test bench finished\n")
  end
end

class IpsecUtilitiesVatf
  # This class holds ipsec utilities to be used with the vatf.
  def initialize
    @lnx_helper = LinuxHelperUtilities.new
    @vatf_helper = VatfHelperUtilities.new
    
    # Default settings for Alpha and Beta side certificates and ipsec.conf files. The alpha side is considered the Linux PC. The beta side is considered the EVM.
    # Dynamic variables with default settings
    @alpha_side_ss_major_version = "4"
    @beta_side_ss_major_version = "4"
    @is_alpha_side_fqdn = true
    @is_beta_side_fqdn = true
    @alpha_side_ref = "Alpha"
    @beta_side_ref = "Beta"
    @alpha_side_ip = ""
    @beta_side_ip = ""
    @server_ipsec_tftp_path = ""
    @alpha_side_ca_key_file = "/etc/ipsec.d/private/caKey.der"
    @beta_side_ca_key_file = "/etc/ipsec.d/private/caKey.der"
    @alpha_side_key_file = "/etc/ipsec.d/private/alphaKey.der"
    @beta_side_key_file = "/etc/ipsec.d/private/betaKey.der"
    @alpha_side_ca_cert_file = "/etc/ipsec.d/cacerts/caCert.der"
    @beta_side_ca_cert_file = "/etc/ipsec.d/cacerts/caCert.der"
    @alpha_side_cert_file = "/etc/ipsec.d/certs/alphaCert.der"
    @beta_side_cert_file = "/etc/ipsec.d/certs/betaCert.der"
    @alpha_side_ip_cert_file = "/etc/ipsec.d/certs/alphaCertIP.der"
    @beta_side_ip_cert_file = "/etc/ipsec.d/certs/betaCertIP.der"
    @alpha_side_temp_ca_key_file = "/etc/caKey.der"
    @beta_side_temp_ca_key_file = "/etc/caKey.der"
    @alpha_side_temp_key_file = "/etc/alphaKey.der"
    @beta_side_temp_key_file = "/etc/betaKey.der"
    @alpha_side_temp_file = "/etc/temp.der"
    @beta_side_temp_file = "/etc/temp.der"
    @alpha_side_net_name = "alpha.test.org"
    @beta_side_net_name = "beta.test.org"
    @alpha_side_ipv6 = "2000::1"
    @beta_side_ipv6 = "2000::3"
    @alpha_side_ipsec_conf_file = "/etc/ipsec.conf"
    @beta_side_ipsec_conf_file = "/etc/ipsec.conf"
    @alpha_side_ipsec_secrets_file = "/etc/ipsec.secrets"
    @beta_side_ipsec_secrets_file = "/etc/ipsec.secrets"
    @ipsec_conf_template_file_name = "ipsec_conf_template.txt"
    @default_rekey_lifetime = "48h"
    @vatf_dut_ref = 'dut1'
    @vatf_server_ref = 'server1'
    @ipsec_conf_save_name = "ipsec_conf.save"
    @equipment = ""
    @is_gen_on_alpha_only = true
    @result = 0
    @error_bit = 0
    @result_text = ""
    # Static variable settings
    @sudo_cmd = true
    @normal_cmd = false
  end
  def default_rekey_lifetime()
    return @default_rekey_lifetime
  end
  def result()
    @result |= @vatf_helper.result
    return @result
  end
  def result_text
    @result_text
  end
  def clear_results()
    @lnx_helper.clear_result()
    @vatf_helper.clear_result()
    @result = 0
    @result_text = ""
  end
  def alpha_side_gen_all_on()
    @is_gen_on_alpha_only = true
  end
  def alpha_side_gen_all_off()
    @is_gen_on_alpha_only = false
  end
  def ALPHA_SIDE()
    return true
  end
  def BETA_SIDE()
    return false
  end
  def IPV4()
    return true
  end
  def IPV6()
    return false
  end
  def FQDN_TUNNEL()
    return true
  end
  def IP_TUNNEL()
    return false
  end
  def PASS_THROUGH()
    return true
  end
  def IPSEC_CONN()
    return false
  end
  def is_failed(is_alpha_side, function_name, error_message)
    location = (is_alpha_side ? "Alpha side" : "Beta side")
    @result_text += "(#{function_name}, #{location}): #{error_message}" if (result() != 0)
    # Merge all available results to @result and return true or false
    return ((result() != 0) ? true : false)
  end
  def set_error_bit_to_set(error_bit)
    this_error_bit = 0
    min_range = 0
    max_range = 31
    this_error_bit = error_bit.to_i
    this_error_bit = ((this_error_bit <= min_range) ? min_range : this_error_bit)
    this_error_bit = ((this_error_bit >= max_range) ? max_range : this_error_bit)
    @error_bit = this_error_bit
  end
  def display_settings()
    puts("IpsecUtilitiesVatf variable settings:\r\n")
    puts("  Dynamic:\r\n")
    puts("    @server_ipsec_tftp_path       : #{@server_ipsec_tftp_path}\r\n")
    puts("    @alpha_side_ss_major_version  : #{@alpha_side_ss_major_version}\r\n")
    puts("    @beta_side_ss_major_version   : #{@beta_side_ss_major_version}\r\n")
    puts("    @is_alpha_side_fqdn           : #{@is_alpha_side_fqdn ? "FQDN" : "IP"} Tunnel\r\n")
    puts("    @is_beta_side_fqdn            : #{@is_beta_side_fqdn ? "FQDN" : "IP"} Tunnel\r\n")
    puts("    @alpha_side_ref               : #{@alpha_side_ref}\r\n")
    puts("    @beta_side_ref                : #{@beta_side_ref}\r\n")
    puts("    @alpha_side_ip                : #{@alpha_side_ip}\r\n")
    puts("    @beta_side_ip                 : #{@beta_side_ip}\r\n")
    puts("    @alpha_side_ca_key_file       : #{@alpha_side_ca_key_file}\r\n")
    puts("    @beta_side_ca_key_file        : #{@beta_side_ca_key_file}\r\n")
    puts("    @alpha_side_key_file          : #{@alpha_side_key_file}\r\n")
    puts("    @beta_side_key_file           : #{@beta_side_key_file}\r\n")
    puts("    @alpha_side_ca_cert_file      : #{@alpha_side_ca_cert_file}\r\n")
    puts("    @beta_side_ca_cert_file       : #{@beta_side_ca_cert_file}\r\n")
    puts("    @alpha_side_cert_file         : #{@alpha_side_cert_file}\r\n")
    puts("    @beta_side_cert_file          : #{@beta_side_cert_file}\r\n")
    puts("    @alpha_side_temp_file         : #{@alpha_side_temp_file}\r\n")
    puts("    @beta_side_temp_file          : #{@beta_side_temp_file}\r\n")
    puts("    @alpha_side_temp_ca_key_file  : #{@alpha_side_temp_ca_key_file}\r\n")
    puts("    @beta_side_temp_ca_key_file   : #{@beta_side_temp_ca_key_file}\r\n")
    puts("    @alpha_side_temp_key_file     : #{@alpha_side_temp_key_file}\r\n")
    puts("    @beta_side_temp_key_file      : #{@beta_side_temp_key_file}\r\n")
    puts("    @alpha_side_net_name          : #{@alpha_side_net_name}\r\n")
    puts("    @beta_side_net_name           : #{@beta_side_net_name}\r\n")
    puts("    @alpha_side_ipv6              : #{@alpha_side_ipv6}\r\n")
    puts("    @beta_side_ipv6               : #{@beta_side_ipv6}\r\n")
    puts("    @alpha_side_ipsec_conf_file   : #{@alpha_side_ipsec_conf_file}\r\n")
    puts("    @beta_side_ipsec_conf_file    : #{@beta_side_ipsec_conf_file}\r\n")
    puts("    @ipsec_conf_template_file_name: #{@ipsec_conf_template_file_name}\r\n")
    puts("    @default_rekey_lifetime       : #{@default_rekey_lifetime}\r\n")
    puts("    @vatf_dut_ref                 : #{@vatf_dut_ref}\r\n")
    puts("    @vatf_server_ref              : #{@vatf_server_ref}\r\n")
    puts("    @ipsec_conf_save_name         : #{@ipsec_conf_save_name}\r\n")
    puts("    @equipment                    : #{@equipment!="" ? "(value is set)" : "(value not set)"}\r\n")
    puts("    @result                       : #{@result}\r\n")
    puts("    @is_gen_on_alpha_only         : #{@is_gen_on_alpha_only ? "All certificates & keys are generated on alpha side" : "Certificates & keys are generated on each side"}\r\n")
  end
  def set_alpha_cert(as_ip, as_is_fqdn, as_ss_major_ver, as_ref, as_ca_key_file, as_key_file, as_ca_cert_file, as_cert_file, as_ip_cert_file, as_net_name, as_ipv6, as_ipsec_conf)
    @alpha_side_ip = as_ip if (as_ip != "")
    @is_alpha_side_fqdn = as_is_fqdn if (as_is_fqdn != "")
    @alpha_side_ss_major_version = as_ss_major_ver if (as_ss_major_ver != "")
    @alpha_side_ref = as_ref if (as_ref != "")
    @alpha_side_ca_key_file = as_ca_key_file if (as_ca_key_file != "")
    @alpha_side_key_file = as_key_file if (as_key_file != "")
    @alpha_side_ca_cert_file = as_ca_cert_file if (as_ca_cert_file != "")
    @alpha_side_cert_file = as_cert_file if (as_cert_file != "")
    @alpha_side_ip_cert_file = as_ip_cert_file if (as_ip_cert_file != "")
    @alpha_side_net_name = as_net_name if (as_net_name != "")
    @alpha_side_ipv6 = as_ipv6 if (as_ipv6 != "")
    @alpha_side_ipsec_conf_file = as_ipsec_conf if (as_ipsec_conf != "")
  end
  def get_file_tftp_server_file_name_path(is_alpha_side, file_name_path)
    # Add alpha or beta path to tftp server ipsec path base
    tftp_file_name_path = File.join(@server_ipsec_tftp_path, (is_alpha_side ? "a" : "b"))
    # Add file name to modified tftp path
    tftp_file_name_path = File.join(tftp_file_name_path, File.basename(file_name_path))
    return tftp_file_name_path
  end
  def set_beta_cert(bs_ip, bs_is_fqdn, bs_ss_major_ver, bs_ref, bs_ca_key_file, bs_key_file, bs_ca_cert_file, bs_cert_file, bs_ip_cert_file, bs_net_name, bs_ipv6, bs_ipsec_conf)
    @beta_side_ip = bs_ip if (bs_ip != "")
    @is_beta_side_fqdn = bs_is_fqdn if (bs_is_fqdn != "")
    @beta_side_ss_major_version = bs_ss_major_ver if (bs_ss_major_ver != "")
    @beta_side_ref = bs_ref if (bs_ref != "")
    @beta_side_ca_key_file = bs_ca_key_file if (bs_ca_key_file != "")
    @beta_side_key_file = bs_key_file if (bs_key_file != "")
    @beta_side_ca_cert_file = bs_ca_cert_file if (bs_ca_cert_file != "")
    @beta_side_cert_file = bs_cert_file if (bs_cert_file != "")
    @beta_side_ip_cert_file = bs_ip_cert_file if (bs_ip_cert_file != "")
    @beta_side_net_name = bs_net_name if (bs_net_name != "")
    @beta_side_ipv6 = bs_ipv6 if (bs_ipv6 != "")
    @beta_side_ipsec_conf_file = bs_ipsec_conf if (bs_ipsec_conf != "")
  end
  def set_alpha_temp_locations(as_temp_ca_key_file, as_temp_key_file, as_temp_file)
    @alpha_side_temp_ca_key_file = as_temp_ca_key_file if (as_temp_ca_key_file != "")
    @alpha_side_temp_key_file = as_temp_key_file if (as_temp_key_file != "")
    @alpha_side_temp_file = as_temp_file if (as_temp_file != "")
  end
  def set_beta_temp_locations(bs_temp_ca_key_file, bs_temp_key_file, bs_temp_file)
    @beta_side_temp_ca_key_file = bs_temp_ca_key_file if (bs_temp_ca_key_file != "")
    @beta_side_temp_key_file = bs_temp_key_file if (bs_temp_key_file != "")
    @beta_side_temp_file = bs_temp_file if (bs_temp_file != "")
  end
  def set_helper_common(vatf_server_ref, vatf_dut_ref, equipment)
    @vatf_dut_ref = vatf_dut_ref if (vatf_dut_ref != "")
    @vatf_server_ref = vatf_server_ref if (vatf_server_ref != "")
    @equipment = equipment if (equipment != "")
    @vatf_helper.set_common(@equipment, @vatf_server_ref, @vatf_dut_ref)
    @lnx_helper.set_vatf_equipment(@equipment)
  end
  def set_common(ipsec_conf_template_file_name, default_rekey_lifetime, ipsec_conf_save_name)
    @ipsec_conf_template_file_name = ipsec_conf_template_file_name if (ipsec_conf_template_file_name != "")
    @default_rekey_lifetime = default_rekey_lifetime if (default_rekey_lifetime != "")
    @ipsec_conf_save_name = ipsec_conf_save_name if (ipsec_conf_save_name != "")
  end
  def server_prompt_wait_workaround(equipment_ref, wait_message)
    if equipment_ref.include?("server")
      @equipment[equipment_ref].send_cmd("echo $?",/^0/,5) if (wait_message == "")
    end
  end
  def clean_all_key_and_certificate_file(is_alpha_side)
    send_sudo = true
    is_alpha_side_local = (@is_gen_on_alpha_only ? ALPHA_SIDE() : is_alpha_side)
    if (is_alpha_side)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_ip_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_ca_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_temp_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_temp_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_temp_key_file}", "", @error_bit, 0)
      
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_key_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_ca_key_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_cert_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_ip_cert_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_ca_cert_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_temp_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_temp_ca_key_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_temp_key_file)}", "", @error_bit, 0)
    else
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_ip_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_ca_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_temp_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_temp_key_file}", "", @error_bit, 0)
      
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_key_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_ca_key_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_cert_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_ip_cert_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_ca_cert_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_temp_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_temp_ca_key_file)}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_temp_key_file)}", "", @error_bit, 0)
    end
  end
  def ipsec_stop(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec stop", "", @vatf_helper.DONT_SET_ERROR_BIT(), 5)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec statusall", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
  end
  def ipsec_start(is_alpha_side)
    function_name = "ipsec_start"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    # Display ipsec.conf and ipsec.secrets file contests and the ipsec.conf template file name
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /etc/ipsec.conf", "", @vatf_helper.DONT_SET_ERROR_BIT(), 2)
    @vatf_helper.log_info(is_alpha_side, "\r\n\r\n")
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /etc/ipsec.secrets", "", @vatf_helper.DONT_SET_ERROR_BIT(), 2)
    @vatf_helper.log_info(is_alpha_side, "\r\n\r\n")
    @vatf_helper.log_info(is_alpha_side, "ipsec.conf template: #{File.dirname(__FILE__)}/#{@ipsec_conf_template_file_name}\r\n\r\n")
    # Display ipsec.conf template file to user while test is running
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "echo", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "echo '## .conf template:  #{File.basename(@ipsec_conf_template_file_name)}'", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "echo", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    
    # Start IPSEC and list the certs
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec start", "", @error_bit, 5)
    return if (is_failed(is_alpha_side, function_name, " IPSEC: did not start properly.\r\n"))
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec listcerts", "authkey:", @error_bit, 0)
    return if (is_failed(is_alpha_side, function_name, " IPSEC: listcerts response not correct.\r\n"))
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec listcacerts", "authkey:", @error_bit, 0)
    return if (is_failed(is_alpha_side, function_name, " IPSEC: listcacerts response not correct.\r\n"))
  end
  def bring_ipsec_tunnel_up(is_alpha_side, is_ipv4, is_pass_through)
    function_name = "bring_ipsec_tunnel_up"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    verify_message = (is_pass_through ? "PASS" : "ESTABLISHED")
    ipsec_cmd = (is_pass_through ? "route" : "up")
    ip_ref = ( is_pass_through ? "Udp3" : (is_ipv4 ? "Udp1" : "Udp2") )
    connect_ref = (is_alpha_side ? "#{@alpha_side_ref}-#{ip_ref}" : "#{@beta_side_ref}-#{ip_ref}")
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec #{ipsec_cmd} #{connect_ref}", "", @error_bit, 0)
    sleep(3)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec status", verify_message, @error_bit, 0)
    return if (is_failed(is_alpha_side, function_name, " IPSEC: status response to check for #{verify_message} not correct.\r\n"))
    # Collect information from the ipsec statusall command
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec statusall", "", @error_bit, 0)
  end
  def xfer_file(is_alpha_side, from_path_file_name, to_path_file_name)
    # Tranfer file from tftp server to beta side correct directory
    file_name = File.basename(to_path_file_name)
    from_dir = File.dirname(from_path_file_name)
    to_dir = File.dirname(to_path_file_name)
    transfer_file(is_alpha_side, file_name, from_dir, to_dir)
  end
  def create_side_specific_ipsec_certificates(is_alpha_side, ca_key_file, ca_cert_file)
    function_name = "create_side_specific_ipsec_certificates"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    is_alpha_side_here = (@is_gen_on_alpha_only ? ALPHA_SIDE() : is_alpha_side)
    
    # Set local specific cert file and key
    local_ip_address = (is_alpha_side ? @alpha_side_ip : @beta_side_ip)
    cert_org = (is_alpha_side ? @alpha_side_net_name : @beta_side_net_name)
    cert_file = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_cert_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_cert_file))
    key_file = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_key_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_key_file))
    ip_cert_file = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_ip_cert_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_ip_cert_file))
    temp_file = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_temp_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_temp_file))
    temp_key_file = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_temp_key_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_temp_key_file))
    
    # Create empty files and make sure they are writeable. This is necessary for the ipsec commands to work properly
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, cert_file)
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, key_file)
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, ip_cert_file)
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, temp_file)
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, temp_key_file)
    
    # Create alphaKey.der and alphaCert.der  or  betaKey.der and betaCert.der
    @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki -g > #{temp_key_file}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --pub --in #{temp_key_file} > #{temp_file}", "", @error_bit, 0)
    # Create FQDN certificate
    @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --issue --dn \"C=US, O=Test, CN=#{cert_org}\" --san \"#{cert_org}\" --cacert #{ca_cert_file} --cakey #{ca_key_file} < #{temp_file} > #{cert_file}", "", @error_bit, 0)
    # Create IP address certificate
    @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --issue --san \"#{local_ip_address}\" --cacert #{ca_cert_file} --cakey #{ca_key_file} < #{temp_file} > #{ip_cert_file}", "", @error_bit, 0)
    return if (is_failed(is_alpha_side_here, function_name, " IPSEC: pki -g, pki --pub or pki --issue response not correct.\r\n"))
    
    # Copy files to the appropriate directories on the alpha or beta side
    xfer_file(is_alpha_side, key_file, (is_alpha_side ? @alpha_side_key_file : @beta_side_key_file))
    xfer_file(is_alpha_side, cert_file, (is_alpha_side ? @alpha_side_cert_file : @beta_side_cert_file))
    xfer_file(is_alpha_side, ip_cert_file, (is_alpha_side ? @alpha_side_ip_cert_file : @beta_side_ip_cert_file))
  end
  def create_ipsec_certificates(is_alpha_side)
    function_name = "create_ipsec_certificates"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    is_alpha_side_here = (@is_gen_on_alpha_only ? ALPHA_SIDE() : is_alpha_side)

    # Get caKey.der file locations for the alpha an beta side
    alpha_tftp_ca_key_file = get_file_tftp_server_file_name_path(ALPHA_SIDE(), @alpha_side_ca_key_file)
    beta_tftp_ca_key_file = get_file_tftp_server_file_name_path(BETA_SIDE(), @beta_side_ca_key_file)
    # Get caCert.der file locations for the alpha an beta side
    alpha_tftp_ca_cert_file  = get_file_tftp_server_file_name_path(ALPHA_SIDE(), @alpha_side_ca_cert_file)
    beta_tftp_ca_cert_file  = get_file_tftp_server_file_name_path(BETA_SIDE(), @beta_side_ca_cert_file)
    
    # Create empty files and make sure they are writeable. This is necessary for the ipsec commands to work properly
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, alpha_tftp_ca_key_file)
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, alpha_tftp_ca_cert_file)
    
    # Create common caKey.der and caCert.der files
    @vatf_helper.smart_send_cmd_wait(is_alpha_side_here, @normal_cmd, "ipsec pki -g > #{alpha_tftp_ca_key_file}", "", @error_bit, 0, 45)
    return if (is_failed(is_alpha_side_here, function_name, " IPSEC: pki -g response not correct.\r\n"))
    @vatf_helper.smart_send_cmd_wait(is_alpha_side_here, @normal_cmd, "ipsec pki -s --in #{alpha_tftp_ca_key_file} --dn \"C=US, O=TI, CN=Strongswan CA\" --ca > #{alpha_tftp_ca_cert_file}", "", 6, 0, 45)
    return if (is_failed(is_alpha_side_here, function_name, " IPSEC: pki -s response not correct.\r\n"))
    
    # Copy caKey.der and caCert.der files the beta side tftp area
    xfer_file(ALPHA_SIDE(), alpha_tftp_ca_key_file, beta_tftp_ca_key_file)
    xfer_file(ALPHA_SIDE(), alpha_tftp_ca_cert_file, beta_tftp_ca_cert_file)
    # Copy caKey.der and caCert.der files to the proper alpha side directory
    xfer_file(ALPHA_SIDE(), alpha_tftp_ca_key_file, @alpha_side_ca_key_file)
    xfer_file(ALPHA_SIDE(), alpha_tftp_ca_cert_file, @alpha_side_ca_cert_file)
    # Copy caKey.der and caCert.der files to the proper beta side directory
    xfer_file(BETA_SIDE(), beta_tftp_ca_key_file, @beta_side_ca_key_file)
    xfer_file(BETA_SIDE(), beta_tftp_ca_cert_file, @beta_side_ca_cert_file)
    
    # Create and copy the side specific keys and certificates. Use the caKey.der and caCert.der created on the alpha side for all other certificate creation.
    create_side_specific_ipsec_certificates(ALPHA_SIDE(), alpha_tftp_ca_key_file, alpha_tftp_ca_cert_file)
    create_side_specific_ipsec_certificates(BETA_SIDE(), alpha_tftp_ca_key_file, alpha_tftp_ca_cert_file)
  end
  def get_network_ip_from_ip(ip_address)
    ip_items = ip_address.split(".")
    ip_network = "#{ip_items[0]}.#{ip_items[1]}.#{ip_items[2]}.0"
    
    #Return the class C network based on the ip address specified
    return ip_network
  end
  def transfer_file(is_alpha_side, file, from_path, to_path)
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    if (is_alpha_side)
      @lnx_helper.copy_file(file, from_path, to_path, is_alpha_side)
    else
      puts(" tftp_path: #{@server_ipsec_tftp_path}, file_name: #{file}, from_dir: #{from_path}, to_dir: #{to_path}")
      # Strip off server tftp base path since on the remote side the base path will not be used
      from_dir = from_path.gsub(File.dirname(@server_ipsec_tftp_path)+"/", "")
      @lnx_helper.tftp_file(file, from_dir, to_path, @equipment[@vatf_helper.vatf_server_ref].telnet_ip, is_alpha_side)
    end
  end
  def transfer_files(is_alpha_side, array_of_files, from_path, to_path)
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    if (is_alpha_side)
      @lnx_helper.copy_files(array_of_files, from_path, to_path, is_alpha_side)
    else
      puts(" tftp_path: #{@server_ipsec_tftp_path}, file_name: #{array_of_files}, from_dir: #{from_path}, to_dir: #{to_path}")
      # Strip off server tftp base path since on the remote side the base path will not be used
      from_dir = from_path.gsub(File.dirname(@server_ipsec_tftp_path)+"/", "")
      @lnx_helper.tftp_files(array_of_files, from_dir, to_path, @equipment[@vatf_helper.vatf_server_ref].telnet_ip, is_alpha_side)
    end
  end
  def create_ipsec_secrets_file(is_alpha_side)
    function_name = "create_ipsec_secrets_file"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    is_alpha_side_here = ALPHA_SIDE()
    fileUtils = FileUtilities.new
    secrets_path_file_name_real = (is_alpha_side ? @alpha_side_ipsec_secrets_file : @beta_side_ipsec_secrets_file)
    # Get path and file name as located on the tftp server
    key_path_file_name = (is_alpha_side ? @alpha_side_key_file : @beta_side_key_file)
    ipsec_secrets = Array.new
    ipsec_secrets.push("# /etc/ipsec.secrets - strongSwan IPsec secrets file\n")
    ipsec_secrets.push("\n")
    ipsec_secrets.push(": RSA #{key_path_file_name}\n")
    secrets_tftp_path_file_name = get_file_tftp_server_file_name_path(is_alpha_side, secrets_path_file_name_real)
    # Create directory in file system if needed
    fileUtils.create_directory_if_needed(File.dirname(secrets_tftp_path_file_name))
    
    # Backup existing file only if the backup file does not alread exist
    if ( !File.exist?(secrets_tftp_path_file_name) )
      save_file = secrets_tftp_path_file_name + ".save"
      # Copy current file to save file name
      @vatf_helper.smart_send_cmd(is_alpha_side_here, @sudo_cmd, "cp #{secrets_tftp_path_file_name} #{save_file}", "", @error_bit, 0)
    end
    return if (is_failed(is_alpha_side_here, function_name, " IPSEC: failed to copy secrets file.\r\n"))

    # Create empty file and make sure it is writeable. This is necessary for the ipsec commands to work properly
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, secrets_tftp_path_file_name)
    
    # Write modified contents to file
    fileUtils.write_file_contents(secrets_tftp_path_file_name, ipsec_secrets)
    
    # Set file attributes back to normal
    @lnx_helper.set_chmod_conf_normal(is_alpha_side_here, secrets_tftp_path_file_name)
    
    # copy or tftp created file to proper directory on alpha or beta side
    xfer_file(is_alpha_side, secrets_tftp_path_file_name, secrets_path_file_name_real)
  end
  def create_ipsec_conf_file(is_alpha_side)
    function_name = "create_ipsec_conf_file"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    fileUtils = FileUtilities.new
    ipsec_conf = Array.new
    is_alpha_side_here = (@is_gen_on_alpha_only ? ALPHA_SIDE() : is_alpha_side)
    
    # Set ipsec variables appropriately
    ss_version = (is_alpha_side ? @alpha_side_ss_major_version : @beta_side_ss_major_version)
    connection_ref = (is_alpha_side ? @alpha_side_ref : @beta_side_ref)
    is_fqdn = (is_alpha_side ? @is_alpha_side_fqdn : @is_alpha_side_fqdn)
    if (is_fqdn)
      cert_file_path_name = (is_alpha_side ? @alpha_side_cert_file : @beta_side_cert_file)
    else
      cert_file_path_name = (is_alpha_side ? @alpha_side_ip_cert_file : @beta_side_ip_cert_file)
    end
    local_network_name = (is_alpha_side ? @alpha_side_net_name : @beta_side_net_name)
    remote_network_name = (!is_alpha_side ? @alpha_side_net_name : @beta_side_net_name)
    local_ip = (is_alpha_side ? @alpha_side_ip : @beta_side_ip)
    remote_ip = (!is_alpha_side ? @alpha_side_ip : @beta_side_ip)
    local_ipv6 = (is_alpha_side ? @alpha_side_ipv6 : @beta_side_ipv6)
    remote_ipv6 = (!is_alpha_side ? @alpha_side_ipv6 : @beta_side_ipv6)
    ipsec_conf_template_file = File.join(File.dirname(__FILE__), @ipsec_conf_template_file_name)
    ipsec_conf_file = (is_alpha_side ? @alpha_side_ipsec_conf_file : @beta_side_ipsec_conf_file)
    ipsec_conf_file_tftp = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_ipsec_conf_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_ipsec_conf_file))
    ipsec_conf_save_file = ipsec_conf_file.gsub(File.basename(ipsec_conf_file), @ipsec_conf_save_name)
    ike_lifetime = @default_rekey_lifetime
    lifetime = @default_rekey_lifetime
    
    # Get ipsec template file contents
    fileUtils.get_file_contents(ipsec_conf_template_file)
    
    puts(" StrongSwan version for #{connection_ref} is: #{ss_version}\r\n")
    
    # Substitute template contents with ipsec variables
    fileUtils.file_contents.each do |item|
      file_line = item
      if (item.length > 0)
        # Don't do any substitution if the lines starts with a "#"
        if (item[0] != "#")
          file_line.gsub!("%LOCAL_IP_ADDRESS%", local_ip)
          file_line.gsub!("%LOCAL_IP_NETWORK%", get_network_ip_from_ip(local_ip))
          file_line.gsub!("%CERT_FILE_PATH_NAME%", cert_file_path_name)
          file_line.gsub!("%LOCAL_CN%", local_network_name)
          file_line.gsub!("%REMOTE_IP_ADDRESS%", remote_ip)
          file_line.gsub!("%REMOTE_IP_NETWORK%", get_network_ip_from_ip(remote_ip))
          file_line.gsub!("%REMOTE_CN%", remote_network_name)
          file_line.gsub!("%CONNECTION_SIDE%", connection_ref)
          file_line.gsub!("%IKE_LIFETIME%", ike_lifetime)
          file_line.gsub!("%LIFETIME%", lifetime)
          file_line.gsub!("%LOCAL_IPV6_ADDRESS%", local_ipv6)
          file_line.gsub!("%REMOTE_IPV6_ADDRESS%", remote_ipv6)
        end
      end
      if ss_version == "5"
        # Do not include the depreciated commands for version 5
        if (!file_line.include?("pfs=") and !file_line.include?("plutostart="))
          ipsec_conf.push(file_line.gsub("\r\n","\n"))
        end
      else
        ipsec_conf.push(file_line.gsub("\r\n","\n"))
      end
    end
    
    # Create directory in file system if needed
    fileUtils.create_directory_if_needed(File.dirname(ipsec_conf_file_tftp))
    
    # Backup existing file only if the backup file does not alread exist
    if ( !File.exist?(ipsec_conf_save_file) )
      # Copy current file to save file name
      @vatf_helper.smart_send_cmd(is_alpha_side_here, @sudo_cmd, "cp #{ipsec_conf_file_tftp} #{ipsec_conf_save_file}", "", @error_bit, 0)
    end
    return if (is_failed(is_alpha_side_here, function_name, " IPSEC: failed to copy conf file.\r\n"))
    
    # Create empty file and make sure it is writeable. This is necessary for the ipsec commands to work properly
    @lnx_helper.create_writeable_empty_file(is_alpha_side_here, ipsec_conf_file_tftp)
    # Write modified contents to file
    fileUtils.write_file_contents(ipsec_conf_file_tftp, ipsec_conf)
    
    # Set file attributes back to normal
    @lnx_helper.set_chmod_conf_normal(is_alpha_side_here, ipsec_conf_file_tftp)
    # Transfer file
    xfer_file(is_alpha_side, ipsec_conf_file_tftp, ipsec_conf_file)
  end
  def create_ipsec_conf_and_certificate_files(is_alpha_side)
    # Create the ipsec.conf file
    create_ipsec_conf_file(is_alpha_side)
    # Create the key and certificate that goes with the ipsec.conf file. All keys and certificates are generated on the alpha side and copied to the beta side.
    create_ipsec_certificates(is_alpha_side) if is_alpha_side
  end
  def start_tunnels(is_ipv4, is_pass_through)
    # Bring up the IPSEC tunnel on both sides
    bring_ipsec_tunnel_up(BETA_SIDE(), is_ipv4, is_pass_through)    
    bring_ipsec_tunnel_up(ALPHA_SIDE(), is_ipv4, is_pass_through)
  end
  def ipsec_start_all(is_ipv4, is_pass_through)
    function_name = "ipsec_start_all"
    # Start the alpha side ipsec
    ipsec_start(ALPHA_SIDE())
    # Start the beta side ipsec. Beta side connection status happens in the ipsec_start
    ipsec_start(BETA_SIDE())
    sleep(3)
    # Bring up the IPSEC tunnel on both sides
    start_tunnels(is_ipv4, is_pass_through)
  end
  def ipsec_restart_all(is_ipv4, is_pass_through)
    ipsec_stop(ALPHA_SIDE())
    ipsec_stop(BETA_SIDE())
    ipsec_start_all(is_ipv4, is_pass_through)
  end
  def ipsec_restart_with_new_ipsec_conf_file(is_ipv4, tunnel_type, ipsec_conf_input_file, is_clear_previous_result, is_pass_through)
    puts("\r\nRestarting ipsec with file: #{ipsec_conf_input_file}, tunnel type: #{(tunnel_type ? "FQDN" : "IP")}\r\n")
    clear_results() if is_clear_previous_result
    # Set ipsec.conf input template file
    set_common(ipsec_conf_input_file, "", "")
    # Set the alpha side tunnel type. Leave everything else as is.
    set_alpha_cert("", tunnel_type, "", "", "", "", "", "", "", "", "", "")
    # Set the beta side tunnel type. Leave everything else as is.
    set_beta_cert("", tunnel_type, "", "", "", "", "", "", "", "", "", "")
    # Stop currently running ipsec
    ipsec_stop(ALPHA_SIDE())
    ipsec_stop(BETA_SIDE())
    # Create ipsec.conf files from input template
    create_ipsec_conf_file(ALPHA_SIDE())
    create_ipsec_conf_file(BETA_SIDE())
    # Start ipsec on both sides. Start the ipsec connection on the beta side.
    ipsec_start_all(is_ipv4, is_pass_through)
    return result()
  end
  def ipsec_generate_keys_and_certs_and_start_all(is_ipv4, is_pass_through)
    # Set the time on the evm to match the PC. This is a must to have the certificates work properly.
    @lnx_helper.set_evm_date_time(BETA_SIDE())
    # Show ipsecVatf setting
    display_settings
    # Stop currently running ipsec
    ipsec_stop(ALPHA_SIDE())
    ipsec_stop(BETA_SIDE())
    # Delete all keys and certificates that are dynamically generated from both sides
    clean_all_key_and_certificate_file(ALPHA_SIDE())
    clean_all_key_and_certificate_file(BETA_SIDE())
    # Generate keys and certificates for both sides
    create_ipsec_conf_and_certificate_files(ALPHA_SIDE())
    create_ipsec_conf_and_certificate_files(BETA_SIDE())
    # Create ipsec.secrets file for both sides
    create_ipsec_secrets_file(ALPHA_SIDE())
    create_ipsec_secrets_file(BETA_SIDE())
    # Start ipsec on both sides. Start the ipsec connection on the beta side.
    ipsec_start_all(is_ipv4, is_pass_through)
  end
  def set_swan_major_version(is_alpha_side, swan_major_version)
    maj_ver = (swan_major_version >= 5 ? "5" : "4")
    if is_alpha_side
      # Set only the StrongSwan major version number. Leave everything else at default.
      set_alpha_cert("", "", "#{maj_ver}", "", "", "", "", "", "", "", "", "")
    else
      # Set only the StrongSwan major version number. Leave everything else at default.
      set_beta_cert("", "", "#{maj_ver}", "", "", "", "", "", "", "", "", "")
    end
  end
  def ipsec_typical_config(equipment, tunnel_type, ipsec_conf_input_file)
    function_name = "ipsec_typical_config"
    # Typical inputs to this function
    #  equipment will be:  @equipment
    #  tunnel_type could be: ipsecVatf.FQDN_TUNNEL or ipsecVatf.IP_TUNNEL
    #  ipsec_conf_input_file would be: ""  (This could also be a template file within the vatf scmcsdk\syslib path. e.g. "ipsec_conf_template.txt" or "ipsec_test_confs/ipsec_cp_1.conf")
    
    # Get IP addresses to use on each side of the IPSEC connection
    alpha_ip = equipment[@vatf_helper.vatf_server_ref].telnet_ip
    beta_ip = equipment[@vatf_helper.vatf_dut_ref].telnet_ip
    @server_ipsec_tftp_path = File.join(equipment[@vatf_helper.vatf_server_ref].tftp_path, "ipsec_files")

    # Use the default vatf linux pc ('server1') and evm ('dut1') reference, but set the equipment variable so we can communicate with them
    set_helper_common("", "", equipment)
    # Set the alpha side IP address and StrongSwan major version number. Leave everything else at default.
    set_alpha_cert(alpha_ip, tunnel_type, "5", "", "", "", "", "", "", "", "", "")
    # Set the beta side IP address , StrongSwan major version number. Leave everything else at default.
    set_beta_cert(beta_ip, tunnel_type, "4", "", "", "", "", "", "", "", "", "")
    # Set ipsec.conf input template file to use.
    set_common(ipsec_conf_input_file, "", "")
    # Add an IPv6 ip address to the Linux PC side and the EVM side
    #  Need to add the ability to figure out the interface to use instead of hard coding it like it currently is
    #@lnx_helper.add_ip_address_to_interface(ALPHA_SIDE(), "#{@alpha_side_ipv6}/64", "eth3")
    #@lnx_helper.add_ip_address_to_interface(BETA_SIDE(), "#{@beta_side_ipv6}/64", "eth0")
  end
  def ipsec_typical_start(is_ipv4, is_pass_through)
    function_name = "ipsec_typical_start"
    # Set ipsecVatf.result to zero
    clear_results()
    # Create all the certificates needed and start ipsec on both the Linux PC and the EVM. Start the ipsec tunnel on the EVM.
    ipsec_generate_keys_and_certs_and_start_all(is_ipv4, is_pass_through)
    # Bring up the IPV6 IPSEC tunnel on both sides
    #start_tunnels(IPV6())
  end
end