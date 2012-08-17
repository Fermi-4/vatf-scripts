require File.dirname(__FILE__)+'/../lib/plot'

include TestPlots

module StarterwareDefault
  
  def setup
    # Install application binaries
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
    install_package()
  end

  def run
    apps=get_apps_list(@test_params.params_chan.apps_subdir[0])
    res_table=create_subtests_results_table
    tests, failures, skips= run_apps(apps, res_table)
    if failures > 0
      set_result(FrameworkConstants::Result[:fail], "#{failures} tests failed out of #{tests} tests.")
    elsif skips > 0
      set_result(FrameworkConstants::Result[:fail], "#{skips} tests skipped out of #{tests} tests.")  
    else
      set_result(FrameworkConstants::Result[:pass], "All #{tests} tests Passed.")
    end
  end

  def run_apps(apps, res_table)
    tests=0
    failures=0
    skips=0

    apps.each {|app|
      puts "Starting test with #{app}"
      @equipment['dut1'].log_info("\n=============================================================================\nStarting test with: #{app}\n=============================================================================")
      result=[]
      tests+=1
      begin
        # Boot DUT with desired app
        load_app(app)
        # Check app is working
        app_result, app_fail_msg = check_app(app)
        if app_result == 0
          @equipment['dut1'].log_info("RESULT for: #{app}: PASSED")
          result = [app, 'PASSED', 'Expected responses received']

        else
          failures+=1
          @equipment['dut1'].log_info("RESULT for: #{app}: FAILED")
          result = [app, 'FAILED', app_fail_msg]
          
        end
      rescue Exception => e
        skips+=1
        @equipment['dut1'].log_info("RESULT for: #{app}: SKIP")
        result = [app, 'SKIP', e.to_s]
      end
      
      # Save subtest result
      add_subtest_result(res_table, result)
    }

    [tests, failures, skips]
  end

  def load_app(app)
    params= {'primary_bootloader'   => @test_params.primary_bootloader,
             'secondary_bootloader' => File.join(@apps_dir,app),
             'boot_device'          => @test_params.var_boot_device,
             'server'               => @equipment['server1'],
             'power_handler'        => @power_handler,
             'staf_service_name'    => @test_params.staf_service_name.to_s
            }
    @equipment['dut1'].boot(params)
    sleep 3
  end

  def check_app(app)
    @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
    cmds_result=[0, '']
    @test_params.params_chan.commands.each {|cmd|
      send=cmd.split('::')[0]
      expect=cmd.split('::')[1].to_s != '' ? /#{cmd.split('::')[1]}/ : /\|RESULT\|PASS\|/
      timeout= cmd.split('::')[2] ? cmd.split('::')[2].to_i : 10         # default timeout is 10 secs 
      @equipment['dut1'].send_cmd(send+"\r\n", expect, timeout, false)   # last false param tells driver not to expect cmd echo
      if @equipment['dut1'].timeout?
        cmds_result=[1, "Command:#{send} did not return expected text:#{expect.to_s}"]
        break
      end
    }
    @equipment['dut1'].disconnect('serial')
    cmds_result
  end

  

  def clean
  end

  def install_package
    raise "apps package was not defined. Check your build description" if !@test_params.instance_variable_defined?(:@apps)
    @apps_dir = File.join(@linux_temp_folder, get_checksum)
    if !File.exists? @apps_dir
      `mkdir -p #{@apps_dir}`
      `cp -f #{@test_params.apps} #{@apps_dir}`
      `cd #{@apps_dir}; unzip #{File.basename @test_params.apps}`    
    end
    rescue Exception => e
      raise "Error installing apps\n"+e.to_s+"\n"+e.backtrace.to_s
  end

  def get_checksum
    if @test_params.apps.match(/_md5_([\da-f]+)/)
      return $1
    else
      return `md5sum #{@test_params.apps} | cut -d' ' -f 1 | tr -d '\n'`
    end
  end

  def get_apps_list(name)
    Dir.chdir @apps_dir
    apps = Dir.glob "**/#{name}/*"
    raise "#{name} directory was not included in apps package" if apps.empty?
    apps
  end

  def create_subtests_results_table
    table_title = Array.new()
    table_title << ['Test Case', {:width => "60%"}]
    table_title << ['Result', {:width => "10%"}]
    table_title << ['Notes', {:width => "30%"}]
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Sub-Tests Results",{:bgcolor => "336666", :colspan => table_title.length},{:color => "white"}]],{:border => "1",:width=>"80%"})
    table_title = table_title
    @results_html_file.add_row_to_table(res_table,table_title)
    res_table
  end

  def add_subtest_result(table,result)
    result_color = case result[1]
    when /PASSED/i
      "#00FF00"
    when /FAILED/i
      "#FF0000"
    when /SKIP/i
      "#FFFF00"
    end
    @results_html_file.add_row_to_table(table, [result[0], [result[1], {:bgcolor => result_color}], result[2]])
  end

end
