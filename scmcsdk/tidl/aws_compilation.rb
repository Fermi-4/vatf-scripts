# -*- coding: ISO-8859-1 -*-

# This script requires that
#  1) docker is installed in the host machine, for example:
#     sudo apt-get update && sudo apt-get install docker.io
#  2) default user is part of docker group, for example:
#     sudo groupadd docker && sudo gpasswd -a $USER docker && newgrp docker

require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require 'date'
require 'socket'

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
    @aws_tempdir=`mktemp -d`.gsub(/\n/,'')
    @equipment['server1'].send_cmd("cd #{@aws_tempdir}; wget --no-proxy #{@test_params.params_chan.model[0]}", @equipment['server1'].prompt, 30)
    # Load manually until private docker registry is available
    @equipment['server1'].send_cmd("docker load -i /mnt/gtautoftp/docker_images/aws_buster.tar.gz", @equipment['server1'].prompt, 60)
    @equipment['server1'].send_cmd("docker run --rm -v /mnt/gtautoftp/:/mnt/gtautoftp "\
        "-v #{@aws_tempdir}:/testfiles aws:buster python aws_compile_local_model.py "\
        "-f /testfiles/#{File.basename(@test_params.params_chan.model[0])}  -t #{map_dut_aws_target} "\
        "-n #{Socket.gethostname.downcase()}-#{DateTime.now.strftime("%y-%m-%dT%H-%M-%S")}",
        @equipment['server1'].prompt, timeout)
    return @equipment['server1'].response
end

def copy_model_files_to_target
    dut_ip = get_ip_addr()
    model_name = File.basename(@test_params.params_chan.model[0]).gsub(/\.tgz$/, "-#{map_dut_aws_target}.tgz")
    scp_push_file(dut_ip, File.join(@aws_tempdir, model_name), '/tmp')
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

def clean
    @equipment['server1'].send_cmd("rm -rf #{@aws_tempdir}", @equipment['server1'].prompt)
    super()
end
