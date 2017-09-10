require File.dirname(__FILE__)+'/../armtest/common_utils.rb'
require File.dirname(__FILE__)+'/../../LSP/A-CRYPTO/crypto_host_tests.rb'

def get_platform()
  if @equipment['dut1'].id.split("_").grep(/k2.?/).size > 0
    @equipment['dut1'].id.split("_").grep(/k2.?/)[0] 
  else
    "k2h"
  end
end

def is_crypto_omap()
  if dut_dir_exist?("/opt/ltp")
    dut_orig_path = save_dut_orig_path()
    export_ltppath()
    @equipment['dut1'].send_cmd("get_modular_name.sh crypto",@equipment['dut1'])
    response = @equipment['dut1'].response
    restore_dut_path(dut_orig_path)
    return response.include? "omap"
  else
    return false
  end
end

def get_crypto_modules()
  module_list = Array.new
  if (is_crypto_omap)
    module_list = ["omap_aes_driver", "omap_des", "omap_sham"]
  else
    module_list = ["ipsecmgr_mod"]
  end
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

def get_variable_value(string)
  value = (string.include?("=") ? "" : string)
  items = string.split("=")
  if (items.length > 1)
    value = items[1].gsub(">]", "")
  end
  value = value.gsub('\"', "")
  value = value.tr("\"", "")
  return value
end

def convert_string_to_case_insensitive_reg_expression(string)
  reg_exp = ""
  if string.length > 0
    reg_exp = ""
    make_case_insensitive = true
    in_bracket = false
    for index in (0..string.length-1)
      swapcase_string = string.swapcase
      if string[index,1] == "["
        in_bracket = true
      else
        if string[index,1] == "]"
          in_bracket = false
        else
          make_case_insensitive = ((string[index-1,1] == "\\" or in_bracket) ? false : true)
        end
      end
      reg_exp += ((swapcase_string[index] != string[index]) and make_case_insensitive) ? "[#{string[index,1]}|#{swapcase_string[index,1]}]" : string[index,1]
    end
    reg_exp = /#{reg_exp}/
  end
  return reg_exp
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
    #arr_to_check = array_to_check
    #arr_to_check = [array_to_check] if array_to_check.kind_of?(String)
    arr_to_check = (array_to_check.kind_of?(String) ? [array_to_check] : array_to_check)  
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
    @result_text = ""
    @error_bit = 10
    @is_debug = true
  end

  def clear_result()
    @result = 0
    @result_text = ""
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

  def smart_send_cmd_wait(is_alpha_side, is_sudo, command_to_send, wait_message, error_bit_set, sleep_before_return, wait_secs, chk_cmd_echo=true)
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
      #puts("\r\n\r\n send_cmd: #{@equipment}, #{equipment_ref}, #{command_to_send} \r\n\r\n")
      @equipment[equipment_ref].send_cmd("#{command_to_send}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      server_prompt_wait_workaround(equipment_ref, wait_message)
    end
    if ( (@equipment[equipment_ref].timeout?) and (error_bit_set != DONT_SET_ERROR_BIT()) )
      puts("     Command timed out.\r\n") if @is_debug
      @result |= bit_to_set(error_bit_set)
    end
    sleep(sleep_before_return) if (sleep_before_return > 0)
    return @equipment[equipment_ref].response
  end

  def smart_send_cmd(is_alpha_side, is_sudo, command_to_send, wait_message, error_bit_set, sleep_before_return, chk_cmd_echo=true)
    return smart_send_cmd_wait(is_alpha_side, is_sudo, command_to_send, wait_message, error_bit_set, sleep_before_return, 20, chk_cmd_echo)
  end

  def get_policy_id(is_alpha_side, direction_type)
    get_index_command = "echo `ip -s xfrm policy | grep \"dir #{direction_type}\" | grep -v grep | awk '{print $6}'`"
    policy_index = "not found"
    smart_send_cmd(is_alpha_side, @sudo_cmd, get_index_command, "", @error_bit, 2)
    raw_buffer = @equipment[(is_alpha_side ? @vatf_server_ref : @vatf_dut_ref)].response
    items = raw_buffer.split("\n")
    # Get policy index value that is not equal to 0
    items.each do |item|
      if !(item.to_i == 0) and !(item.include?("$")) and !(item.include?("#"))
        policy_index = "#{item.to_i}"
        break
      end
    end
    #log_info(is_alpha_side, " Policy Index (#{direction_type}): #{policy_index}, buffer: \"#{raw_buffer}\"\r\n [0]:#{items[0]}, [1]:#{items[1]}\r\n")
    return policy_index
  end

  def is_matched_count(raw_buffer, string, count)
    is_matched = false
    temp = raw_buffer.scan(convert_string_to_case_insensitive_reg_expression(string))
    #is_matched = true if (temp.length == count)
    is_matched = true if (temp.length >= count)
    # log_info(BETA_SIDE(), "\r\n##########################\r\n string: #{string}, temp.length: #{temp.length}, count: #{count}, is_matched #{is_matched}, raw_buffer:\r\n#{raw_buffer} \r\n##########################\r\n")
    log_info(BETA_SIDE(), "\r\n##### string: #{string}, temp.length: #{temp.length}, count: #{count}, is_matched: #{is_matched} #####\r\n")
    return is_matched
  end

  def offload_indices_common(is_alpha_side, policy_index_in, policy_index_out, offload_command_post_fix, is_fatal, offload_command)
    log_info(is_alpha_side, " Policy Indices; In: #{policy_index_in}, Out: #{policy_index_out}\r\n")
    raw_buffer = smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{offload_command} --sp_id #{policy_index_in} #{offload_command_post_fix}", "sa_handle", DONT_SET_ERROR_BIT(), 2, 4)
    # Check to see that we receive the correct number of success messages
    @result |= @error_bit if !is_matched_count(raw_buffer, "SUCCESS", 2)
    if (result() != 0)
      @result_text += " #{offload_command} command failed for policy index : #{policy_index_in}\r\n"
      return if is_fatal
    end
    raw_buffer = smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{offload_command} --sp_id #{policy_index_out} #{offload_command_post_fix}", "sa_handle", DONT_SET_ERROR_BIT(), 2, 4)
    # Check to see that we receive the correct number of success messages
    @result |= @error_bit if !is_matched_count(raw_buffer, "SUCCESS", 2)
    if (result() != 0)
      @result_text += " #{offload_command} command failed for policy index : #{policy_index_out}\r\n"
      return if is_fatal
    end
    sleep(5)
  end

  def offload_indices(is_alpha_side, policy_index_in, policy_index_out, offload_command_post_fix, is_fatal)
    offload_indices_common(is_alpha_side, policy_index_in, policy_index_out, offload_command_post_fix, is_fatal, "offload_sp")
  end

  def stop_offload_indices(is_alpha_side, policy_index_in, policy_index_out, offload_command_post_fix, is_fatal, offload_command_pre_fix)
    offload_indices_common(is_alpha_side, policy_index_out, policy_index_in, offload_command_post_fix, is_fatal, offload_command_pre_fix)
  end

  def get_file_location(is_alpha_side, filename, locations_to_scan="/")
    file_name_path = ""
    find_cmd = "find #{locations_to_scan} -iname"
    raw_buffer = smart_send_cmd(is_alpha_side, @normal_cmd, "#{find_cmd} #{filename}", "", @error_bit, 5)
    items = raw_buffer.split("\n")
    # Get first line that contains the file name
    items.each do |item|
      if item.include?(filename) and !item.include?(find_cmd)
        file_name_path = item.gsub("./", "/")
        break
      end
    end
    return file_name_path
  end

  def result()
    return @result
  end

  def result_text()
    return @result_text
  end

  def vatf_dut_ref()
    return @vatf_dut_ref
  end

  def vatf_server_ref()
    return @vatf_server_ref
  end

  def equipment
    @equipment
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

  def ALPHA_SIDE()
    return @vatf_helper.ALPHA_SIDE()
  end

  def BETA_SIDE()
    return @vatf_helper.BETA_SIDE()
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
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "tftp -g -r #{from_file} -l #{to_file} #{host}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "tftp -g -r #{from_file} -l #{to_file} #{host}", "", @error_bit, 0, 60)
  end

  def tftp_put_file(file, from_path, to_path, host, is_alpha_side)
    from_file = File.join(from_path, file)
    to_file = File.join(to_path, file)
    #create_writeable_empty_file(is_alpha_side, to_file)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "tftp -p -l #{from_file} -r #{to_file} #{host}", "", @error_bit, 0, 60)
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
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "tftp -g -r #{from_file} -l #{to_file} #{host}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "tftp -g -r #{from_file} -l #{to_file} #{host}", "", @error_bit, 0, 60)
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

  def untar_file(gzip_file, directory_where_file_should_be_untarred, is_alpha_side)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "cd #{directory_where_file_should_be_untarred} ; tar -xzf #{gzip_file}", "", @error_bit, 0, 60)
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
    # Add time for Daylight savings time
    utc_secs_diff = utc_secs_diff + (60 * 60)
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

  def files_exist?(is_alpha_side, directory, filespec)
    temp_state = true
    # Handle filespec for one or more files
    files = (filespec.include?(";") ? filespec.split(";") : [filespec])
    # Get directory listing
    raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ls -l #{directory}", @equipment[(is_alpha_side ? @vatf_helper.vatf_server_ref() : @vatf_helper.vatf_dut_ref())].prompt, @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    # Check for each file listed in the filespec
    files.each do |file|
      temp = raw_buffer.scan(convert_string_to_case_insensitive_reg_expression(file))
      temp_state = false if !(temp.length >= 1)
    end
    # Indicate in the log file if file(s) were found.
    @vatf_helper.log_info(is_alpha_side, "\r\n\r\n [#{(temp_state ? "Found" : "Did not find ")} trigger file#{(files.length == 1 ? "" : "s")}: \"#{filespec}\" in \"#{directory}\"]\r\n\r\n")
    return temp_state
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
    @miw_linux_pc_arm_apps_path = "~/tempdown/temp_MS5_arm_executeables"
    @miw_linux_pc_dsp_apps_path = "~/tempdown/temp_MS5_dsp_executeables"
    @miw_directory = "miw"
    @miw_apps = Array.new
    @femto_logger_executable = "/home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger/femto_logger.pl"
    @femto_logger_log_file = "/home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger/logger_out.txt"
    @ccxml_file = "C6614_Mezzanine_511_33.ccxml"
    @dss_dir = ""
    @load_ti_dir = ""
    @ccxml_dir = ""

    @sudo_cmd = true
    @normal_cmd = false
    @is_cmd_shell = false
    
    @result = 0
    @error_bit = 1
    @result_text = ""
    set_default_ti_dirs()
  end

  def set_default_ti_dirs()
    @dss_dir = "/home/gtscmcsdk-systest/ti/ccsv5/ccs_base/scripting/bin"
    @load_ti_dir = "#{File.dirname(__FILE__)}/dsploadrun/loadti"
    @ccxml_dir = "#{File.dirname(__FILE__)}/dsploadrun/ccxmls"
  end

  def clear_results()
    @lnx_helper.clear_result()
    @vatf_helper.clear_result()
    @result = 0
    @result_text = ""
  end

  def ms4x_file_set(is_for_transfer)
    if is_for_transfer
      add_to_miw_apps("ms5_core0.out")
      add_to_miw_apps("ms5_core1.out")
      add_to_miw_apps("ms5_core2.out")
      add_to_miw_apps("miw_utest_iubl")
      add_to_miw_apps("miw_utest_boam")
      
      add_to_miw_apps("msgrouter.out")
      add_to_miw_apps("setup_snooper_env.sh")
      add_to_miw_apps("ipsecsnooper.out")
      add_to_miw_apps("setup_shell_env.sh")
      add_to_miw_apps("ipsecmgr_cmd_shell.out")
    else
      # All the files that are transferred are used. No other files are needed.
    end
  end

  def ms5_file_set(is_for_transfer)
    if is_for_transfer
      add_to_miw_apps("miw_utest_iubl")
      add_to_miw_apps("miw_utest_boam")
      add_to_miw_apps("miw_utest_pma")
    else
      # These files are used but do not need to be transferred.
      add_to_miw_apps("ms5_core0.out")
      add_to_miw_apps("ms5_core1.out")
      add_to_miw_apps("ms5_core2.out")
      add_to_miw_apps("ms5_core3.out")
      
      add_to_miw_apps("msgrouter.out")
      add_to_miw_apps("cmd_shell.out")
    end
  end

  def LINUX_PC()
    return "linux_pc"
  end

  def TFTP_SERVER()
    return "tftp_server"
  end

  def EVM_APPS()
    return "evm_apps"
  end

  def TRANSFER()
    return true
  end

  def USED()
    return false
  end

  def get_file_and_path(location_string, file_string_to_match)
    full_path = ""
    apps_file = ""
    @miw_apps.each do |file_name|
      if file_name.include?(file_string_to_match)
        apps_file = file_name
        break
      end
    end
    case location_string
      when LINUX_PC()
        miw_path = (apps_file.include?("core") ? @miw_linux_pc_dsp_apps_path : @miw_linux_pc_arm_apps_path)
        full_path =  File.join(miw_path, apps_file)
      when TFTP_SERVER()
        miw_apps_path = File.join(@from_path, @miw_directory)
        full_path = File.join(miw_apps_path, apps_file)
      when EVM_APPS()
        full_path = File.join(@to_path, apps_file)
      else
        # Make sure all other counts are zero
        puts(" Error: invalid get_file_path location.\r\n")
    end
    return full_path
  end

  def copy_miw_files_to_tftp_dir(server_tftp_base_dir)
    @miw_apps.each do |file_name|
      from_path = File.dirname(get_file_and_path(LINUX_PC(), file_name))
      to_path = File.dirname(get_file_and_path(TFTP_SERVER(), file_name))
      to_path = File.join(server_tftp_base_dir, to_path)
      @lnx_helper.copy_executable(file_name, from_path, to_path, @vatf_helper.ALPHA_SIDE())
    end
  end

  def move_files_to_evm(host)
    @miw_apps.each do |file_name|
      from_path = File.dirname(get_file_and_path(TFTP_SERVER(), file_name))
      to_path = File.dirname(get_file_and_path(EVM_APPS(), file_name))
      @lnx_helper.tftp_executable(file_name, from_path, to_path, host, @vatf_helper.BETA_SIDE())
    end
  end

  def display_path_info()
    temp_txt = ""
    temp_txt += "Nash PAL tftp paths:\r\n"
    temp_txt += "  TFTP server apps path : #{@from_path}\r\n"
    temp_txt += "  EVM apps path         : #{@to_path}\r\n"
    temp_txt += "  MIW_arm_apps_path     : #{@miw_linux_pc_arm_apps_path}\r\n"
    temp_txt += "  MIW_dsp_apps_path     : #{@miw_linux_pc_dsp_apps_path}\r\n"
    temp_txt += "  MIW relative path     : #{@miw_directory}\r\n"
    temp_txt += "Nash PAL Linux PC MIW files:\r\n"
    @miw_apps.each do |file_name|
      temp_txt += "  #{get_file_and_path(LINUX_PC(), file_name)}\r\n"
    end
    temp_txt += "Nash PAL TFTP Server MIW files:\r\n"
    @miw_apps.each do |file_name|
      temp_txt += "  #{get_file_and_path(TFTP_SERVER(), file_name)}\r\n"
    end
    temp_txt += "Nash PAL EVM MIW files:\r\n"
    @miw_apps.each do |file_name|
      temp_txt += "  #{get_file_and_path(EVM_APPS(), file_name)}\r\n"
    end
    puts("#{temp_txt}\r\n")
  end

  def set_miw_tftp_paths(tftp_server_from_path, evm_to_path, miw_linux_pc_arm_apps_path, miw_linux_pc_dsp_apps_path, miw_directory)
    @from_path = tftp_server_from_path if (tftp_server_from_path != "")
    @to_path = evm_to_path if (evm_to_path != "")
    @miw_linux_pc_arm_apps_path = miw_linux_pc_arm_apps_path if (miw_linux_pc_arm_apps_path != "")
    @miw_linux_pc_dsp_apps_path = miw_linux_pc_dsp_apps_path if (miw_linux_pc_dsp_apps_path != "")
    @miw_directory = miw_directory if (miw_directory != "")
  end

  def set_femto_logger_paths(executable, log_file)
    @femto_logger_executable = executable if (executable != "")
    @femto_logger_log_file = log_file if (log_file != "")
  end

  def add_to_miw_apps(file_name)
    @miw_apps.push(file_name)
  end

  def copy_miw_apps_to_tftp_server()
    if @from_path != ""
    end
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
    last_file = ""
    #load_ti_dir = "#{File.dirname(__FILE__)}/dsploadrun/loadti"
    #ccxml_dir = "#{File.dirname(__FILE__)}/dsploadrun/ccxmls"
    #dsp_files_dir = "/home/gtscmcsdk-systest/tempdown/temp_MS5_dsp_executeables"
    load_ti_parameters = ""
    execution_setup_time = 90 # Approximate maximum time it will take to get the test apps loaded and run. Actual time will vary from run to run. 
    #load_ti_parameters += "-gtl \"#{@ccxml_dir}/evmtci6614.gel\""
    #load_ti_parameters += " -gftr \"Global_Default_Setup()\""
    dsp_test_milisecs = (test_secs.to_i + execution_setup_time) * 1000
    #load_ti_parameters += " -v -sfpc -t #{dsp_test_milisecs} -ctr 3"
    load_ti_parameters += " -v -sfpc -t #{dsp_test_milisecs} -ctr 4"
    load_ti_parameters += " -c \"#{@ccxml_dir}/#{@ccxml_file}\""
    
    #load_ti_parameters += " \"#{dsp_files_dir}/ms5_core0.out\"+"
    #load_ti_parameters += "\"#{dsp_files_dir}/ms5_core1.out\"+"
    #load_ti_parameters += "\"#{dsp_files_dir}/ms5_core2.out\"+"
    #load_ti_parameters += "\"#{dsp_files_dir}/ms5_core3.out\""
    
    dsp_file = get_file_and_path(LINUX_PC(), "core0")
    last_file = dsp_file if dsp_file != ""
    load_ti_parameters += " \"#{dsp_file}\"" if dsp_file != ""
    dsp_file = get_file_and_path(LINUX_PC(), "core1")
    last_file = dsp_file if dsp_file != ""
    load_ti_parameters += "+\"#{dsp_file}\"" if dsp_file != ""
    dsp_file = get_file_and_path(LINUX_PC(), "core2")
    last_file = dsp_file if dsp_file != ""
    load_ti_parameters += "+\"#{dsp_file}\"" if dsp_file != ""
    dsp_file = get_file_and_path(LINUX_PC(), "core3")
    last_file = dsp_file if dsp_file != ""
    load_ti_parameters += "+\"#{dsp_file}\"" if dsp_file != ""
    #load_ti_parameters += " 2>&1"
    #load_ti_parameters += " &"
    cmd_wait_string = File.basename(last_file)
    
    dsp_run_command = "export LOADTI_PATH=#{@load_ti_dir} ; cd #{@load_ti_dir} ; #{@dss_dir}/dss.sh #{@load_ti_dir}/main.js #{load_ti_parameters}"
    @vatf_helper.log_info(@vatf_helper.ALPHA_SIDE(), "DSP run command: #{dsp_run_command}")
    start_thread = true
    # Load DSP .out file using DSS
    if start_thread
      dsp_thread = Thread.new {
        #system "export LOADTI_PATH=#{@load_ti_dir} ; cd #{@load_ti_dir} ; #{@dss_dir}/dss.sh #{@load_ti_dir}/main.js #{load_ti_parameters}"
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
    #logger_dir = "/home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger"
    logger_dir = File.dirname(@femto_logger_log_file)
    logger_file = File.basename(@femto_logger_log_file)
    executable_dir = File.dirname(@femto_logger_executable)
    executable_file = File.basename(@femto_logger_executable)
    parameters = "-v #{evm_ip} --port=22225"
    parameters += " --dir #{logger_dir} --logfile #{logger_file}"
    parameters += " 2>&1"
    cmd_wait_string = ""
    femto_thread = Thread.new {
      system "cd #{executable_dir} ; ./#{executable_file} #{parameters}"
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
    #rx_port = "4500"
    #tx_port = "4500"
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
    @is_cmd_shell = true
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
    @is_cmd_shell = true
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
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "netstat -rn", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "route -n", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "arp -a", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    if !is_alpha_side
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "cat /proc/net/xfrm_stat", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    end
  end

  def exit_cmd_shell(is_alpha_side)
    if !is_alpha_side
      # On EVM get out of the cmd_shell
      if @is_cmd_shell
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "exit", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
        @is_cmd_shell = false
      end
    end
  end

  def get_net_stats(is_alpha_side)
    exit_cmd_shell(is_alpha_side)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "netstat -rn", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route -n", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "arp -a", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    get_route_xfrm_info(is_alpha_side)
    if !is_alpha_side
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /var/log/netfp_proxy.log", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
      #@vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cat /proc/net/xfrm_stat", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
    end
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "cat /proc/sys/net/ipv4/route/gc_timeout", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "ip -s xfrm policy", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "ip -s xfrm state", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "ipsec status", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @sudo_cmd, "ipsec statusall", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 5)
  end

  def run_nash_pal_test_bench(equipment, test_secs, is_pass_through, ipsecVatf)
    #array_of_arm_files = Array.new
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
    dut_ip = get_ip_addr(@vatf_helper.vatf_dut_ref)
    server_tftp_base_dir = equipment[@vatf_helper.vatf_server_ref].tftp_path

    # Set the trigger phrases to be used for determining if the test is running properly
    #bad_dsp_arm_communication_phrase = "size: 100,"
    bad_dsp_arm_communication_phrase = "recvCnt: 0,"
    dsp_started_phrase = "BOAM com test"
    bad_recv_count_phrase = "recvCnt: 0,"
    
    #femto_logger_log_file = "/home/gtscmcsdk-systest/tempdown/MS45/femtologger/logger/logger_out.txt"
    # The next two lines are debug code. Remove when code is working.
    #validate_results(femto_logger_log_file, is_ms5_or_greater)
    #return
    
    # Set files to be used transferred and used on ARM
#    array_of_arm_files.push("miw_utest_iubl")
#    array_of_arm_files.push("miw_utest_boam")
#    if is_ms5_or_greater
#      array_of_arm_files.push("miw_utest_pma")
#      transfer_files_to_evm(array_of_arm_files, @from_path, @to_path, server_ip)
#      # This file will not be transfered since it is already on the file system in MS5 or greater, but it needs to be used
#      array_of_arm_files.push("msgrouter.out")
#    else
#      array_of_arm_files.push("msgrouter.out")
#      array_of_arm_files.push("setup_snooper_env.sh")
#      array_of_arm_files.push("ipsecsnooper.out")
#      array_of_arm_files.push("setup_shell_env.sh")
#      array_of_arm_files.push("ipsecmgr_cmd_shell.out")
#      transfer_files_to_evm(array_of_arm_files, @from_path, @to_path, server_ip)
#    end

    if is_ms5_or_greater
      # Set miw_apps array for MS5 files
      ms5_file_set(TRANSFER())
    else
      # Set miw_apps array for MS4x files
      ms4x_file_set(TRANSFER())
    end

    display_path_info()
    
    # Copy MIW apps files to the proper server side tftp directory
    copy_miw_files_to_tftp_dir(server_tftp_base_dir)
    # Copy MIW apps files to the proper EVM directory
    move_files_to_evm(server_ip)

    if is_ms5_or_greater
      # Add executeables that are used but already exist in the file system to that miw_apps array
      ms5_file_set(USED())
    end
    
    # Debug code. Remove when working
    #exit
    
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
      run_router_and_miw_arm_executeables(@miw_apps, @to_path, is_ms5_or_greater)
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
        #run_snooper(@miw_apps, @to_path)
        run_nefpproxy("/usr/bin/")
        get_route_xfrm_info(@vatf_helper.BETA_SIDE())
        get_route_xfrm_info(@vatf_helper.ALPHA_SIDE())
        #run_offloader(@miw_apps, @to_path, policy_index_in, policy_index_out, RETURN_ON_FIRST_ERROR)
        if is_ms5_or_greater
          run_offloader_new(@miw_apps, @to_path, policy_index_in, policy_index_out, CONTINUE_ON_ERROR())
          sleep(30)
        else
          run_offloader(@miw_apps, @to_path, policy_index_in, policy_index_out, CONTINUE_ON_ERROR())
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
          validate_results(@femto_logger_log_file, is_ms5_or_greater)
        end
      end
    else
      run_router_and_miw_arm_executeables(@miw_apps, @to_path, is_ms5_or_greater)
    end
    get_net_stats(@vatf_helper.BETA_SIDE())
    get_net_stats(@vatf_helper.ALPHA_SIDE())
    #@vatf_helper.smart_send_cmd_wait(@vatf_helper.ALPHA_SIDE(), @normal_cmd, "cat #{echopkt_log_file}", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0, 75)
    puts(" Nash PAL test bench finished\n")
  end
end

class SmartCardUtilities
  def initialize
    @vatf_helper = VatfHelperUtilities.new
    @lnx_helper = LinuxHelperUtilities.new
    
    @result = 0
    @result_text = ""
    
    @pin_number = "1234"
    @alpha_side_working_directory = ""
    @beta_side_working_directory = "/home/root/download"
    @alpha_side_tftp_server_directory = ""
    @beta_side_tftp_server_directory = ""
    @libsecstore = "/usr/lib/softhsm/libsecstore.so.1"
    @secure_store_label = "token-0"
    
    @vatf_dut_ref = 'dut1'
    @vatf_server_ref = 'server1'
    @equipment = ""
    @error_bit = 2
    @openssl_prompt = "OpenSSL>"
    @sudo_cmd = true
    @normal_cmd = false
    @command_done_addition = ";cmddoneprefix=command;echo $cmddoneprefix done."
    @command_done_trigger = "command done."
    @pin_prompt1 = /SO PIN:/
    @pin_prompt2 = /user PIN:/
    @token_initialized = "initialized."
  end

  def clear_result()
    @lnx_helper.clear_result()
    @vatf_helper.clear_result()
    @result = 0
    @result_text = ""
  end

  def set_pin_number(pin_number)
    @pin_number = pin_number if (pin_number != "")
  end

  def set_common(equipment, vatf_server_ref, vatf_dut_ref)
    @vatf_dut_ref = vatf_dut_ref if (vatf_dut_ref != "")
    @vatf_server_ref = vatf_server_ref if (vatf_server_ref != "")
    @equipment = equipment if (equipment != "")
    @vatf_helper.set_common(@equipment, @vatf_server_ref, @vatf_dut_ref)
    @lnx_helper.set_vatf_equipment(@equipment)
  end

  def set_alpha_side_directories(working_directory, tftp_directory)
    @alpha_side_working_directory = working_directory if (working_directory != "")
    @alpha_side_tftp_server_directory = tftp_directory if (tftp_directory != "")
  end

  def set_beta_side_directories(working_directory, tftp_directory)
    @beta_side_working_directory = working_directory if (working_directory != "")
    @beta_side_tftp_server_directory = tftp_directory if (tftp_directory != "")
  end

  def show_secure_store(is_alpha_side)
    command = "softhsm-util --show-slots --module #{@libsecstore} #{@command_done_addition}"
    return @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", @command_done_trigger, @error_bit, 0, 45)
  end

  def is_error_result?(is_alpha_side, error_area="setting up secure store")
    is_error = (@vatf_helper.result != 0 ? true : false)
    if is_error
      @result_text += "\r\n An error occurred while #{error_area}...\r\n" if (@result == 0)
      @result |= @error_bit
      @vatf_helper.log_info(is_alpha_side, @result_text)
    end
    return is_error
  end

  def fix_strongswan_conf_file_if_needed(is_alpha_side)
    equip = @equipment[(is_alpha_side ? @vatf_server_ref : @vatf_dut_ref)]
    if !check_cmd?("cat /etc/strongswan.conf | grep libsecstore.so.1", equip)
      command = "sed -i 's/libsecstore.so/libsecstore.so.1/g' /etc/strongswan.conf"
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", "#{@pin_prompt1}", @error_bit, 0, 5)
    end
  end

  def initialize_secure_store(is_alpha_side)
    equip = @equipment[(is_alpha_side ? @vatf_server_ref : @vatf_dut_ref)]
    return @vatf_helper.result if is_error_result?(is_alpha_side)
    no_cmd_echo_chk = false
    command = "softhsm-util  --init-token --slot 0 --label #{@secure_store_label} --module #{@libsecstore}"
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, command, @pin_prompt1, @error_bit, 0, 5)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, @pin_number, @pin_prompt1, @vatf_helper.DONT_SET_ERROR_BIT(), 0, 2, no_cmd_echo_chk)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, @pin_number, @pin_prompt2, @vatf_helper.DONT_SET_ERROR_BIT(), 0, 2, no_cmd_echo_chk)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, @pin_number, @pin_prompt2, @vatf_helper.DONT_SET_ERROR_BIT(), 0, 2, no_cmd_echo_chk)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, @pin_number, @token_initialized, @error_bit, 0, 15, no_cmd_echo_chk)
    return @vatf_helper.result if is_error_result?(is_alpha_side, "initializing secure store")
    # Soft reboot
    reboot(equip)
    show_secure_store(is_alpha_side)
    fix_strongswan_conf_file_if_needed(is_alpha_side)
  end

  def initialize_secure_store_if_needed(is_alpha_side)
    command_response = show_secure_store(is_alpha_side)
    secure_store_match = /Label:\s*#{@secure_store_label}/.match(command_response)
    if secure_store_match == nil
      initialize_secure_store(is_alpha_side)
    end
  end

  def open_openssl_shell(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "openssl", @openssl_prompt, @error_bit, 0)
  end

  def load_pkcs11_engine(is_alpha_side)
    return @vatf_helper.result if is_error_result?(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "engine -vvvv dynamic -pre SO_PATH:/usr/lib/engines/engine_pkcs11.so -pre ID:pkcs11 -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:#{@libsecstore} -pre \"VERBOSE\" -pre \"PIN:#{@pin_number}\"", @openssl_prompt, @error_bit, 0)
  end

  def open_smartcard_session(is_alpha_side)
    open_openssl_shell(is_alpha_side)
    load_pkcs11_engine(is_alpha_side)
  end

  def close_smartcard_session(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "quit", "", @error_bit, 0)
  end

  def send_smartcard_command(is_alpha_side, command)
    return @vatf_helper.result if is_error_result?(is_alpha_side)
    working_directory = (is_alpha_side ? @alpha_side_working_directory : @beta_side_working_directory)
    # Change to working directory
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "cd #{working_directory}", "", @error_bit, 0)
    # Go to openssl command prompt and load pkcs11 engine
    open_smartcard_session(is_alpha_side)
    # Send openssl command
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", @openssl_prompt, @error_bit, 0, 45)
    # Close openssl command prompt
    close_smartcard_session(is_alpha_side)
  end

  def store_certificate(is_alpha_side, slot_num, id_num, label_name, cert_file_name)
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"STORE_CERT:slot_#{slot_num}:id_#{id_num}:label_#{label_name}:cert_#{cert_file_name}\"")
  end

  def generate_rsa_key_pair(is_alpha_side, slot_num, id_num, label_name)
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"GEN_KEY:slot_#{slot_num}:size_2048:id_#{id_num}:label_#{label_name}\"")
  end

  def retrieve_public_key(is_alpha_side, slot_num, id_num, label_name, key_file_name)
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"GET_PUBKEY:slot_#{slot_num}:id_#{id_num}:label_#{label_name}:key_#{key_file_name}\"")
  end

  def list_objects_in_key_store(is_alpha_side, slot_num)
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"LIST_OBJS:#{slot_num}\"")
  end

  def remove_certificate(is_alpha_side, slot_num, id_num, label_name)
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"DEL_OBJ:slot_#{slot_num}:type_cert:id_#{id_num}:label_#{label_name}:cert\"")
  end

  def remove_certificate_based_on_file(is_alpha_side, slot_num, id_num, file_name_and_path)
    label_name = File.basename(file_name_and_path).split(".")[0]
    remove_certificate(is_alpha_side, slot_num, id_num, label_name)
  end

  def remove_key_set(is_alpha_side, slot_num, id_num, label_name)
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"DEL_OBJ:slot_#{slot_num}:type_pubkey:id_#{id_num}:label_#{label_name}:key\"")
    send_smartcard_command(is_alpha_side, "engine pkcs11 -pre \"DEL_OBJ:slot_#{slot_num}:type_privkey:id_#{id_num}:label_#{label_name}:key\"")
  end

  def remove_key_set_based_on_file(is_alpha_side, slot_num, id_num, file_name_and_path)
    label_name = File.basename(file_name_and_path).split(".")[0]
    remove_key_set(is_alpha_side, slot_num, id_num, label_name)
  end

  def start_smartcard(is_alpha_side)
    return if is_error_result?(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "/etc/init.d/softhsm-daemon.sh start", "", @error_bit, 0)
  end

  def stop_smartcard(is_alpha_side)
    return if is_error_result?(is_alpha_side)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "/etc/init.d/softhsm-daemon.sh stop", "", @error_bit, 0)
  end

  def get_pubic_key_via_tftp(is_alpha_side, host_ip, slot_num, id_num, label_name, key_file_name)
    from_path = (is_alpha_side ? @alpha_side_working_directory : @beta_side_working_directory)
    to_path = (is_alpha_side ? @alpha_side_tftp_server_directory : @beta_side_tftp_server_directory)
    retrieve_public_key(is_alpha_side, slot_num, id_num, label_name, key_file_name)
    @lnx_helper.tftp_put_file(key_file_name, from_path, to_path, host_ip, is_alpha_side)
  end

  def put_cert_file_via_tftp(is_alpha_side, host_ip, slot_num, id_num, label_name, cert_file_name)
    # The directories used here are from the point of view of the EVM tftping from the Linux PC or the EVM tftping to the Linux PC
    from_path = (is_alpha_side ? @alpha_side_tftp_server_directory : @beta_side_tftp_server_directory)
    to_path = (is_alpha_side ? @alpha_side_working_directory : @beta_side_working_directory)
    @lnx_helper.tftp_file(cert_file_name, from_path, to_path, host_ip, @vatf_helper.BETA_SIDE())
    store_certificate(is_alpha_side, slot_num, id_num, label_name, cert_file_name)
  end

  def secrets_store(key_id)
    return ": PIN %smartcard0@secstore:#{key_id} #{@pin_number}"
  end

  def result
    @result
  end

  def result_text
    @result_text
  end
end

class CascadeSetupUtilities
  def initialize
    @vatf_helper = VatfHelperUtilities.new
    @lnx_helper = LinuxHelperUtilities.new
    
    @bridge_ipv4_ip_address = ""
    @bridge_ipv6_ip_address = "2000::3/64"
    @bridge_default_gw_ip_address = ""
    
    @dtb_tftp_path = "multi_if_dtb/"
    @dtb_multi_if_filename = "tci6614-evm-multi-if.dtb"
    @dtb_local_path = "/home/root/download"
    @dtb_single_if_filename = "tci6614-evm.dtb"
    
    @tftp_server_tftp_path="/tftpboot/multi_if_dtb/"
    @tftp_server_from_path="/home/gtscmcsdk-systest/tempdown/temp_MS5_arm_executeables"
    
    @mnt_directory = "/mnt/boot"
    @mount_command = "mount /dev/ubi0_0"
    
    @reboot_wait_prompt="evm ttyS0"
    @evm_login="root"
    
    @vatf_dut_ref = 'dut1'
    @vatf_server_ref = 'server1'
    @equipment = ""
    @error_bit = 3
    @sudo_cmd = true
    @normal_cmd = false
    
    @result = 0
    @result_text = ""
  end

  def set_common(equipment, vatf_server_ref, vatf_dut_ref, evm_login)
    @vatf_dut_ref = vatf_dut_ref if (vatf_dut_ref != "")
    @vatf_server_ref = vatf_server_ref if (vatf_server_ref != "")
    @evm_login = evm_login if (evm_login != "")
    @equipment = equipment if (equipment != "")
    @vatf_helper.set_common(@equipment, @vatf_server_ref, @vatf_dut_ref)
    @lnx_helper.set_vatf_equipment(@equipment)
  end

  def set_bridge_info(bridge_ipv4_ip_address, bridge_ipv6_ip_address, bridge_default_gw_ip_address)
    @bridge_ipv4_ip_address = bridge_ipv4_ip_address if (bridge_ipv4_ip_address != "")
    @bridge_ipv6_ip_address = bridge_ipv6_ip_address if (bridge_ipv6_ip_address != "")
    @bridge_default_gw_ip_address = bridge_default_gw_ip_address if (bridge_default_gw_ip_address != "")
  end

  def set_tftp_info(dtb_tftp_path, dtb_multi_if_filename, dtb_local_path, dtb_single_if_filename, tftp_server_tftp_path, tftp_server_from_path)
    @dtb_tftp_path = dtb_tftp_path if (dtb_tftp_path != "")
    @dtb_multi_if_filename = dtb_multi_if_filename if (dtb_multi_if_filename != "")
    @dtb_local_path = dtb_local_path if (dtb_local_path != "")
    @dtb_single_if_filename = dtb_single_if_filename if (dtb_single_if_filename != "")
    @tftp_server_tftp_path = tftp_server_tftp_path if (tftp_server_tftp_path != "")
    @tftp_server_from_path = tftp_server_from_path if (tftp_server_from_path != "")
  end

  def copy_dtb_files_to_tftp_server_tftp_directory()
    is_alpha_side = true
    @lnx_helper.copy_file(@dtb_multi_if_filename, @tftp_server_from_path, @tftp_server_tftp_path, is_alpha_side)
    @lnx_helper.copy_file(@dtb_single_if_filename, @tftp_server_from_path, @tftp_server_tftp_path, is_alpha_side)
  end

  def mount_boot_dir_and_go_there()
    is_alpha_side = false
    
    #root@tci6614-evm:~# mkdir /mnt/boot
    #root@tci6614-evm:~# mount /dev/ubi0_0 /mnt/boot
    #
    #UBIFS: mounted UBI device 0, volume 0, name "boot"
    #UBIFS: file system size:   3936256 bytes (3844 KiB, 3 MiB, 31 LEBs)
    #UBIFS: journal size:       1142785 bytes (1116 KiB, 1 MiB, 8 LEBs)
    #UBIFS: media format:       w4/r0 (latest is w4/r0
    #UBIFS: default compressor: lzo
    #UBIFS: reserved for root:  0 bytes (0 KiB) root@tci6614-evm:~# 
    #root@tci6614-evm:~# root@tci6614-evm:~# cd /mnt/boot 
    #root@tci6614-evm:/mnt/boot# ls 
    
    # Mount boot directory and then go there
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cd ~/ ; mkdir #{@mnt_directory}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#{@mount_command} #{@mnt_directory}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cd #{@mnt_directory}", "", @error_bit, 0)
  end

  def reboot_evm_and_login()
    is_alpha_side = false
    # Reboot unit and then log back in
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "reboot", @reboot_wait_prompt, @error_bit, 2, 45)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "#{@evm_login}", "", @error_bit, 1)
  end

  #def copy_dtb_file_to_evm_file_system_and_reboot_evm()
  def copy_multiIf_dtb_file_to_evm_boot_directory_and_reboot_evm_to_use_this_file()
    is_alpha_side = false
    local_path_and_filename = File.join(@dtb_local_path, @dtb_multi_if_filename)
    overwrite_path_and_filename = File.join(@mnt_directory, @dtb_single_if_filename)
    # Mount boot directory and then go there
    mount_boot_dir_and_go_there()
    # Copy multi if dtb file to mount directory
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cp #{local_path_and_filename} #{overwrite_path_and_filename}", "", @error_bit, 2)
    # Reboot unit and then log back in
    reboot_evm_and_login()
  end

  def copy_singleIf_dtb_file_to_evm_boot_directory_and_reboot_evm_to_use_this_file()
    is_alpha_side = false
    local_path_and_filename = File.join(@dtb_local_path, @dtb_single_if_filename)
    overwrite_path_and_filename = File.join(@mnt_directory, @dtb_single_if_filename)
    # Mount boot directory and then go there
    mount_boot_dir_and_go_there()
    # Copy multi if dtb file to mount directory
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "cp #{local_path_and_filename} #{overwrite_path_and_filename}", "", @error_bit, 2)
    # Reboot unit and then log back in
    reboot_evm_and_login()
  end

  def transfer_dtb_files_to_evm(tftp_host)
    is_alpha_side = false
    @lnx_helper.tftp_file(@dtb_multi_if_filename, @dtb_tftp_path, @dtb_local_path, tftp_host, is_alpha_side)
    @lnx_helper.tftp_file(@dtb_single_if_filename, @dtb_tftp_path, @dtb_local_path, tftp_host, is_alpha_side)
  end

  def set_bridge_interfaces()
    is_alpha_side = false
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "ifconfig eth0 0.0.0.0 up", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "ifconfig eth1 0.0.0.0 up", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "brctl addbr br0", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "brctl addif br0 eth0", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "brctl addif br0 eth1", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "ifconfig br0 #{@bridge_ipv4_ip_address} netmask 255.255.255.0 up", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "ip addr add #{@bridge_ipv6_ip_address} dev br0", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "route add default gw #{@bridge_default_gw_ip_address}", "", @error_bit, 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side, @normal, "ifconfig", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "ifconfig", "eth1", @error_bit, 2)
    if (result() != 0)
      @result_text += " Fatal Error: EVM is not in cascade mode. Eth1 was not detected.\r\n"
      return
    else
      @result_text += " Unit appears to be in Cascade mode. Eth1 interface was detected.\r\n"
    end
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal, "route -n", "", @error_bit, 0)
  end

  def result()
    @result |= @vatf_helper.result
    return @result
  end

  def result_text()
    @result_text
  end

end

class TputBinarySearch
  def initialize
    # set default search values. User can do an init_search_values to change these before execution.
    @max_mbps = 1000
    @previous_tested_mbps = @max_mbps
    @best_mbps = 0
    @search_increment= 25
    @binary_search_complete = false
  end

  def binary_search_complete
    @binary_search_complete
  end

  def init_search_values(max_mbps, step)
    @max_mbps = max_mbps
    @previous_tested_mbps = @max_mbps
    @best_mbps = 0
    @search_increment = step
    @binary_search_complete = false
    return 0
  end

  def incremented_value(value)
    new_value = (value / @search_increment) * @search_increment
    new_value += @search_increment if (value - ((@search_increment / 2) + 1)) > new_value
    new_value = @search_increment if new_value < @search_increment
    return new_value
  end

  def binary_search(tested_mbps, measured_mbps, vatf_helper, perf_client_side)
    new_test_mbps = measured_mbps
    action = "go_higher" if (tested_mbps - measured_mbps) == 0
    action = "go_higher" if (tested_mbps - measured_mbps) < 0
    action = "go_lower" if (tested_mbps - measured_mbps) > 0

    @best_mbps = measured_mbps if measured_mbps > @best_mbps

    #puts("\r\n before: ac:#{action}, t:#{tested_mbps}, m:#{measured_mbps}, b:#{@best_mbps}, p:#{@previous_tested_mbps}\r\n")
    vatf_helper.log_info(perf_client_side, " before: ac:#{action}, t:#{tested_mbps}, m:#{measured_mbps}, b:#{@best_mbps}, p:#{@previous_tested_mbps}\r\n")

    case action
      when "go_higher"
        new_test_mbps = @best_mbps + ((@previous_tested_mbps - @best_mbps) / 2)
        @binary_search_complete = true if (@search_increment >= (@previous_tested_mbps - @best_mbps).abs || measured_mbps >= @max_mbps)
      when "go_lower"
        lower_mbps = @best_mbps
        upper_mbps = tested_mbps
        new_test_mbps = lower_mbps + ((upper_mbps - lower_mbps) / 2)
        @binary_search_complete = true if @search_increment >= (@previous_tested_mbps - @best_mbps).abs
    end

    if @binary_search_complete
      new_test_mbps = @previous_tested_mbps
    end

    @previous_tested_mbps = tested_mbps

    #puts("\r\n after: ac:#{action}, t:#{tested_mbps}, m:#{measured_mbps}, b:#{@best_mbps}, p:#{@previous_tested_mbps}\r\n")
    vatf_helper.log_info(perf_client_side, " after: ac:#{action}, t:#{tested_mbps}, m:#{measured_mbps}, b:#{@best_mbps}, p:#{@previous_tested_mbps}\r\n")
    return incremented_value(new_test_mbps)
  end

end

class PerfUtilities
  def initialize
    @lnx_helper = LinuxHelperUtilities.new
    @vatf_helper = VatfHelperUtilities.new

    @result = 0
    @error_result_text = ""
    @error_bit = 0
    @result_text = ""
    @session_result_text = ""
    @vatf_dut_ref = ""
    @vatf_server_ref = ""
    @equipment = ""
    @vatf_dut_ref = 'dut1'
    @vatf_server_ref = 'server1'
    @alpha_ip = ""
    @beta_ip = ""
    @alpha_ipv6 = ""
    @beta_ipv6 = ""
    @is_ipv4 = IPV4()
    @additional_alpha_params = ""
    @additional_beta_params = ""
    @free_mem_start = ""
    @free_mem_end = ""

    @max_mbps = 0
    @best_mbps = 0
    @adjusted_max_mbps = 0
    @binary_increment = 0
    @binary_search_complete = false
    @auto_bandwidth_detect = false
    @auto_bw_test_secs = 5
    @perf_app = IPERF_APP()
    @iperf_threads = 2
    @test_direction = INGRESS()
    @min_ingress_mbps = 0
    @min_egress_mbps = 0
    @first_xfrm_stat = Array.new
    @next_xfrm_stat = Array.new
    @first_sideband_stat = Array.new
    @next_sideband_stat = Array.new
    clear_stat_arrays()

    # Static variable settings
    @sudo_cmd = true
    @normal_cmd = false
    @iperf_cmd = "iperf "
    @netperf_cmd = "netperf "
    @max_retries = 3
    @error_bit = 5
    @xfrm_stats_accumulation = 0
    @xfrm_stat_command = "cat /proc/net/xfrm_stat"
    @sideband_stat_command = "cat /sys/devices/soc.0/20c0000.crypto/stats/tx_drop_pkts"
    @wait_for_text = "command_done"
  end

  def IPERF_APP()
    return "iperf"
  end

  def NETPERF_APP()
    return "netperf"
  end

  def INGRESS()
    return "ingress"
  end

  def EGRESS()
    return "egress"
  end

  def BOTH()
    return "both"
  end

  def IPV4()
    return true
  end

  def IPV6()
    return false
  end

  def set_auto_bandwidth_detect(state)
    @auto_bandwidth_detect = state
  end

  def set_perf_app(string)
    case string.downcase
      when IPERF_APP()
        @perf_app = IPERF_APP()
      when NETPERF_APP()
        @perf_app = NETPERF_APP()
    end
  end

  def clear_stat_arrays()
    @first_xfrm_stat.clear
    @next_xfrm_stat.clear
    @first_sideband_stat.clear
    @next_sideband_stat.clear
  end

  def ALPHA_SIDE()
    return true
  end

  def BETA_SIDE()
    return false
  end

  def equipment_set(equipment)
    @equipment = equipment if (equipment != "")
  end

  def set_helper_common(equipment, vatf_server_ref, vatf_dut_ref)
    @vatf_dut_ref = vatf_dut_ref if (vatf_dut_ref != "")
    @vatf_server_ref = vatf_server_ref if (vatf_server_ref != "")
    @equipment = equipment if (equipment != "")
    @vatf_helper.set_common(@equipment, @vatf_server_ref, @vatf_dut_ref)
    @lnx_helper.set_vatf_equipment(@equipment)
  end

  def clear_results()
    @lnx_helper.clear_result()
    @vatf_helper.clear_result()
    @result = 0
    @result_text = ""
    @session_result_text = ""
    @error_result_text = ""
  end

  def clear_result_text()
    @result_text = ""
    @session_result_text = ""
  end

  def result()
    @result |= @vatf_helper.result
    return @result
  end

  def result_text
    @result_text
  end

  def is_task_running(is_alpha_side, task_name, check_string)
    monitor_secs = 1
    task_started = false
    task_check_command = "ps -ef | grep \"#{task_name}\" | grep -v grep"
    response_string = @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, task_check_command, "force fail", @vatf_helper.DONT_SET_ERROR_BIT(), 0, monitor_secs)
    #task_check_command = "ps -ef | grep \"#{task_name}\" | grep -v grep ; echo $WAITFOR"
    #response_string = @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, task_check_command, @wait_for_text, @vatf_helper.DONT_SET_ERROR_BIT(), 0, monitor_secs)
    response_string.gsub!(task_check_command, "")
    @vatf_helper.log_info(is_alpha_side, "\r\n is_task_running response_string: \"#{response_string}\")\r\n")
    task_started = true if response_string.downcase.include?(check_string.downcase)
  end

  def kill_task(is_alpha_side, task_name)
    @vatf_helper.log_info(is_alpha_side, "\r\n kill_task... (#{task_name}\r\n")
    if is_task_running(is_alpha_side, task_name, task_name)
      @vatf_helper.log_info(is_alpha_side, "\r\n kill -9 `ps -ef | grep \"#{task_name}\" | grep -v grep | awk '{print $2}'`\r\n")
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "kill -9 `ps -ef | grep \"#{task_name}\" | grep -v grep | awk '{print $2}'`", "", @error_bit, 0)
      count = 30
      while is_task_running(is_alpha_side, task_name, task_name)
        break if count <= 0
        # sleep(2)
        count -= 1
        @vatf_helper.log_info(is_alpha_side, "\r\n Waiting for task \"#{task_name}\" to be removed... (#{count})\r\n")
      end
    end
  end

  def iperf_server_start(is_alpha_side, protocol, monitor_secs, packet_size, file_pipe="")
    command = ""
    command += @iperf_cmd
    command += "-s "
    if !@is_ipv4
      command += "-V "
      command += "-B #{(is_alpha_side ? @alpha_ipv6 : @beta_ipv6)} "
    end
    command += "-u " if protocol == "udp"
    command += (is_alpha_side ? @additional_alpha_params : @additional_beta_params)
    command += " --len #{packet_size} "
    command += file_pipe
    command += " 2>&1 "
    command += "&"
    @vatf_helper.log_info(is_alpha_side, "\r\n Starting iperf server thread... (command: #{command})\r\n")
    server_thread = Thread.new {
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", "Mbits/sec", @error_bit, 0, monitor_secs)
    }
    @vatf_helper.log_info(is_alpha_side, "\r\n Iperf server thread is running.\r\n")
    return server_thread
  end

  def netperf_server_start(is_alpha_side, protocol, monitor_secs, file_pipe="")
    command = ""
    command += "netserver"
    if !is_task_running(is_alpha_side, "#{command}", "#{command}")
      command += (is_alpha_side ? @additional_alpha_params : @additional_beta_params)
      @vatf_helper.log_info(is_alpha_side, "\r\n Starting netperf server thread... (command: #{command})\r\n")
      server_thread = Thread.new {
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0, monitor_secs)
      }
      sleep(5)
    else
      server_thread = Thread.new {
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#Netperf is already running.", "", @error_bit, 0, monitor_secs)
      }
    end
    @vatf_helper.log_info(is_alpha_side, "\r\n Netperf server thread is running.\r\n")
    return server_thread
  end

  def server_start(is_alpha_side, protocol, monitor_secs, packet_size, file_pipe="")
    case @perf_app
      when IPERF_APP()
        return iperf_server_start(is_alpha_side, protocol, monitor_secs, packet_size, file_pipe)
      when NETPERF_APP()
        return netperf_server_start(is_alpha_side, protocol, monitor_secs, file_pipe)
    end
  end

  def get_crypto_support(is_alpha_side)
    temp = ""
    command = "cat /proc/crypto"
    temp = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
  end

  def server_kill(is_alpha_side)
    task_name = ""
    case @perf_app
      when IPERF_APP()
        task_name = "iperf -s"
      when NETPERF_APP()
        task_name = (is_alpha_side ? "netserver" : "")
    end
    kill_task(is_alpha_side, task_name) if task_name != ""
  end

  def client_kill(is_alpha_side)
    task_name = ""
    case @perf_app
      when IPERF_APP()
        task_name = "iperf -c"
      when NETPERF_APP()
        task_name = "netperf"
    end
    kill_task(is_alpha_side, task_name) if task_name != ""
  end

  def run_top(is_alpha_side, test_seconds)
    do_top = true
    case @perf_app
      when IPERF_APP()
        do_top = true
      when NETPERF_APP()
        do_top = false
    end
    if do_top
      iterations = (test_seconds / 5)
      iterations = (iterations > 1 ? iterations : 2)
      command = "rm /home/root/top_stats.txt"
      temp = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
      command = "top -b -d 5 -n #{iterations} > /home/root/top_stats.txt &"
      temp = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
    end
  end

  def display_memfree_info()
    return "[#{@free_mem_start} / #{@free_mem_end}]"
  end

  def is_stat_string?(string)
    temp = string.scan(/[0-9]+/)
    # Return true if number found in string
    #puts(" string(len=#{temp.length}): #{string}\r\n")
    #sleep(1)
    return true if (temp.length == 1)
    #puts("   NOT A STAT STRING!\r\n")
    return false
  end

  def push_to_array(command, string, is_still_the_first_push)
    is_first_push = false
    case "#{command}"
      when "#{@xfrm_stat_command}"
        if !@first_xfrm_stat.any? or is_still_the_first_push
          @first_xfrm_stat.push(string) if is_stat_string?(string)
          is_first_push = true
        else
          @next_xfrm_stat.push(string) if is_stat_string?(string)
        end
      when "#{@sideband_stat_command}"
        if !@first_sideband_stat.any? or is_still_the_first_push
          @first_sideband_stat.push(string) if is_stat_string?(string)
          is_first_push = true
        else
          @next_sideband_stat.push(string) if is_stat_string?(string)
        end
    end
    return is_first_push
  end

  def stat_count_diff(command, curr_array, prev_array, index)
    diff_count = 0
    stat_count = ""
    # If arrays are different lengths then just use the current array's value
    if curr_array.length != prev_array.length
      stat_count = curr_array[index] if (curr_array.length > index)
    else
      # Make sure index is within bounds before continuing
      if (curr_array.length > index) and (prev_array.length > index)
        curr_stat_name = curr_array[index].scan(/[a-zA-Z\s\t]+/)[0]
        prev_stat_name = prev_array[index].scan(/[a-zA-Z\s\t]+/)[0]
        #puts("\r\n@xfrm_stats_accumulation1: #{curr_stat_name} / #{prev_stat_name}")
        # If it is the same stat name then check the difference
        if curr_stat_name == prev_stat_name
          curr_stat_count = curr_array[index].scan(/[0-9]+/)[0].to_i
          prev_stat_count = prev_array[index].scan(/[0-9]+/)[0].to_i
          diff_count = curr_stat_count - prev_stat_count
          stat_count = "#{curr_stat_name}#{diff_count}" if (diff_count != 0)
          if command == @xfrm_stat_command
            @xfrm_stats_accumulation += diff_count
            #puts("\r\n@xfrm_stats_accumulation2(#{curr_stat_name}}: #{@xfrm_stats_accumulation}/#{stat_count}")
            #sleep(1)
          end
        else
          stat_count = curr_array[index]
        end
      end
      puts("\r\n\r\n")
    end
    return stat_count 
  end

  def set_error_result_base_on_count_difference_verses_first_stat(command, set_error_bit)
    # Set current array and previous array to check for differences
    case command
      when @xfrm_stat_command
        @xfrm_stats_accumulation = 0
        curr_arr_to_check = (@next_xfrm_stat.kind_of?(String) ? [@next_xfrm_stat] : @next_xfrm_stat)
        prev_arr_to_check = (@first_xfrm_stat.kind_of?(String) ? [@first_xfrm_stat] : @first_xfrm_stat) 
      when @sideband_stat_command
        curr_arr_to_check = (@next_sideband_stat.kind_of?(String) ? [@next_sideband_stat] : @next_sideband_stat)
        prev_arr_to_check = (@first_sideband_stat.kind_of?(String) ? [@first_sideband_stat] : @first_sideband_stat) 
        @result_text += "Xfrm error count total: #{@xfrm_stats_accumulation}\r\n" if (@xfrm_stats_accumulation != 0)
    end
    # Scan arrays for different stat counts and log results if there are differences
    index = 0
    curr_arr_to_check.each do |line|
      stat_line = stat_count_diff(command, curr_arr_to_check, prev_arr_to_check, index)
      index += 1
      if stat_line != ""
        if set_error_bit
          @result |= @error_bit
        end
        @result_text += "Stat Error (#{command}): #{stat_line}\r\n"
      end
    end
  end

  def set_error_result_for_non_zero_stat(command, raw_buffer, set_error_bit)
    is_first_push = false
    temp = raw_buffer.split("\n")
    temp.each do |stat_line|
      is_first_push = push_to_array(command, stat_line.strip, is_first_push)
    end
    if !is_first_push
      set_error_result_base_on_count_difference_verses_first_stat(command, set_error_bit)
    end
  end

  def get_proc_info(is_alpha_side, crypto_mode)
    command = "cat /proc/meminfo"
    mem_stat = ""
    raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
    temp = raw_buffer.scan(/MemFree:[\s0-9.]* kB/)
    if temp.length >= 1
      mem_stat = "#{temp[0].gsub(" ", "")}"
      mem_stat = mem_stat.gsub("MemFree:", "")
      mem_stat = mem_stat.gsub("kB", " kB")
    end
    if @free_mem_start == ""
      @free_mem_start =  mem_stat
    else
      @free_mem_end =  mem_stat
    end
    stat_commands = Array.new
    stat_commands.push("cat /proc/net/snmp")
    stat_commands.push("ip -s xfrm state")
    if (is_crypto_omap)
      stat_commands.push("cat /proc/interrupts |grep edma")
      stat_commands.push("cat /proc/interrupts |grep sham")
    else
      stat_commands.push("cat /sys/devices/soc.0/20c0000.crypto/stats/rx_pkts")
      stat_commands.push("cat /sys/devices/soc.0/20c0000.crypto/stats/tx_pkts")
      stat_commands.push("cat /sys/devices/soc.0/20c0000.crypto/stats/sc_tear_drop_pkts")
      stat_commands.push("cat /sys/devices/soc.0/20c0000.crypto/stats/tx_drop_pkts")
    end

    #command = "ip -s xfrm state"
    #raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
    stat_commands.each do |stat_command|
      raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{stat_command}", "", @error_bit, 0)
    end
    command = @xfrm_stat_command
    raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
    set_error_result_for_non_zero_stat(command, raw_buffer, false)
    if (crypto_mode.downcase == "sideband") or (crypto_mode.downcase == "hardware")
      command = @sideband_stat_command
      raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
      set_error_result_for_non_zero_stat(command, raw_buffer, false)
    end
  end

  def get_top_idle_stat(is_alpha_side)
    lowest = "100"
    samples = 0
    count = 0
    average = 0
    result = ""
    command = "cat /home/root/top_stats.txt"
    raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{command}", "", @error_bit, 0)
    #temp = raw_buffer.scan(/ [0-9]*.[0-9]*%id/)
    temp = raw_buffer.scan(/[0-9]*.[0-9]*%id/)
    result += "\r\n CPU idle stats:\r\n"
    temp.each do |match_string|
      idle = match_string.gsub("%id", "")
      lowest = idle if (lowest.to_f > idle.to_f)
      # average only the middle samples. The first and last sample are not averaged in.
      if count >= 1 and samples < temp.length
        average += idle.to_f
        samples += 1
      end
      count += 1
      result += "\r\n  (lowest)#{match_string} : #{lowest}"
    end
    average = average.to_f / samples.to_f
    result += "\r\n  (average) : #{average}"
    result += "\r\n"
    #return lowest
    return "%3.1f" % [average]
  end

  def get_base_index_by_string(is_alpha_side, search_array, string)
    current_index = 0
    search_array.each do |stat|
      break if stat == string
      current_index += 1
    end

    count = 0
    temp_string = ""
    search_array.each do |stat|
      temp_string += "\r\n stat_values[#{count}]: #{stat}"
      count += 1
    end
    @vatf_helper.log_info(is_alpha_side, "#{temp_string}\r\n\r\n")

    return current_index
  end

  def get_tput_and_cpu_utilization_for_netperf(is_alpha_side, raw_buffer, protocol, tput_error_string, cpu_util_error_string)
    throughput = tput_error_string
    cpu_util_stat = cpu_util_error_string
    stat_values = raw_buffer.scan(/[0-9.]+|Demand/)
    base_index = get_base_index_by_string(is_alpha_side, stat_values, "Demand")
    tput_index = (protocol.downcase == "udp" ? 14 : 7) + base_index
    tx_util_index = (protocol.downcase == "udp" ? 9 : 8) + base_index
    rx_util_index = (protocol.downcase == "udp" ? 15 : 9) + base_index
    highest_index = rx_util_index
    if (stat_values.length > highest_index)
      tx_util = stat_values[tx_util_index]
      rx_util = stat_values[rx_util_index]
      throughput = stat_values[tput_index]
      # Only interested in the EVMs CPU utilization measurements so if on alpha side use the rx utilization number and if on the beta side use the tex utilization number
      cpu_util_stat = (is_alpha_side ? rx_util : tx_util)
    end
    return throughput, cpu_util_stat
  end

  def get_iperf_tput_number_from_buffer(is_alpha_side, raw_buffer, protocol, tput_error_string)
    throughput = tput_error_string
    if protocol.downcase == "tcp"
      tputs = raw_buffer.scan(/[0-9.]* Mbits\/sec/)
    else
      tputs = raw_buffer.scan(/[0-9.]* Mbits\/sec[\s0-9.ems\-\/(]*%\)/)
    end
    aggregated_throughput = 0
    tputs.each do | tput_info |
      @vatf_helper.log_info(is_alpha_side, "\r\n get_iperf_tput_number_from_buffer: (tputs.length: #{tputs.length}, tput_info: #{tput_info})\r\n")
      if protocol.downcase == "tcp"
        aggregated_throughput = tput_info.split(" ")[0].to_f
      else
        aggregated_throughput += tput_info.split(" ")[0].to_f
      end
    end
    if (tputs.length > 0)
      #throughput = aggregated_throughput.to_i
      throughput = aggregated_throughput
    end
    return throughput
  end

  def get_tput_and_cpu_utilization_for_iperf(is_alpha_side, raw_buffer, protocol, tput_error_string, cpu_util_error_string, auto_detect)
    throughput = tput_error_string
    cpu_util_stat = cpu_util_error_string
    cpu_idle_stat = get_top_idle_stat(is_alpha_side) if !auto_detect
    cpu_util_stat = "#{'%.2f' % (100 - cpu_idle_stat.to_f)}"
    throughput = get_iperf_tput_number_from_buffer(is_alpha_side, raw_buffer, protocol, tput_error_string)
    @vatf_helper.log_info(is_alpha_side, "\r\n get_tput_and_cpu_utilization_for_iperf: (throughput: #{format_tput(throughput)}, cpu_util_stat: #{cpu_util_stat})\r\n")
    return throughput, cpu_util_stat
  end

  def validate_throughput(ingress_tput, egress_tput)
    if ingress_tput != "" && @min_ingress_mbps != ""
      if @min_ingress_mbps.to_f > ingress_tput.to_f
        @result = @error_bit 
        @error_result_text += "\r\n\r\nFAILED: Throughput measurement for ingress was below the required #{@min_ingress_mbps} mbps.\r\n\r\n"
      end
    end
    if egress_tput != "" && @min_egress_mbps != ""
      if @min_egress_mbps.to_f > egress_tput.to_f
        @result = @error_bit 
        @error_result_text += "\r\n\r\nFAILED: Throughput measurement for egress was below the required #{@min_egress_mbps} mbps.\r\n\r\n"
      end
    end
    @vatf_helper.log_info(ALPHA_SIDE(), "\r\n perf @result_text: \"#{@error_result_text}\"\r\n")
  end

  def is_numeric?(input)
    is_numeric = false
    is_numeric = true if input.to_i.to_s == input.to_s
    is_numeric = true if input.to_f.to_s == input.to_s
    return is_numeric
  end

  def format_tput(throughput_string)
    return (is_numeric?(throughput_string) ? '%.1f' % throughput_string.to_f : throughput_string)
  end

  def get_tput_result_string(test_headline, ingress_tput, egress_tput, packet_size, cpu_util_stat)
    tput_result_display = ""
    validate_throughput(ingress_tput, egress_tput)
    if @test_direction != BOTH()
      throughput = (ingress_tput != "" ? ingress_tput : egress_tput)
      tput_result_display = "   Test: #{test_headline}, Tput: #{format_tput(throughput)}, Pkt_size: #{packet_size} [CPU_Util%: #{cpu_util_stat}]\r\n"
    else
      tput_result_display = "   Test: #{test_headline}, Tput_ingress: #{format_tput(ingress_tput)}, Tput_egress: #{format_tput(egress_tput)}, Pkt_size: #{packet_size} [CPU_Util%: #{cpu_util_stat}]\r\n"
    end
    return tput_result_display
  end

  def get_netperf_stat(is_alpha_side, test_headline, raw_buffer, protocol, packet_size, auto_detect=false)
    tput_ingress = ""
    tput_egress = ""
    throughput = "[ERROR: netperf measurement is incomplete]"
    cpu_util_stat = ""
    result_string = ""
    throughput, cpu_util_stat = get_tput_and_cpu_utilization_for_netperf(is_alpha_side, raw_buffer, protocol, throughput, cpu_util_stat)
    if @test_direction == INGRESS()
      tput_ingress = throughput
    else
      tput_egress = throughput
    end
    #result_string = "   Test: #{test_headline}, Tput: #{'%.1f' % throughput}, Pkt_size: #{packet_size} [CPU_Util%: #{cpu_util_stat}]\r\n"
    result_string = get_tput_result_string(test_headline, tput_ingress, tput_egress, packet_size, cpu_util_stat)
    @result = @error_bit if result_string.downcase.include?("error:")
    return result_string
  end

  def get_iperf_stat(is_alpha_side, test_headline, raw_buffer, protocol, packet_size, auto_detect=false)
    tput_ingress = ""
    tput_egress = ""
    throughput = "[ERROR: iperf measurement is incomplete]"
    cpu_util_stat = ""
    result_string = ""
    throughput, cpu_util_stat = get_tput_and_cpu_utilization_for_iperf(is_alpha_side, raw_buffer, protocol, throughput, cpu_util_stat, auto_detect)
    if @test_direction == INGRESS()
      tput_ingress = throughput
    else
      tput_egress = throughput
    end
    if !auto_detect
      #result_string = "   Test: #{test_headline}, Tput: #{'%.1f' % throughput}, Pkt_size: #{packet_size} [CPU_Util%: #{cpu_util_stat}]\r\n"
      result_string = get_tput_result_string(test_headline, tput_ingress, tput_egress, packet_size, cpu_util_stat)
    else
      #result_string = (!result_string.downcase.include?("error:") ? throughput.gsub(" Mbits/sec", "").to_i : 0)
      result_string = (!result_string.downcase.include?("error:") ? throughput.to_i : 0)
    end
    if !auto_detect
      @result = @error_bit if result_string.downcase.include?("error:")
    end
    return result_string
  end

  def get_perf_stat(is_alpha_side, test_headline, raw_buffer, protocol, packet_size, auto_detect=false)
    case @perf_app
      when IPERF_APP()
        return get_iperf_stat(is_alpha_side, test_headline, raw_buffer, protocol, packet_size, auto_detect)
      when NETPERF_APP()
        return get_netperf_stat(is_alpha_side, test_headline, raw_buffer, protocol, packet_size, auto_detect)
    end
  end

  def get_iperf_stat_simultaneous(is_alpha_side, test_headline, raw_buffer_ingress, raw_buffer_egress, protocol, packet_size)
    throughput_ingress = "[ERROR: iperf measurement is incomplete]"
    throughput_egress = throughput_ingress
    cpu_idle_stat = get_top_idle_stat(is_alpha_side)
    cpu_util_stat = "#{'%.2f' % (100 - cpu_idle_stat.to_f)}"
    result_string = ""
    throughput_ingress = get_iperf_tput_number_from_buffer(is_alpha_side, raw_buffer_ingress, protocol, throughput_ingress)
    throughput_egress = get_iperf_tput_number_from_buffer(is_alpha_side, raw_buffer_egress, protocol, throughput_egress)
    #result_string = "   Test: #{test_headline}, Tput_ingress: #{'%.1f' % throughput_ingress}, Tput_egress: #{'%.1f' % throughput_egress}, Pkt_size: #{packet_size} [CPU_Util%: #{cpu_util_stat}]\r\n"
    result_string = get_tput_result_string(test_headline, throughput_ingress, throughput_egress, packet_size, cpu_util_stat)
    @result = @error_bit if result_string.downcase.include?("error:")
    return result_string
  end

  def netperf_client_run(is_alpha_side, protocol, test_time, udp_bandwidth, packet_size)
    #wait_for_text = "/sec"
    #wait_for_text = " ms    "
    wait_for_text = "forcing timeout to occur"
    #wait_secs = test_time + 10
    wait_secs = test_time + 10
    command = ""
    command += @netperf_cmd
    command += "-H "
    command += (is_alpha_side ? @beta_ip : @alpha_ip)
    command += " -c -C "
    command += "-l #{test_time} "
    command += "-T 1 "
    command += "-t "
    command += "UDP_STREAM " if protocol.downcase == "udp"
    command += "TCP_STREAM " if protocol.downcase == "tcp"
    command += "-- -m #{packet_size}"
    #command += "-P 2 " if protocol.downcase == "tcp"
    #command += (is_alpha_side ? @additional_alpha_params : @additional_beta_params)
    @vatf_helper.log_info(is_alpha_side, "\r\n Starting netperf client... (command: #{command})\r\n")
    return @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", wait_for_text, @error_bit, 0, wait_secs)
  end

  def iperf_client_run(is_alpha_side, protocol, test_time, udp_bandwidth, packet_size)
    threaded_bandwidth = "#{(udp_bandwidth.to_f / @iperf_threads)}M"
    wait_for_text = "forcing timeout to occur"
    wait_secs = test_time + 10
    command = ""
    command += @iperf_cmd
    command += "-V " if !@is_ipv4
    command += "-c "
    command += (is_alpha_side ? (@is_ipv4 ? @beta_ip : @beta_ipv6) : (@is_ipv4 ? @alpha_ip : @alpha_ipv6))
    command += " "
    command += "-P #{@iperf_threads} --format m "
    command += "-u -b #{threaded_bandwidth} --len #{packet_size} " if protocol.downcase == "udp"
    command += "-M #{packet_size} -w 128K " if protocol.downcase == "tcp"
    command += "-t #{test_time} "
    command += (is_alpha_side ? @additional_alpha_params : @additional_beta_params)
    @vatf_helper.log_info(is_alpha_side, "\r\n Starting iperf client... (command: #{command})\r\n")
    return @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "#{command}", wait_for_text, @error_bit, 0, wait_secs)
  end

  def client_run(is_alpha_side, protocol, test_time, udp_bandwidth, packet_size)
    case @perf_app
      when IPERF_APP()
        return iperf_client_run(is_alpha_side, protocol, test_time, udp_bandwidth, packet_size)
      when NETPERF_APP()
        return netperf_client_run(is_alpha_side, protocol, test_time, udp_bandwidth, packet_size)
    end
  end

  def get_ip_address_for_eth_port_from_static_base(eth_port)
    static_ip_address = get_equipment_param_value('dut1', "static_ip_base_address")
    return "" if !static_ip_address
    static_ip_address_items = static_ip_address.split(".")
    octet_to_change = static_ip_address_items.length - 1
    eth_port_static_ip_address = ""
    separator = ""
    octet_count = 0
    static_ip_address_items.each do |ip_item|
      eth_port_static_ip_address += (octet_count == octet_to_change ? "#{separator}#{ip_item.to_i + eth_port}" : "#{separator}#{ip_item}")
      separator = "."
      octet_count += 1
    end
    return eth_port_static_ip_address
  end

  def isolate_dut_ethernet_test_port(iface_type)
    is_alpha_side = false
    this_eth_port = iface_type.split("eth")[1].to_i
    this_eth_static_ip_address = get_ip_address_for_eth_port_from_static_base(this_eth_port)
    wait_for_text = "id:"
    wait_secs = 10
    eth_min_port = 0
    eth_max_port = 5
    last_dhcp_port = 0
    do_dhclient = (this_eth_static_ip_address == "" ? true : false)
    if (this_eth_port > last_dhcp_port)
      if do_dhclient
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "ifconfig eth#{this_eth_port} up", "Link is Up", @vatf_helper.DONT_SET_ERROR_BIT(), 0, wait_secs)
        sleep(2)
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "dhclient eth#{this_eth_port} ; echo 'command_done'", "command_done", @vatf_helper.DONT_SET_ERROR_BIT(), 0, wait_secs)
      else
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "ifconfig eth#{this_eth_port} #{this_eth_static_ip_address} up", "Link is Up", @vatf_helper.DONT_SET_ERROR_BIT(), 0, wait_secs)
      end
    end
    for curr_port in (eth_min_port..eth_max_port)
      if curr_port != this_eth_port
        @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "ifconfig eth#{curr_port} down ; echo 'command_done'", "command_done", @vatf_helper.DONT_SET_ERROR_BIT(), 0, wait_secs)
      end
    end
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "ping #{@alpha_ip} -c 3", /seq=2.*?#{@equipment['dut1'].prompt}/m, @error_bit, 0, wait_secs)
    @result |= @vatf_helper.result
    @result_text += "Ping check for eth#{this_eth_port} did not pass.\r\n" if @result != 0
  end

  def find_eth_interface_by_ipaddress(ip_address, is_alpha_side)
    eth_iface = ""
    raw_ifconfig = @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "ifconfig", "force timeout" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 2)
    temp = raw_ifconfig.gsub("\n","").scan(/eth[0-9a-zA-Z\s:.]*\W*inet addr:[0-9.]+/)
    temp.each do |eth_item|
      if eth_item.include?(ip_address)
        eth_iface = eth_item.scan(/eth[0-9]*/)[0]
      end
    end
    return eth_iface
  end

  def set_mtu_size(mtu_set_size, evm_eth_port)
    eth_iface_evm = (evm_eth_port == "" ? "eth0" : "eth#{evm_eth_port}")
    eth_iface_pc = find_eth_interface_by_ipaddress(@alpha_ip, ALPHA_SIDE())
    @vatf_helper.smart_send_cmd_wait(ALPHA_SIDE(), @sudo_cmd, "ifconfig #{eth_iface_pc} mtu #{mtu_set_size}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    @vatf_helper.smart_send_cmd_wait(BETA_SIDE(), @normal_cmd, "ifconfig #{eth_iface_evm} mtu #{mtu_set_size}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    @vatf_helper.smart_send_cmd_wait(ALPHA_SIDE(), @sudo_cmd, "ifconfig #{eth_iface_pc}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    @vatf_helper.smart_send_cmd_wait(BETA_SIDE(), @normal_cmd, "ifconfig #{eth_iface_evm}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
  end

  def perf_typical_config(equipment, dev='dut1', iface_type='eth', is_ipv4=IPV4())
    # Use the default vatf linux pc ('server1') and evm ('dut1') reference, but set the equipment variable so we can communicate with them
    set_helper_common(equipment, "", "")

    # Get IP addresses to use on each side of the IPSEC connection
    @alpha_ip = equipment[@vatf_helper.vatf_server_ref].telnet_ip
    isolate_dut_ethernet_test_port(iface_type)
    @beta_ip = get_ip_addr(dev, iface_type)
    alpha_iface_type = find_eth_interface_by_ipaddress(@alpha_ip, ALPHA_SIDE())
    @alpha_ipv6 = get_ipv6_global_addr("#{@vatf_helper.vatf_server_ref}", alpha_iface_type)
    @beta_ipv6 = get_ipv6_global_addr(dev, iface_type)
    @is_ipv4 = is_ipv4
    return @result
  end

  def start_log_thread(is_alpha_side, time_secs)
    evm_log_thread = Thread.new {
      evm_status = @equipment[(is_alpha_side ? @vatf_helper.vatf_server_ref : @vatf_helper.vatf_dut_ref)].read_for(time_secs)
    }
    return evm_log_thread
  end

  def wait_on_thread_complete(this_thread)
    while this_thread.alive?
      sleep(1)
    end
  end

  def wait_on_log_thread_complete(is_alpha_side, evm_log_thread)
    # Assume error and Control-C to command prompt
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "\cC", "", @error_bit, 0, 1)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "\cC", "", @error_bit, 0, 1)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "dmesg", "", @error_bit, 0, 1)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "cat /var/log/error", "", @error_bit, 0, 1)
    while evm_log_thread.alive?
      sleep(1)
    end
    #@vatf_helper.log_info(is_alpha_side, "\r\n\r\nread_for_info: #{@equipment[(is_alpha_side ? @vatf_helper.vatf_server_ref : @vatf_helper.vatf_dut_ref)].response}\r\n\r\n")
    sleep(2)
  end

  def clear_dmesg(is_alpha_side)
    @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "dmesg -c", "", @error_bit, 0, 1)
  end

  def dmesg_on_error(is_alpha_side, raw_buffer)
    if raw_buffer.downcase.include?(" WARNING:")
      # Assume error and Control-C to command prompt
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "\cC", "", @error_bit, 0, 1)
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "\cC", "", @error_bit, 0, 1)
      sleep(1)
      @vatf_helper.log_info(is_alpha_side, "\r\n\r\n#################### dmesg start ####################\r\n")
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "dmesg", "", @error_bit, 0, 1)
      @vatf_helper.smart_send_cmd_wait(is_alpha_side, @normal_cmd, "cat /var/log/error", "", @error_bit, 0, 1)
      @vatf_helper.log_info(is_alpha_side, "\r\n\#################### dmesg end ####################\r\n\r\n")
    end
  end

  def test_common(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode, auto_detect=false)
    clear_stat_arrays()
    # Manual test to set perf server used
    #@perf_app = "iperf"
    #@perf_app = NETPERF_APP()
    result = ""
    measured_mbps = 0
    linux_pc = ALPHA_SIDE()
    evm_side = BETA_SIDE()
    @vatf_helper.smart_send_cmd_wait(linux_pc, @normal_cmd, "export WAITFOR=#{@wait_for_text}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    @vatf_helper.smart_send_cmd_wait(evm_side, @normal_cmd, "export WAITFOR=#{@wait_for_text}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    cpu_stats_side = evm_side
    case @perf_app
      when IPERF_APP()
        cpu_stats_side = evm_side
      when NETPERF_APP()
        cpu_stats_side = perf_client_side
    end
    get_proc_info(evm_side, crypto_mode) if !auto_detect
    server_thread = server_start(perf_server_side, protocol, test_time_secs + 10, packet_size, " > ~/perf_svr_log.txt")
    if !auto_detect
      run_top(evm_side, test_time_secs)
      result += "\r\n============================================================\r\n\r\n"
      result += (perf_server_side == linux_pc ? " EVM to Linux PC" : " Linux PC to EVM")
      result += " transfer stats:\r\n"
    end
    raw_buffer = client_run(perf_client_side, protocol, test_time_secs, udp_bandwidth, packet_size)
    if !auto_detect
      result += raw_buffer
      result += "\r\n============================================================\r\n"
    end
    wait_on_thread_complete(server_thread)
    if !auto_detect
      @session_result_text = ""
      @session_result_text += get_perf_stat(cpu_stats_side, test_headline, raw_buffer, protocol, packet_size)
      @session_result_text += @error_result_text
      @session_result_text += result
    end
    server_kill(perf_server_side)
    client_kill(perf_client_side)
    if !auto_detect
      get_proc_info(evm_side, crypto_mode)
    else
      measured_mbps = get_perf_stat(cpu_stats_side, test_headline, raw_buffer, protocol, packet_size, auto_detect)
    end
    return measured_mbps
  end

  def test_simultaneous_common(protocol, test_time_secs, udp_bandwidth_ingress, udp_bandwidth_egress, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode)
    clear_stat_arrays()
    result = ""
    raw_buffer_ingress = ""
    raw_buffer_egress = ""
    linux_pc = ALPHA_SIDE()
    evm_side = BETA_SIDE()
    @vatf_helper.smart_send_cmd_wait(linux_pc, @normal_cmd, "export WAITFOR=#{@wait_for_text}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    @vatf_helper.smart_send_cmd_wait(evm_side, @normal_cmd, "export WAITFOR=#{@wait_for_text}", "" , @vatf_helper.DONT_SET_ERROR_BIT(), 0, 1)
    get_proc_info(evm_side, crypto_mode)
    server_thread_ingress = server_start(perf_server_side, protocol, test_time_secs + 20, packet_size, " > ~/perf_svr_log.txt")
    server_thread_egress = server_start(perf_client_side, protocol, test_time_secs + 20, packet_size, " > ~/perf_svr_log.txt")
    sleep(4)
    run_top(evm_side, test_time_secs)
    #result += "\r\n============================================================\r\n\r\n"
    #result += " Simultaneous EVM to Linux PC and Linux PC to EVM"
    #result += " transfer stats:\r\n"
    client_thread_ingress = Thread.new {
      raw_buffer_ingress = client_run(perf_client_side, protocol, test_time_secs, udp_bandwidth_ingress, packet_size)
    }
    client_thread_egress = Thread.new {
      raw_buffer_egress = client_run(perf_server_side, protocol, test_time_secs, udp_bandwidth_egress, packet_size)
    }
    wait_on_thread_complete(client_thread_ingress)
    wait_on_thread_complete(client_thread_egress)
    #result += raw_buffer_ingress
    #result += raw_buffer_egress
    #result += "\r\n============================================================\r\n"
    wait_on_thread_complete(server_thread_ingress)
    wait_on_thread_complete(server_thread_egress)
    @result_text += get_iperf_stat_simultaneous(evm_side, test_headline, raw_buffer_ingress, raw_buffer_egress, protocol, packet_size)
    @result_text += @error_result_text
    @result_text += result
    server_kill(perf_server_side)
    server_kill(perf_client_side)
    get_proc_info(evm_side, crypto_mode)
  end

  def test_common_mbps_detect(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode, perf_server_side, perf_client_side)
    auto_detect = true
    max_attempts = 15
    binary_step =  2
    current_auto_mbps = udp_bandwidth.gsub("M", "").to_i
    # Since the auto detect resolution is 1M, return the specified bandwidth if less than 1M
    if current_auto_mbps > @iperf_threads
      tput_detect = TputBinarySearch.new
      tput_detect.init_search_values(current_auto_mbps, binary_step)
      while ((!tput_detect.binary_search_complete) && (max_attempts > 0))
        measured_mbps = test_common(protocol, test_time_secs, "#{current_auto_mbps}M", packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode, auto_detect)
        # try again
        if measured_mbps == 0
          measured_mbps = test_common(protocol, test_time_secs, "#{current_auto_mbps}M", packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode, auto_detect)
        end
        current_auto_mbps = tput_detect.binary_search(current_auto_mbps, measured_mbps, @vatf_helper, perf_client_side)
        max_attempts -= 1
      end
      @vatf_helper.log_info(perf_client_side, " final bin search; mbps: #{measured_mbps}, @current_auto_mbps: #{@current_auto_mbps}, max_attempts: #{max_attempts}\r\n")
    else
      current_auto_mbps = udp_bandwidth.gsub("M", "")
    end
    return "#{current_auto_mbps}M"
  end

  def test_linux_to_evm_mbps_detect(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode)
    @test_direction = INGRESS()
    @min_ingress_mbps = 0
    @min_egress_mbps = 0
    case @perf_app
      when NETPERF_APP()
        return udp_bandwidth
    end
    perf_server_side = BETA_SIDE()   # EVM
    perf_client_side = ALPHA_SIDE()  # Linux PC
    current_auto_mbps = test_common_mbps_detect(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode, perf_server_side, perf_client_side)
    return current_auto_mbps
  end

  def test_evm_to_linux_mbps_detect(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode)
    @test_direction = EGRESS()
    @min_ingress_mbps = 0
    @min_egress_mbps = 0
    case @perf_app
      when NETPERF_APP()
        return udp_bandwidth
    end
    perf_server_side = ALPHA_SIDE() # Linux PC
    perf_client_side = BETA_SIDE()  # EVM
    current_auto_mbps = test_common_mbps_detect(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode, perf_server_side, perf_client_side)
    return current_auto_mbps
  end

  def continue_auto_bandwidth_detection?(udp_bandwidth, result)
    response = nil
    current_thread_bandwidth = udp_bandwidth.gsub("M", "").to_i / @iperf_threads
    if @auto_bandwidth_detect && result != 0 && current_thread_bandwidth > 1
      response = (current_thread_bandwidth - (current_thread_bandwidth > 2 ? 2 : 1)) * @iperf_threads
      response = "#{response}M"
    end
    return response
  end

  def test_linux_to_evm(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode, min_ingress_mbps, min_egress_mbps)
    @test_direction = INGRESS()
    @min_ingress_mbps = min_ingress_mbps
    @min_egress_mbps = min_egress_mbps
    perf_server_side = BETA_SIDE()   # EVM
    perf_client_side = ALPHA_SIDE()  # Linux PC
    test_bandwidth = udp_bandwidth
    if @auto_bandwidth_detect
      test_bandwidth = test_linux_to_evm_mbps_detect(protocol, @auto_bw_test_secs, test_bandwidth, packet_size, "auto detect mbps", crypto_mode)
    end
    test_common(protocol, test_time_secs, test_bandwidth, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode)
    retry_attempts = @max_retries
    new_test_bandwidth = test_bandwidth
    while (new_test_bandwidth = continue_auto_bandwidth_detection?(new_test_bandwidth, @result)) && (retry_attempts > 0)
      @result = 0
      new_test_bandwidth = test_linux_to_evm_mbps_detect(protocol, test_time_secs, new_test_bandwidth, packet_size, "auto detect mbps", crypto_mode)
      test_common(protocol, test_time_secs, new_test_bandwidth, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode)
      retry_attempts -= 1
    end
    @result_text = @session_result_text
    @vatf_helper.log_info(ALPHA_SIDE(), "\r\n last perf @result_text: \"#{@result_text}\"\r\n")
    return @result
  end

  def test_evm_to_linux(protocol, test_time_secs, udp_bandwidth, packet_size, test_headline, crypto_mode, min_ingress_mbps, min_egress_mbps)
    @test_direction = EGRESS()
    @min_ingress_mbps = min_ingress_mbps
    @min_egress_mbps = min_egress_mbps
    perf_server_side = ALPHA_SIDE()  # Linux PC
    perf_client_side = BETA_SIDE()   # EVM
    test_bandwidth = udp_bandwidth
    if @auto_bandwidth_detect
      test_bandwidth = test_evm_to_linux_mbps_detect(protocol, @auto_bw_test_secs, test_bandwidth, packet_size, "auto detect mbps", crypto_mode)
    end
    test_common(protocol, test_time_secs, test_bandwidth, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode)
    retry_attempts = @max_retries
    new_test_bandwidth = test_bandwidth
    while (new_test_bandwidth = continue_auto_bandwidth_detection?(new_test_bandwidth, @result)) && (retry_attempts > 0)
      @result = 0
      new_test_bandwidth = test_evm_to_linux_mbps_detect(protocol, test_time_secs, new_test_bandwidth, packet_size, "auto detect mbps", crypto_mode)
      test_common(protocol, test_time_secs, new_test_bandwidth, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode)
      retry_attempts -= 1
    end
    @result_text = @session_result_text
    return @result
  end

  def test_linux_to_evm_and_evm_to_linux(protocol, test_time_secs, udp_bandwidth_ingress, udp_bandwidth_egress, packet_size, test_headline, crypto_mode, min_ingress_mbps, min_egress_mbps)
    @test_direction = BOTH()
    @min_ingress_mbps = min_ingress_mbps
    @min_egress_mbps = min_egress_mbps
    perf_server_side = BETA_SIDE()   # EVM
    perf_client_side = ALPHA_SIDE()  # Linux PC
    test_simultaneous_common(protocol, test_time_secs, udp_bandwidth_ingress, udp_bandwidth_egress, packet_size, test_headline, perf_server_side, perf_client_side, crypto_mode)
    return @result
  end
end

class IpsecUtilitiesVatf
  # This class holds ipsec utilities to be used with the vatf.
  def initialize
    @lnx_helper = LinuxHelperUtilities.new
    @vatf_helper = VatfHelperUtilities.new
    @smart_card = SmartCardUtilities.new
    
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
    @ipv6_addr_prefix = "2000::"
    @ipv6_addr_netmask = "/64"
    @alpha_side_ipsec_conf_file = "/etc/ipsec.conf"
    @beta_side_ipsec_conf_file = "/etc/ipsec.conf"
    @alpha_side_ipsec_secrets_file = "/etc/ipsec.secrets"
    @beta_side_ipsec_secrets_file = "/etc/ipsec.secrets"
    @ipsec_conf_template_file_name = "ipsec_conf_template.txt"
    @default_margintime = "9m"
    @default_rekey_lifetime = "48h"
    @default_rekey_ike_lifetime = "48h"
    @alpha_side_secure_data = false
    @beta_side_secure_data = false
    @alpha_side_natt = false
    @beta_side_natt = false
    @alpha_side_nat_gateway_ip = ""
    @alpha_side_nat_public_ip = ""
    @beta_side_nat_gateway_ip = "192.168.1.80"
    @beta_side_nat_public_ip = "10.218.104.131"
    @default_stop_offload_pre_cmd = "stop_offload"
    @default_stop_offload_post_cmd = "--no_expire_sa"
    @slot_num = "0"
    @id_num = "01"
    @vatf_dut_ref = 'dut1'
    @vatf_server_ref = 'server1'
    @ipsec_conf_save_name = "ipsec_conf.save"
    @equipment = ""
    @is_gen_on_alpha_only = true
    @result = 0
    @error_bit = 1
    @result_text = ""
    @esp_encryption = "aes128ctr"
    @esp_integrity = "sha1"
    @esp = "cipher_null"
    @protocol = "udp"
    @connection_name = "Udp"
    @trigger_key_and_cert_rebuild_file_name = "/etc/rebuild_certs_trigger.tmp"
    @is_ipv4 = IPV4()
    @ipsec_outer = "ipv4"
    @ipsec_inner = "ipv4"
    # Static variable settings
    @sudo_cmd = true
    @normal_cmd = false
    # Ipsec Manager variables
    @executable_directory = "/usr/bin"
    @hplib_file_name = "hplibmod.ko"
    @ipsec_mgr = "ipsecmgr_mod.ko"  # Workaround for Sandeep's stuff
    @app_sock_name_env_cmd = "export IPSECMGR_APP_SOCK_NAME=\"/etc/app_sock\""
    @daemon_sock_name_env_cmd ="export IPSECMGR_DAEMON_SOCK_NAME=\"/etc/ipsd_sock\""
    @log_file_env_cmd = "export IPSECMGR_LOG_FILE=\"/var/run/ipsecmgr_app.log\""
    @daemon_cmd = "ipsecmgr_daemon.out"
    @cmd_shell_cmd = "ipsecmgr_cmd_shell.out"
    @inflow_active_name = "INFLOW_MODE_ACTIVE"
    @do_friendly = false
  end

  def get_ipsec_cmd_additions_using_bench_file()
    cmd_platform_addition = get_platform()
    @equipment['dut1'].log_info("\r\n cmd_platform_addition: #{cmd_platform_addition}\r\n")
    if cmd_platform_addition != ""
      @daemon_cmd = (!@daemon_cmd.include?(cmd_platform_addition) ? @daemon_cmd.gsub(".out", "_#{cmd_platform_addition}.out &") : @daemon_cmd)
      @cmd_shell_cmd = (!@cmd_shell_cmd.include?(cmd_platform_addition) ? @cmd_shell_cmd.gsub(".out", "_#{cmd_platform_addition}.out") : @cmd_shell_cmd)
    end
  end

  def default_margintime()
    return @default_margintime
  end

  def default_rekey_ike_lifetime()
    return @default_rekey_ike_lifetime
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
    @smart_card.clear_result()
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

  def NON_SECURE_DATA()
    return false
  end

  def SECURE_DATA()
    return true
  end

  def REMOTE_SIDE()
    return true
  end

  def LOCAL_SIDE()
    return false
  end

  def is_ipv4
    @is_ipv4
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
    puts("    @alpha_side_secure_data       : #{@alpha_side_secure_data}\r\n")
    puts("    @beta_side_secure_data        : #{@beta_side_secure_data}\r\n")
    puts("    @alpha_side_natt              : #{@alpha_side_natt}\r\n")
    puts("    @beta_side_natt               : #{@beta_side_natt}\r\n")
    puts("    @alpha_side_nat_gateway_ip    : #{@alpha_side_nat_gateway_ip}\r\n")
    puts("    @alpha_side_nat_public_ip     : #{@alpha_side_nat_public_ip}\r\n")
    puts("    @beta_side_nat_gateway_ip     : #{@beta_side_nat_gateway_ip}\r\n")
    puts("    @beta_side_nat_public_ip      : #{@beta_side_nat_public_ip}\r\n")
    puts("    @slot_num                     : #{@slot_num}\r\n")
    puts("    @id_num                       : #{@id_num}\r\n")
    puts("    @ipsec_conf_template_file_name: #{@ipsec_conf_template_file_name}\r\n")
    puts("    @default_margintime           : #{@default_margintime}\r\n")
    puts("    @default_rekey_ike_lifetime   : #{@default_rekey_ike_lifetime}\r\n")
    puts("    @default_rekey_lifetime       : #{@default_rekey_lifetime}\r\n")
    puts("    @vatf_dut_ref                 : #{@vatf_dut_ref}\r\n")
    puts("    @vatf_server_ref              : #{@vatf_server_ref}\r\n")
    puts("    @ipsec_conf_save_name         : #{@ipsec_conf_save_name}\r\n")
    puts("    @equipment                    : #{@equipment!="" ? "(value is set)" : "(value not set)"}\r\n")
    puts("    @result                       : #{@result}\r\n")
    puts("    @is_gen_on_alpha_only         : #{@is_gen_on_alpha_only ? "All certificates & keys are generated on alpha side" : "Certificates & keys are generated on each side"}\r\n")
  end

  def set_ipsec_ip_operation(ipsec_outer, ipsec_inner, is_ipv4)
    @ipsec_outer = ipsec_outer if (ipsec_outer != "")
    @ipsec_inner = ipsec_inner if (ipsec_inner != "")
    @is_ipv4 = is_ipv4 if (is_ipv4 != "")
  end

  def set_protocol_encryption_integrity_name(protocol, esp_encryption, esp_integrity, connection_name)
    @protocol = protocol if (protocol != "")
    @esp_encryption = esp_encryption if (esp_encryption != "")
    @esp_integrity = esp_integrity if (esp_integrity != "")
    @connection_name = connection_name if (connection_name != "")
  end

  def set_alpha_cert(as_ip, as_is_fqdn, as_ss_major_ver, as_ref, as_ca_key_file, as_key_file, as_ca_cert_file, as_cert_file, as_ip_cert_file, as_net_name, as_ipv6, as_ipsec_conf, as_is_secure_data)
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
    @alpha_side_secure_data = as_is_secure_data if (as_is_secure_data != "")
  end

  def get_file_tftp_server_file_name_path(is_alpha_side, file_name_path)
    # Add alpha or beta path to tftp server ipsec path base
    tftp_file_name_path = File.join(@server_ipsec_tftp_path, (is_alpha_side ? "a" : "b"))
    # Add file name to modified tftp path
    tftp_file_name_path = File.join(tftp_file_name_path, File.basename(file_name_path))
    return tftp_file_name_path
  end

  def set_beta_cert(bs_ip, bs_is_fqdn, bs_ss_major_ver, bs_ref, bs_ca_key_file, bs_key_file, bs_ca_cert_file, bs_cert_file, bs_ip_cert_file, bs_net_name, bs_ipv6, bs_ipsec_conf, bs_is_secure_data)
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
    @beta_side_secure_data = bs_is_secure_data if (bs_is_secure_data != "")
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

  def equipment_set(equipment)
    @equipment = equipment if (equipment != "")
  end

  def set_helper_common(equipment, vatf_server_ref, vatf_dut_ref)
    @vatf_dut_ref = vatf_dut_ref if (vatf_dut_ref != "")
    @vatf_server_ref = vatf_server_ref if (vatf_server_ref != "")
    @equipment = equipment if (equipment != "")
    @vatf_helper.set_common(@equipment, @vatf_server_ref, @vatf_dut_ref)
    @lnx_helper.set_vatf_equipment(@equipment)
    @smart_card.set_common(@equipment, @vatf_server_ref, @vatf_dut_ref)
  end

  def set_common(ipsec_conf_template_file_name, default_margintime, default_rekey_ike_lifetime, default_rekey_lifetime, ipsec_conf_save_name)
    @ipsec_conf_template_file_name = ipsec_conf_template_file_name if (ipsec_conf_template_file_name != "")
    @default_margintime = default_margintime if (default_margintime != "")
    @default_rekey_ike_lifetime = default_rekey_ike_lifetime if (default_rekey_ike_lifetime != "")
    @default_rekey_lifetime = default_rekey_lifetime if (default_rekey_lifetime != "")
    @ipsec_conf_save_name = ipsec_conf_save_name if (ipsec_conf_save_name != "")
  end

  def set_rekey_parameters(default_margintime, default_rekey_ike_lifetime, default_rekey_lifetime)
    set_common("", default_margintime, default_rekey_ike_lifetime, default_rekey_lifetime, "")
  end

  def set_stop_offload_commands(pre_cmd, post_cmd)
    @default_stop_offload_pre_cmd = pre_cmd if (pre_cmd != "")
    @default_stop_offload_post_cmd = post_cmd if (post_cmd != "")
  end

  def set_alpha_nat(is_nat_traversal, nat_public_ip, nat_gateway_ip)
    @alpha_side_natt = is_nat_traversal if (is_nat_traversal != "")
    @alpha_side_nat_public_ip = nat_public_ip if (nat_public_ip != "")
    @alpha_side_nat_gateway_ip = nat_gateway_ip if (nat_gateway_ip != "")
  end

  def set_beta_nat(is_nat_traversal, nat_public_ip, nat_gateway_ip)
    @beta_side_natt = is_nat_traversal if (is_nat_traversal != "")
    @beta_side_nat_public_ip = nat_public_ip if (nat_public_ip != "")
    @beta_side_nat_gateway_ip = nat_gateway_ip if (nat_gateway_ip != "")
  end

  def set_ipsecmgr_variables(executable_directory, hplib_file_name, daemon_cmd, cmd_shell_cmd, app_sock_name_env_cmd, daemon_sock_name_env_cmd, log_file_env_cmd)
    @executable_directory = executable_directory if (executable_directory != "")
    @hplib_file_name = hplib_file_name if (hplib_file_name != "")
    @daemon_cmd = daemon_cmd if (daemon_cmd != "")
    @cmd_shell_cmd = cmd_shell_cmd if (cmd_shell_cmd != "")
    @app_sock_name_env_cmd = app_sock_name_env_cmd if (app_sock_name_env_cmd != "")
    @daemon_sock_name_env_cmd = daemon_sock_name_env_cmd if (daemon_sock_name_env_cmd != "")
    @log_file_env_cmd = log_file_env_cmd if (log_file_env_cmd != "")
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
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_key_file.gsub(".der", ".pem")}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_ip_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_ca_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_temp_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_temp_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@alpha_side_temp_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_local, @sudo_cmd, "rm #{@trigger_key_and_cert_rebuild_file_name}", "", @error_bit, 0)
      
      if @alpha_side_secure_data
        @smart_card.remove_key_set_based_on_file(is_alpha_side, @slot_num, @id_num, @alpha_side_key_file)
        @smart_card.remove_certificate_based_on_file(is_alpha_side, @slot_num, @id_num, @alpha_side_cert_file)
        @smart_card.remove_certificate_based_on_file(is_alpha_side, @slot_num, @id_num, @alpha_side_ip_cert_file)
        @smart_card.remove_certificate_based_on_file(is_alpha_side, @slot_num, @id_num, @alpha_side_ca_cert_file)
        @smart_card.list_objects_in_key_store(is_alpha_side, @slot_num)
        @result |= @smart_card.result
        @result_text += @smart_card.result_text
      end
      
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
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_key_file.gsub(".der", ".pem")}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_ip_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_ca_cert_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_temp_ca_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@beta_side_temp_key_file}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "rm #{@trigger_key_and_cert_rebuild_file_name}", "", @error_bit, 0)
      
      if @beta_side_secure_data
        @smart_card.remove_key_set_based_on_file(is_alpha_side, @slot_num, @id_num, @beta_side_key_file)
        @smart_card.remove_certificate_based_on_file(is_alpha_side, @slot_num, @id_num, @beta_side_cert_file)
        @smart_card.remove_certificate_based_on_file(is_alpha_side, @slot_num, @id_num, @beta_side_ip_cert_file)
        @smart_card.remove_certificate_based_on_file(is_alpha_side, @slot_num, @id_num, @beta_side_ca_cert_file)
        @smart_card.list_objects_in_key_store(is_alpha_side, @slot_num)
        @result |= @smart_card.result
        @result_text += @smart_card.result_text
      end
      
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

  def load_crypto_module_as_needed(is_alpha_side,mode="hardware")
    side_ref = is_alpha_side ? @vatf_helper.vatf_server_ref : @vatf_helper.vatf_dut_ref
    if side_ref.downcase.include?("dut")
      module_list = Array.new
      module_list = get_crypto_modules
      puts "module_list is #{module_list}\n"
      module_list.each do |module_name|
        if (mode == "software" || mode == "sideband")
          @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "modprobe -r #{module_name}", "", @error_bit, 2)
        else
          @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "modprobe #{module_name}", "", @error_bit, 2)
          set_queue_length('dut1', 300)
          if !module_running?(module_name, @equipment[side_ref])
            @result_text += "Error: Unable to start module: #{module_name}"
            @result += @error_bit
          end
        end
      end
    end
  end

  def ipsec_start(is_alpha_side, crypto_mode)
    function_name = "ipsec_start"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    # Load crypto modules before starting IPSEC
    load_crypto_module_as_needed(is_alpha_side, crypto_mode)
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
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec listcerts", "authkey", @error_bit, 0)
    return if (is_failed(is_alpha_side, function_name, " IPSEC: listcerts response not correct.\r\n"))
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "ipsec listcacerts", "authkey", @error_bit, 0)
    return if (is_failed(is_alpha_side, function_name, " IPSEC: listcacerts response not correct.\r\n"))
  end

  def bring_ipsec_tunnel_up(is_alpha_side, is_ipv4, is_pass_through)
    function_name = "bring_ipsec_tunnel_up"
    # Return immediately if errors have already occurred.
    return if (result() != 0)
    #verify_message = (is_pass_through ? "PASS" : "ESTABLISHED")
    verify_message = (is_pass_through ? "PASS" : "TUNNEL")
    ipsec_cmd = (is_pass_through ? "route" : "up")
    ip_ref = ( is_pass_through ? (is_ipv4 ? "#{@connection_name}3" : "#{@connection_name}4") : (is_ipv4 ? "#{@connection_name}1" : "#{@connection_name}2") )
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

  def generate_key_pair(is_alpha_side, private_key_file_and_path, public_key_file_and_path)
    is_alpha_side_here = (@is_gen_on_alpha_only ? ALPHA_SIDE() : is_alpha_side)
    is_secure_data = (is_alpha_side ? @alpha_side_secure_data : @beta_side_secure_data)
    if !is_secure_data
      @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki -g > #{private_key_file_and_path}", "", @error_bit, 0)
      @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --pub --in #{private_key_file_and_path} > #{public_key_file_and_path}", "", @error_bit, 0)
    else
      label_name = File.basename(private_key_file_and_path).split(".")[0]
      slot_num = @slot_num
      id_num = @id_num
      host_ip = @equipment[@vatf_helper.vatf_server_ref].telnet_ip
      key_file_name = "#{label_name}.pem"
      @smart_card.generate_rsa_key_pair(is_alpha_side, slot_num, id_num, label_name)
      @smart_card.get_pubic_key_via_tftp(is_alpha_side, host_ip, slot_num, id_num, label_name, key_file_name)
      @result |= @smart_card.result
      @result_text += @smart_card.result_text
      #exit
    end
  end

  def put_file_in_key_store(is_alpha_side, cert_file_name_and_path)
    host_ip = @equipment[@vatf_helper.vatf_server_ref].telnet_ip
    slot_num = @slot_num
    id_num = @id_num
    label_name = File.basename(cert_file_name_and_path).split(".")[0]
    cert_file_name = File.basename(cert_file_name_and_path)
    @smart_card.put_cert_file_via_tftp(is_alpha_side, host_ip, slot_num, id_num, label_name, cert_file_name)
    @result |= @smart_card.result
    @result_text += @smart_card.result_text
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
    #@vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki -g > #{temp_key_file}", "", @error_bit, 0)
    #@vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --pub --in #{temp_key_file} > #{temp_file}", "", @error_bit, 0)
    generate_key_pair(is_alpha_side, temp_key_file, temp_file)
    # Create FQDN certificate
    @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --issue --dn \"C=US, O=Test, CN=#{cert_org}\" --san \"#{cert_org}\" --cacert #{ca_cert_file} --cakey #{ca_key_file} < #{temp_file} > #{cert_file}", "", @error_bit, 0)
    # Create IP address certificate
    @vatf_helper.smart_send_cmd(is_alpha_side_here, @normal_cmd, "ipsec pki --issue --san \"#{local_ip_address}\" --cacert #{ca_cert_file} --cakey #{ca_key_file} < #{temp_file} > #{ip_cert_file}", "", @error_bit, 0)
    return if (is_failed(is_alpha_side_here, function_name, " IPSEC: pki -g, pki --pub or pki --issue response not correct.\r\n"))
    
    # Copy files to the appropriate directories on the alpha or beta side
    is_secure_data = (is_alpha_side ? @alpha_side_secure_data : @beta_side_secure_data)
    if !is_secure_data
      xfer_file(is_alpha_side, key_file, (is_alpha_side ? @alpha_side_key_file : @beta_side_key_file))
      xfer_file(is_alpha_side, cert_file, (is_alpha_side ? @alpha_side_cert_file : @beta_side_cert_file))
      xfer_file(is_alpha_side, ip_cert_file, (is_alpha_side ? @alpha_side_ip_cert_file : @beta_side_ip_cert_file))
    else
      put_file_in_key_store(is_alpha_side, cert_file)
      put_file_in_key_store(is_alpha_side, ip_cert_file)
    end
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
    #xfer_file(BETA_SIDE(), beta_tftp_ca_key_file, @beta_side_ca_key_file)
    #xfer_file(BETA_SIDE(), beta_tftp_ca_cert_file, @beta_side_ca_cert_file)
    #is_secure_data = (is_alpha_side ? @alpha_side_secure_data : @beta_side_secure_data)
    is_secure_data = @beta_side_secure_data
    if !is_secure_data
      xfer_file(BETA_SIDE(), beta_tftp_ca_key_file, @beta_side_ca_key_file)
      xfer_file(BETA_SIDE(), beta_tftp_ca_cert_file, @beta_side_ca_cert_file)
    else
      put_file_in_key_store(BETA_SIDE(), beta_tftp_ca_cert_file)
      #exit
    end
    
    # Create and copy the side specific keys and certificates. Use the caKey.der and caCert.der created on the alpha side for all other certificate creation.
    create_side_specific_ipsec_certificates(ALPHA_SIDE(), alpha_tftp_ca_key_file, alpha_tftp_ca_cert_file)
    create_side_specific_ipsec_certificates(BETA_SIDE(), alpha_tftp_ca_key_file, alpha_tftp_ca_cert_file)
    
    if is_secure_data
      @smart_card.list_objects_in_key_store(BETA_SIDE(), @slot_num)
      @result |= @smart_card.result
      @result_text += @smart_card.result_text
      @vatf_helper.smart_send_cmd(BETA_SIDE(), @normal_cmd, "ls -l /etc/ipsec.d/cacerts/", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
      @vatf_helper.smart_send_cmd(BETA_SIDE(), @normal_cmd, "ls -l /etc/ipsec.d/certs/", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
      @vatf_helper.smart_send_cmd(BETA_SIDE(), @normal_cmd, "ls -l /etc/ipsec.d/private/", "", @vatf_helper.DONT_SET_ERROR_BIT(), 0)
      #exit
    end
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
    secrets_key_id = @id_num
    is_secure_data = (is_alpha_side ? @alpha_side_secure_data : @beta_side_secure_data)
    if !is_secure_data
      ipsec_secrets.push(": RSA #{key_path_file_name}\n")
    else
      ipsec_secrets.push("#{@smart_card.secrets_store(secrets_key_id)}\n")
    end
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

  def get_tunnel_end_point_address(is_alpha_side)
    ip_address = ""
    is_nat_traversal = (is_alpha_side ? @alpha_side_natt : @beta_side_natt)
    nat_gateway = (is_alpha_side ? @alpha_side_nat_gateway_ip : @beta_side_nat_gateway_ip)
    if is_nat_traversal and (nat_gateway == "")
      #ip_address = (is_alpha_side ? @alpha_side_nat_public_ip : @beta_side_nat_public_ip)
      # If a NAT gateway is present on this side then use the normal endpoint IP. If there is no NAT gateway present then assume the NAT public address is the end point.
      #if is_nat_gw_present
      #  ip_address = (is_alpha_side ? @alpha_side_ip : @beta_side_ip)
      #else
        ip_address = (is_alpha_side ? @alpha_side_nat_public_ip : @beta_side_nat_public_ip)
      #end
    end
    # if ip_address equals "" at this point then use the normal ip address
    if ip_address == ""
      ip_address = (is_alpha_side ? @alpha_side_ip : @beta_side_ip)
    end
    return ip_address
  end

  def get_tunnel_subnet(is_alpha_side, is_remote)
    this_alpha_side_ip = get_tunnel_end_point_address(ALPHA_SIDE())
    this_beta_side_ip = get_tunnel_end_point_address(BETA_SIDE())
    if is_remote
      ip_subnet = (!is_alpha_side ? this_alpha_side_ip : this_beta_side_ip)
    else
      ip_subnet = (is_alpha_side ? this_alpha_side_ip : this_beta_side_ip)
    end
    return ip_subnet
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
    local_ip_subnet = get_tunnel_subnet(is_alpha_side, LOCAL_SIDE())
    remote_ip_subnet = get_tunnel_subnet(is_alpha_side, REMOTE_SIDE())
    local_ipv6 = (is_alpha_side ? @alpha_side_ipv6 : @beta_side_ipv6)
    remote_ipv6 = (!is_alpha_side ? @alpha_side_ipv6 : @beta_side_ipv6)
    ipsec_conf_template_file = File.join(File.dirname(__FILE__), @ipsec_conf_template_file_name)
    ipsec_conf_file = (is_alpha_side ? @alpha_side_ipsec_conf_file : @beta_side_ipsec_conf_file)
    ipsec_conf_file_tftp = (is_alpha_side ? get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_ipsec_conf_file) : get_file_tftp_server_file_name_path(is_alpha_side, @beta_side_ipsec_conf_file))
    ipsec_conf_save_file = ipsec_conf_file.gsub(File.basename(ipsec_conf_file), @ipsec_conf_save_name)
    margintime = @default_margintime
    ike_lifetime = @default_rekey_ike_lifetime
    lifetime = @default_rekey_lifetime
    
    # Set outer IP address
    case "#{@ipsec_outer}"
      when "ipv4"
        local_ip = (is_alpha_side ? @alpha_side_ip : @beta_side_ip)
        remote_ip = (!is_alpha_side ? @alpha_side_ip : @beta_side_ip)
      when "ipv6"
        local_ip = (is_alpha_side ? @alpha_side_ipv6 : @beta_side_ipv6)
        remote_ip = (!is_alpha_side ? @alpha_side_ipv6 : @beta_side_ipv6)
    end
    
    # Get ipsec template file contents
    fileUtils.get_file_contents(ipsec_conf_template_file)
    
    puts(" StrongSwan version for #{connection_ref} is: #{ss_version}\r\n")
    
    is_nat_traversal = (is_alpha_side ? @alpha_side_natt : @beta_side_natt)
    is_secure_data = (is_alpha_side ? @alpha_side_secure_data : @beta_side_secure_data)
    right_side_state = ""
    left_cert_disable = ""
    if (is_nat_traversal and is_alpha_side)
      right_side_state = "#"
    end
    if (is_secure_data and !is_alpha_side)
      left_cert_disable = "#"
    end
    
    if(@esp_encryption == "cipher_null")
      @esp = "cipher_null"
    else
      @esp = @esp_encryption+"-"+@esp_integrity+"-"+"modp2048-noesn!"
    end
 
    # Substitute template contents with ipsec variables
    fileUtils.file_contents.each do |item|
      file_line = item
      if (item.length > 0)
        # Don't do any substitution if the lines starts with a "#"
        if (item[0] != "#")
          file_line.gsub!("%LOCAL_IP_ADDRESS%", local_ip)
          file_line.gsub!("%LOCAL_IP_NETWORK%", get_network_ip_from_ip(local_ip))
          file_line.gsub!("%LOCAL_IP_SUBNET%", local_ip_subnet)
          file_line.gsub!("%CERT_FILE_PATH_NAME%", cert_file_path_name)
          file_line.gsub!("%LOCAL_CN%", local_network_name)
          file_line.gsub!("%REMOTE_IP_ADDRESS%", remote_ip)
          file_line.gsub!("%REMOTE_IP_NETWORK%", get_network_ip_from_ip(remote_ip))
          file_line.gsub!("%REMOTE_IP_SUBNET%", remote_ip_subnet)
          file_line.gsub!("%RIGHT_DISABLE%", right_side_state)
          file_line.gsub!("%LEFT_CERT_DISABLE%", left_cert_disable)
          file_line.gsub!("%REMOTE_CN%", remote_network_name)
          file_line.gsub!("%CONNECTION_SIDE%", connection_ref)
          file_line.gsub!("%MARGINTIME%", margintime)
          file_line.gsub!("%IKE_LIFETIME%", ike_lifetime)
          file_line.gsub!("%LIFETIME%", lifetime)
          file_line.gsub!("%LOCAL_IPV6_ADDRESS%", local_ipv6)
          file_line.gsub!("%REMOTE_IPV6_ADDRESS%", remote_ipv6)
          file_line.gsub!("%CONNECTION_NAME%", @connection_name)
          file_line.gsub!("%PROTOCOL%", @protocol)
          file_line.gsub!("%ESP_ENCRYPTION%", @esp_encryption)
          file_line.gsub!("%ESP_INTEGRITY%", @esp_integrity)
          file_line.gsub!("%ESP_CIPHER_SUITE%", @esp)
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

  def ipsec_start_all(is_ipv4, is_pass_through, crypto_mode)
    function_name = "ipsec_start_all"
    # Start the alpha side ipsec
    ipsec_start(ALPHA_SIDE(), crypto_mode)
    # Start the beta side ipsec. Beta side connection status happens in the ipsec_start
    ipsec_start(BETA_SIDE(), crypto_mode)
    sleep(3)
    # Bring up the IPSEC tunnel on both sides
    # start_tunnels(is_ipv4, is_pass_through)
    # Bring up the IPSEC tunnel on the EVM
    bring_ipsec_tunnel_up(BETA_SIDE(), is_ipv4, is_pass_through)    
  end

  def ipsec_restart_all(is_ipv4, is_pass_through, crypto_mode)
    ipsec_stop(ALPHA_SIDE())
    ipsec_stop(BETA_SIDE())
    ipsec_start_all(is_ipv4, is_pass_through, crypto_mode)
  end

  def load_friendlies(is_alpha_side)
    if @do_friendly
      get_ipsec_cmd_additions_using_bench_file()
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "cd #{@executable_directory}; chmod 777 #{@daemon_cmd}; tftp -g -r #{@daemon_cmd} -l #{@daemon_cmd} 192.168.1.84", "", @error_bit, 2)
    end
  end

  def ipsec_restart_with_new_ipsec_conf_file(is_ipv4, tunnel_type, ipsec_conf_input_file, is_clear_previous_result, is_pass_through, crypto_mode)
    puts("\r\nRestarting ipsec with file: #{ipsec_conf_input_file}, tunnel type: #{(tunnel_type ? "FQDN" : "IP")}\r\n")
    clear_results() if is_clear_previous_result
    # Set ipsec.conf input template file
    set_common(ipsec_conf_input_file, "", "", "", "")
    # Set the alpha side tunnel type. Leave everything else as is.
    set_alpha_cert("", tunnel_type, "", "", "", "", "", "", "", "", "", "", "")
    # Set the beta side tunnel type. Leave everything else as is.
    set_beta_cert("", tunnel_type, "", "", "", "", "", "", "", "", "", "", "")
    # Stop currently running ipsec
    ipsec_stop(ALPHA_SIDE())
    ipsec_stop(BETA_SIDE())
    #@do_friendly = true
    @do_friendly = false
    load_friendlies(BETA_SIDE()) # Debug code remove when working
    # Create ipsec.conf files from input template
    create_ipsec_conf_file(ALPHA_SIDE())
    create_ipsec_conf_file(BETA_SIDE())
    # Start ipsec on both sides. Start the ipsec connection on the beta side.
    ipsec_start_all(is_ipv4, is_pass_through, crypto_mode)
    return result()
  end

  def ipsec_generate_keys_and_certs_only(is_ipv4, is_pass_through)
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
  end

  def ipsec_generate_keys_and_certs_and_start_all(is_ipv4, is_pass_through, crypto_mode)
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
    ipsec_start_all(is_ipv4, is_pass_through, crypto_mode)
  end

  def set_swan_major_version(is_alpha_side, swan_major_version)
    maj_ver = (swan_major_version >= 5 ? "5" : "4")
    if is_alpha_side
      # Set only the StrongSwan major version number. Leave everything else at default.
      set_alpha_cert("", "", "#{maj_ver}", "", "", "", "", "", "", "", "", "", "")
    else
      # Set only the StrongSwan major version number. Leave everything else at default.
      set_beta_cert("", "", "#{maj_ver}", "", "", "", "", "", "", "", "", "", "")
    end
  end

  def get_ipv6_global_ip(dev, ipv4_address, is_save_ipv6_network_mask)
    eth_iface = get_eth_interface_by_ipaddress(dev, ipv4_address)
    ipv6_addr = set_ipv6_global_addr_if_not_exist(dev, eth_iface, @ipv6_addr_prefix, @ipv6_addr_netmask)
    if eth_iface && ipv6_addr && is_save_ipv6_network_mask
      ipv6_netmask = get_ipv6_global_netmask(dev, eth_iface)
      @ipv6_addr_netmask = (ipv6_netmask ? ipv6_netmask : @ipv6_addr_netmask)
    end
    ipv6_addr ? ipv6_addr : nil
  end

  def ipsec_typical_config(equipment, tunnel_type, ipsec_conf_input_file)
    function_name = "ipsec_typical_config"
    # Use the default vatf linux pc ('server1') and evm ('dut1') reference, but set the equipment variable so we can communicate with them
    set_helper_common(equipment, "", "")
    
    save_ipv6_network_mask = true
    use_saved_ipv6_network_mask = false
    # Typical inputs to this function
    #  equipment will be:  @equipment
    #  tunnel_type could be: ipsecVatf.FQDN_TUNNEL or ipsecVatf.IP_TUNNEL
    #  ipsec_conf_input_file would be: ""  (This could also be a template file within the vatf scmcsdk\syslib path. e.g. "ipsec_conf_template.txt" or "ipsec_test_confs/ipsec_cp_1.conf")
    
    # Get IP addresses to use on each side of the IPSEC connection
    alpha_ip = equipment[@vatf_helper.vatf_server_ref].telnet_ip
    beta_ip = get_ip_addr("#{@vatf_helper.vatf_dut_ref}")
    # Get alpha side ipv6 ip address. Save ipv6 network mask that both sides will use based on the Linux PC's ipv6 interface.
    alpha_side_ipv6 = get_ipv6_global_ip(@vatf_helper.vatf_server_ref, alpha_ip, save_ipv6_network_mask)
    # Get beta side ipv6 ip address. Use the ipv6 network mask set by the alpha side.
    beta_side_ipv6 = get_ipv6_global_ip(@vatf_helper.vatf_dut_ref, beta_ip, use_saved_ipv6_network_mask)
    @server_ipsec_tftp_path = File.join(equipment[@vatf_helper.vatf_server_ref].tftp_path, "ipsec_files")

    # Set the alpha side IP address and StrongSwan major version number. Leave everything else at default.
    set_alpha_cert(alpha_ip, tunnel_type, "5", "", "", "", "", "", "", "", alpha_side_ipv6, "", "")
    # Set the beta side IP address , StrongSwan major version number. Leave everything else at default.
    set_beta_cert(beta_ip, tunnel_type, "5", "", "", "", "", "", "", "", beta_side_ipv6, "", "")
    # Set ipsec.conf input template file to use.
    set_common(ipsec_conf_input_file, "", "", "" ,"")
  end

  def secure_store_initialize(is_alpha_side)
    @smart_card.initialize_secure_store_if_needed(is_alpha_side ? ALPHA_SIDE() : BETA_SIDE())
    @result |= @smart_card.result
    @result_text += @smart_card.result_text
  end

  def set_secure_data(is_alpha_side)
    # Get server tftp directory
    server_tftp_directory = File.dirname(get_file_tftp_server_file_name_path(is_alpha_side, @alpha_side_cert_file))
    if server_tftp_directory.downcase.include?("/tftpboot/")
      server_tftp_directory = server_tftp_directory.split("/tftpboot/")[1]
    end
    if is_alpha_side
      # Set the alpha side to use secure data (TI SIMULATED SMARTCARD). Leave everything else at default.
      set_alpha_cert("", "", "", "", "", "", "", "", "", "", "", "", SECURE_DATA())
      set_alpha_temp_locations("", "", "/etc/alphaKey.pem")
      @smart_card.set_alpha_side_directories(server_tftp_directory, server_tftp_directory)
    else
      # Set the beta side to use secure data (TI SIMULATED SMARTCARD). Leave everything else at default.
      set_beta_cert("", "", "", "", "", "", "", "", "", "", "", "", SECURE_DATA())
      set_beta_temp_locations("", "", "/etc/betaKey.pem")
      @smart_card.set_beta_side_directories("", server_tftp_directory)
    end
    @result |= @smart_card.result
    @result_text += @smart_card.result_text
  end

  def set_new_default_route(is_alpha_side, current_gateway, new_gateway)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route add default gw #{new_gateway}", "", @error_bit, 0)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route del default gw #{current_gateway}", "", @error_bit, 0)
  end

  def add_nat_host_route(is_alpha_side, host_ip, gateway_ip)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route add -host #{host_ip} gw #{gateway_ip}", "", @error_bit, 0)
  end

  def del_nat_host_route(is_alpha_side, host_ip, gateway_ip)
    @vatf_helper.smart_send_cmd(is_alpha_side, @sudo_cmd, "route del -host #{host_ip} gw #{gateway_ip}", "", @error_bit, 0)
  end

  def set_nat_traversal(is_alpha_side, is_nat_traversal, nat_public_ip, local_nat_gateway_ip, remote_host_ip)
    if is_alpha_side
      # Set the alpha side to use nat traversal Leave everything else at default.
      set_alpha_nat(is_nat_traversal, nat_public_ip, local_nat_gateway_ip)
      # Add route for host through NAT router
      if @alpha_side_natt
        if remote_host_ip != "" and @alpha_side_nat_gateway_ip != ""
          #add_nat_host_route(is_alpha_side, remote_host_ip, @alpha_side_nat_gateway_ip)
        end
        if @alpha_side_nat_gateway_ip != ""
          set_new_default_route(is_alpha_side, @beta_side_ip, @alpha_side_nat_gateway_ip)
        end
      end
    else
      # Set the beta side to use nat traversal Leave everything else at default.
      set_beta_nat(is_nat_traversal, nat_public_ip, local_nat_gateway_ip)
      # Add route for host through NAT router
      if @beta_side_natt
        if remote_host_ip != "" and @beta_side_nat_gateway_ip != ""
          #add_nat_host_route(is_alpha_side, remote_host_ip, @beta_side_nat_gateway_ip)
        end
        if @beta_side_nat_gateway_ip != ""
          set_new_default_route(is_alpha_side, @alpha_side_ip, @beta_side_nat_gateway_ip)
        end
      end
    end
  end

  def set_ipsec_template_file(ipsec_conf_input_file)
    # Set ipsec.conf input template file
    set_common(ipsec_conf_input_file, "", "", "", "")
  end

  def ipsec_typical_start(is_ipv4, is_pass_through, crypto_mode)
    function_name = "ipsec_typical_start"
    # Set ipsecVatf.result to zero
    clear_results()
    # Create all the certificates needed and start ipsec on both the Linux PC and the EVM. Start the ipsec tunnel on the EVM.
    ipsec_generate_keys_and_certs_and_start_all(is_ipv4, is_pass_through, crypto_mode)
    # Bring up the IPV6 IPSEC tunnel on both sides
    #start_tunnels(IPV6())
  end

  def verify_ls_dir(is_alpha_side, directory, filename, state)
    temp_state = (state ? @lnx_helper.files_exist?(is_alpha_side, directory, filename) : state)
    return temp_state
  end

  def trigger_key_and_cert_rebuild(is_alpha_side)
    # Create empty file to flag that keys and certs need to be remade
    @lnx_helper.create_writeable_empty_file(is_alpha_side, @trigger_key_and_cert_rebuild_file_name)
  end

  def is_genned_already()
    state = true
    # Check the alpha side keys and certificate existance
    state = false if verify_ls_dir(ALPHA_SIDE(), File.dirname(@trigger_key_and_cert_rebuild_file_name), File.basename(@trigger_key_and_cert_rebuild_file_name), state)
    state = verify_ls_dir(ALPHA_SIDE(), "/etc/ipsec.d/cacerts/", "caCert.der", state)
    state = verify_ls_dir(ALPHA_SIDE(), "/etc/ipsec.d/certs/", "alphaCert.der;alphaCertIP.der", state)
    state = verify_ls_dir(ALPHA_SIDE(), "/etc/ipsec.d/private/", "alphaKey.der;caKey.der", state)
    # Check the beta side keys and certificate existance
    state = false if verify_ls_dir(BETA_SIDE(), File.dirname(@trigger_key_and_cert_rebuild_file_name), File.basename(@trigger_key_and_cert_rebuild_file_name), state)
    state = verify_ls_dir(BETA_SIDE(), "/etc/ipsec.d/cacerts/", "caCert.der", state)
    state = verify_ls_dir(BETA_SIDE(), "/etc/ipsec.d/certs/", "betaCert.der;betaCertIP.der", state)
    state = verify_ls_dir(BETA_SIDE(), "/etc/ipsec.d/private/", "betaKey.der;caKey.der", state)
    return state
  end

  def ipsec_gen_only_start(is_ipv4, is_pass_through)
    function_name = "ipsec_gen_only_start"
    # Set ipsecVatf.result to zero
    clear_results()
    if !is_genned_already()
      # Create all the certificates needed and start ipsec on both the Linux PC and the EVM. Start the ipsec tunnel on the EVM.
      ipsec_generate_keys_and_certs_only(is_ipv4, is_pass_through)
    else
      # Set the time on the evm to match the PC. This is a must to have the certificates work properly.
      @lnx_helper.set_evm_date_time(BETA_SIDE())
    end
  end

  def ipsec_mgr_start(is_alpha_side)
    string = "IPSECMGR_"
    count = 4
    raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "env", "/usr/bin/env", @vatf_helper.DONT_SET_ERROR_BIT(), 2)
    # Only start the ipsec manager if the variables do not already exist
    if !@vatf_helper.is_matched_count(raw_buffer, string, count)
      @vatf_helper.log_info(is_alpha_side, "\r\nrmServer_up?: #{rmServer_up?}\r\n")
      if !rmServer_up?
        @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "cd /usr/bin; ./rmServer.out device/#{get_platform()}/global-resource-list.dtb device/#{get_platform()}/policy_dsp_arm.dtb", "", @error_bit, 2)
      end
      get_ipsec_cmd_additions_using_bench_file()
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "insmod #{@vatf_helper.get_file_location(is_alpha_side, @hplib_file_name)}", "", @error_bit, 2)
      if @do_friendly
        @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "insmod #{@vatf_helper.get_file_location(is_alpha_side, @ipsec_mgr)}", "", @error_bit, 2)
      end
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "cd #{@executable_directory}", "", @error_bit, 1)
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@app_sock_name_env_cmd}", "", @error_bit, 1)
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@daemon_sock_name_env_cmd}", "", @error_bit, 1)
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@log_file_env_cmd}", "", @error_bit, 1)
      if @do_friendly
        @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@daemon_cmd}&", "", @error_bit, 2)
      else
        @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@daemon_cmd}", "", @error_bit, 2)
      end
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "lsmod", "", @error_bit, 1)
    end
    @result |= @vatf_helper.result
    @result_text += @vatf_helper.result_text
    return @result
  end

  def inflow_offload(is_alpha_side)
    get_ipsec_cmd_additions_using_bench_file()
    inflow_stop_offload(is_alpha_side)
    policy_index_in = @vatf_helper.get_policy_id(is_alpha_side, "in")
    policy_index_out = @vatf_helper.get_policy_id(is_alpha_side, "out")
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@cmd_shell_cmd}", "CFG>", @error_bit, 2)
    @vatf_helper.offload_indices(is_alpha_side, policy_index_in, policy_index_out, "--shared", true)
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "exit", "", @error_bit, 2)
    # Set inflow active flag on EVM using an environment variable
    @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "export #{@inflow_active_name}=\"yes\"", "", @error_bit, 1)
    @result |= @vatf_helper.result
    @result_text += @vatf_helper.result_text
    return @result
  end

  def inflow_stop_offload(is_alpha_side)
    get_ipsec_cmd_additions_using_bench_file()
    string = @inflow_active_name
    count = 1
    raw_buffer = @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "env", "/usr/bin/env", @vatf_helper.DONT_SET_ERROR_BIT(), 2)
    # Only stop offload if inflow mode is active
    if @vatf_helper.is_matched_count(raw_buffer, string, count)
      policy_index_in = @vatf_helper.get_policy_id(is_alpha_side, "in")
      policy_index_out = @vatf_helper.get_policy_id(is_alpha_side, "out")
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "#{@cmd_shell_cmd}", "CFG>", @error_bit, 2)
      @vatf_helper.stop_offload_indices(is_alpha_side, policy_index_in, policy_index_out, @default_stop_offload_post_cmd, false, @default_stop_offload_pre_cmd)
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "exit", "", @error_bit, 2)
      # Remove inflow active flag on EVM by unsetting an environment variable
      @vatf_helper.smart_send_cmd(is_alpha_side, @normal_cmd, "unset #{@inflow_active_name}", "", @error_bit, 1)
    end
    @result |= @vatf_helper.result
    @result_text += @vatf_helper.result_text
    return @result
  end

end
