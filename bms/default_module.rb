require File.dirname(__FILE__)+'/../lib/plot'
require 'fileutils'

include TestPlots

module BmsDefault
  
  def setup
    # Check inputs
    check_test_inputs
    # Install Test Scripts 
    if OsFunctions::is_windows?
      @temp_data_folder = "#{SiteInfo::WINCE_DATA_FOLDER}/../bms/#{@test_params.staf_service_name.to_s}"
    else
      @temp_data_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
    end
    install_package()
  end

  def run
    testcase_dir= "#{@bms_scripts_dir}/#{@test_params.params_chan.testcase_folder[0]}"
    start_time = Time.now
    if OsFunctions::is_windows?
      @equipment['dut1'].send_cmd("cd #{testcase_dir} && copy /Y #{@test_params.firmware} test.out && copy /Y #{@test_params.bcfg} test.bcfg",
                                   @equipment['dut1'].prompt,
                                   10)
    
      @equipment['dut1'].send_cmd("cd #{testcase_dir} && #{@equipment['dut1'].params['fgsim_home']}/FgSim.exe test.out test.bcfg test.py",
                                   @equipment['dut1'].prompt,
                                   @test_params.params_chan.duration[0].to_i)

    else
      @equipment['dut1'].send_cmd("cd #{testcase_dir}; cp -f #{@test_params.firmware} test.out; cp -f #{@test_params.bcfg} test.bcfg",
                                   @equipment['dut1'].prompt,
                                   10)
      @equipment['dut1'].send_cmd("cd #{testcase_dir}; wine #{@equipment['dut1'].params['fgsim_home']}/FgSim.exe test.out test.bcfg test.py",
                                   @equipment['dut1'].prompt,
                                   @test_params.params_chan.duration[0].to_i)
    end
    end_time = Time.now
    result, comment, perf_data = process_result_file(testcase_dir, start_time)
    set_result(result, comment.to_s, perf_data)
  end

  def clean
  end

  def check_test_inputs
    raise "bms_scripts is not defined. Check your build description" if !@test_params.instance_variable_defined?(:@var_bms_scripts_root) && !@test_params.instance_variable_defined?(:@bms_scripts)
    raise "firmware is not defined. Check your build description" if !@test_params.firmware
    raise "bcfg file is not defined. Check your build description" if !@test_params.bcfg
    raise "FgSim home directory is not defined. Check you bench file" if !@equipment['dut1'].params.key?('fgsim_home')
  end

  def install_package
    @bms_scripts_dir = nil
    if @test_params.instance_variable_defined?(:@var_bms_scripts_root)
      @bms_scripts_dir = @test_params.var_bms_scripts_root  
      return
    end
    @bms_scripts_dir = "#{@temp_data_folder}/#{get_checksum(@test_params.bms_scripts)}" if !@bms_scripts_dir
    if !File.exists? @bms_scripts_dir
      FileUtils.mkdir_p @bms_scripts_dir
      FileUtils.cp @test_params.bms_scripts, @bms_scripts_dir
      FileUtils.cd @bms_scripts_dir
      @equipment['dut1'].send_cmd("unzip -o #{File.basename @test_params.bms_scripts} -d #{@bms_scripts_dir}", @equipment['dut1'].prompt, 60)
    end
    rescue Exception => e
      raise "Error installing bms scripts\n"+e.to_s+"\n"+e.backtrace.to_s
  end

  def get_checksum(file)
    if file.match(/_md5_([\da-f]+)/)
      return $1
    else
      if OsFunctions::is_windows?
        x=`#{SiteInfo::UTILS_FOLDER}/fciv.exe #{file}`
      else
        x=`md5sum #{file}`
      end
      return x.match(/^([\da-f]{32})\s/).captures[0]
    end
  end

  def process_result_file(test_dir, start_time)
    Dir.chdir test_dir
    results = Dir.glob "**/TestResult.log"
    if results.empty?
      Dir.chdir "#{test_dir}/.."
      results = Dir.glob "**/TestResult.log"
    end
    raise "Could not find TestResult.log file in #{test_dir}" if results.empty?
    raise "Too many TestResult.log files in #{test_dir} or #{test_dir}/../" if results.size > 1
    result_file = "#{Dir.getwd}/#{results[0]}"
    File.open(result_file) {|f|
      if start_time > f.mtime  
        raise "#{result_file} is too old. It was created before test started" 
      else
        headers = Array.new
        data = Array.new
        f.readlines.each{|l|
          if l.match(/^Result\s/)
            headers = l.split(/[\s\t]+/)
          elsif l.match(/^(Pass|Fail)\s/)
            data = l.split(/[\s\t]+/)
          end
          break if data.length > 0
        }
        if headers.length != data.length or headers[0].strip != 'Result'
          raise "#{result_file} contains invalid format"
        else
          perf_data = []
          result = data[0].downcase.strip == "pass" ? FrameworkConstants::Result[:pass] : FrameworkConstants::Result[:fail]
          headers.delete_at(0)
          data.delete_at(0)
          headers.each_index{|i|
            perf_data << {'name' => headers[i], 'value' => [data[i]], 'units' => ''}
          }
          return [result, nil, perf_data]
        end
      end
    }
  end

end
