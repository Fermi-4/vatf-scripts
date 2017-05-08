#  Downloads specified package in destination directory
def download_package(package,dest_dir)
  @equipment['server1'].send_sudo_cmd("wget -N -P #{dest_dir} #{package}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chmod 777 #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chown nobody #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
end

# Transfers files from host to dut
def transfer_to_dut(file_name,server_ip)
  @equipment['dut1'].send_cmd("tftp -g -r #{file_name} #{server_ip}", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("ls -l", @equipment['dut1'].prompt,10)
end

# Transfers files from dut to log server
def copy_dlpsdk_scan_file_to_server(path,file,dut_ip)
  log_tm = Time.now.strftime("%d_%m_%y_%H_%M_%S")
  dlpsdk_logs_subdir = "dlpsdk_scan_files"
  @equipment['dut1'].send_cmd("cd #{path}", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cp *#{file} #{log_tm}#{file}", @equipment['dut1'].prompt,10)
  dlpsdk_scan_file = File.join(@linux_temp_folder, "#{log_tm}#{file}")
  scp_pull_file(dut_ip, File.join(path, "#{log_tm}#{file}"), dlpsdk_scan_file)
  host_file_ref = upload_file(dlpsdk_scan_file)
  @equipment['dut1'].send_cmd("rm #{log_tm}#{file}", @equipment['dut1'].prompt,10)
  if host_file_ref
    host_logs_dir = File.join(File.dirname(host_file_ref[0]), dlpsdk_logs_subdir)
    @equipment['server1'].send_cmd("mkdir -p #{host_logs_dir}", @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("cd #{host_logs_dir}; mv ../#{log_tm}#{file} .", @equipment['server1'].prompt, 10)
    report_file_web_link = host_file_ref[1].gsub("#{log_tm}#{file}", dlpsdk_logs_subdir)
  else
    puts "Unable to fetch logs from dut!!!"
    @equipment['server1'].log_info("Unable to fetch logs from dut!!!")
    report_file_web_link = nil
  end
  return report_file_web_link
end
