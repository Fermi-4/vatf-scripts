# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'

include LspTestScript

def map_dut_aws_target
    return case @equipment['dut1'].name
    when /am57/i
        'sitara_am57x'
    else
        'sitara_am57x'
    end
end

def compile_model(timeout)
    @equipment['server1'].send_cmd("rm #{File.dirname(__FILE__)}/*.tgz", @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("cd #{File.dirname(__FILE__)}; wget --no-proxy #{@test_params.params_chan.model[0]}", @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("cd #{File.dirname(__FILE__)}; python compile-local-model.py -f #{File.basename(@test_params.params_chan.model[0])}"\
                                   " -t #{map_dut_aws_target} -n job#{rand(1000)}", @equipment['server1'].prompt, timeout)
    return @equipment['server1'].response
end

def copy_model_files_to_target
    dut_ip = get_ip_addr()
    model_name = File.basename(@test_params.params_chan.model[0]).gsub(/\.tgz$/, "-#{map_dut_aws_target}.tgz")
    scp_push_file(dut_ip, File.join(File.dirname(__FILE__), model_name), '/tmp')
    @equipment['dut1'].send_cmd("cd /tmp; tar -xvzf #{model_name}", @equipment['dut1'].prompt, 30)
    @equipment['dut1'].send_cmd("wget --proxy off #{@test_params.params_chan.image[0]}", @equipment['dut1'].prompt, 30)
    @equipment['dut1'].send_cmd("wget --proxy off #{@test_params.params_chan.tidl_script[0]}", @equipment['dut1'].prompt, 30)
end

def execute_model
    @equipment['dut1'].send_cmd("python3 ./tidl_dlr4.py ./ #{@test_params.params_chan.batch_size[0]} input #{File.basename(@test_params.params_chan.image[0])}", @equipment['dut1'].prompt, 60)
    return @equipment['dut1'].response
end

def run
   timeout = @test_params.params_chan.instance_variable_defined?(:@timeout) ? @test_params.params_chan.timeout[0].to_i : 1200

   compile_output = compile_model(timeout)
   if compile_output.match(/Traceback.+error/i)
        set_result(FrameworkConstants::Result[:fail], "Error compiling model:\n#{compile_output}")
        return
   end

   copy_model_files_to_target()

   inference_output = execute_model()

   if inference_output.match(/index:#{@test_params.params_chan.image_index[0]}/i)
        perf = []
        if inference_output.match(/Time per inference:([\d\.]+) seconds/i)
            perf << {'name' => "time_per_inference", 'value' => inference_output.match(/Time per inference:([\d\.]+) seconds/i).captures[0], 'units' => "seconds"}
        end
        set_result(FrameworkConstants::Result[:pass], "Test Passed. Image properly recognized", perf)
   else
        set_result(FrameworkConstants::Result[:fail], "Test Failed. Image was not recognized")
   end

end