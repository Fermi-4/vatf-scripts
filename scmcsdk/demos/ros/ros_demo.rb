require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../common_utils/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  pass_crit = @test_params.params_chan.pass_crit[0]
  # get Server ip address
  server_ip = @equipment['server1'].telnet_ip
 begin
    dut_ip = get_dut_ip()  # get EVM ip address
    configure_server(dut_ip, server_ip)
    configure_dut(dut_ip, server_ip)
    run_ros(pass_crit)
    set_result(FrameworkConstants::Result[:pass], "Test Passed. Robotic Operating System Demo Passed.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
 end
end

def clean
    self.as(LspTestScript).clean
    @equipment['dut1'].send_cmd("cd /etc;cp ntpd_bk.conf ntpd.conf", @equipment['dut1'].prompt, 20)
end
# function to configure dut path
def configure_dut(dut_ip, server_ip)
  @equipment['dut1'].send_cmd("cd /usr/bin/;ls -l *python*;ln -s -f python3 python.python;ln -s -f \
python3-config python-config.python;ls -l *python*", @equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("export ROS_ROOT=/opt/ros/indigo", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export PATH=$PATH:/opt/ros/indigo/bin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export LD_LIBRARY_PATH=/opt/ros/indigo/lib", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export PYTHONPATH=/usr/lib/python3.5/site-packages:/opt/ros/indigo/lib\
/python3.5/site-packages", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_MASTER_URI=http://#{dut_ip}:11311", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_IP=#{dut_ip}", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_HOSTNAME=#{dut_ip}", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export CMAKE_PREFIX_PATH=/opt/ros/indigo", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_PACKAGE_PATH=/opt/ros/indigo/share", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("touch /opt/ros/indigo/.catkin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cd /etc;cp ntpd.conf ntpd_bk.conf", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("sed -i 's/server ntp.example.org/server ntp.example.org\\n\\nserver \
#{server_ip}/g' ntpd.conf;cat ntpd.conf;cd", @equipment['dut1'].prompt, 30)
end

# function to run ros demo
def run_ros(pass_crit)
  @equipment['dut1'].send_cmd("cd /opt/ros/indigo/bin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("roscore > roscore.log 2>&1 &", @equipment['dut1'].prompt, 10)
  sleep(20)
  @equipment['dut1'].send_cmd("rosrun roscpp_tutorials talker > ros_talker.log 2>&1 &", \
                               @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("rosrun roscpp_tutorials listener > ros_listener.log 2>&1 &", \
                               @equipment['dut1'].prompt, 10)
  sleep(10)
  @equipment['dut1'].send_cmd("kill $(jobs -p); echo 'Closing Application.'", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("jobs -p", @equipment['dut1'].prompt, 20)
  sleep(10)
  @equipment['dut1'].send_cmd("cat roscore.log && cat ros_talker.log && cat ros_listener.log", \
                              @equipment['dut1'].prompt, 20)
  dut_log = @equipment['dut1'].response
  if @equipment['dut1'].timeout? or !(dut_log =~ Regexp.new("(#{pass_crit})"))
    raise "Failed to match constraint or test timed out."
  end
end

# function to configure server path
def configure_server(dut_ip, server_ip)
  @equipment['server1'].send_cmd("export ROS_MASTER_URI=http://#{dut_ip}:11311", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("export ROS_IP=#{server_ip}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("export ROS_HOSTNAME=#{server_ip}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("/opt/ros/indigo/setup.bash", @equipment['server1'].prompt, 10)
end
