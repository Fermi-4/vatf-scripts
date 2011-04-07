require 'rexml/document'
include REXML

def setup
end 
 # Execute shell script in DUT(s) and save results.
 def run
    flag = 0
    delete_dir_file # delete all dirs and files before we start the test
    cts_test   = Thread.new(flag) {cts_start} 
    cts_driver = Thread.new(flag) {cts_driver}
    cts_test.join
    cts_driver.join
    run_save_results(run_collect_performance)
end  
 
def clean 
end

def cts_driver
  puts "CTS DRIVER RUNNING"
  #flag = 0
  counter =0
  @equipment['dut1'].connect({'type'=>'serial'})
  @equipment['dut1'].send_cmd("","#",-1)
  @equipment['dut1'].response+","
  while (flag != 1)  
   @equipment['dut1'].send_cmd("","Uncompressing",-1)
   puts "the platform is reset, waiting platform to comeup(zygote detected) then to send reconnect command"
   temp = @equipment['dut1'].response+","
   string_read =  temp.to_s 
   sleep 60
   @equipment['dut1'].send_cmd("stop adbd;sleep 1;start adbd;",@equipment['dut1'].prompt)
   counter = counter + 1 
   puts "Number of times platform reset #{counter}"
   puts "Sent CTS reconnect comand, Waiting for the next RESET ..."
   sleep 3
  end 
end 
def cts_start
   cts_cmd = @test_params.params_chan.cts_dir[0].to_s + @test_params.params_chan.cmdline[0].to_s + " " + @test_params.params_chan.test_plan[0]
   puts cts_cmd
   system(cts_cmd)
   flag = 1 
end
 

def get_new_dir
   result_file_path = Dir.entries(@test_params.params_chan.cts_res_dir[0].to_s)
   new_dir = ""
   result_file_path.each{|dir|
   if dir.include?("zip")
     new_dir =  dir.gsub(/.zip/,"")
   break
   end 
  }
   return new_dir 
end 

def delete_dir_file
   result_file_path = Dir.entries(@test_params.params_chan.cts_res_dir[0].to_s)
   result_file_path.each{|dir|
   if dir.include?("zip")
      dir_absolute = @test_params.params_chan.cts_res_dir[0].to_s + "/" + dir.gsub(/.zip/,"")
      file_absolute = @test_params.params_chan.cts_res_dir[0].to_s + "/" + dir
      FileUtils.remove_dir(dir_absolute)
      File.delete(file_absolute)
   end 
   }
   return 
end 


# The function writes performance values into perf.log. Also write all results to HTML file to be linked to each test case result.  
def run_collect_performance
   total_testcase = 0
   total_failure = 0
   percentage_pass =0
   total_pass = 0
   total_timeout =0   
   puts get_new_dir
   new_dir = @test_params.params_chan.cts_res_dir[0].to_s + "/"  + get_new_dir 
   file_name =  File.join(new_dir , "testResult.xml")
   xml_file_open  = File.new(file_name)
   @xml_doc = REXML::Document.new(xml_file_open)
   @xml_doc.elements.each {|elements| 
   elements.each {|summary|
   if summary.to_s.include? "Summary"
   failed  = summary.to_s.scan(/failed=\s*'[0-9]+'\s*/m)[0].to_s.gsub(/failed=/,'').to_s.gsub(/'/,'')
   pass    = summary.to_s.scan(/pass=\s*'[0-9]+'\s*/m)[0].to_s.gsub(/pass=/,'').gsub(/\'/,'').to_s
   timeout = summary.to_s.scan(/timeout=\s*'[0-9]+'\s*/m)[0].gsub(/timeout=/,'').to_s.gsub(/\'/,'').to_s
   total_testcase = failed.to_i + pass.to_i + timeout.to_i
   total_failure = failed.to_i + timeout.to_i
   percentage_pass =  (pass.to_i * 100) / total_testcase
   total_pass = pass.to_i
   total_timeout = timeout.to_i
   break 
   end  
   }
   }
   upload_results = upload_file(new_dir + ".zip")
   @results_html_file.add_paragraph("PLEASE CLICK ME TO DOWNLOAD THE RESULT FILE",nil, nil,upload_results[1]) 
   @results_html_file.add_paragraph("")
   res_table = @results_html_file.add_table([["CTS TEST SUMMARY",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
   @results_html_file.add_row_to_table(res_table,["Total Pass","Total Fail","Timeout", "Pass By Percentage ",  "Total Test cases"])
   @results_html_file.add_row_to_table(res_table,[total_pass,total_failure,total_timeout,percentage_pass,total_testcase])
 
  return percentage_pass 
 ensure
  #close file 
end

# The function determines test outcome for power  consumption or policy
 def run_determine_test_outcome(pass_percentage)
    if pass_percentage > 95 then
      puts "-----------test passed---------"
      #result, comment = [FrameworkConstants::Result[:pass], "This test pass."]
	  [FrameworkConstants::Result[:pass], "Test case PASS.",pass_percentage]
    else 
      puts "-----------test failed---------"
     # result, comment = [FrameworkConstants::Result[:fail], "This test failed."]
    [FrameworkConstants::Result[:fail], "Test case FAILED.",pass_percentage]	  
    end
end


# Write test result and performance data to results database (either xml or msacess file)
 def run_save_results(pass_percentage)
    puts "\n WinceTestScript::run_save_results"
    result,comment,perfdata = run_determine_test_outcome(pass_percentage)
    if perfdata
      set_result(result,comment,perfdata)
    else
      set_result(result,comment)
    end
end

