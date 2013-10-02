require File.dirname(__FILE__)+'/../default_test_module' 

include LspTestScript

def setup
  # HP wave generator is connected to host through serial connection. 
  # HP wave generator analog autput is connected to jumpers for ADC input.
  # Connect to multimeter and bench entry should look like the following. 
  #winfo = EquipmentInfo.new("wavegen")
  #winfo.driver_class_name = "HpWaveGenDriver"
  #winfo.serial_port = '/dev/ttyUSB1'
  #winfo.serial_params = {"baud" => 9600, "data_bits" => 8, "stop_bits" => 1,   "parity"=>SerialPort::NONE}
  @equipment['wavegen1'].connect({'type'=>'serial'})
  # Configure multimeter 
  @equipment['wavegen1'].configure_wave_gen()
  self.as(LspTestScript).setup
end

def run
  perf = []
  
  @equipment['dut1'].connect({'type'=>'serial'})
  #vin = 1 # in volt 
  #vref = 1.8 # reference voltage 
  vin = @equipment['dut1'].params['vin'] # in volt 
  vref = @equipment['dut1'].params['vref'] # reference voltage 
  channels = @equipment['dut1'].params['channels']
  #D = Vin * (2^n - 1) / Vref # theoretical digital represention of the input voltage 
    #This mode configuration is not yet decided on the main kernel
  mode = 'oneshot' # continuous
  #Configure ADC  
  #config_adc(mode) this function call is for future use. The developers are debating as of now. 
  test_name = @test_params.params_chan.test_name[0]
  puts "test name is #{test_name}"
  case test_name 
  when "cont"
    test_status = cont_test(channels,vin, vref)
  when "oneshot"
    test_status = oneshot_test(channels,vin,vref)
  else 
    puts "undefined test case!"
    test_status = 0
  end 
  
  if test_status > 0
    set_result(FrameworkConstants::Result[:pass], "ADC Test Pass","")
  else
    set_result(FrameworkConstants::Result[:fail], "ADC Test Pass","")   
  end  
end 

#Function configures platform's ADC.
# Input parameters: mode is to set it to continoues or oneshot 
# Return Parameter: none 

def config_adc(mode)
  @equipment['dut1'].send_cmd("echo #{mode} > /sys/bus/iio/devices/iio\:device0/mode", @equipment['dut1'].prompt)
end

#Function configures does ADC continoues test.
# Input parameters: number of channels supported by platform ADC, voltage input and voltage refrence 
# Return Parameter: test status  
def cont_test(channels, vin, vref)
  dReadings =  Hash.new()
  channels.each do |chan|
    dReadings[chan.to_s] = Array.new()
  end
  #dtheo = vin * (2**12 - 1) / vref
  wave_gen_cmd = 'OUTPut:LOAD 50'
  @equipment['wavegen1'].gen_wave_cmd(wave_gen_cmd)
  sleep 1
  vin_shift =  vin/2 
  wave_gen_cmd =  "APPL:SIN #{@test_params.params_chan.freq[0]}, #{vin}, #{vin_shift}"
  @equipment['wavegen1'].gen_wave_cmd(wave_gen_cmd)
  sleep 1
  fail = 0
  20.times do
      channels.each do |chan|
          @equipment['dut1'].send_cmd("cat /sys/bus/iio/devices/iio\:device0/in_voltage#{chan}_raw", @equipment['dut1'].prompt)
          dread =  @equipment['dut1'].response.to_s.match(/raw\s+([0-9]+)/).captures[0]
          vd = ((dread.to_f * vref).to_f/ (2**12 - 1).to_f).round(1)
          dReadings[chan.to_s] << vd
      end 
  end 
  dReadings.each do |key,values|
    dreadingMax = dReadings[key].max
    dreadingMin = dReadings[key].min
    if (dreadingMax).round(2) > vin || dreadingMin < 0 
       puts "ADC FAILED on channel #{key} #################." 
       fail = 1 
    else 
       puts puts "ADC SUCCESS ON CHANNEL #{key} #################."
    end  
  end      
  return fail 
end  

#Function configures does ADC oneshot test.
# Input parameters: number of channels supported by platform ADC, voltage input and voltage refrence 
# Return Parameter: test status  

def oneshot_test(channels, vin, vref)
  #dtheo = vin * (2**12 - 1) / vref
  wave_gen_cmd = 'APPLy:DC #{vin}'
  @equipment['wavegen1'].gen_wave_cmd(wave_gen_cmd)
  sleep 1
  wave_gen_cmd = 'OUTPut:LOAD INFinity'
  @equipment['wavegen1'].gen_wave_cmd(wave_gen_cmd)
  sleep 1
  wave_gen_cmd =  "VOLTage:OFFSet #{vin}"
  @equipment['wavegen1'].gen_wave_cmd(wave_gen_cmd)
  sleep 1
  fail = 0
  channels.each do |chan|
      @equipment['dut1'].send_cmd("cat /sys/bus/iio/devices/iio\:device0/in_voltage#{chan}_raw", @equipment['dut1'].prompt)
      dread =  @equipment['dut1'].response.to_s.match(/raw\s+([0-9]+)/).captures[0]
      #ddelta =  (dtheo - dread.to_i).abs
      vd = ((dread.to_f * vref).to_f/ (2**12 - 1).to_f).round(1)
      vdelta = (vin - vd.to_i).abs 
      if vdelta > 0.2 
         puts "ADC FAILED ON CHANNEL #{chan}" 
         puts "Channel #{chan} : Voltage in #{vin} : ADC Value #{vd}"
         fail = 1 
      else 
        puts puts "ADC SUCCESS ON CHANNEL #{chan}"
        puts "Channel #{chan} : Voltage in #{vin} : ADC Value #{vd}"
      end  
  end 
  return fail
end  

def clean
  
end 
