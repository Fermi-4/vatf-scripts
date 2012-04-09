def setup
  @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
  @jsAutoArgsFile    = File.join(@linux_temp_folder, 'getAutoArgs.js')
  @equipment['dut1'].connect({'type' => 'ccs'})
  if @equipment.has_key?('server1')
    if @equipment['server1'].kind_of? LinuxLocalHostDriver
      @equipment['server1'].connect({})     # In this case, nothing happens as the server is running locally
    elsif @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip) and !@equipment['server1'].target.telnet
      @equipment['server1'].connect({'type'=>'telnet'})
    elsif !@equipment['server1'].target.telnet 
      raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
    end
  end
  createAutotestEnv()
  @equipment['dut1'].target.ccs.jsEnvArgsFile = @jsAutoArgsFile
  #@equipment['dut1'].target.ccs.tempdir = @linux_temp_folder
end

def run
  set_result(FrameworkConstants::Result[:nry], "You need to implement run() method")
end

def clean
end

# Create file to pass parameters to javascript
def createAutotestEnv
  FileUtils.mkdir_p @linux_temp_folder
  out_file = File.new(@jsAutoArgsFile, 'w')
  out_file.puts("autotestEnv = {};")
  val = @test_params.instance_variable_defined?(:@ccsConfig) ? "\"#{@test_params.ccsConfig}\"" : @equipment['dut1'].params.key?('ccsConfig') ? "\"#{@equipment['dut1'].params['ccsConfig']}\"" : "null"
  out_file.puts("autotestEnv.ccsConfig = #{val};")
  val = @test_params.instance_variable_defined?(:@gelFile) ? "\"#{@test_params.gelFile}\"" : @equipment['dut1'].params.key?('gelFile') ? "\"#{@equipment['dut1'].params['gelFile']}\"" : "null"
  out_file.puts("autotestEnv.gelFile = #{val};")
  val = @test_params.instance_variable_defined?(:@var_ccsPlatform) ? "\"#{@test_params.var_ccsPlatform}\"" : @equipment['dut1'].params.key?('ccsPlatform') ? "\"#{@equipment['dut1'].params['ccsPlatform']}\"" : "null"
  out_file.puts("autotestEnv.ccsPlatform  = #{val};")
  val = @test_params.params_control.instance_variable_defined?(:@ccsCpu) ? "\"#{@test_params.params_control.ccsCpu[0]}\"" : @equipment['dut1'].params.key?('ccsCpu') ? "\"#{@equipment['dut1'].params['ccsCpu']}\"" : "null"
  out_file.puts("autotestEnv.ccsCpu       = #{val};")
  val = @test_params.instance_variable_defined?(:@outFile) ? "\"#{@test_params.outFile}\"" : "null"
  out_file.puts("autotestEnv.outFile = #{val};")
  out_file.close
end
