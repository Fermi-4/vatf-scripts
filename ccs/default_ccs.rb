require 'timeout'

module CcsTestScript

  def setup
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
    @jsAutoArgsFile    = File.join(@linux_temp_folder, 'getAutoArgs.js')
    connect()
    create_autotest_env()
    @equipment['dut1'].target.ccs.jsEnvArgsFile = @jsAutoArgsFile
    @equipment['dut1'].target.ccs.tempdir = @linux_temp_folder
  end

  def run
    set_result(FrameworkConstants::Result[:nry], "You need to implement run() method")
  end

  def clean
  end

  def get_autotest_env(param)
  x=`cat #{@jsAutoArgsFile} | grep autotestEnv.#{param}`
    y = x.match(/autotestEnv.#{param}\s*=\s*\"([\w\d\.\-\+\_\\\/]+)\"/)
  y ? y.captures[0] : nil
  end


  # Create file to pass parameters to javascript
  def create_autotest_env
  FileUtils.mkdir_p @linux_temp_folder
  out_file = File.new(@jsAutoArgsFile, 'w')
  # Create input/output pipes for IPC w/ javascript
  ["#{@linux_temp_folder}/in", "#{@linux_temp_folder}/out"].each {|name|
    `rm -f #{name};  mkfifo --mode=777 #{name}`
  }
  out_file.puts("autotestEnv = {};")
  out_file.puts("autotestEnv.inIpc = \"#{@linux_temp_folder}/in\";")
  out_file.puts("autotestEnv.outIpc = \"#{@linux_temp_folder}/out\";")
  val = @test_params.instance_variable_defined?(:@ccsConfig) ? "\"#{@test_params.ccsConfig}\"" : @equipment['dut1'].params.key?('ccsConfig') ? "\"#{@equipment['dut1'].params['ccsConfig']}\"" : "null"
  out_file.puts("autotestEnv.ccsConfig = #{val};")
  val = @test_params.instance_variable_defined?(:@gelFile) ? "\"#{@test_params.gelFile}\"" : @equipment['dut1'].params.key?('gelFile') ? "\"#{@equipment['dut1'].params['gelFile']}\"" : "null"
  out_file.puts("autotestEnv.gelFile = #{val};")
  val = @test_params.instance_variable_defined?(:@var_ccsPlatform) ? "\"#{@test_params.var_ccsPlatform}\"" : @equipment['dut1'].params.key?('ccsPlatform') ? "\"#{@equipment['dut1'].params['ccsPlatform']}\"" : "null"
  out_file.puts("autotestEnv.ccsPlatform  = #{val};")
  val = @test_params.params_control.instance_variable_defined?(:@ccsCpu) ? "\"#{@test_params.params_control.ccsCpu[0]}\"" : @equipment['dut1'].params.key?('ccsCpu') ? @equipment['dut1'].params['ccsCpu'].kind_of?(Array) ? "#{@equipment['dut1'].params['ccsCpu']}" : "\"#{@equipment['dut1'].params['ccsCpu']}\"" : "null"
  out_file.puts("autotestEnv.ccsCpu       = #{val};")
  val = @test_params.instance_variable_defined?(:@outFile) ? "\"#{@test_params.outFile}\"" : @equipment['dut1'].params.key?('outFile') ? @equipment['dut1'].params['outFile'].kind_of?(Array) ? "#{@equipment['dut1'].params['outFile']}" : "\"#{@equipment['dut1'].params['outFile']}\"" : "null"
  out_file.puts("autotestEnv.outFile = #{val};")
  param_names = @test_params.instance_variables
  param_names.each {|name|
    next if name.to_s.match(/params_control|params_chan|params_equip|ccsconfig|gelFile|ccsPlatform|outFile|image_path/i)
    next if !@test_params.instance_variable_get(name).respond_to? :[]
    val=@test_params.instance_variable_get(name)
    out_file.puts("autotestEnv.#{name.to_s.gsub(/@/,'')} = \"#{val.to_s.gsub(/\"/,"\\\"")}\";")
    #out_file.puts("autotestEnv.#{name.to_s.gsub(/@/,'')} = \"#{val}\";")
  }
  param_names = @test_params.params_chan.instance_variables
  param_names.each {|name|
    val=@test_params.params_chan.instance_variable_get(name)[0]
    out_file.puts("autotestEnv.#{name.to_s.gsub(/@/,'')} = #{val};")
  }
  param_names = @test_params.params_control.instance_variables
  param_names.each {|name|
    next if name.to_s.match(/ccscpu/i)
    val=@test_params.params_control.instance_variable_get(name)[0]
    out_file.puts("autotestEnv.#{name.to_s} = #{val};")
  }
  out_file.close
  end

  def connect
  @equipment['dut1'].connect({'type' => 'ccs'})
  if @equipment.has_key?('server1')
    if @equipment['server1'].kind_of? LinuxLocalHostDriver
      @equipment['server1'].connect({})     # In this case, nothing happens as the server is running locally
    elsif @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip) and !@equipment['server1'].target.telnet
      @equipment['server1'].connect({'type'=>'telnet'})
    elsif !@equipment['server1'].target.telnet 
      raise "You need Telnet connectivity to the Linux Server, Please check your bench file" 
    end
  end
  end
end




