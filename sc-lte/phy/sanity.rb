# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/lte_test_module'
include SCLTETestScript 
  
def setup
  super
end

def run

  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  testcase_dir = "#{@lte_test_dir}/artifacts/test/phy/testcases/#{@group}/#{@testcase}"
  local_logs = "#{testcase_dir}/output"
  power_port = @equipment['dut1'].power_port
  iteration = Time.now
  @iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
  FileUtils.mkdir_p "#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}" if !Dir.exists?("#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}")
  logs_dir = "#{SiteInfo::SCLTE_LOGS_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}"
  
  @equipment['server1'].send_cmd("cd #{testcase_dir} ; make #{@targetFlag}",/Finished All Tests/,450)
  if (@equipment['server1'].timeout?)
    raise "make #{@targetFlag} failed"
  end
  sleep 30
  @equipment['server1'].send_cmd("cp #{local_logs}/* #{logs_dir}",@equipment['server1'].prompt,60)
  # @equipment['server1'].send_cmd("rm #{local_logs}/*") 
  logfile = "#{logs_dir}/_log.txt"
  test_done_result, comment = parse_results(logfile)
  set_result(test_done_result,comment)
  
end

def parse_results(logfile)
    status = nil
    test_comment = " "
    test_done_result = FrameworkConstants::Result[:fail]
    res_table = @results_html_file.add_table([["Testcase",{:bgcolor => "green", :colspan => "2"},{:color => "red"}], ["Config",{:bgcolor => "green", :colspan => "2"},{:color => "red"}], ["Result",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]])

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
    if (testresult.match(/PASSED|FAILED/))
      sep = "\\"
      test_comment += "\n Logs at #{File.dirname(logfile).gsub("/mnt/gtsnowball/","\\\\\\gtsnowball\\System_Test\\").gsub(/\\|\//,sep)}"
    end

    [test_done_result, test_comment]
  end


def clean

end
