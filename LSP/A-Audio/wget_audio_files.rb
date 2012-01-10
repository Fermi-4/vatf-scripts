# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../TARGET/dev_test2.rb'
# Default Server-Side Test script implementation for LSP releases
   
#include LspTestScript
def setup
  #super
  self.as(LspTargetTestScript).setup
end

def run
  #super
  get_files_from_url
  self.as(LspTargetTestScript).run
end

def clean
  #super
  self.as(LspTargetTestScript).clean
end


def get_files_from_url
	test_file_url = @test_params.params_control.instance_variable_defined?(:@test_file_url) ? @test_params.params_control.test_file_url[0] : -1
	test_file = @test_params.params_control.instance_variable_defined?(:@test_file) ? @test_params.params_control.test_file[0] : -1
	dst_path = @equipment['dut1'].nfs_root_path
	@equipment['server1'].send_sudo_cmd("wget #{test_file_url} -O #{dst_path}/home/root/#{test_file}.wav", @equipment['server1'].prompt, 100) if @test_params.params_control.instance_variable_defined?(:@test_file_url)
end

