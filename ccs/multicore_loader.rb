# Multicore Loader - takes cores and binaries and loads and runs them
require File.dirname(__FILE__)+'/default_ccs'
require File.dirname(__FILE__)+'/../LSP/lsp_helpers.rb'
include CcsTestScript
include LspHelpers
def setup
  rtos_bins = @test_params.instance_variable_defined?(:@rtos_bins) ? @test_params.rtos_bins : nil
  if (rtos_bins == nil) 
    raise "Please specify test bins tarball"  
  end
  @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
  @RTOS_BINS_DIR = "#{@linux_temp_folder}/rtos_bins"
  @equipment['server1'].send_cmd("mkdir -p #{@RTOS_BINS_DIR}")
  untar(rtos_bins, @RTOS_BINS_DIR)

  cores =  @test_params.params_chan.instance_variable_defined?(:@core_list) ?@test_params.params_chan.core_list[0].tr('"','').split(" ") : "*"

  bins = @test_params.params_chan.instance_variable_defined?(:@bin_list) ?@test_params.params_chan.bin_list[0].split(" ") : nil

  if (bins == nil)
    raise "must specify at least one binary to load"
  end

  bins.each { |word| word[0,0] = ("#{@RTOS_BINS_DIR}/") }
  bins.each { |word| word.tr!('"','') }

  if (bins.length != cores.length && bins.length != 1)
    raise "Number of cores and binaries must match or there must be a single binary"
  end
 
  @equipment['dut1'].params['outFile'] = bins
  @equipment['dut1'].params['ccsCpu'] = cores
  @equipment['dut1'].params['ccsPlatform'] = "*"  
  super
end

def run

	thr0 = Thread.new() {
               @equipment['dut1'].run "",
                          1000,
                          {'reset' => 'yes',
                           'no_profile' => 'yes',
                           'timeout' => @test_params.params_chan.instance_variable_defined?(:@timeout) ?@test_params.params_chan.timeout[0] : '9000'}
       }
	
    thr0.join()
    puts @equipment['dut1'].response
    criteria_regex = @test_params.params_chan.instance_variable_defined?(:@pass_fail) ? Regexp.new(@test_params.params_chan.pass_fail[0].to_s.tr!('"',''), Regexp::MULTILINE) : nil
  
  if @equipment['dut1'].response.match(criteria_regex)
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end
end
def clean
  #@equipment['server1'].send_cmd("rm -r #{@RTOS_BINS_DIR}")
end

def untar(tar,dir) 
  params = {}
  params['server'] = @equipment['server1']
  tar_options = get_tar_options(tar,params)
  @equipment['server1'].send_cmd("tar #{tar_options} #{tar} -C #{dir}")
end
