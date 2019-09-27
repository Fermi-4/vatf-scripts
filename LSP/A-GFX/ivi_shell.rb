require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('/etc/init.d/weston stop; sleep 3',@equipment['dut1'].prompt,10)
end

def run
  @equipment['dut1'].send_cmd('ls /etc/weston_bak.ini &> /dev/null || mv /etc/weston.ini /etc/weston_bak.ini', @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("opkg list | grep -i 'weston -'", @equipment['dut1'].prompt,10)
  weston_version = @equipment['dut1'].response.match(/weston -\s([\d\.]+)/im).captures[0]
  config_ivi_shell_ini(weston_version)
  @equipment['dut1'].send_cmd('cat /etc/weston.ini',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('/etc/init.d/weston start; sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('cat /var/log/weston.log',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('weston-simple-shm &',@equipment['dut1'].prompt,30)
  @equipment['dut1'].send_cmd('layer-add-surfaces -l 1000 -s 2 &',/.*?waiting\s*for\s*2\s*surfaces.*?#{@equipment['dut1'].prompt}/im,10)
  if @equipment['dut1'].response.match(/visibility:\s*TRUE.*?added\s*to\s*layer\s*\D1000\D/im) and
  !@equipment['dut1'].response.match(/segmentation\s*fault|failed|not\s*available/im)
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test failed, unable to add surfaces:\n#{@equipment['dut1'].response}")
  end
end

def clean
  @equipment['dut1'].send_cmd('ls /etc/weston_bak.ini &> /dev/null && mv /etc/weston_bak.ini /etc/weston.ini',@equipment['dut1'].prompt,10)
end


# Funtion to obtain the appropriate data/config/command from a dict based
# on the version specified. The value returned is the command/config/data
# for the newest data_dict version that is less or equal than the version
# specified  
# Parameters:
#   version: string containing the version
#   data_dict: Dict where the keys are version and the values are a
#              data/config/command
def get_value_for_version(version, data_dict)
  versions = data_dict.keys.sort {|a,b| b <=> a}  # sort by version
  data_keys = versions.select {|v| Gem::Version.new(v.dup) <= Gem::Version.new(version)}
  data_dict[data_keys[0]]
end

# Function to create the Weston ini file for IVI shell
def config_ivi_shell_ini(version, dut=@equipment['dut1'])

default_ini = "
[core]
require-input=false
shell=ivi-shell.so

[ivi-shell]
ivi-module=ivi-controller.so
ivi-input-module=ivi-input-controller.so

[shell]
locking=false
animation=zoom
panel-position=top
startup-animation=fade

[screensaver]
# Uncomment path to disable screensaver
#path=@libexecdir@/weston-screensaver
"

v500_ini = "
[core]
require-input=false
shell=ivi-shell.so
modules=ivi-controller.so

[ivi-shell]
ivi-input-module=ivi-input-controller.so

[shell]
locking=false
animation=zoom
panel-position=top
startup-animation=fade

[screensaver]
# Uncomment path to disable screensaver
#path=@libexecdir@/weston-screensaver
"

  ini_dict = {
    '0.0' => default_ini,
    '5.0.0' => v500_ini
  }

  ivi_ini = get_value_for_version(version, ini_dict)

  ivi_ini.each_line { |line| dut.send_cmd("echo \"#{line.rstrip()}\" >> /etc/weston.ini", dut.prompt) }
end

