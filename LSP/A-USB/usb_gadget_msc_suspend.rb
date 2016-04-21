require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/usb_dev_msc_cdc'
require File.dirname(__FILE__)+'/../../lib/utils'


include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
# estimate of 60 sec per iteration
  mutex_timeout = 60000*@test_params.params_control.iterations[0].to_i
  staf_mutex("usbdevice", mutex_timeout) do
     i=0
     successful_enums=0
     session_data_pointer=0
  
     # Make sure module is installed
     device = get_sd_partition.strip+'p1'
     sd_dev = '/dev/'+device

     @equipment['dut1'].send_cmd("modprobe g_mass_storage file=#{sd_dev} stall=0", @equipment['dut1'].prompt, 5)
  @equipment['dut1'].send_cmd("lsmod", /g_mass_storage\s+\d+/, 3)
    
     # Loop for Suspend/Resume
     i=0
     @test_params.params_control.iterations[0].to_i.times do
         num_usb_dev_before=`lsusb | wc -l`
         session_data_pointer = @equipment['dut1'].update_response.length
         @equipment['server1'].send_sudo_cmd("dmesg -c",@equipment['server1'].prompt) 
         @equipment['dut1'].send_cmd("dmesg -c",@equipment['dut1'].prompt) 
         @equipment['dut1'].send_cmd("rtcwake -d /dev/rtc0 -m mem -s 10",@equipment['dut1'].prompt, 20)
         sleep @test_params.params_control.wait_after_connect[0].to_i
         num_usb_dev_after=`lsusb | wc -l`
         @equipment['server1'].send_sudo_cmd("dmesg",@equipment['server1'].prompt) 
         usb_dev_after=@equipment['server1'].response
         # Check device is enumerated
         @equipment['dut1'].send_cmd("dmesg",@equipment['dut1'].prompt) 
         enum_data=@equipment['dut1'].response
         @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
         successful_enums = successful_enums + 1 if (verify_dut_detection_msg(enum_data) == 1 && verify_host_detection_msg(num_usb_dev_before, num_usb_dev_after, usb_dev_after) == 1)
         i = i+1
     end

     success_rate = (successful_enums.to_f / @test_params.params_control.iterations[0].to_f)*100.0
     if (success_rate >= @test_params.params_control.pass_rate[0].to_f)
        set_result(FrameworkConstants::Result[:pass], "Success Enumeration rate=#{success_rate}")
     else
       set_result(FrameworkConstants::Result[:fail], "Success Enumeration rate=#{success_rate}")
     end
  end
end

private

def verify_dut_detection_msg(data)
  @equipment['dut1'].log_info ("Inside verify_dut_detection_msg")
  return 1 if data.match(/\s*Linux\s*\S*\s*Storage\s*/i)
  @equipment['dut1'].log_info("Failed check with dut data #{data}\n")
  return 0
end

def verify_host_detection_msg(before, after, data)
  @equipment['dut1'].log_info("Inside verify_host_detection_msg")
  return 1 if (before.to_i == after.to_i) 
  @equipment['dut1'].log_info("Failed check with host before=#{before}, after=#{after}, and data #{data}")
  return 0
end

