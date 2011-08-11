# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
require 'net/http'
require 'uri'
require 'rest_client'

  
def setup
  super
end

def run
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  dest_path = @test_params.params_chan.instance_variable_defined?("@output_path") ? @test_params.params_chan.instance_variable_get("@output_path")[0].to_s : '/tmp/myfile-out'
  @equipment['server1'].send_cmd("cd #{C6xTestScript.nfs_root_path}", @equipment['server1'].prompt, 30)  
  @equipment['server1'].send_sudo_cmd("rm myfile.txt", @equipment['server1'].prompt, 30)
  @equipment['dut1'].send_cmd("rm #{dest_path}", @equipment['dut1'].prompt, 30)
    
  if @test_params.instance_variable_defined?(:@file_to_write)       
    fsFile =  @test_params.file_to_write
    BuildClient.copy(fsFile, "#{C6xTestScript.samba_root_path}/myfile") 
  else
    puts "No input file specified, creating an input file .."
    id = Time.now.strftime("%m_%d_%Y_%H_%M_%S")
    test_str = "This is a filesystem test " + id
    f = File.new("#{C6xTestScript.samba_root_path}/myfile","w+")
    f.puts test_str
    f.close
    fsFile = "#{C6xTestScript.samba_root_path}/myfile"
  end 
  input_bytes = File.size(File.new("#{C6xTestScript.samba_root_path}/myfile"))
  puts "Input file size is #{input_bytes} bytes\n"
  RestClient.post("http://#{@equipment['dut1'].telnet_ip}/cgi-bin/filesystemwrite.cgi", 
  :fsFile => dest_path,
  :lfile => File.new(fsFile))
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/default.css"))
  sleep 10
  @equipment['dut1'].send_cmd("ls -la #{dest_path} | awk \'{ print $5}\'",@equipment['dut1'].prompt, 30)
  puts @equipment['dut1'].response.scan(/(\d+)\s+/)[0][0].to_i
  output_bytes = @equipment['dut1'].response.scan(/(\d+)\s+/)[0][0].to_i
  puts "Output file size is #{output_bytes}"
  
  if (!@equipment['dut1'].timeout? && output_bytes == input_bytes)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  
  @equipment['server1'].send_sudo_cmd("rm myfile.txt", @equipment['server1'].prompt, 30)
  @equipment['dut1'].send_cmd("rm #{dest_path}", @equipment['dut1'].prompt, 30)
  set_result(test_done_result,comment)
end

def clean

end