#  Downloads specified package in destination directory
def download_package(package, dest_dir)
  @equipment['server1'].send_sudo_cmd("wget -N -P #{dest_dir} #{package}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chmod 777 #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chown nobody #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
end

# Transfers files from host to dut
def transfer_to_dut(file_name, server_ip, dut = @equipment['dut1'])
  dut.send_cmd("tftp -g -r #{file_name} #{server_ip}", dut.prompt, 10)
  dut.send_cmd("ls -l", dut.prompt, 10)
end