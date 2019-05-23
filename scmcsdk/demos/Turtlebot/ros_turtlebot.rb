require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../common_utils/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  pass_crit = @test_params.params_chan.pass_crit[0]
  fail_crit = @test_params.params_chan.fail_crit[0]
  # get Server ip address
  server_ip = @equipment['server1'].telnet_ip
 begin
    dut_ip = get_dut_ip()  # get EVM ip address
    configure_dut(dut_ip, server_ip)
    run_ros_turtlebot(pass_crit, fail_crit, dut_ip, server_ip)
    set_result(FrameworkConstants::Result[:pass], "Test Passed. ROS Turtlebot demo Passed.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
 end
end

def clean
    self.as(LspTestScript).clean
end
# function to configure dut path
def configure_dut(dut_ip, server_ip)
  @equipment['dut1'].send_cmd("cd /usr/bin/;ls -l *python*;ln -s -f python3 python.python;ln -s -f python3-config python-config.python;ls -l *python*;cd", \
                             @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_ROOT=/opt/ros/indigo", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export PATH=$PATH:/opt/ros/indigo/bin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export LD_LIBRARY_PATH=/opt/ros/indigo/lib", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export PYTHONPATH=/usr/lib/python3.5/site-packages:/opt/ros/indigo/lib/python3.5/site-packages", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_MASTER_URI=http://#{dut_ip}:11311", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_IP=#{dut_ip}", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_HOSTNAME=#{dut_ip}", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export CMAKE_PREFIX_PATH=/opt/ros/indigo", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("export ROS_PACKAGE_PATH=/opt/ros/indigo/share", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("touch /opt/ros/indigo/.catkin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("ntpd -s", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("source /opt/ros/indigo/setup.bash", @equipment['dut1'].prompt, 10)
end

# function to run ros turtlebot demo
def run_ros_turtlebot(pass_crit, fail_crit, dut_ip, server_ip)
  @equipment['dut1'].send_cmd("roscore > roscore.log 2>&1 &", @equipment['dut1'].prompt, 10)
  sleep(10)
  configure_server(dut_ip, server_ip)
  sleep(20)
  @equipment['dut1'].send_cmd("roslaunch turtlebot_bringup minimal.launch mmwave_device:=6843 > turtlebot_bringup.log 2>&1 &", \
                             @equipment['dut1'].prompt, 10)
  sleep(30)
  @equipment['dut1'].send_cmd("roslaunch turtlebot_mmwave_launchers radar_navigation.launch > radar_navigation.log 2>&1 &", \
                             @equipment['dut1'].prompt, 10)
  sleep(30)
  @equipment['dut1'].send_cmd("cd /opt/ros/indigo/share/turtlebot_mmwave_launchers/scripts/", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("./start_nav.sh > ~/navigation.log 2>&1 &", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cd", @equipment['dut1'].prompt, 10)
  sleep(10)
  cleanup_ros_jobs()
  sleep(10)
  @equipment['dut1'].send_cmd("cat roscore.log && cat turtlebot_bringup.log && cat radar_navigation.log && cat navigation.log", \
                                @equipment['dut1'].prompt, 10)
  dut_log = @equipment['dut1'].response
  server_log = @equipment['server1'].response
  if @equipment['dut1'].timeout?
    raise "Failed due to Time out"
  elsif !(dut_log =~ Regexp.new("(#{pass_crit})"))
      raise "Failed to match constraint or test timed out."
  elsif (dut_log =~ Regexp.new("(#{fail_crit})"))
      raise "Log contains negative criteria #{fail_crit}"
  end
end

# function to configure server path
def configure_server(dut_ip, server_ip)
  @equipment['server1'].send_cmd("export ROS_MASTER_URI=http://#{dut_ip}:11311", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("export ROS_IP=#{server_ip}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("export ROS_HOSTNAME=#{server_ip}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("source /opt/ros/indigo/setup.bash", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("roslaunch turtlebot_bringup description.launch > turtlebot_bringup_description.log 2>&1 ", \
                                @equipment['server1'].prompt, 10)
  sleep(5)
  @equipment['server1'].send_cmd("cat turtlebot_bringup_description.log", @equipment['server1'].prompt, 10)
end

# function to clean up ROS jobs
def cleanup_ros_jobs()
   @equipment['dut1'].send_cmd("kill $(jobs -p); echo 'Closing Application.'", @equipment['dut1'].prompt, 20)
   @equipment['dut1'].send_cmd("jobs -p", @equipment['dut1'].prompt, 20)
   @equipment['server1'].send_cmd("kill $(jobs -p); echo 'Closing Application.'", @equipment['server1'].prompt, 20)
   @equipment['server1'].send_cmd("jobs -p", @equipment['server1'].prompt, 20)
end
