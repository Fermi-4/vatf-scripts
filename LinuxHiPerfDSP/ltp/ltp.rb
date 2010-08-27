require 'net/ftp'
DUT_DST_DIR = "opt/ltp"

  # Connects Test Equipment to DUT(s) and Boot DUT(s)
  require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
  include C6xTestScript
			
	def setup
		super
  end

  # Execute shell script in DUT(s) and save results.
  def run
    @show_debug_messages = false
    debug_puts "LTP::run"
    iteration = Time.now
    @iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
    @test_case_id = @test_params.caseID
    FileUtils.mkdir_p SiteInfo::LTP_TEMP_FOLDER if !Dir.exists?(SiteInfo::LTP_TEMP_FOLDER)
    FileUtils.mkdir_p "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}" if !Dir.exists?("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}")
    run_generate_test_list
    run_generate_test_cfg
    run_transfer_script
    run_call_script
    results_file,log_file = run_get_script_output
    if(results_file == nil or log_file == nil)
      set_result(FrameworkConstants::Result[:fail],'')
      clean()
      return
    end
    run_collect_performance_data
    run_save_results(results_file,log_file)
  end

  # Do nothing by default.  Overwrite implementation in test script if required
  def clean
    debug_puts "LTP::clean"
  end
  
  # Do nothing by default.  Overwrite implementation in test script if required to connect test equipment to DUT(s)
  def setup_connect_equipment
    debug_puts "LTP::setup_connect_equipment"
  end
  

  # Generate commands file to be executed at DUT.
  # By default this function only replaces the @test_params references and creates testlist.coff 
  def run_generate_test_list

    commands = {}
    out_file = File.new(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}", 'testlist.coff'),'w')
    @test_params.params_chan.instance_variable_get("@testlist").each do |test_tag|
      tagName, tagValue = test_tag.split("=")[0],test_tag.split("=")[1] 
      out_file.puts "#{tagName} sandbox #{tagValue}"
    end
    out_file.close
  end
  
  
  def run_generate_test_cfg
    in_file = File.open(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/#{@test_params.platform}", 'stmc_template.cfg'),'r')
    out_file = File.open(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}", 'stmc.cfg'),'w')
    while in_file.gets do
    if $. == 2 then # we are at the 2 line
      out_file.puts "condev		#{@equipment['dut1'].telnet_ip}:#{@equipment['dut1'].telnet_port}"
      out_file.puts "start		[DEAD-NET]"
      out_file.puts "lockdir		/tmp"
      out_file.puts "testlist	#{@equipment['dut1'].nfs_root_path}/#{DUT_DST_DIR}/ti-c6x/testlist.coff"
      out_file.puts "testlog		\"testruns/test-%Y%m%d-%H%M%S.log\""
      out_file.puts "commlog		\"testruns/comm-%Y%m%d-%H%M%S.log\""
    end
    out_file.print $_
    end
    out_file.close
    in_file.close
  end
  
  # Transfer the shell script (test.bat) to the DUT. 
  def run_transfer_script()
    debug_puts "LTP::run_transfer_script"
    @equipment['server1'].send_cmd("cd #{@equipment['dut1'].nfs_root_path}/#{DUT_DST_DIR}",@equipment['server1'].prompt)
    @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt)
    if !(File.exists?"\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}/#{DUT_DST_DIR}/ti-c6x")
      @equipment['server1'].send_sudo_cmd("mkdir ti-c6x ",@equipment['server1'].prompt) 
      @equipment['server1'].send_sudo_cmd("chmod 777 ti-c6x",@equipment['server1'].prompt)
    end
    test_copy({'filename' => 'testlist.coff','src_dir' => "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}", 'dst_dir' => "#{DUT_DST_DIR}/ti-c6x"})
    test_copy({'filename' => 'stmc.cfg','src_dir' => "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}", 'dst_dir' => "#{DUT_DST_DIR}/ti-c6x"})
  end
  
  # Calls shell script (test.bat)
  def run_call_script
    debug_puts "LTP::run_call_script"
    @equipment['server1'].send_cmd("cd #{@equipment['dut1'].nfs_root_path}/#{DUT_DST_DIR}",@equipment['server1'].prompt)
    if(File.exists?"\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}/#{DUT_DST_DIR}/testruns")
    @equipment['server1'].send_sudo_cmd("rm -f testruns/* ",@equipment['server1'].prompt)
    else
    @equipment['server1'].send_sudo_cmd("mkdir testruns ",@equipment['server1'].prompt)
    end
    @equipment['server1'].send_sudo_cmd("\./testdriver ti-c6x/stmc.cfg",@equipment['server1'].prompt,-1)
  end
  
  def run_get_script_output
    debug_puts "LTP::run_get_script_output"
    @equipment['server1'].send_cmd("ls testruns/",/test-\d+-\d+\.log/,10)
    debug_puts @equipment['server1'].response
    if(@equipment['server1'].timeout?)
      cleanup
      results_file = log_file = nil
      [results_file,log_file]
      return
    end
    results_file = /test-\d+-\d+\.log/.match(@equipment['server1'].response).to_s
    log_file = /comm-\d+-\d+\.log/.match(@equipment['server1'].response).to_s
    debug_puts results_file
    debug_puts log_file
    if(results_file == nil or log_file == nil)
      [results_file,log_file]
      return
    end
    log_copy({'filename' => results_file,'src_dir' => "#{DUT_DST_DIR}/testruns", 'dst_dir' => "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}"})
    log_copy({'filename' => log_file,'src_dir' => "#{DUT_DST_DIR}/testruns", 'dst_dir' => "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}"})
    [results_file,log_file]
  end
  
  # Parse test.log and extracts performance data into perf.log. This method MUST be overridden if performance data needs to be collected.
  # The default implementation creates and empty perf.log file
  def run_collect_performance_data
    debug_puts "LTP::run_collect_performance_data"
  end
  
  # Parse test.log 
  def run_determine_test_outcome(results_file,log_file)
    debug_puts "LTP::run_determine_test_outcome"
    results_hash = {}
    results_arr = []
    testcase = nil
    dur = 0
    status = nil
    test_comment = " "
    test_done_result = FrameworkConstants::Result[:fail]

    res_table = @results_html_file.add_table([["Test",{:bgcolor => "green", :colspan => "2"},{:color => "red"}],["Result",{:bgcolor => "green", :colspan => "2"},{:color => "red"}],["Description",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})

    begin
    resfile = IO.readlines(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}",results_file))
    nPass = 0
    nFail = 0
    resfile.each {|line|
      if ((/#/).match(line))
      
      else 
        results_arr = line.split(":")
        testcase = results_arr[0].strip
        status = results_arr[1].strip
        if(status == "failure")
          log = ''
          desc =''
          logfile = File.new(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}",log_file))
          while(log = logfile.gets)
            if ( (/#{testcase}\s+\d+\s+(TFAIL|TBROK)/).match(log) == nil) 
            else
              desc += log + '\n'
            end
          end
          test_done_result = FrameworkConstants::Result[:fail]
          test_comment += "#{testcase} failed \n"
          nFail += 1    
          logfile.close
        else 
          test_done_result = FrameworkConstants::Result[:pass]
          desc = "Test Pass"
          nPass += 1
        end
        results_hash[testcase] = [status,desc]
        @results_html_file.add_row_to_table(res_table,[[testcase,{:colspan => "2"}],[status,{:colspan => "2"}],[desc,{:colspan => "2"}]])
      end
      }
   #   IO.close(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}",results_file))
    rescue => err
      raise "Exception: #{err}"
    end

    resfile = File.new(File.join("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}",results_file))
    test_comment += "\n Results file #{(File.path(resfile)).gsub("/","\\")} \n"
    if((nPass + nFail) == 0)
      test_comment += "#{nPass} Tests Passed \n #{nFail} Tests Failed \n 0% Success"
    else
      test_comment += "#{nPass} Tests Passed \n #{nFail} Tests Failed \n #{((nPass.to_f/(nPass+nFail))*100).round}% Success"
    end
    [test_done_result, test_comment]
  end
  
  # Write test result and performance data to results database (either xml or msacess file)
  def run_save_results(results_file,log_file)
    debug_puts "LTP::run_save_results"
    result,comment = run_determine_test_outcome(results_file,log_file)
    set_result(result,comment)
  end
 
  private
  
 
 #takes initial source, final dest and filename
  def test_copy(params)
    src = "#{params['src_dir']}\\#{params['filename']}"
    dst_path = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}\\#{params['dst_dir']}\\#{params['filename']}"
#    @equipment['server1'].send_sudo_cmd("chmod 777 #{@equipment['dut1'].nfs_root_path}\/#{params['dst_dir']}",@equipment['server1'].prompt)
#    debug_puts src, dst_path
    BuildClient.copy(src, dst_path)     
  end
  
  def log_copy(params)
    src = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}\\#{params['src_dir']}\\#{params['filename']}"
    dst_path = "#{params['dst_dir']}\\#{params['filename']}"
   # debug_puts src, dst_path
    BuildClient.copy(src, dst_path)   
  end
  
  def cleanup
    result = FrameworkConstants::Result[:fail] 
    comment = "DUT timed out"
    set_result(result,comment)
  end
  
def debug_puts(message)
  if @show_debug_messages == true
    puts(message)
  end
end 