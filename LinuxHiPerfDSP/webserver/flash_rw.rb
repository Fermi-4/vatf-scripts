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
  
  test_type = @test_params.params_chan.instance_variable_get("@nand_test_type")[0].to_s
  
  @equipment['server1'].send_cmd("cd #{C6xTestScript.nfs_root_path}", @equipment['server1'].prompt, 30)  
  @equipment['server1'].send_sudo_cmd("rm myfile", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("rm myfile-out", @equipment['server1'].prompt, 30)
  
  if (@test_params.instance_variable_defined?(:@flash_kernel_to_write) || @test_params.instance_variable_defined?(:@flash_filesystem_to_write))  
    fsFile = (test_type == "kernel") ? @test_params.flash_kernel_to_write : @test_params.flash_filesystem_to_write
    BuildClient.copy(fsFile, "#{C6xTestScript.samba_root_path}/myfile") 
  else
    puts "No input file specified, creating an input file .."
    id = Time.now.strftime("%m_%d_%Y_%H_%M_%S")
    test_str = "This is a NAND #{test_type} test " + id
    f = File.new("#{C6xTestScript.samba_root_path}/myfile","w+")
    f.puts test_str
    f.close
    fsFile = "#{C6xTestScript.samba_root_path}/myfile"
  end 
  bytes = File.size(File.new("#{C6xTestScript.samba_root_path}/myfile"))
  puts "Input file size is #{bytes} bytes\n"
  # Write to NAND partition
  RestClient.post("http://#{@equipment['dut1'].telnet_ip}/cgi-bin/flashwrite.cgi", 
  :mtd_partition => "#{test_type}",
  :datafile => File.new(fsFile))
  
  sleep 60
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/default.css"))
  
  # Now read back from NAND partition
  RestClient.post("http://#{@equipment['dut1'].telnet_ip}/cgi-bin/flashread.cgi", 
  :mtd_partition =>  "#{test_type}",
  :multipart => true
  )
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/default.css"))
  sleep 30
  response = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/#{test_type}.bin"))
  sleep 30
  if(response.code.to_i != 200)
    raise "Could not read back from NAND fs"
  end
  


  of = File.new("#{C6xTestScript.samba_root_path}/myfile-out","w+")
  of.puts response.body
  of.close
  
  # Now compare (restclient seems to be adding \r so do 'fromdos')
    
  @equipment['server1'].send_cmd("fromdos myfile-out", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("cmp -n #{bytes-1} myfile myfile-out;echo $?",/0/, 30)
  

  
  if (!@equipment['server1'].timeout?)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  
  @equipment['server1'].send_sudo_cmd("rm myfile", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("rm myfile-out", @equipment['server1'].prompt, 30)

  set_result(test_done_result,comment)
end

def clean

end