VLAB_ERRORS = {
	14 => 'VLAB installation error',
	13 => 'VLAB user files installation error',
	2  => 'VLAB output did not match expected response',
	1  => 'VLAB failed to run'
}


def setup
	begin
		@linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
		@sw_assets_folder = '/usr/local/staf/data/STAF/user/sw_assets'
		@vlab_installer = @test_params.vlab_installer; @vlab_installer.slice! @sw_assets_folder
		@vlab_toolbox = @test_params.vlab_toolbox; @vlab_toolbox.slice! @sw_assets_folder
		@vlab_files = @test_params.vlab_files; @vlab_files.slice! @sw_assets_folder
		@test_cmd = @test_params.params_control.test_cmd[0] # ./run_auto_vlab.exp
		@pass_signature = @test_params.params_control.pass_signature[0] # [[:digit:]]+ passed, 0 failed
		@timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
	rescue Exception => e
		@equipment['server1'].log_error("Make sure you are defining mandatory parameters in\n"\
			"  build description: vlab_installer, vlab_toolbox, vlab_files\n"\
			"  application parameters: test_cmd, pass_signature. timeout is optional (default=10mins)")
		raise e
	end

end


# Start VLAB and pass/fail based on simulator exit value (0=PASS, else FAIL)
def run
    cmd = "docker run --rm -a stdout "
    cmd += "-v #{@sw_assets_folder}:/home/opentest/sw_assets "
    cmd += "--env VLAB_INSTALLER=/home/opentest/sw_assets#{@vlab_installer} "
    cmd += "--env VLAB_TBOX=/home/opentest/sw_assets#{@vlab_toolbox} "
    cmd += "--env USER_FILES=/home/opentest/sw_assets#{@vlab_files} "
    cmd += "--env LOG_FILE=/home/opentest/sw_assets/#{@test_params.staf_service_name}.log "
    cmd += "--env VLAB_INST_DIR=/home/opentest/vlab "
    cmd += "--env VLABDIR=/home/opentest/vlab "
    cmd += "--env LOG_PASS=\"#{@pass_egrep}\" "
    cmd += "vlab ./vlab_wrapper.sh #{@test_cmd}"

    @equipment['server1'].send_cmd(cmd, @pass_signature, @timeout)
	if !@equipment['server1'].timeout?
		set_result(FrameworkConstants::Result[:pass], "VLAB output matched expected response")
	else
		set_result(FrameworkConstants::Result[:fail], VLAB_ERRORS[$?.exitstatus])
	end
end


def clean
end
