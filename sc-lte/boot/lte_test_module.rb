# -*- coding: ISO-8859-1 -*-


module SCLTETestScript 
    public
    @show_debug_messages = false
    def setup
      @equipment['dut1'].set_api('linux-c6x')
      @platform = @test_params.platform.downcase
      @dss_dir = @equipment['server1'].params["dss_dir"]
      @group = @test_params.params_chan.instance_variable_defined?(:@group) ? @test_params.params_chan.instance_variable_get("@group")[0].to_s : ""
      @testcase = @test_params.params_chan.instance_variable_get("@testcase")[0].to_s if @test_params.params_chan.instance_variable_defined?(:@testcase)
      @test_case_id = @test_params.caseID
      puts "Test case = #{@testcase} ************"
      puts "Group = #{@group} ************"
      @lte_test_dir = @equipment['server1'].params["sclte_test_dir"]
      @emulator = @equipment['dut1'].id.split("_")[1]
      @power_port = @equipment['dut1'].power_port
      if ! @test_params.instance_variable_defined?(:@artifacts)
        raise "No artifacts directory specified"
      else
        artifacts = @test_params.artifacts
      end
      # Telnet to Linux server
      if @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip)
        @equipment['server1'].connect({'type'=>'telnet'})
      elsif !@equipment['server1'].target.telnet 
        raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
      end
      endianness = (@equipment['dut1'].id.split("_")[0].to_s == "bigendian") ? "be" : "le"

      case (@platform)
      when "nyquist"
        if @emulator == "xds560"
          @targetFlag = "vevmz"
        else
          raise "PHY tests not supported on #{@platform} with #{@emulator}"
        end
      else
        raise "PHY tests not supported on #{@platform}"
      end
      
      @power_handler.switch_off(@power_port)
      sleep 10
      @power_handler.switch_on(@power_port)
      sleep 50
      @equipment['server1'].send_cmd("export PATH=$PATH:#{@dss_dir}",/.*/,10)
      @equipment['server1'].send_cmd("export TEST_DATA_DIR=#{@lte_test_dir}/artifacts/test/test_data",/.*/,10)
      @equipment['server1'].send_cmd("export ENDIANNESS=#{endianness}",/.*/,10)
      @new_keys = (artifacts)? (get_keys() + artifacts) : (get_keys()) 
      if boot_required?(@old_keys, @new_keys) 
        @equipment['server1'].send_cmd("rm -rf #{@lte_test_dir}/*",@equipment['server1'].prompt,120) 
        @equipment['server1'].send_cmd("cp #{artifacts} #{@lte_test_dir}",@equipment['server1'].prompt,120)
        @equipment['server1'].send_cmd("cd #{@lte_test_dir} ; mv #{File.basename(artifacts)} artifacts.tgz ; tar -xzf artifacts.tgz",@equipment['server1'].prompt,120)
        @equipment['server1'].send_cmd("cd #{@lte_test_dir}/artifacts/output ; tar xf *.tar",@equipment['server1'].prompt,120)
        @equipment['server1'].send_cmd("cp -r #{@lte_test_dir}/artifacts/output/sc_lte_dsp/mo/phy/scripts/ #{@lte_test_dir}/artifacts/test/phy/",@equipment['server1'].prompt,120)
      end
    end

    
    def clean
    end
    
  def get_test_string(params)
    test_string = ''
    if(params == nil)
      return nil
    end
    params.each_line {|element|
    test_string += element.strip
    }
    test_string
  end
  
  def boot_required?(old_params, new_params)
    old_test_string = get_test_string(old_params)
    new_test_string = get_test_string(new_params)
    old_test_string != new_test_string
  end
  
  def get_keys
    keys = @test_params.platform.to_s
    keys
  end

end
   






