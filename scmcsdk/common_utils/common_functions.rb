#  Downloads specified package in destination directory
def download_package(package, dest_dir, timeout=60)
  @equipment['server1'].send_sudo_cmd("wget -N -P #{dest_dir} #{package}", @equipment['server1'].prompt, timeout)
  @equipment['server1'].send_sudo_cmd("chmod 777 #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chown nobody #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
end

# Transfers files from host to dut
def transfer_to_dut(file_name, server_ip=@equipment['server1'].telnet_ip, dut=@equipment['dut1'], timeout=60)
  dut.send_cmd("tftp -g -r #{file_name} #{server_ip}", dut.prompt, timeout)
  dut.send_cmd("ls -l", dut.prompt, 10)
end

# function to get EVM ip address
def get_dut_ip(interface = "eth0", dut = @equipment['dut1'])
  dut.send_cmd("ifconfig #{interface} | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'", \
                dut.prompt, 10)
  dut_ip = /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/.match(dut.response)
  return dut_ip
end

#function to get rtos/linux build urls
def get_build(release_ver, release_tag, platform_name, evm, os='linux')
  return "http://tigt_qa.gt.design.ti.com/qacm/test_area/PROCESSOR-SDK/#{release_ver}/#{release_ver.gsub('.','_')}_#{release_tag}\
/processor-sdk-#{os}/esd/#{platform_name}/#{release_ver.gsub('.','_')}_#{release_tag}/exports/ti-processor-sdk-#{os}-#{evm}-#{release_ver}\
.#{release_tag}-Linux-x86-Install.bin"
end

#function to install sdk
def install_sdk(sdk_to_install, dir_to_install, timeout=440)
  command = "#{dir_to_install}#{sdk_to_install} --prefix #{dir_to_install}ti --mode unattended"
  @equipment['server1'].send_sudo_cmd("mkdir -p -m 777 #{dir_to_install}ti", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd(command, @equipment['server1'].prompt, timeout)
end
