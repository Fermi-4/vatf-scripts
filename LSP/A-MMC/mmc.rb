# -*- coding: ISO-8859-1 -*-
include LspTestScript

def run
        puts "mmc.run"
        
        # get the commands to run
        commands = ensure_commands = ""
        commands = parse_cmd('cmd') 
        ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
        @mount_device = @test_params.params_chan.instance_variable_get("@mount_device").to_s
        
        if mmc_card_exists then # check for the SD card on the given mount device, run the commmands if one exists
          result, cmd = execute_cmd(commands)
          if result == 0 
            set_result(FrameworkConstants::Result[:pass], "Test Pass.")
          elsif result == 1
            set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
          elsif result == 2
            set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
          else
            set_result(FrameworkConstants::Result[:nry])
          end
        else # no mmc card was found
          set_result(FrameworkConstants::Result[:fail], "No MMC/SD card found")
        end          
        ensure 
          result, cmd = execute_cmd(ensure_commands)
end

# checks the unit to see if the memory card exists/is mountable
def mmc_card_exists
  expect_regex = "#|special"
  regex = Regexp.new(expect_regex)
  # first unmount the device, then try to remount it
  @equipment['dut1'].send_cmd("umount #{@mount_device} ; mount -t vfat #{@mount_device} /mnt/mmc", regex, 5) 
  Regexp.new(/special/).match(@equipment['dut1'].response) ? false : true
end

def clean
    puts 'mmc.clean'
end


