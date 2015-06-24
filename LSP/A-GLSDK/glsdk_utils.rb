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
#     var_glsdk_git_repo      ; To specify a different GSLDK git repository
#     var_glsdk_clone_to_dir  ; To specify a different GSLDK clone to directory on the EVM
#     var_glsdk_dir           ; To specify a different GSLDK execution directory on the EVM
#
#  Test case parameters:
#     test_mins               ; Max time to allow the GSLDK framework to run          (range: 0 to infinity, default = 350)
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
    return check_cmd?("ls #{File.dirname(path_or_file)} | grep #{File.basename(path_or_file)}", equip)
  end

  def clone_git_repository(equip, to_directory, chk_exists_dir)
    result_text = ""
    if !item_exists?(equip, chk_exists_dir)
      git_repository = get_glsdk_git_repository()
      command_wait_message = equip.prompt
      wait_secs = 180
      chk_cmd_echo = true
      # Clone the git repository to the specified directory
      equip.send_cmd("cd #{to_directory}; git clone #{git_repository}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      # Check to see if cloned directory exists after git clone is run
      if !item_exists?(equip, chk_exists_dir)
        result_text = "Error: Clone of git repository was not successful (#{git_repository})"
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
    command = "cat #{file_and_path} | grep #{current_phrase}"
    equip.send_cmd("#{command}", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    file_current_phrase = equip.response.split("\n")[1].chomp
    sed_file_phrase(equip, file_and_path, file_current_phrase, new_phrase)
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
      equip.send_cmd("cd #{glsdk_dir}; echo rm *.csv > clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo rm *.gz >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo rm *.txt >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo rm error_reports/* >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo rm logs/* >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo rm report.html >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
      equip.send_cmd("cd #{glsdk_dir}; echo rm wkar >> clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
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
  
  def run_glsdk(equip, glsdk_dir, test_mins)
    command_wait_message = equip.prompt
    wait_secs = 60
    chk_cmd_echo = true
    # Remove previous results
    equip.send_cmd("cd #{glsdk_dir}; ./clean_results.sh", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
    wait_secs = test_mins * 60
    # Run GLSDK script. Make sure command line echo is turned back on.
    equip.send_cmd("cd #{glsdk_dir}/scripts; ./INIT_TEST.sh; stty echo; echo \"stty echo on\"", /#{command_wait_message}/, wait_secs, chk_cmd_echo)
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
    is_clone_git_repo_on_pc = true
    
    # Set Host and EVM equipment references
    equip_srv = @equipment['server1']
    equip_evm = @equipment['dut1']

    # Set default test values
    error_text = ""
    test_mins = 350
    loop = "no"
    run_once = "yes"
    modules = ""
    tee_instance_id = @test_params.staf_service_name.tr("\"", "").strip
    glsdk_test_report_tar_name = "glsdk_test_report.tar.gz"
    srv_tftp_dir = File.join(equip_srv.tftp_path, tee_instance_id)
    
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
    equip_srv.log_info("  srv_tftp_dir   : #{srv_tftp_dir}")
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
      error_text = clone_git_repository(g_clone_equip, g_clone_to_dir, g_glsdk_dir)
      break if error_text == ""
      sleep(15)
    end
    if error_text == ""
      # Configure GLSDK framework files
      configure_glsdk(equip_evm, glsdk_dir, test_mins, loop, run_once, modules)
      # Run GLSDK framework
      run_glsdk(equip_evm, glsdk_dir, test_mins)
      # Generate GLSDK test report
      generate_glsdk_report(equip_evm, glsdk_dir)
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
    
    if error_text == ""
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