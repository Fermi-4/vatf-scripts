# Multicore Loader - takes cores and binaries and loads and runs them
require File.dirname(__FILE__)+'/default_ccs'
require File.dirname(__FILE__)+'/../LSP/lsp_helpers.rb'
require File.dirname(__FILE__)+'/../ipc/multicore_data.rb'
include CcsTestScript
include LspHelpers
include MulticoreData

@base_dir = ""
@rtos_bins_dir = ""
@test_name = ""

def setup
  #set the addresses for the coredump tar.gz and the ipc binaries
  coredump_tar = SiteInfo::COREDUMP_UTIL
  rtos_bins = @test_params.instance_variable_defined?(:@rtos_bins) ? @test_params.rtos_bins : nil
  if (rtos_bins == nil)
    raise "Please specify ipc bins tarball"
  end

  #set the binary prefix--can change based on the build
  @base_dir = @test_params.params_chan.instance_variable_defined?(:@path_prefix) ?@test_params.params_chan.path_prefix.to_s : nil
  if (@base_dir == nil)
    raise "Please specify the prefix path i.e. '/mytestdir/bios_66AK2E_norebuild/ipc_3_42_00_00_eng'"
  end
  @base_dir = @base_dir[3...-4]

  #create the temp directory and untar the binaires
  @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
  @rtos_bins_dir = "#{@linux_temp_folder}/rtos_bins"
  @equipment['server1'].send_cmd("mkdir -p #{@rtos_bins_dir}")
  untar(rtos_bins, @rtos_bins_dir)

  #wget the coredump utilities and untar into the temp dir
  @equipment['server1'].send_cmd("wget --directory-prefix=#{@rtos_bins_dir} #{coredump_tar}",Regexp.new('.*'),0)
  coredump = "#{@rtos_bins_dir}/coredump.tar.gz"
  @equipment['server1'].send_cmd("mkdir -p #{@rtos_bins_dir}/xdc/rov")
  untar(coredump, @rtos_bins_dir+"/xdc/rov")

  #check for specified test
  @test_name = @test_params.params_chan.instance_variable_defined?(:@ipc_test) ?@test_params.params_chan.ipc_test.to_s : ""
  if (@test_name == "")
    raise "please specify a test to run"
  end
  @test_name.gsub!(/\W+/, '')

  #get the cores and binaries out of MulticoreIPCDATA
  cores = get_data(@equipment['dut1'].name,@test_name,"cores")
  bins = get_data(@equipment['dut1'].name,@test_name,"binaries")

  #prepend temp dir path to the relative bin path
  bins.each { |word| word[0,0] = ("#{@rtos_bins_dir}#{@base_dir}") }
  bins.each { |word| word.tr!('"','') }

  #set the values that get picked up by auto_main.js
  @equipment['dut1'].params['outFile'] = bins
  @equipment['dut1'].params['ccsCpu'] = cores
  @equipment['dut1'].params['ccsPlatform'] = "*"
  super
end

def run
  #run auto_main.js
  thr0 = Thread.new() {
             @equipment['dut1'].run "",
                        1000,
                        {'reset' => 'yes',
                         'no_profile' => 'yes',
                         'timeout' => @test_params.params_chan.instance_variable_defined?(:@timeout) ?@test_params.params_chan.timeout[0] : '9000'}
       }

  #kill the thread and print the result
  thr0.join()
  puts @equipment['dut1'].response

  #set regular expression for the pass/fail criteria
  criteria_regex = Regexp.new("#{get_data(@equipment['dut1'].name,@test_name,"output")}", Regexp::MULTILINE)
  passed = false

  #if the test does not use ROV, match the print statements to pass/fail
  rov = get_data(@equipment['dut1'].name,@test_name,"ROV")
  if (!rov)
    if @equipment['dut1'].response.match(criteria_regex)
      passed = true
    end

  #if the test does use ROV, dump the logs and pass/fail on those
  else
    passed = check_ROV(criteria_regex, rov)
  end

  #set the test result
  if passed
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end
end

def clean
  #remove the coredump utility
  @equipment['server1'].send_cmd("rm -r #{@rtos_bins_dir}/xdc",Regexp.new('.*'),0)

  #remove the ROV text dumps, if they exist
  bins = @equipment['dut1'].params['outFile']
  bins.each { |word| @equipment['server1'].send_cmd("rm -r #{word}.txt",Regexp.new('.*'),0)}

  #remove the remainder of the rtos binaries
  @equipment['server1'].send_cmd("rm -r #{@rtos_bins_dir}",Regexp.new('.*'),0)
end

def untar(tar,dir)
  params = {}
  params['server'] = @equipment['server1']
  tar_options = get_tar_options(tar,params)
  @equipment['server1'].send_cmd("tar #{tar_options} #{tar} -C #{dir}",Regexp.new('.*'),0)
end

def check_ROV(criteria_regex, rov_paths)
  #setting the paths used by the coredump utility
  status = true
  bins = @equipment['dut1'].params['outFile']
  ccs_install_dir = @equipment['dut1'].params['ccs_install_dir']
  jre = ccs_install_dir+"/eclipse/jre"
  xdc = @equipment['dut1'].params['xdctools']
  rovtools = "#{@rtos_bins_dir}"
  bios = @equipment['dut1'].params['bios']
  dss = ccs_install_dir+"/ccs_base/DebugServer/packages"

  #prepend the temp dir path to the relative rov.xs path
  rov_paths.each { |word| word[0,0] = ("#{@rtos_bins_dir}#{@base_dir}") }
  rov_paths.each { |word| word.tr!('"','') }

  #allow for specialized ROV fields, default to LoggerBuf
  rov_field = get_data(@equipment['dut1'].name,@test_name,"field")
  if (!rov_field)
    rov_field = "xdc.runtime.LoggerBuf Records"
  end

  #move the rov.xs to the appropriate dir then run the coredump on each core
  passed = true
  (0..bins.length - 1).each do |i|
    @equipment['server1'].send_cmd("cp #{rov_paths[i]} `dirname #{bins[i]}`")
    @equipment['server1'].send_cmd("export XDCTOOLS_JAVA_HOME=#{jre};export XDCPATH=#{rovtools}\\;#{bios}\\;#{dss}\\;$XDCPATH;echo \"m #{rov_field}\\nq\"| #{xdc}/xs xdc.rov.coredump -e #{bins[i]} -d #{bins[i]}.raw 2>&1 | tee #{bins[i]}.txt")

    #if any core fails, the whole test fails
    if !(File.open("#{bins[i]}.txt").read() =~ criteria_regex)
      status = false
    end
  end
  return status
end
