require File.dirname(__FILE__)+'/default_mcusdk'
require File.dirname(__FILE__)+'/usbMux'

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

        if failures > 0
            set_result(FrameworkConstants::Result[:fail], "#{failures} tests failed out of #{tests} tests.")
        else
            set_result(FrameworkConstants::Result[:pass], "All #{tests} tests Passed.")
        end

    else
        set_result(FrameworkConstants::Result[:fail], "No subdirectory is defined in the testcase.")
    end

    autoDeselectBoard()
end

# Function to run the actual tests
def run_apps(apps, res_table, board = nil)
    tests = 0
    failures = 0

    # for each app in apps
    apps.each { |app|
        result = []

        # Filter subDirectory with tests for board
        if ((board == nil) || (File.basename(app).match(board)))
            puts "Starting test: #{app}"
            tests += 1

            # Reset board before attempting to load the application
            autoResetBoard()

            begin
            # Load test onto the target
            @equipment['dut1'].log_info("Loading and run application ...")
            thr = load_program(File.join(@apps_dir,app), get_autotest_env('ccsConfig'), 240)
            @equipment['dut1'].log_info("Loading program thread returned #{thr.value}.")

            # C I/O outputfile, golden file, compare results file name
            outFile, gldFile, resultsFile = get_smart_compare_files(app)
            puts "outfile: #{outFile}; gldFile: #{gldFile}, resultsFile: #{resultsFile}"

            # Run test comparison
            if (runTestComparison(outFile, gldFile, resultsFile) == 'PASS')
                result = [app, 'PASSED', 'Test passed']
                puts "Test #{app} passed.\n\n"
                @equipment['dut1'].log_info("Test #{app} passed.\n\n")

            else
                failures += 1
                retString =   "======== Test failed with C I/O ========\n" +
                             @equipment['dut1'].target.ccs.cio() +
                            "\n========    Compare results     ========\n" +
                            `cat #{resultsFile}` +
                            "\n========         End Test       ========\n"
                result = [app, 'FAILED', retString]
                puts "Test #{app} failed.\n#{retString}\n"
                @equipment['dut1'].log_info("Test #{app} failed.\n\n")
            end

            rescue Exception => e
                failures += 1
                puts "Test failed due to #{e.to_s}"
                @equipment['dut1'].log_info("Test #{app} timed out: FAILED")
                result = [app, 'FAILED', e.to_s]
            end

            add_subtest_result(res_table, result)
        else
            puts "Skipping test: #{app}"
        end

    }
    [tests, failures]
end

# Load the actual application onto the target
def load_program(app, config, timeout=100)
  puts "Starting new thread to load #{app}"
  Thread.new() {
      @equipment['dut1'].run app, timeout, {'no_profile' => 'yes', 'config' => config, 'timeout' => timeout ? (timeout - 1) * 1000 : 0}
  }.join
end

# Helper function to get the needed files for the smart compare script
def get_smart_compare_files(app)

    out = @equipment['dut1'].target.ccs.cioFile()
    gold = nil
    result = "#{@equipment['dut1'].tempdir}/scResult"
    test = File.basename(app, ".*")
    json_files = get_golden_json

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
        end
    }

    # return C I/O outputfile, golden file, compare results file name
    return [out, gold, result]

end

def runTestComparison(outFile, goldenFile, resultsFile)

    if (goldenFile == nil)
        `echo "No golden file found" > #{resultsFile}`
        return 'FAIL'
    end

    `export XDCPATH=#{File.dirname(__FILE__)}; \
         /home/a0273433/ti/xdctools_3_25_04_88/xs -c #{File.join(File.dirname(__FILE__), "mainCompare.xs")} #{outFile} #{goldenFile} #{resultsFile}`

    if (File.zero?(resultsFile))
        return 'PASS'
    else
        return 'FAIL'
    end
end
