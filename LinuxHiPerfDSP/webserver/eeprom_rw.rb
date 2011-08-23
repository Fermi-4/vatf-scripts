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
  
  i2c_bus_addr = @test_params.params_chan.instance_variable_get("@i2c_bus_addr")[0].to_s
  restore_ibl_config = @test_params.params_chan.instance_variable_get("@restore_ibl_config")[0].to_s == /[T|t]rue/ ? "True" : "False"
  ibl_config_addr = @test_params.params_chan.instance_variable_get("@ibl_config_addr")[0].to_s
  
  @equipment['server1'].send_cmd("cd #{C6xTestScript.nfs_root_path}", @equipment['server1'].prompt, 30)  
  @equipment['server1'].send_sudo_cmd("rm myfile", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("rm myfile-out", @equipment['server1'].prompt, 30)
  
  if (@test_params.instance_variable_defined?(:@eeprom_0x50_to_write) || @test_params.instance_variable_defined?(:@eeprom_0x51_to_write))  
    fsFile = (i2c_bus_addr == "0x51") ? @test_params.eeprom_0x51_to_write : @test_params.eeprom_0x50_to_write 
    BuildClient.copy(fsFile, "#{C6xTestScript.samba_root_path}/myfile") 
  else
    puts "No input file specified, creating an input file .."
    id = Time.now.strftime("%m_%d_%Y_%H_%M_%S")
    test_str = "This is a EEPROM #{i2c_bus_addr} test " + id
    f = File.new("#{C6xTestScript.samba_root_path}/myfile","w+")
    f.puts test_str
    f.close
    fsFile = "#{C6xTestScript.samba_root_path}/myfile"
  end 
  bytes = File.size(File.new("#{C6xTestScript.samba_root_path}/myfile"))
  puts "Input file size is #{bytes} bytes\n"
  
  # Write to EEPROM partition
  RestClient.post("http://#{@equipment['dut1'].telnet_ip}/cgi-bin/eepromwrite.cgi", 
  :busAddr => "#{i2c_bus_addr}",
  :cfgSave => "#{restore_ibl_config}",
  :address => "#{ibl_config_addr}",
  :datafile => File.new(fsFile))
  
  sleep 60
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/default.css"))
  # Now read back from EEPROM partition
  RestClient.post("http://#{@equipment['dut1'].telnet_ip}/cgi-bin/eepromread.cgi", 
  :busAddr => "#{i2c_bus_addr}",
  :multipart => true
  )
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/default.css"))
  sleep 30
  response = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}/i2c_#{i2c_bus_addr}.bin"))
  sleep 30
  if(response.code.to_i != 200)
    raise "Could not read back from EEPROM"
  end
  
  of = File.new("#{C6xTestScript.samba_root_path}/myfile-out","w+")
  of.puts response.body
  of.close
  # (restclient seems to be adding \r so do 'fromdos')    
  @equipment['server1'].send_cmd("fromdos myfile-out", @equipment['server1'].prompt, 30)
  if(restore_ibl_config == "False")
    # Now compare 
    @equipment['server1'].send_cmd("cmp -n #{bytes-1} myfile myfile-out;echo $?",/0/, 30)
  else
    @equipment['server1'].send_cmd("ls -la myfile-out | awk \'{ print $5}\'",@equipment['server1'].prompt, 30)
    puts @equipment['server1'].response.scan(/(\d+)\s+/)[0][0].to_i
    output_bytes = @equipment['server1'].response.scan(/(\d+)\s+/)[0][0].to_i
    puts "Output file size is #{output_bytes}"
  end
    
  
  if (!@equipment['dut1'].timeout? && !@equipment['server1'].timeout?)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  
  @equipment['server1'].send_sudo_cmd("rm myfile", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("rm myfile-out", @equipment['server1'].prompt, 30)

  set_result(test_done_result,comment)
end

def clean

end