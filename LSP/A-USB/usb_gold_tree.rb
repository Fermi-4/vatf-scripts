require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/usb_tree_util'
# Notes regarding test case and bench requirements

# hw_assets and params_control is test case xml should be as below
#      <hw_assets_config><![CDATA[dut1=["<platform>",linux_usbhostmsc];server1=["linux_server"];sw-ob1=["usb_switch","sw-ob1"];sw-ob2=["usb_switch","sw-ob2"];sw-ob3=["usb_switch","sw-ob3"];sw-ob4=["usb_switch","sw-ob4"];sw-ob5=["usb_switch","sw-ob5"];sw-ob6=["usb_switch","sw-ob6"];sw-ob7=["usb_switch","sw-ob7"]
#]]></hw_assets_config>
#      <params_control><![CDATA[iterations=2,wait_after_connect=5,wait_after_disconnect=5,device=hub_hub_hub_hub_hub_hid-mouse;hub_msc,action=suspend_resume,enum_strings=USB\s+HID,enum_count=1,port_name=usbhost_ehci,port_num=0
#]]></params_control>


# bench entries should be like below
#dut.params =

#{'usbhost_ehci' => [
#{'sw-ob1'=>{'port_1'=>{'hub'=>{'sw-ob2'=>{'port_1'=>'camera'},
#                            'sw-ob3'=>{'port_1'=>'msc'},
#                            'hub'=>
#                               {'hub'=>
#                                 {'hub'=>
#                                   {'sw-ob5'=>{'port_1'=>{'hub'=>
#                                                 {'sw-ob4'=>{'port_1'=>'hid-mouse'},
#                                                  'sw-ob6'=>{'port_1'=>'msc'},
#                                                  'sw-ob7'=>{'port_1'=>'hid-keyboard'}}}
#                                               }
#                                    }
#                                  }
#                              }
#                            }
#                       }
#               }
#}
#                                    ],
#}

#swob1 = EquipmentInfo.new("usb_switch_controller","sw-ob1")
#swob1.serial_port = '/dev/ttyACM0'
#swob1.serial_params = {"baud"=>9600,"data_bits"=>8,"stop_bits"=>1,"parity"=>SerialPort::NONE}
#swob1.driver_class_name = 'TiUsbSwitch'
# and similarly for all the required switches


def setup
  @equipment['dut1'].set_api('psp')
  connect_to_extra_equipment()
  self.as(LspTargetTestScript).setup
end

# Function: run_gold_tree_tests
# input: none
# output: none
# Function uses test case parameters to determine action to be performed 
# It disconnects device(s), connects device(s), and runs the appropriate command
# Based on LTP command success or enumeration success after running the commands# test result is updated as pass or fail
def run_gold_tree_tests
  test_seq = @test_params.params_control.action[0]
  port_name = @test_params.params_control.port_name[0]
  port_num = @test_params.params_control.port_num[0].to_i
  device_array = @test_params.params_control.device
  device_switch_hash = Hash.new
  device_array.each do |dev_node|
    switch_port_array = []
    switch_port_array = determine_switch_port(dev_node, port_name, port_num)
    device_switch_hash[dev_node] = switch_port_array
   end
    # creating an array of all switch-port pairs for this node to ensure no error conditions are present
    total_array_switch_port=[]
    device_switch_hash.each do |key, array|
      array.each do |elem|
       if (elem != nil)
         total_array_switch_port<<elem
       end
     end
    end
    # Iterate through array to make sure only a unique combination of any switch-port pair exists in array. If for a switch, more than one port occurs in array, test will exit with error as below
     total_array_switch_port.each do |elem|
     match_count = 0
     total_array_switch_port.each do |elem1|
    # If switches are same, check if ports are different
       if (elem[1] == elem1[1] && elem[2] != elem1[2])
         match_count = match_count+1
         if (match_count > 1)
           raise "Two ports in same USB switch are required for this test. This is not supported. Please check bench or test case parameter."
         end
       end
      end
    end
    iteration=0
    while (iteration<@test_params.params_control.iterations[0].to_i)
      enum_data = []
      device_array.each do |dev_node|
        disconnect_device(device_switch_hash[dev_node])
      end
      sleep @test_params.params_control.wait_after_disconnect[0].to_i
      session_data_pointer = @equipment['dut1'].update_response.length
      device_array.each do |dev_node|
        connect_device(device_switch_hash[dev_node])
      end
      sleep @test_params.params_control.wait_after_connect[0].to_i
      
      case test_seq.strip.downcase
         when 'enumerate','warm_boot','suspend_resume','cold_boot'
         case test_seq.strip.downcase
           when 'warm_boot'
              @equipment['dut1'].send_cmd('reboot',@equipment['dut1'].login_prompt,120)
              @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10)
           when 'suspend_resume'
              @equipment['dut1'].send_cmd("echo mem > /sys/power/state", /Freezing remaining freezable tasks/, 10)
              raise "DUT took more than 10 seconds to suspend" if @equipment['dut1'].timeout?
              sleep 2
              @equipment['dut1'].send_cmd(" ", @equipment['dut1'].prompt, 10)
           when 'cold_boot'
              translated_boot_params = setup_host_side()
              @equipment['dut1'].power_cycle(translated_boot_params)
              @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10)
          end # of case for each type of enum
          # do all that is common for the enum cases above
          if ( @equipment['dut1'].timeout?) 
            set_result(FrameworkConstants::Result[:fail], "Test for #{test_seq} is taking too long to complete") 
               return
          else
            ses_data = @equipment['dut1'].update_response
            enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
            @equipment['dut1'].log_info("ENUM DATA #{enum_data}")
            if (enum_data.match(/(kernel NULL pointer dereference)|(reset \w+-speed USB device number \d+)/m) )
               set_result(FrameworkConstants::Result[:fail], "Kernel crash or USB reset errors detected")
               return
            elsif (!enum_data.match(/new \w+-speed USB device number \d+/i))
               set_result(FrameworkConstants::Result[:fail], "DUT is no longer detecting USB devices")  
               return
            elsif (verify_device_detected(enum_data) == 1)  
               puts "\n\n\nSUCCESS\n\n\n"
               set_result(FrameworkConstants::Result[:pass], "Device Re-enumerated Succesfully") 
               return
            else  
               set_result(FrameworkConstants::Result[:fail], "No USB Errors detected but device did not re-enumerate successfully") 
               return
             end
         end
          #
         when 'msc_write', 'msc_copy', 'hid_mouse_tests'
          # do all that is common for these ltp tests here
             @equipment['dut1'].send_cmd("cd /opt/ltp", @equipment['dut1'].prompt, 5)
             cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 1200
             
             case test_seq.strip.downcase # ltp commands for each case
               when 'msc_write'
                 @equipment['dut1'].send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBHOST_S_PERF_VFAT_0001", @equipment['dut1'].prompt, cmd_timeout)
               when 'msc_copy'
                 @equipment['dut1'].send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_msc_copy -s USBHOST_M_FUNC_COPY_bw_USB_DRIVES_50M", @equipment['dut1'].prompt, cmd_timeout)
               when 'hid_mouse_tests'
                 @equipment['dut1'].send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_hid_mouse -s USBHOST_L_FUNC_HID_Mouse_Detection_Test ", @equipment['dut1'].prompt, cmd_timeout)
             end #  of case for msc and hid
             # do all that is common for ltp tests here
             if ( @equipment['dut1'].timeout?) 
               set_result(FrameworkConstants::Result[:fail], "LTP Test is taking too long to complete") 
               return
             else  
               set_result(FrameworkConstants::Result[:pass], "LTP Test ran successfully.") 
               return
             end
      end #  of case statement
      iteration = iteration+1
    end # of while iteration
end

def run
  time = Time.now
  @equipment['dut1'].send_cmd("cd /opt/ltp", @equipment['dut1'].prompt, 5)
  @equipment['dut1'].log_info("Debug Data: \n #{@equipment['dut1'].response}")
  raise "Could not change directory to ltp-ddt root location" if @equipment['dut1'].timeout?
  run_gold_tree_tests
end
