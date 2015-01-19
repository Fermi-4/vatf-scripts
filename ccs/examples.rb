require File.dirname(__FILE__)+'/default_mcusdk'
require File.dirname(__FILE__)+'/usbMux'
require File.dirname(__FILE__)+'/script'

require 'rubygems'
require 'json'

def run 
    board = autoSelectBoard()

    # Search for tests in the specified sub directory
    if (@test_params.params_chan.instance_variable_defined?(:@subdirectory))
        subdirectory = @test_params.params_chan.instance_variable_get(:@subdirectory)
        @equipment['dut1'].log_info("Searching for #{subdirectory} tests.")
        apps = get_apps_list(subdirectory[0])

        # Function call from "default_mcusdk" script to create the results table
        res_table = create_subtests_results_table()
        @equipment['dut1'].log_info("Running tests in \"#{subdirectory[0]}/")
        tests, failures = run_apps(apps, res_table, board)

        if failures > 0 || tests == 0
            set_result(FrameworkConstants::Result[:fail], "#{failures} tests failed out of #{tests} tests.")
        else
            set_result(FrameworkConstants::Result[:pass], "All #{tests} tests Passed.")
        end

    else
        set_result(FrameworkConstants::Result[:fail], "Tests need to be placed into a subdirectory.\n" +
                                                      "Check to see if you defined a 'subdirectory=value " +
                                                      "in the testcase or check if tests exist in the " +
                                                      "specified 'subdirectory'.")
    end

    autoDeselectBoard()
end

# Function to run the actual tests
def run_apps(apps, res_table, board = nil)
    tests = 0
    failures = 0
    targetApps = ""

    script = Script.new(@test_params, @equipment)
    script.addArg("--cio=#{@equipment['dut1'].target.ccs.cioFile()}")

    # If the bench file defines additional parameter to be passed to testlink
    # scripts, then pass them as well
    if (@equipment['dut1'].params.key?('benchArgs'))
        benchArgs = ""
        @equipment['dut1'].params['benchArgs'].each { |k,v|
            benchArgs.concat("#{k}=#{v}~")
        }
        script.addArg("--bench=\"#{benchArgs[0..-2]}\"")
    end

    # Check if need to test a specific target application, otherwise filter
    # on applications with a 'board' prefix. If no board is specified, it will
    # find test all applications.
    if (@test_params.params_chan.instance_variable_defined?(:@targetapp))
        str = @test_params.params_chan.instance_variable_get(:@targetapp)[0]
        #str = '/tcpEcho(IPv6)?\.out/'
        #str = 'tcpEcho*'
        if str =~ /\/.*\//
            targetApps = /#{str[1..-2]}/
        else
            targetApps = str
        end
    else
        targetApps = board
    end

    # for each app in apps
    apps.each { |app|
        goldPass = false
        scriptPass = false
        result = []

        # Filter subDirectory with tests for board
        if (File.basename(app).match(targetApps))
            puts "Starting test: #{app}"
            tests += 1

            begin
            @equipment['dut1'].log_info("Loading and run application ...")
            if script.exists()
                puts "Loading app..."
                thr = load_program(File.join(@apps_dir,app), get_autotest_env('ccsConfig'), 150)
                @equipment['dut1'].log_info("Loading program started with #{thr.status}.")

                puts "Executing host script..."
                @equipment['dut1'].log_info("Executing host script ...")
                script.execute(150)

                puts "Waiting for target thread to join..."
                @equipment['dut1'].log_info("Waiting for target thread to join...")
                thr.join()
            else
                thr = load_program(File.join(@apps_dir,app), get_autotest_env('ccsConfig'), 150)
                thr.join()
            end
            rescue Exception => e
                puts "Exception test #{app} with #{e}"
                @equipment['dut1'].log_info("Test #{app} had an exception #{e}")
            end

            # C I/O outputfile, golden file, compare results file name
            outFile, gldFile, resultsFile = get_smart_compare_files(app)
            puts "outfile: #{outFile}; gldFile: #{gldFile}, resultsFile: #{resultsFile}"
            @equipment['dut1'].log_info("outfile: #{outFile}\ngldFile: #{gldFile}\nresultsFile: #{resultsFile}")

            # If a gold file was found, run smart comparison
            if (!gldFile.nil? && (runTestComparison(outFile, gldFile, resultsFile)  == 'PASS'))
                @equipment['dut1'].log_info("Using gold file: #{gldFile}")
                goldPass = true
            end

            # If a script exists, didn't abort, and printed 'PASS', then the
            # script passed 
            if (script.exists() && (script.status == 0) && script.stdout.match(/.*PASS.*/))
                scriptPass = true
            end

            if ((!gldFile.nil? && goldPass &&  script.exists() && scriptPass) || #both gold and script passed
                (!gldFile.nil? && goldPass && !script.exists()              ) || #gold passed, but no script
                ( gldFile.nil?             &&  script.exists() && scriptPass))   #no gold, but script passed

                result = [app, 'PASSED', 'Test passed']
                puts "Test #{app} passed.\n\n"
                @equipment['dut1'].log_info("Test #{app} passed.\n\n")
            else
                failures += 1
                retString = "Test failed\n ======== Loadti script ========\n" +
                            @equipment['dut1'].target.ccs.response() +
                            "Test failed\n ======== C I/O ========\n" +
                            @equipment['dut1'].target.ccs.cio()
                
                if (!gldFile.nil?)
                    retString += "\n======== Gold file compare output ========\n" +
                                 `cat #{resultsFile}` + "\n"
                end

                if script.exists()
                    retString += "\n======== Script STDOUT ========\n" +
                                  script.stdout() + 
                                 "\n======== Script STDERR ========\n" +
                                  script.stderr() +
                                 "\n======== Script args ========\n" +
                                  script.hostScriptArgs.join(" ").to_s
                end

                result = [app, 'FAILED', retString]
                puts "Test #{app} failed.\n#{retString}\n"
                @equipment['dut1'].log_info("Test #{app} failed.\n\n")
            end

            add_subtest_result(res_table, result)
        else
            puts "Skipping test: #{app}"
        end

    }
    [tests, failures]
end

# Load the actual application onto the target
def load_program(app, config, timeout = 100, async = false)
  # Enable this if you have CCS Debugger logs enabled
  #`rm -f /home/a0273433/ccsDebugLog.log`
  puts "Starting new thread to load #{app}"
  `cat /dev/null > #{@equipment['dut1'].target.ccs.cioFile()}` 
  # Let the script time out instead of the thread. Otherwise, this will cause
  # some issues when using MSP430F5529
  thread = Thread.new() {
      @equipment['dut1'].run(app, timeout + 30, {
        'no_profile' => 'yes',
        'config' => config,
        "timeout" => timeout*1000,
       #'verbose' => 'yes',
        'reset' => 'yes'
      })
  }
  return thread
end

# Helper function to get the needed files for the smart compare script
def get_smart_compare_files(app)
    out = @equipment['dut1'].target.ccs.cioFile()
    gold = nil
    result = "#{@equipment['dut1'].tempdir}/scResult"
    test = File.basename(app, ".*")
    json_files = get_golden_json()

    if json_files.empty?
        puts "No json file found in the golden directory, so attempt to find the .k file"
        gold = Dir.glob(File.join(@apps_dir, "**", "golden", "#{test}.k"))[0]
    else
        # Find the needed file to compare the results with
        json_files.each { |json|
            begin
            jfile = File.open(json, "r").read()
            parsedJFile = JSON.parse(jfile)

            # Check if the json file has a golden file defined
            if (parsedJFile.has_key?("tests") && parsedJFile["tests"].has_key?(test) && parsedJFile["tests"][test].has_key?("golden"))
                # Found .k file entry
                kfile = parsedJFile["tests"][test]["golden"]
                if (File.exists?(File.join(File.dirname(json), "#{kfile}")))
                    gold = File.join(File.dirname(json), "#{kfile}")
                    break
                else
                    puts "Can't find golden file #{kfile} for test #{test} specified in #{File.basename(json)}"
                end

            # No .k entry in json file, checking if the .k file of the test exists in the golden dir
            else
                # Check if .k file exists in the same directory as the json file
                if (File.exists?(File.join(File.dirname(json), "#{test}.k")))
                    puts "No \".k\" entry found in #{File.basename(json)}; using #{test}.k"
                    gold = File.join(File.dirname(json), "#{test}.k")
                    break
                else
                    puts "No golden file found"
                end
            end

            rescue Exception => e
                puts parsedJFile.inspect
                puts "Error reading the JSON file #{e.to_s}"
                @equipment['dut1'].log_info("Error reading the JSON file #{e.to_s}")
            end
        }
    end

    # return C I/O outputfile, golden file, compare results file name
    return [out, gold, result]

end

def runTestComparison(outFile, goldenFile, resultsFile)

    if (goldenFile == nil)
        `echo "No golden file found" > #{resultsFile}`
        return 'FAIL'
    end

    xdcPath = (@equipment['dut1'].params.key?('xdcRoot')) ? @equipment['dut1'].params['xdcRoot'] : '/home/a0273433/ti/xdctools_3_25_04_88/'

    `export XDCPATH=#{File.dirname(__FILE__)}; \
         #{xdcPath}/xs -c #{File.join(File.dirname(__FILE__), "mainCompare.xs")} #{outFile} #{goldenFile} #{resultsFile}`

    if (File.zero?(resultsFile))
        return 'PASS'
    else
        return 'FAIL'
    end
end
