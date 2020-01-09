# This script is to test USB DRD feature

require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/../network_utils'

include LspTestScript

def setup
  # dut2->master board  
  add_equipment('dut2', @equipment['dut1'].params['master']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['master'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)

  # boot up dut1 --- slave 
  setup_boards('dut1')

  # boot up dut2 --- master
  setup_boards('dut2', {'dut_idx' => '2'})

end


def run
  result = 0
  msg = ''

  usb_addr_dut1 = get_low_usb_addr("dut1")
  puts "usb_addr_dut1:" + usb_addr_dut1
  @equipment['dut1'].send_cmd("cat /sys/kernel/debug/#{usb_addr_dut1}.usb/mode", @equipment['dut1'].prompt, 10, false)
  if ! @equipment['dut1'].response.match(/device|otg/i)
    raise "Please make sure USB ID pin is floating by changing on board SW. Ex, on dra7x, change the position of SW1. Also make sure using non OTG adapter"
  end

  usb_addr_dut2 = get_low_usb_addr("dut2")
  puts "usb_addr_dut2: " + usb_addr_dut2
  @equipment['dut2'].send_cmd("cat /sys/kernel/debug/#{usb_addr_dut2}.usb/mode", @equipment['dut2'].prompt, 10, false)
  if ! @equipment['dut2'].response.match(/device|otg/i)
    raise "Please make sure USB ID pin is floating by changing on board SW. Ex, on dra7x, change the position of SW1. Also make sure using non OTG adapter"
  end

  @equipment['dut1'].send_cmd("modprobe g_zero", @equipment['dut1'].prompt, 10, false)
  @equipment['dut2'].send_cmd("modprobe g_zero", @equipment['dut2'].prompt, 10, false)

  # make dut1 as host
  @equipment['dut1'].send_cmd("echo host > /sys/kernel/debug/#{usb_addr_dut1}.usb/mode", @equipment['dut1'].prompt, 10, false)
  @equipment['dut1'].send_cmd("cat /sys/kernel/debug/#{usb_addr_dut1}.usb/mode", @equipment['dut1'].prompt, 10, false)
  sleep 2
  @equipment['dut1'].send_cmd("lsusb", @equipment['dut1'].prompt, 30, false)
  if ! @equipment['dut1'].response.match(/Linux-USB\s*\"\s*Gadget\s*Zero/i)
    result += 1
    msg += "dut1 as host: Gadget Zero is not enumerated in dut1 which is now host side; "
  end

  # make dut1 as device and dut2 as host
  # remove all mass storage modules and mass storage devices before switching to device mode
  #remove_usb_stuff("dut1")
  @equipment['dut1'].send_cmd("echo device > /sys/kernel/debug/#{usb_addr_dut1}.usb/mode", @equipment['dut1'].prompt, 10, false)
  @equipment['dut2'].send_cmd("echo host > /sys/kernel/debug/#{usb_addr_dut2}.usb/mode", @equipment['dut2'].prompt, 10, false)
  @equipment['dut2'].send_cmd("cat /sys/kernel/debug/#{usb_addr_dut2}.usb/mode", @equipment['dut2'].prompt, 10, false)
  sleep 2
  @equipment['dut2'].send_cmd("lsusb", @equipment['dut2'].prompt, 30, false)
  if ! @equipment['dut2'].response.match(/Linux-USB\s*\"\s*Gadget\s*Zero/i)
    result += 1
    msg += "dut1 as device: Gadget Zero is not enumerated in dut2 which is now host side"
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed: #{msg}")
  end
 
end


# find the lowest usb address
def get_low_usb_addr(dut='dut1')
  @equipment["#{dut}"].send_cmd("ls /sys/kernel/debug/ |grep -iE '\d*\.usb'", @equipment["#{dut}"].prompt, 10, false)
  #usb_addr = @equipment["#{dut}"].response.match(/(\h+)\.usb/).captures[0]
  addr_a = @equipment["#{dut}"].response.scan(/\h+(?=\.usb)/im)
  addr_a.collect {|a| "0x"+a}
  addr_a.each{|a| puts a}
  rtn = addr_a.min.sub(/0x/,'')
  return rtn
end

def remove_usb_stuff(dut='dut1')
  @equipment["#{dut}"].send_cmd("umount /dev/sd*", @equipment["#{dut}"].prompt, 30, false)
  sleep 1
  # remove usb modules 
  @equipment["#{dut}"].send_cmd("modprobe -r usb_storage", @equipment["#{dut}"].prompt, 30, false)
end


def app_installed?(dut, app_name)
  dut.send_cmd("which #{app_name}; echo $?", /^0[\0\n\r]+/im, 5)
  raise "#{app_name} is not installed!" if dut.timeout?
end

