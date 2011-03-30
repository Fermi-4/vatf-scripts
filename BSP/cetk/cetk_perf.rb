require File.dirname(__FILE__)+'/../default_test'
require 'rexml/document'
include REXML
require 'iconv'
include WinceTestScript
# Collect output from standard output, standard error and serial port in test.log
#attr_reader :serial_port_data    # Holds last data read from serial port
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end


def run_collect_performance_data
  puts "\n cetk_perf_test::run_collect_performance_data" 
  log_files = get_dir_files({'src_dir'=>'\Release','dst_dir'=>@wince_temp_folder,'binary'=>true} )
  begin
  log_files.each {|log_file|
    if (File.extname(log_file) == '.LOG')
	puts "this LOG is LOG\n"
    puts "#{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_PERFTOCSV_APP)} #{log_file} #{File.basename(log_file)}\.csv #{log_file}\.csv"
    if system("#{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_PERFTOCSV_APP)} #{log_file} #{log_file}\.csv") then
	  csv_file = File.read("#{log_file}\.csv")
	  log_file = File.join(@wince_temp_folder, "test_#{@test_id}\.csv")
	  puts "LOG_FILE is #{log_file}\n"
      file = File.new(log_file,"w")
      file.write(csv_file)
      file.close
      puts "after convert log to csv. writing to html"
      res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"20%"})
      File.open("#{log_file}").each {|line|
        # puts 'line: '+line
        #if !/,=(.*?),/.match(line)
        if !/,=\s*([0-9\.\/]+)/.match(line)
          @results_html_file.add_row_to_table( res_table, line.split(',') )
          next
        end
        m = line.scan(/,=\s*([0-9\.\/]+)/)
        puts m
        m.each {|data|
          data = data[0]
          line = line.gsub(/=\s*#{data.to_s}/,"#{eval data.to_s}")
        } 
        puts line
        @results_html_file.add_row_to_table( res_table, line.split(',') )
	}
	end
	  
	elsif (File.extname(log_file) == '.xml')  
   	  xml_file = File.read(log_file)
      conv = Iconv.new("UTF-8", "UTF-16")
      utf8_data = conv.iconv(xml_file)
	  utf8_data.insert(0,"\xEF\xBB\xBF")
	  utf8_data.sub!("\"1.0\"","\"1.0\"  encoding\=\"UTF-8\"")
	  log_file = File.join(@wince_temp_folder, "test_#{@test_id}\.xml")
      file = File.new(log_file,"w")
      file.write(utf8_data)
      file.close
	  perfdata = parse_xml_data(log_file)
	  puts "PerfData from collect_performance_data is #{perfdata}\n"
	end 

  if (log_file)
        log_file_path = upload_file(log_file)
	    puts "Log file path is #{log_file_path}\n"
	 # add_log_to_html(log_file)
     @results_html_file.add_paragraph("Click here for Performance Log",nil,nil,log_file_path[1])
  end 
  if perfdata
	return perfdata
	end
  }
  rescue Exception => e
    clean
    #clean_delete_log_files
    raise
  end
 end


def run_determine_test_outcome
  puts "\n cetk_test::run_determine_test_outcome"
  result, comment = [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
  File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line| 
    if line =~ /\*\*\*\s*passed:\s+1/i then
      puts "-----------test passed---------"
      result = [FrameworkConstants::Result[:pass], "This test pass.", run_collect_performance_data]
	  puts "result is #{result}\n"
    end
  }
  return result

end

def parse_xml_data(log_file)
    result = ""
	perfdata = []
     xmldoc = REXML::Document.new(File.open(log_file,'r'))
     res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"20%"})
     scenario_instance = XPath.match(xmldoc, "//ScenarioInstance")
     scenario_instance.each do |instance|
     scenario = XPath.first(instance,"Scenario")
     scenario_name = scenario.attributes.get_attribute("Name")
	 session_namespace = XPath.first(instance,"SessionNamespace")
	 session_namespace = XPath.first(session_namespace,"SessionNamespace")
	 statistic = XPath.first(session_namespace,"Statistic") 
	 duration = XPath.first(session_namespace,"Duration")
     aux_data = XPath.match(session_namespace,"//AuxData")
	 if (!scenario_name.to_s.include?("Throughput"))
	  return
	 end
     @results_html_file.add_row_to_table( res_table,["Test_Type",scenario_name])
     #statistic = XPath.first(instance,"//Statistic") 
	 #puts "Statistic is #{statistic}\n"
     #statistic_array = XPath.match(instance,"//Statistic")
	 #puts "Statistic_array is #{statistic_array}\n"
     #duration = XPath.first(instance,"//Duration")
     #aux_data = XPath.match(instance,"//AuxData")
	 result = {}
     result_duration = {}
	if (statistic)	   
		statistic.attributes.each {		 
		|attr| result[attr[0]] = attr[1]}
	    @results_html_file.add_row_to_table( res_table,["Statistics_Data",result])		
	    end			
	if (duration)
         duration.attributes.each {|attr| result_duration[attr[0]] = attr[1]}
	     @results_html_file.add_row_to_table( res_table,["Duration_Data",result_duration])
	   end
	   aux_text = ''
	if (aux_data)
	    case aux_data[0].text.to_s
		 when "SDMemory"
		  aux_text = "SD"
		 when "SDHCMemory"
		  aux_text = "SDHC"
		 when "MMC"
		  aux_text = "MMC"
		 when "MSFlash","NandFlashDisk"
		  aux_text = "NAND"
		 when "USBHDProfile"
		  if (@test_params.params_chan.cmdline[0].include?("EHCI"))
		  aux_text = "USB_EHCI"
		  else
		  aux_text = "USB_OTG"
		  end
		 else
		  aux_text = "RAM"
		end
	  end
	  scenario_name = scenario_name.to_s.chomp
	  scenario_name.to_s.gsub!(/; /,' ')
	  scenario_name.to_s.gsub!(/['('') '' ']/,'_').chop!
	  puts "Scenario name is #{scenario_name}\n"
	  clean_name = scenario_name.gsub('Throughput_','')
	  perf_name = clean_name.to_s.gsub('BufferSize_','')
	  puts "Perf name is #{perf_name} and #{result["ChangeAverage"]}\n"
	  perf_value = Float(result["ChangeAverage"])/1048576
	  perfdata<<{'name'=>perf_name,'value'=>perf_value,'units'=>'Mbytes/s'} 
end
return perfdata
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
  @equipment['dut1'].send_cmd("del \*\.xml",@equipment['dut1'].prompt) 
end

 def transfer_files(libs_var, libs_root)
	cetk_perf_files = {'perflog.dll'=>{'7.0'=>["perflog.dll","ceperf.dll","perfscenario.dll","btsperflog.dll","qa.dll","qak.dll","mtu.dll","wttlog.dll"]}}
	os_version=get_os_version.to_s
	src_dir = @test_params.instance_variable_get(libs_root)
  if @test_params.params_chan.instance_variable_defined?(libs_var) && @test_params.instance_variable_defined?(libs_root) #and false  ###### TODO TODO MUST REMOVE 'and false', Added to work around filesystem storage limit error
	if (os_version!='6.0_R3')        
         @test_params.params_chan.instance_variable_get(libs_var).each {|lib|	
		 if !cetk_perf_files[lib]
           put_file({'filename' => lib, 'src_dir' => src_dir, 'binary' => true})
		 else
		   new_libs = ''
		   new_libs = cetk_perf_files[lib][os_version]
		   new_libs.each{|new_lib|
		   put_file({'filename' => new_lib, 'src_dir' => src_dir, 'binary' => true})
		   }
		 end
		}
	else
      @test_params.params_chan.instance_variable_get(libs_var).each {|lib|
        put_file({'filename' => lib, 'src_dir' => src_dir, 'binary' => true})		
      }
    end
  end
 end
