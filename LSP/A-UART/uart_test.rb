require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript
require 'serialport'

#Description
#This file contains functions to execute uart automatic test.
#Using flow defined here, UART  TX/RX will be tested:
# 1. different baud rates
# 2. different flow control.

#Test setup needed to run the test 
#1) Direct Serial Connect with the host 
 #dut.serial_port = active connected serial port
 #dut.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}

#Function gets default serial configuration to be
#used to restore  configuration at the end of the
#test
#input parameter: dut_serial_port
#Return Hash table: serial_default_config 

def get_serial_default_config(dut_serial_port)
  serial_default_config = {}
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  cmd = "stty -a -F #{dut_serial_port}"
  @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, 2)
  serial_default_config['baud'] = @equipment['dut1'].response.match(/speed\s+([0-9]+)/).captures[0]
  @equipment['dut1'].response.split("\n").each{|line|
    if line.to_s.include?('cstopb')
      line.split(" ").each{|param|
       serial_default_config[param.gsub(/-/,"")] = param
      }
    end
  }
  
  return serial_default_config
end 

#Function does 5 and 6 data bit testing.
#input parameter: databit,serial_port,stop_bits,baud,parity
#return: Test status.

def six_databit_test(databit,serial_port,stop_bits,baud,parity)
  status = 1
  reference_value = {'cs6' => [40, 37, 44, 44, 47, 55, 32, 44, 35, 48, 36]}
  @equipment['dut1'].disconnect() 
  ser = SerialPort.new(serial_port, baud.to_i, databit.gsub(/cs/,"").to_i, stop_bits.to_i, parity)
  ser.write('hellow lcpd')
  six_or_five_bit_data = ser.read
  data_byte_values=[]
  six_or_five_bit_data.each_byte{|b| 
  data_byte_values << b.to_i
  }
  ser.close
  if reference_value[databit] == data_byte_values
    status = 0
  else
    puts data_byte_values
    status = 1
  end 
  #this step is needed because setup function checks for 
  #uart connection before it reboots the platform
  #resetting to clean databit 6 config so setup to work.
  translated_boot_params = setup_host_side()
  @equipment['dut1'].boot(translated_boot_params) 
  connect_to_equipment('dut1')
  check_dut_booted()
  return status
end 

def run 
  status = 0
  serial_port = @equipment['dut1'].serial_port
  dut_serial_port =  '/dev/' + @equipment['dut1'].boot_args.match(/(tty\w[0-9]),/).captures[0]
  serial_default_config = get_serial_default_config(dut_serial_port)
  setting = @test_params.params_chan.cmd[0].gsub('stty','').to_s
  cmd = "stty -F #{dut_serial_port} #{setting}"
  @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, 2)
  
  config_value =  setting.split(' ')[setting.split(' ').length - 1].strip
  if config_value != 'cs6' 
    puts "Test none cs6"
    cmd = "stty -F #{serial_port} #{setting}"
    @equipment['server1'].send_cmd(cmd, @equipment['server1'].prompt, 10)
    @equipment['dut1'].send_cmd('echo hellow lcpd', @equipment['dut1'].prompt, 2)
    connectivity__test =  @equipment['dut1'].response.match(/hellow\s+lcpd/)
    cmd = "stty -a -F #{dut_serial_port}"
    @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, 2) 
    check_configuration = @equipment['dut1'].response.to_s
    #set uart configuration back to the default at the end.
    if check_configuration.include?(config_value) != nil and connectivity__test != nil
      status = 0
    else
      status = 1
    end
  else 
   puts "testing cs6"
   baud = config_value.include?('speed') ? config_value.match(/speed\s+([0-9]+)/).captures[0] : @equipment['dut1'].serial_params['baud']
   databit = config_value.include?('cs6')? 'cs6' :  @equipment['dut1'].serial_params['data_bits']
   stop_bits = config_value.include?('cstopb')? config_value.match(/(-{0,1}cstopb)/).captures[0] :  @equipment['dut1'].serial_params['stop_bits']
   parity =   config_value.include?('parodd')?  config_value.match(/(-{0,1}parodd)/).captures[0] :  @equipment['dut1'].serial_params['parity']
   status = six_databit_test(databit,serial_port,stop_bits,baud,parity)
  end

  set_serial_default_config(serial_port,dut_serial_port,serial_default_config)

  if status == 0
    puts "\nUart Test PASS"
    set_result(FrameworkConstants::Result[:pass], "UART Test Pass","")
  else
    puts "\nUart Test FAILED"
    set_result(FrameworkConstants::Result[:fail], "UART Test Fail","")   
  end
 
end

#Function puts the serial port configuration of the host and the platform
#to thier default value
#input parameter is: serial_port interface to be configured. 
#return: None
def set_serial_default_config(serial_port,dut_serial_port,serial_default_config)
  serial_default_config.each {|k,v|
    puts "Setting #{k} to #{v}"
    @equipment['dut1'].send_cmd("stty -F #{dut_serial_port} #{v}", @equipment['dut1'].prompt, 2)
    @equipment['server1'].send_cmd("stty -F #{serial_port} #{v}", @equipment['server1'].prompt, 2)
  }
end 


