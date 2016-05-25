# Functions used to configure and run the GLSDK
#
#  Currently only NFS is supported. This is due to the fact that the EVM does not support git yet, which means the
#  git repository needs to be cloned on the NFS volume of the host PC instead of the EVM. Will add support for doing
#  git on the EVM when git on the EVM is available.
# 
#  To get the report.html hyperlink to work properly in the Notes section of TestLink, the latest version of the
#  upwardTranslator.xsl that contains the xsl:choose for href is required. The latest upwardTranslater.xsl
#  file can be retrieved using the steps shown below.
#   a) Bring up http://arago-project.org/git/projects/?p=test-automation/staf.git;a=summary in your browser
#   b) Click on the tree of the latest update
#   c) Click on misc
#   d) Click on vatf
#   e) Right click on raw next to upwardTranslater.xsl and then "Save Target As" to desired location
#
#  Build variables which will override the defaults:
#     var_glsdk_git_repo             ; To specify a different GLSDK git repository
#     var_glsdk_clone_to_dir         ; To specify a different GLSDK clone to directory on the EVM
#     var_glsdk_dir                  ; To specify a different GLSDK execution directory on the EVM
#     var_glsdk_framework_commit_id  ; To specify the checkout commit id for GLSDK git repository
#     glsdk_framework_patch_file     ; To specify the patch file to apply to GLSDK git repository
#
#  Test case parameters:
#     test_mins               ; Max time to allow the GLSDK framework to run          (range: 0 to infinity, default = 350)
#     loop                    ; Loop through modules until time expires               (range: "yes" or "no", default = "no")
#     run_once                ; Run through modules only once                         (range: "yes" or "no", default = "yes")
#     modules                 ; GLSDK modules to run (such as modules="graphics vpe") (range: list of modules separated by spaces, default = ""     )
#                                                                                     ( modules are the directories listed under the                )
#                                                                                     ( glsdk-genkins-automation/component_tests directory          )
#                                                                                     ( specific parts of the module can be run by specifying the   )
#                                                                                     ( module directory plus the shell script under that directory )
#                                                                                     ( such as module="graphics/kms-cube.sh". If just the directory)
#                                                                                     ( is specified then all shell scripts in that directory will  )
#                                                                                     ( be run.                                                     )

module GlsdkUtils
  
  def get_glsdk_git_repository()
    glsdk_git_repository = "git://gitorious.design.ti.com/glsdk-jenkins-automation/glsdk-jenkins-automation.git"
    glsdk_git_repository = @test_params.var_glsdk_git_repo.tr("\"", "") if @test_params.instance_variable_defined?(:@var_glsdk_git_repo)
    return glsdk_git_repository
  end
  
  def get_glsdk_framework_commit_id()
    glsdk_framework_commit_id = ""
    glsdk_framework_commit_id = @test_params.var_glsdk_framework_commit_id.tr("\"", "") if @test_params.instance_variable_defined?(:@var_glsdk_framework_commit_id)
    return glsdk_framework_commit_id
  end
  
  def get_glsdk_framework_patch_file()
    glsdk_framework_patch_file = ""
    glsdk_framework_patch_file = @test_params.glsdk_framework_patch_file.tr("\"", "") if @test_params.instance_variable_defined?(:@glsdk_framework_patch_file)
    return glsdk_framework_patch_file
  end
  
  def get_glsdk_clone_to_directory()
    glsdk_clone_to_dir = "/test"
    glsdk_clone_to_dir = @test_params.var_glsdk_clone_to_dir.tr("\"", "") if @test_params.instance_variable_defined?(:@var_glsdk_clone_to_dir)
    return glsdk_clone_to_dir
  end
  
  def get_glsdk_directory()
    glsdk_dir = File.join(get_glsdk_clone_to_directory(), "glsdk-jenkins-automation")
    glsdk_dir = @test_params.var_glsdk_dir.tr("\"", "") if @test_params.instance_variable_defined?(:@var_glsdk_dir)
    return glsdk_dir
  end
  
  def item_exists?(equip, path_or_file)
    return check_cmd?("ls #{path_or_file}", equip)
  end
  
  def run_and_check_command(equip, command_line, previous_result_text="", wait_secs=10)
    result_text = previous_result_text
    if result_text == ""
      # Verify that command is successful
      if !check_cmd?(command_line, equip, wait_secs)
        result_text = "Error: Command was not successful (#{command_line})"
      end
    end
    return result_text
  end
  
  def clean_and_refresh_git_repository(equip, repo_dir, previous_result_text="", pull_wait_secs=180)
    result_text = previous_result_text
    result_text = run_and_check_command(equip, "cd #{repo_dir}; git clean -xfq", result_text)
    result_text = run_and_check_command(equip, "cd #{repo_dir}; git reset --hard", result_text)
    result_text = run_and_check_command(equip, "cd #{repo_dir}; git checkout master", result_text)
    result_text = run_and_check_command(equip, "cd #{repo_dir}; git pull", result_text, pull_wait_secs)
    return result_text
  end

  def clone_git_repository(equip, to_directory, chk_exists_dir, do_not_modify_repo_file)
    result_text = ""
    wait_secs = 180
    if !item_exists?(equip, chk_exists_dir)
      git_repository = get_glsdk_git_repository()
      command_wait_message = equip.prompt
      chk_cmd_echo = true
      # Clone the git repository to the specified directory
      equip.send_cmd("cd #{to_directory}; git clone #{git_repository}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      # Check to see if cloned directory exists after git clone is run
      if !item_exists?(equip, chk_exists_dir)
        result_text = "Error: Clone of git repository was not successful (#{git_repository})"
      end
    else
      # Clean local git repository and pull down the latest changes when do_not_modify_git_repository file is not present
      if !item_exists?(equip, do_not_modify_repo_file)
        result_text = clean_and_refresh_git_repository(equip, chk_exists_dir, result_text, wait_secs)
      else
        equip.log_info("\r\n#### The \"#{do_not_modify_repo_file}\" file is present and therefore not cleaning git repository. ####\r\n")
      end
    end
    return result_text
  end
  
  def tftp_build_config_file_to_evm(build_param_value, destination_dir, equip=@equipment['dut1'], equip_srv=@equipment['server1'])
    if build_param_value != ""
      tmp_relative_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
      tftp_file_name = File.basename(build_param_value)
      server_tftp_path = File.join(equip_srv.tftp_path, tmp_relative_path)
      server_tftp_file_and_path = File.join(server_tftp_path, tftp_file_name)
      equip_srv.log_info("\r\n src: #{build_param_value}, dst: #{server_tftp_path}\r\n")
      copy_asset(equip_srv, build_param_value, server_tftp_path)
      tftp_file_and_path = File.join(tmp_relative_path, tftp_file_name)
      tftp_server_ip = equip_srv.telnet_ip
      equip.send_cmd("cd #{destination_dir}; tftp -g -r #{tftp_file_and_path} #{tftp_server_ip} ; echo command_done", equip.prompt, 10)
    end
  end
  
  def patch_applied?(patch_file, repo_dir, equip, applied_post_fix="_applied")
    is_applied = false
    is_applied = true if item_exists?(equip, File.join(repo_dir, "#{patch_file}#{applied_post_fix}"))
    return is_applied
  end
  
  def set_patch_as_applied(patch_file, repo_dir, equip, applied_post_fix="_applied")
    equip.send_cmd("cd #{repo_dir}; mv #{File.join(repo_dir, "#{patch_file}")} #{File.join(repo_dir, "#{patch_file}#{applied_post_fix}")}", equip.prompt, 10)
  end
  
  def checkout_and_apply_patch_to_git_repository(equip, repo_dir, commit_id, patch_file)
    result_text = ""
    wait_secs = 10
    chk_cmd_echo = true
    if commit_id != ""
      # Check if commit ID is already checked out
      if !check_cmd?("cd #{repo_dir}; git rev-parse HEAD | grep #{commit_id}", equip, wait_secs)
        # Checkout using commit id
        result_text = run_and_check_command(equip, "cd #{repo_dir}; git checkout #{commit_id}", result_text, wait_secs)
      end
    end
    if patch_file != "" and result_text == ""
      if !patch_applied?(patch_file, repo_dir, equip)
        # Go to the local git repository directory and apply patch
        result_text = run_and_check_command(equip, "cd #{repo_dir}; git apply #{patch_file}", result_text, wait_secs)
        set_patch_as_applied(patch_file, repo_dir, equip) if result_text == ""
      end
    end
    return result_text
  end

  def sed_file_phrase(equip, file_and_path, current_phrase, new_phrase)
    command_wait_message = equip.prompt
    wait_secs = 10
    chk_cmd_echo = true
    adjusted_current_phrase = current_phrase.gsub("/", "\\/")
    adjusted_new_phrase = new_phrase.gsub("/", "\\/")
    command = "sed -i 's/#{adjusted_current_phrase}/#{adjusted_new_phrase}/g' #{file_and_path}"
    equip.send_cmd("#{command}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
  end

  def sed_file_value(equip, file_and_path, current_phrase, new_phrase)
    command_wait_message = equip.prompt
    wait_secs = 10
    chk_cmd_echo = true
    response_isolator = "@@@"
    command = "cat #{file_and_path} | grep #{current_phrase}"
    if check_cmd?(command, equip)
      command = "echo \"#{response_isolator}$(#{command})#{response_isolator}\""
      equip.send_cmd("#{command}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      # Use the response contained between the response isolator strings to avoid random kernel messages contained in the response buffer
      response_items = equip.response.split(response_isolator)
      file_current_phrase = equip.response.split(response_isolator)[response_items.length - 2].chomp
      sed_file_phrase(equip, file_and_path, file_current_phrase, new_phrase)
    end
  end

  def get_glsdk_platform(equip)
    command_wait_message = equip.prompt
    wait_secs = 10
    chk_cmd_echo = true
    command = "echo `uname -a | awk -F\" \" '{ print $2 }'`"
    equip.send_cmd("#{command}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    return equip.response.split("\n")[1].chomp
  end

  def configure_glsdk(equip, glsdk_dir, test_mins, loop, run_once, modules)
    # Set configure operation parameters
    is_full_config = true
    done_indicator_file = "config_done.flg"
    platform = get_glsdk_platform(equip)
    platform_base = platform.split("-")[0]
    if item_exists?(equip, File.join(glsdk_dir, done_indicator_file))
      # Set for params only configuration mode if previously configured indicator file is present
      is_full_config = false
    end
    
    # Set equipment send command parameters 
    command_wait_message = equip.prompt
    wait_secs = 10
    chk_cmd_echo = true
    
    # Log GLSDK configuration parameters used
    equip.log_info("GLSDK framework configuration parameters:")
    equip.log_info("  glsdk_dir     : #{glsdk_dir}")
    equip.log_info("  test_mins     : #{test_mins}")
    equip.log_info("  loop          : #{loop}")
    equip.log_info("  run_once      : #{run_once}")
    equip.log_info("  modules       : #{modules}")
    equip.log_info("  platform      : #{platform}")
    equip.log_info("  platform base : #{platform_base}")
    equip.log_info("  config mode   : #{(is_full_config ? "full" : "params only")}")
    
    # Configure scripts/config-component-tester
    file_and_path = File.join(glsdk_dir, "scripts/config-component-tester")
    if is_full_config
      sed_file_phrase(equip, file_and_path, "^NFSROOT", "#NFSROOT")
      sed_file_phrase(equip, file_and_path, "^TFTPBOOT", "#TFTPBOOT")
      sed_file_value(equip, file_and_path, "^PLATFORM=", "PLATFORM=#{platform_base}")
    end
    sed_file_value(equip, file_and_path, "^ENABLE_RUN_ONCE=", "ENABLE_RUN_ONCE=#{run_once}")
    sed_file_value(equip, file_and_path, "^RUN_ONCE=", "RUN_ONCE=#{run_once}")
    sed_file_value(equip, file_and_path, "^LOOP=", "LOOP=#{loop}")
    sed_file_value(equip, file_and_path, "^DURATION_TO_TEST_MINS=", "DURATION_TO_TEST_MINS=#{test_mins}")
    sed_file_value(equip, file_and_path, "^MODULES=", "MODULES=\"#{modules}\"")

    # Configure scripts/config-release
    file_and_path = File.join(glsdk_dir, "scripts/config-release")
    if is_full_config
      sed_file_phrase(equip, file_and_path, "^NFSROOT", "#NFSROOT")
      sed_file_phrase(equip, file_and_path, "^TFTPBOOT", "#TFTPBOOT")
      sed_file_value(equip, file_and_path, "^PLATFORM=", "PLATFORM=#{platform_base}")
    end
    sed_file_value(equip, file_and_path, "^ENABLE_RUN_ONCE=", "ENABLE_RUN_ONCE=#{run_once}")
    sed_file_value(equip, file_and_path, "^RUN_ONCE=", "RUN_ONCE=#{run_once}")
    sed_file_value(equip, file_and_path, "^LOOP=", "LOOP=#{loop}")
    sed_file_value(equip, file_and_path, "^DURATION_TO_TEST_MINS=", "DURATION_TO_TEST_MINS=#{test_mins}")

    # Configure scripts/S99ztest.sh
    file_and_path = File.join(glsdk_dir, "scripts/S99ztest.sh")
    if is_full_config
      sed_file_phrase(equip, file_and_path, "^sh INIT_TEST.sh", "#sh INIT_TEST.sh")
    end

    # Create the clean_results.sh file which will be used to clear the previous resutls
    if is_full_config
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm *.csv\" > clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm *.gz\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm *.txt\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm scripts/Systeminfo.csv\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm error_reports/*\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm logs/*\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm report.html\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo \"rm wkar\" >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; chmod 777 clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    end
    
    # Create logs directories
    if is_full_config
      file_and_path = File.join(glsdk_dir, "scripts/generate-report.sh")
      equip.send_cmd("cd #{glsdk_dir}; cp #{file_and_path} .", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    end
    
    # Create empty logs directories
    if is_full_config
      logs_dir = File.join(glsdk_dir, "logs")
      equip.send_cmd("mkdir -p #{logs_dir}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      logs_dir = File.join(File.dirname(glsdk_dir), "logs")
      equip.send_cmd("mkdir -p #{logs_dir}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    end
    
    # Create indicator file to show full configuration has been done
    if is_full_config
      equip.send_cmd("cd #{glsdk_dir}; touch #{done_indicator_file}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    end
  end

  def remove_file(equip, file_to_remove, is_sudo)
    result_text = ""
    command_wait_message = equip.prompt
    wait_secs = 30
    chk_cmd_echo = true

    if item_exists?(equip, file_to_remove)
      remove_command = "rm #{file_to_remove}"
      if is_sudo
        equip.send_sudo_cmd(remove_command, /#{command_wait_message}/, wait_secs)
      else
        equip.send_cmd(remove_command, /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      end
    end
    if item_exists?(equip, file_to_remove)
      result_text = "Error: Unable to remove the file (#{file_to_remove})"
    end
    return result_text
  end
  
  def kill_parent_and_children_processes(parent_process, equip)
    error_text = ""
    # Stop current process (Control-Z)
    equip.send_cmd("\x1A",equip.prompt, 10)
    # Put stopped process in the background. Find parent process ID, use parent process ID to find child processes and then kill parent and child processes
    equip.send_cmd("bg ; kill -9 $(top -n 1 | grep $(top -n 1 | grep -v grep | grep #{parent_process} | awk '{print $1}') | sort -u | awk '{printf \"%s \", $1}')",equip.prompt, 10)
    error_text = "###ERROR: Unable to gain access to command prompt.###" if equip.timeout?
    return error_text
  end
  
  def disable_gui_applications(equip, gui_app_files_to_disable, rename_suffix)
    apps_renamed = false
    command_wait_message = equip.prompt
    wait_secs = 10
    chk_cmd_echo = true
    gui_app_files_to_disable.each do |g_app|
      if item_exists?(equip, g_app)
        apps_renamed = true
        file_name = File.basename(g_app)
        equip.send_cmd("cd #{File.dirname(g_app)}; mv #{file_name} #{file_name}#{rename_suffix}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      end
    end
    # Reboot the EVM if GUI applications files were renamed
    if apps_renamed
      # Clear @old_keys to ensure that the EVM reboots.
      @old_keys = ''
      setup 
    end
  end
  
  def restore_gui_application_names(equip, gui_app_files_to_disable, rename_suffix)
    command_wait_message = equip.prompt
    wait_secs = 10
    chk_cmd_echo = true
    gui_app_files_to_disable.each do |g_app|
      if item_exists?(equip, "#{g_app}#{rename_suffix}")
        file_name = File.basename(g_app)
        equip.send_cmd("cd #{File.dirname(g_app)}; mv #{file_name}#{rename_suffix} #{file_name}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      end
    end
  end
  
  def run_glsdk(equip, equip_srv, glsdk_dir, test_mins, evm_ip_address)
    error_text = ""
    command_wait_message = equip.prompt
    wait_secs = 60
    chk_cmd_echo = true
    # Remove previous results
    equip.send_cmd("cd #{glsdk_dir}; ./clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    wait_secs = (test_mins + 2) * 60
    command_wait_message = "GLSDK test framework execution is complete."
    # Run GLSDK script. Make sure command line echo is turned back on.
    equip.send_cmd("cd #{glsdk_dir}/scripts; ./INIT_TEST.sh; stty echo; echo \"stty echo on\"; echo \"#{command_wait_message}\"", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    if equip.timeout?
      error_text = "###ERROR: Script Timeout - GLSDK Product Test Framework did not finish within alloted time. (Timeout minutes: #{test_mins})### "
      command_wait_message = equip.prompt
      wait_secs = 5
      no_chk_cmd_echo = false
      3.times do
        # Send Control-C to stop the currently running script to gain access to the command prompt
        equip.log_info("Sending Control-C to stop currently running script...\r\n")
        equip.send_cmd("\x03", /#{command_wait_message}/, wait_secs, no_chk_cmd_echo)
        break if !equip.timeout?
      end
      if equip.timeout?
        # Next try to kill INIT_TEST.sh parent and child processes
        equip.log_info("Killing parent and children processes...\r\n")
        this_error_text = kill_parent_and_children_processes("INIT_TEST.sh", equip) if equip.timeout?
        if this_error_text != ""
          # Only choice left is to reboot the EVM to gain access to the command prompt
          setup
        end
      end
    end
    return error_text
  end

  def generate_glsdk_report(equip, glsdk_dir)
    command_wait_message = equip.prompt
    wait_secs = 120
    gen_wait_secs = 900
    chk_cmd_echo = true
    file_and_path = File.join(glsdk_dir, "scripts/Systeminfo.csv")
    equip.send_cmd("cd #{glsdk_dir}; cp #{file_and_path} .", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    equip.send_cmd("cd #{glsdk_dir}; ./generate-report.sh test_report.txt logs", /#{command_wait_message}/, gen_wait_secs, chk_cmd_echo)
  end

  def copy_glsdk_results_to_log_server(equip_evm, equip_srv, glsdk_dir, tee_instance_id, glsdk_test_report_tar_name, report_file_name)
    glsdk_tar_includes = "error_reports/ logs/ *.csv *.txt *.html wkar"
    host_glsdk_logs_subdir = "glsdk_logs"
    
    host_tftp_ip = equip_srv.telnet_ip
    tftp_remote_tar = File.join(tee_instance_id, glsdk_test_report_tar_name)
    host_glsdk_test_report_tar = File.join(equip_srv.tftp_path, tftp_remote_tar)
    command_wait_message = equip_evm.prompt
    wait_secs = 120
    chk_cmd_echo = true
    
    # Create tarball for logs files on the EVM
    equip_evm.send_cmd("cd #{glsdk_dir}; tar cvzf #{glsdk_test_report_tar_name} #{glsdk_tar_includes}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    # TFTP tarball from EVM to linux PC
    equip_evm.send_cmd("cd #{glsdk_dir}; tftp -p -l #{glsdk_test_report_tar_name} -r #{tftp_remote_tar} #{host_tftp_ip}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    # Upload PC tarball file to log directory
    host_file_ref = upload_file(host_glsdk_test_report_tar)
    host_logs_dir = File.join(File.dirname(host_file_ref[0]), host_glsdk_logs_subdir)
    command_wait_message = equip_srv.prompt
    # Untar tarball on host
    equip_srv.send_cmd("mkdir -p #{host_logs_dir}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    equip_srv.send_cmd("cd #{host_logs_dir}; tar -xvzf ../#{glsdk_test_report_tar_name}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    # Remove tarball on host
    equip_srv.send_cmd("cd #{File.dirname(host_file_ref[0])}; rm #{glsdk_test_report_tar_name}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    # Create report file link
    report_file_web_link = host_file_ref[1].gsub(glsdk_test_report_tar_name, File.join(host_glsdk_logs_subdir, report_file_name))
    return report_file_web_link
  end

  def get_count_value(test_counts_string, pre_phrase, post_phrase)
    value = ""
    if test_counts_string.include?(pre_phrase)
      temp_str = test_counts_string.split(pre_phrase)[1]
      value = temp_str.split(post_phrase)[0]
    end
    return value
  end
  
  def is_glsdk_passed?(test_counts_string)
    is_test_passed = true
    passed_count = get_count_value(test_counts_string, "Passed: ", ",").to_i
    failed_count = get_count_value(test_counts_string, "Failed: ", ",").to_i
    failed_count += get_count_value(test_counts_string, "Killed: ", ",").to_i
    is_test_passed = false if failed_count != 0
    is_test_passed = false if passed_count == 0
    return is_test_passed
  end
  
  def glsdk_test_counts(equip, file_and_path, pass_phrase, fail_phrase, kill_phrase)
    command_wait_message = equip.prompt
    wait_secs = 60
    chk_cmd_echo = true
    
    # Get pass/fail/kill counts from result file
    equip.send_cmd("cat #{file_and_path} | grep -c #{pass_phrase}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    passed_count = equip.response.split("\n")[1].chomp.to_i
    equip.send_cmd("cat #{file_and_path} | grep -c #{fail_phrase}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    failed_count = equip.response.split("\n")[1].chomp.to_i
    equip.send_cmd("cat #{file_and_path} | grep -c #{kill_phrase}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    killed_count = equip.response.split("\n")[1].chomp.to_i
    total_count = passed_count + failed_count + killed_count
    pass_percent = "%02.02f"  % (100 * (passed_count.to_f / total_count.to_f))
    test_count_display = "Pass %: #{pass_percent};    Passed: #{passed_count},    Failed: #{failed_count},    Killed: #{killed_count},    Total Tests Run: #{total_count}"
    return test_count_display
  end
  
  def create_writeable_dir(equip, path_to_make, is_sudo)
    result_text = ""
    command_wait_message = equip.prompt
    wait_secs = 30
    chk_cmd_echo = true

    if !item_exists?(equip, path_to_make)
      make_dir_command = "mkdir -p #{path_to_make}"
      chmod_aw_command = "chmod a+w #{path_to_make}"
      if is_sudo
        equip.send_sudo_cmd(make_dir_command, /#{command_wait_message}/, wait_secs)
        equip.send_sudo_cmd(chmod_aw_command, /#{command_wait_message}/, wait_secs)
      else
        equip.send_cmd(make_dir_command, /#{command_wait_message}/, wait_secs, chk_cmd_echo)
        equip.send_cmd(chmod_aw_command, /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      end
    end
    if !item_exists?(equip, path_to_make)
      result_text = "Error: Unable to create the writeable directory (#{path_to_make})"
    end
    return result_text
  end
  
  def setup_and_run_glsdk_framework()
    # If true then clone GLSDK to the NFS directory on the Linux PC. If false then clone GLSDK directly on the EVM
    @equipment['dut1'].send_cmd('cat /proc/cmdline',@equipment['dut1'].prompt)
    is_clone_git_repo_on_pc = @equipment['dut1'].response.match(/root=\/dev\/nfs/)

    # Set Host and EVM equipment references
    equip_srv = @equipment['server1']
    equip_evm = @equipment['dut1']

    # Set the list of files to be disabled to allow the GLSDK product framework to run properly
    gui_app_files_to_disable = Array.new
    gui_app_files_to_disable.push("/etc/init.d/weston")
    gui_app_files_to_disable.push("/etc/rc5.d/S97matrix-gui-2.0")
  
    # Set default test values
    error_text = ""
    test_mins = 350
    loop = "no"
    run_once = "yes"
    modules = ""
    tee_instance_id = @test_params.staf_service_name.tr("\"", "").strip
    glsdk_test_report_tar_name = "glsdk_test_report.tar.gz"
    srv_tftp_dir = File.join(equip_srv.tftp_path, tee_instance_id)
    evm_ip_address = get_ip_addr('dut1')

    # Get parameter values from test case
    test_mins = @test_params.params_chan.test_mins[0].to_i if @test_params.params_chan.instance_variable_defined?(:@test_mins)
    loop = @test_params.params_chan.loop[0].tr("\"", "") if @test_params.params_chan.instance_variable_defined?(:@loop)
    run_once = @test_params.params_chan.run_once[0].tr("\"", "") if @test_params.params_chan.instance_variable_defined?(:@run_once)
    modules = @test_params.params_chan.modules[0].tr("\"", "") if @test_params.params_chan.instance_variable_defined?(:@modules)
    
    # Make sure the modules parameter has been set
    if modules.gsub(" ","") == ""
      error_text = "Error: The modules testcase parameter must be set in order to run the GLSDK framework. (e.g. modules=\"grahics vpe\")\r\n"
    end
    
    clone_to_dir = get_glsdk_clone_to_directory()
    glsdk_dir = get_glsdk_directory()
    
    # Set GLSDK git clone information based on whether cloning to the PC's NFS directory or on the EVM directly
    base_dir = (is_clone_git_repo_on_pc ? LspTestScript.nfs_root_path : "/")
    g_clone_equip = (is_clone_git_repo_on_pc ? equip_srv : equip_evm)
    g_clone_to_dir = File.join(base_dir, clone_to_dir)
    g_glsdk_dir = File.join(base_dir, glsdk_dir)
    g_dev_chk_file = File.join(g_clone_to_dir, "do_not_modify_git_repository")
    
    # Log test case parameters used
    equip_srv.log_info("GLSDK framework run parameters:")
    equip_srv.log_info("  TEE id         : #{tee_instance_id}")
    equip_srv.log_info("  test_mins      : #{test_mins}")
    equip_srv.log_info("  loop           : #{loop}")
    equip_srv.log_info("  run_once       : #{run_once}")
    equip_srv.log_info("  clone_to_dir   : #{clone_to_dir}")
    equip_srv.log_info("  glsdk_dir      : #{glsdk_dir}")
    equip_srv.log_info("  git_repository : #{get_glsdk_git_repository()}")
    equip_srv.log_info("  modules        : #{modules}")
    equip_srv.log_info("  g_clone_to_dir : #{g_clone_to_dir}")
    equip_srv.log_info("  g_glsdk_dir    : #{g_glsdk_dir}")
    equip_srv.log_info("  g_dev_chk_file : #{g_dev_chk_file}")
    equip_srv.log_info("  srv_tftp_dir   : #{srv_tftp_dir}")
    equip_srv.log_info("  evm_ip_address : #{evm_ip_address}")
    equip_srv.log_info("  report_tar_name: #{glsdk_test_report_tar_name}")
    equip_srv.log_info("\r\n")

    # Make sure TEE specific TFTP server directory exits
    is_sudo = true
    error_text = create_writeable_dir(equip_srv, srv_tftp_dir, is_sudo) if error_text == ""
    # Make sure clone to directory exists
    is_sudo = false
    error_text = create_writeable_dir(equip_evm, clone_to_dir, is_sudo) if error_text == ""
    # Clear srv side results.gz file
    is_sudo = true
    error_text = remove_file(equip_srv, File.join(srv_tftp_dir, glsdk_test_report_tar_name), is_sudo) if error_text == ""
    # Clone GLSDK git repository. Retry up to 3 times.
    3.times do
      error_text = clone_git_repository(g_clone_equip, g_clone_to_dir, g_glsdk_dir, g_dev_chk_file)
      break if error_text == ""
      sleep(15)
    end
    if error_text == ""
      if !item_exists?(g_clone_equip, g_dev_chk_file)
        # Transfer patch file to DUT
        if !patch_applied?(File.basename(get_glsdk_framework_patch_file()), g_glsdk_dir, g_clone_equip)
          tftp_build_config_file_to_evm(get_glsdk_framework_patch_file(), get_glsdk_directory())
        end
        # Checkout using commit id and apply patch
        error_text = checkout_and_apply_patch_to_git_repository(g_clone_equip, g_glsdk_dir, get_glsdk_framework_commit_id(), File.basename(get_glsdk_framework_patch_file()))
      else
        if get_glsdk_framework_commit_id() != "" or get_glsdk_framework_patch_file() != ""
          g_clone_equip.log_info("\r\n#### The \"#{g_dev_chk_file}\" file is present and therefore not checking out commit ID or applying patch to git repository. ####\r\n")
        end
      end
    end  
    if error_text == ""
      # Suffix to use when renaming the GUI applications on the EVM to disable them.
      rename_suffix = "_aglsdk.bak"
      # Disable the GUI applications before running the GLSDK framework
      disable_gui_applications(equip_evm, gui_app_files_to_disable, rename_suffix)
      # Configure GLSDK framework files
      configure_glsdk(equip_evm, glsdk_dir, test_mins, loop, run_once, modules)
      # Run GLSDK framework
      error_text += run_glsdk(equip_evm, equip_srv, glsdk_dir, test_mins, evm_ip_address)
      # Generate GLSDK test report
      generate_glsdk_report(equip_evm, glsdk_dir)
      # Restore the proper names of the GUI applications if necessary.
      restore_gui_application_names(equip_evm, gui_app_files_to_disable, rename_suffix)
    end
    # Upload results files/logs and set the TestLink test result
    set_glsdk_test_result(equip_evm, equip_srv, tee_instance_id, glsdk_dir, glsdk_test_report_tar_name, error_text)
  end
  
  def set_glsdk_test_result(equip_evm, equip_srv, tee_instance_id, glsdk_dir, glsdk_test_report_tar_name, error_text)
    # Set glsdk test status gathering information
    report_file_name = "report.html"
    counts_file = report_file_name
    pass_phrase = "TESTPASS"
    fail_phrase = "TESTFAIL"
    kill_phrase = "TESTKILL"
    comments = error_text
    result = 0
    test_counts_string = ""
    
    if error_text == "" or error_text.include?("Script Timeout")
      if error_text != ""
        result = 1
      end
      # Copy test result files to log path and get web link to glsdk test report html
      report_html_web_path = copy_glsdk_results_to_log_server(equip_evm, equip_srv, glsdk_dir, tee_instance_id, glsdk_test_report_tar_name, report_file_name)
      report_link  = "<p><a href=\"http://#{report_html_web_path}\" target=\"_blank\">GLSDK Test Report</a></p>"
      
      # Get pass/fail counts and determine pass/fail result
      test_counts_string = glsdk_test_counts(equip_evm, counts_file, pass_phrase, fail_phrase, kill_phrase)
      result = 1 if !is_glsdk_passed?(test_counts_string)
      
      # Set result comments
      comments += "  #{test_counts_string}"
      comments += "  #{report_link}\n"
    else
      result = 1
    end
    
    # Set test result
    if result == 0
      test_done_result = FrameworkConstants::Result[:pass]
    else
      test_done_result = FrameworkConstants::Result[:fail]
    end
    
    # Set test result and result comments
    set_result(test_done_result, comments)
  end
end
