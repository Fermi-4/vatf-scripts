require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end

def run_collect_performance_data
  puts "\n cetk_test::run_collect_performance_data"
  # ftp the log file to host pc
  #sleep 5
  log_files = get_dir_files({'src_dir'=>'\Release','dst_dir'=>@wince_temp_folder} )
  
  # convert to csv
  begin
  log_files.each {|log_file|
    puts "#{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_PERFTOCSV_APP)} #{log_file} #{File.basename(log_file)}\.csv"
    if system("#{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_PERFTOCSV_APP)} #{log_file} #{log_file}\.csv") then
      puts "after convert log to csv. writing to html"
      res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"20%"})
      File.open("#{log_file}\.csv").each {|line|
        # puts 'line: '+line
        #if !/,=(.*?),/.match(line)
        if !/,=\s*([0-9\.\/]+)/.match(line)
          @results_html_file.add_row_to_table( res_table, line.split(',') )
          next
        end
        m = line.scan(/,=\s*([0-9\.\/]+)/)
        puts m
        m.each {|data|
          line = line.gsub(/=\s*#{data.to_s}/,"#{eval data.to_s}")
        }
        puts line
        @results_html_file.add_row_to_table( res_table, line.split(',') )
      }
    end
  }
  rescue Exception => e
    clean_delete_log_files
    raise
  end
end

def run_determine_test_outcome
  puts "\n cetk_test::run_determine_test_outcome"
  result, comment = [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
  File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line| 
    if line =~ /\*\*\*\s*passed:\s+1/i then
      puts "-----------test passed---------"
      result, comment = [FrameworkConstants::Result[:pass], "This test pass."]
    end
  }
  return result, comment

end

def clean
  super
  clean_delete_log_files
end

# Delete log files (if any) 
def clean_delete_log_files
  puts "\n WinceCetkPerfScript::clean_delete_log_files"
  @equipment['dut1'].send_cmd("cd \\Release",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("del \*\.LOG",@equipment['dut1'].prompt) 
end

