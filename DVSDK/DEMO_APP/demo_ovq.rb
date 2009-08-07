=begin
This script can be used to control the Q-Master from the command line
=end

require '/gtsystst_tp/VATF/test_equipment/q_master_dll'
require 'optparse'
require 'ostruct'

#Defining the test files that can be used
DEMO_TEST_FILES = {
    1 => "football_704x480_420p_150frames_30fps.avi",
    2 => "sheilds_720x480_420p_252frames_30fps.avi",
}

#Defining the test types that can be performed
DEMO_TEST_TYPES = {
    0 => "calibrate",
    1 => "composite_out_to_composite_in_test",
    2 => "file_to_composite_in_test",
    3 => "file_to_file_test"
}

#Q-Master information class only value needed in the ip address of the Q-Master
class QMasterInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.0.0.20'
  end
end

#Command Line parse class
class DemoCmdLineParser
    #
    # Return a structure describing the options.
    #
    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      test_files_err = "Unsupported ref file for demo_ovq script check -r option, valid values are\n"
	  test_files_help_string = ""
	  DEMO_TEST_FILES.each {|key, val| test_files_help_string+="#{key} = #{val}\n" }
	  test_files_err+test_files_help_string
	  test_type_err = "Unsupported test type for demo_ovq script check -t option , valid values are\n"
	  test_type_help_string = ""
	  DEMO_TEST_TYPES.each {|key, val| test_type_help_string+="#{key} = #{val}\n" }
	  test_type_err+test_type_help_string
      options = OpenStruct.new
      options.ref_file = 0
      options.test_type = 0
      options.standard = 0
	  options.resolution = nil
	  options.result_file = nil
	  options.iterations = 1

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: demo_ovq -f ref_file_number -t test_type -s standard [-r resolution]"
        
        opts.separator " "
        opts.separator "Specific options:"
        
        opts.on("-t test_type_number","=MANDATORY","Number of the type of test that will be run:\n"+test_type_help_string) do |t_type|
          options.test_type = t_type.strip.to_i
          if !DEMO_TEST_TYPES[options.test_type]
              raise test_type_err
          end
        end
        
        opts.on("-f ref_file_number","=MANDATORY","Reference File number:\n"+test_files_help_string) do |r_file|
          options.ref_file = r_file.strip.to_i
          if !DEMO_TEST_FILES[options.ref_file]
              raise test_type_err
          end
        end
        
        opts.on("-s standard","=MANDATORY","standard 1 = ntsc, !1 = pal") do |std|
          options.standard = std.strip.to_i
        end
		
		opts.on("-r resolution", "=OPTIONAL", "resolution, format: WIDTHxHEIGHT, i.e. 704x480") do |res|
		  options.resolution = res.strip
		end
		
		opts.on("-l results_file", "=OPTIONAL", "file path where the test results are stored, format: string containing file path, i.e. C:/res_file.txt") do |res_file|
		  options.result_file = res_file.strip
		end
		
		opts.on("-i iterations", "=OPTIONAL", "iterations, format: integer, i.e. 4") do |iterations|
		  options.iterations = iterations.strip.to_i
		end
        
        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
     end   
     opts.parse!(args)
     options
    end
end

def run_test(options)
    #Instatiating a Q-Master driver object
	video_tester = TestEquipment::QMasterDriver.new(QMasterInfo.new, "C:/qmaster_log.txt")
    1.upto(options.iterations) do |iter|
	#Running quality test
		puts "Starting Q-Master test iteration " + iter.to_s + " on " + Time.now.to_s
		if options.test_type == 0
			puts "++++++++++++++++++++++++++ Calibrating Q-Master +++++++++++++++++++++++++++++++++++"
		else
		    puts "++++++++++++++++++++++++++ #{DEMO_TEST_TYPES[options.test_type]} for #{DEMO_TEST_FILES[options.ref_file]} +++++++++++++++++++++++++++++++++++"
		end
		res = case options.test_type
				when 0
				    raise "User must enter resolution to calibrate for (-r command line parameter)" if !options.resolution
					video_tester.send(DEMO_TEST_TYPES[options.test_type],options.resolution, options.standard != 1)
				when 3
					
					video_tester.send(DEMO_TEST_TYPES[options.test_type],DEMO_TEST_FILES[options.ref_file],"demo_test_"+DEMO_TEST_FILES[options.ref_file],false)
				else
					video_tester.send(DEMO_TEST_TYPES[options.test_type],DEMO_TEST_FILES[options.ref_file],"demo_test_"+DEMO_TEST_FILES[options.ref_file],options.standard != 1)
					video_tester.wait_for_analog_test_ack(120000)			
				end
	#Printing the test results
		if options.test_type != 0
		    if res == 0 
			    puts "Mean Scores"
			    puts "MOS = "+video_tester.get_mos_score.to_s
			    puts "Blocking = "+video_tester.get_blocking_score.to_s
			    puts "Blurring = "+video_tester.get_blurring_score.to_s	
			    puts "Frame Lost Count = "+video_tester.get_frame_lost_count.to_s
			    puts "Jerkiness = "+video_tester.get_jerkiness_score.to_s
			    puts "Level = "+video_tester.get_level_score.to_s
			    puts "PSNR = "+video_tester.get_psnr_score.to_s
				if options.result_file
					dat_file = File.new(options.result_file,'a')
					dat_file.write(DEMO_TEST_TYPES[options.test_type]+","+DEMO_TEST_FILES[options.ref_file]+","+video_tester.get_mos_score.to_s+","+video_tester.get_blocking_score.to_s+","+video_tester.get_blurring_score.to_s+","+video_tester.get_frame_lost_count.to_s+","+video_tester.get_jerkiness_score.to_s+","+video_tester.get_level_score.to_s+","+video_tester.get_psnr_score.to_s+"\n")
					dat_file.close
				end
		    else
		       puts "Q_master was unable to score the clip"
			   video_tester.abort_test
		    end
		end
	end
	puts "Q-Master Ended on " + Time.now.to_s
	video_tester.stop_logger
end

#Running a test
options = DemoCmdLineParser.parse(ARGV)
run_test(options)