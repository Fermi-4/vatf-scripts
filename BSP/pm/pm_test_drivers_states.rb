require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

  
 def run_determine_test_outcome
  puts "\n cetk_test::run_determine_test_outcome"
  states = Array.new
  expected_states = Array.new
  result, comment = [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
  File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line| 
	if line.include? "GetDevicePower" then
	states << line.scan(/[A-Za-z0-9:,]+\('#{@test_params.params_chan.ipname[0]}:', 0x1\)\s[A-Za-z:,\s]+([0-4])/)[0][0].to_i 
	end 
  }

  #expected_states = [0,1,2,3,4]
  expected_states = @test_params.params_chan.states.collect{|n| states.include?(n)}
  read_states     = expected_states.collect{|n| states.include?(n)}
  if expected_states == read_states then 
      puts "-----------test passed---------"
      result, comment = [FrameworkConstants::Result[:pass], "This test pass."]
  else 
    puts "-----------test failed---------"
    result, comment = [FrameworkConstants::Result[:fail], "This test pass."]
  
  end
  
  return result, comment

end

 # Generate WinCE shell script to be executed at DUT.
  # By default this function only replaces the @test_params references in the shell script template and creates test.bat  
  def run_generate_script
    puts "\n WinceTestScript::run_generate_script"
    #FileUtils.mkdir_p SiteInfo::WINCE_TEMP_FOLDER
    out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
    @test_params.params_chan.states.each{|s| 
	out_file.puts('\windows\pmsetd ' + @test_params.params_chan.ipname[0] + ': ' + s + ' ' + @test_params.params_chan.index[0])
	out_file.puts('\windows\pmgetd ' + @test_params.params_chan.ipname[0] + ': ' + @test_params.params_chan.index[0])
	}
    out_file.close
  end

  
  