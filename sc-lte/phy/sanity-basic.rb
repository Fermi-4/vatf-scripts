# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/lte_test_module'
include SCLTETestScript 
  
def setup
  super
end

def run

  test_done_result = FrameworkConstants::Result[:fail]
  comment = ""
  toplevel_testcase_dir = "#{@lte_test_dir}/artifacts/test/phy/testcases"
  test_result =  FrameworkConstants::Result[:fail]
  iteration = Time.now
  @iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
  test_comment = " "
  nFail = 0
  nPass = 0

  @equipment['server1'].send_cmd("cd #{toplevel_testcase_dir}",@equipment['server1'].prompt,10)
  @equipment['server1'].send_cmd("find . -name makefile",@equipment['server1'].prompt,10)
  puts  "Response: \n #{@equipment['server1'].response}"
  toplevel_logs_dir = "#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}/"
  @equipment['server1'].response.lines.to_a[1..-2].join.each_line { |dir|
    @power_handler.switch_off(@power_port)
    sleep 10
    @power_handler.switch_on(@power_port)
    sleep 50
    testcase_dir = File.dirname(dir)
    @group = File.dirname(testcase_dir).sub(/^\.\//,"")
    puts "@group: #{@group}"
    @testcase = Pathname.new(testcase_dir).basename
    puts "@testcase : #{@testcase}"
    local_logs = "#{toplevel_testcase_dir}/#{@group}/#{@testcase}/output"
    FileUtils.mkdir_p "#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}/#{@group}/#{@testcase}" if !Dir.exists?("#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}/#{@group}/#{@testcase}")
    logs_dir = "#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}/#{@group}/#{@testcase}"
    @equipment['server1'].send_cmd("cd #{toplevel_testcase_dir}/#{@group}/#{@testcase}",@equipment['server1'].prompt,10)
    puts "Running make #{@targetFlag} in #{toplevel_testcase_dir}/#{@group}/#{@testcase}"
    @equipment['server1'].send_cmd("make #{@targetFlag}",/Finished All Tests/,450)
    if (@equipment['server1'].timeout?)
      test_done_result = FrameworkConstants::Result[:fail]
      comment += "make #{@targetFlag} failed for #{@group}/#{@testcase}"
      test_done_result = parse_results()
    else
      @equipment['server1'].send_cmd("cp #{local_logs}/* #{logs_dir}",@equipment['server1'].prompt,60)
      logfile = "#{logs_dir}/_log.txt"
      test_done_result = parse_results(logfile)
    end

    if (test_done_result == FrameworkConstants::Result[:fail])
      puts "Test result for #{@group}/#{@testcase} is FAIL \n"
      nFail += 1
    else
      puts "Test result for #{@group}/#{@testcase} is PASS \n"
      nPass += 1
    end
    puts "nPass: #{nPass} nFail: #{nFail}"

    }
    if (nFail == 0)
      test_result = FrameworkConstants::Result[:pass]
    end
    sep = "\\"
    comment = "#{nPass} test/s passed. #{nFail} test/s failed. Logs at #{toplevel_logs_dir.gsub("/mnt/gtsnowball/","\\\\\\gtsnowball\\System_Test\\").gsub(/\\|\//,sep)}"
    set_result(test_result,comment)
  
end

def parse_results(logfile=nil)
    status = nil
    test_done_result = FrameworkConstants::Result[:fail]
    res_table = @results_html_file.add_table([["Testcase",{:bgcolor => "green", :colspan => "2"},{:color => "red"}], ["Config",{:bgcolor => "green", :colspan => "2"},{:color => "red"}], ["Result",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]])
    if (logfile)
      logs = File.read(logfile)
      output = logs.scan(/\sEnd Test\n\sID:\s+(.*)\n\sConfig:\s+(.*)\n\sTime:\s+(.*)\n\sResult:\s+(.*)/)
      output.length.times do |test_output|
        testcase = output[test_output][0].to_s
        config = output[test_output][1].to_s
        result = output[test_output][3].to_s
        @results_html_file.add_row_to_table(res_table,[[testcase,{:colspan => "2"}],[config,{:colspan => "2"}],[result,{:colspan => "2"}]])
      end
      testresult = logs.scan(/\sFinished All Tests\n\sTime:\s+(.*)\n\sTests:\s+(.*)\n\sResult:\s+(.*)/)[0][2]
      test_done_result = (testresult.match(/PASSED/)) ? FrameworkConstants::Result[:pass] : FrameworkConstants::Result[:fail]
    else
      testcase = "#{@group}/#{@testcase}"
      config = "N/A"
      result = "TIMEOUT"
      @results_html_file.add_row_to_table(res_table,[[testcase,{:colspan => "2"}],[config,{:colspan => "2"}],[result,{:colspan => "2"}]])
    end
    test_done_result
  end


def clean

end
