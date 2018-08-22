require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../common_utils/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  pass_crit = @test_params.params_chan.pass_crit[0]
  listener = @test_params.params_chan.listener[0]
  # get Server ip address
  server_ip = @equipment['server1'].telnet_ip
 begin
    dut_ip = get_dut_ip()  # get EVM ip address
    configure_dut(dut_ip, server_ip)
    run_ros(pass_crit, listener, dut_ip, server_ip)
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
def run_ros(pass_crit, listener, dut_ip, server_ip)
  @equipment['dut1'].send_cmd("cd /opt/ros/indigo/bin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("roscore > roscore.log 2>&1 &", @equipment['dut1'].prompt, 10)
  sleep(20)
  @equipment['dut1'].send_cmd("rosrun roscpp_tutorials talker > ros_talker.log 2>&1 &", \
                               @equipment['dut1'].prompt, 10)
  if listener == "dut"
    @equipment['dut1'].send_cmd("rosrun roscpp_tutorials listener > ros_listener.log 2>&1 &", \
                                 @equipment['dut1'].prompt, 10)
    sleep(10)
    cleanup_ros_jobs(listener)
    sleep(10)
    @equipment['dut1'].send_cmd("cat roscore.log && cat ros_talker.log && cat ros_listener.log", \
                                @equipment['dut1'].prompt, 20)
    dut_log = @equipment['dut1'].response
    if @equipment['dut1'].timeout?
      raise "Failed due to Time out"
    elsif !(dut_log =~ Regexp.new("(#{pass_crit})"))
      raise "Failed to match constraint or test timed out."
    end
  else
    configure_server(dut_ip, server_ip)
    @equipment['server1'].send_cmd("source /opt/ros/indigo/bin/start-ros.sh > ros_listener.log 2>&1 &", \
                                  @equipment['server1'].prompt, 10)
    sleep(10)
    cleanup_ros_jobs(listener)
    sleep(10)
    @equipment['dut1'].send_cmd("cat roscore.log && cat ros_talker.log", @equipment['dut1'].prompt, 20)
    dut_log = @equipment['dut1'].response
    @equipment['server1'].send_cmd("cat ros_listener.log", @equipment['server1'].prompt, 20)
    server_log = @equipment['server1'].response
    if @equipment['dut1'].timeout?
      raise "Failed due to Time out"
    elsif !(server_log =~ /#{pass_crit}/)
      raise "Failed to match constraint or test timed out."
    end
  end
end

# function to configure server path
def configure_server(dut_ip, server_ip)
  @equipment['server1'].send_sudo_cmd("touch /opt/ros/indigo/bin/start-ros.sh", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chmod 777 /opt/ros/indigo/bin/start-ros.sh", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("echo \"export ROS_MASTER_URI=http://#{dut_ip}:11311\" > /opt/ros/indigo/bin/start-ros.sh",\
                                 @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("echo \"export ROS_IP=#{server_ip}\" >> /opt/ros/indigo/bin/start-ros.sh", \
                                @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("echo \"export ROS_HOSTNAME=#{server_ip}\" >> /opt/ros/indigo/bin/start-ros.sh", \
                                @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("echo \"source /opt/ros/indigo/setup.bash\" >> /opt/ros/indigo/bin/start-ros.sh", \
                                @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("echo \"cd /opt/ros/indigo/bin\" >> /opt/ros/indigo/bin/start-ros.sh", \
                                @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("echo \"rosrun roscpp_tutorials listener\" >> /opt/ros/indigo/bin/start-ros.sh", \
                               @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("cat start-ros.sh", @equipment['server1'].prompt, 10)
end

# function to Clean up ROS jobs
def cleanup_ros_jobs(listener)
   @equipment['dut1'].send_cmd("kill $(jobs -p); echo 'Closing Application.'", @equipment['dut1'].prompt, 20)
   @equipment['dut1'].send_cmd("jobs -p", @equipment['dut1'].prompt, 20)
   if listener == "server"
     @equipment['server1'].send_cmd("kill $(jobs -p); echo 'Closing Application.'", @equipment['server1'].prompt, 20)
     @equipment['server1'].send_cmd("jobs -p", @equipment['server1'].prompt, 20)
   end
end
