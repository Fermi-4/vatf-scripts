require File.dirname(__FILE__)+'/../../LSP/A-Video/f2f_utils'
#Function to fetch the test file in the dut and host
def get_file_from_url(url, ref_file_url=nil, dut=@equipment['dut1'], host=@equipment['server1'])
  r_file_url = ref_file_url ? ref_file_url : url
  file_name = File.basename(url)
  r_file_name = File.basename(r_file_url)
  host_path = File.join(@linux_temp_folder, r_file_name)
  dut_path = File.join(@linux_dst_dir, file_name)
  host.send_cmd("wget --no-proxy --tries=1 -T10 #{r_file_url} -O #{host_path}", host.prompt, 300)
  host.send_cmd("wget #{r_file_url} -O #{host_path}", host.prompt, 300) if host.response.match(/failed/im)
  raise "Host is unable to fetch file from #{r_file_url}" if host.response.match(/error/im)
  response = dut.send_adb_cmd("push -p #{host_path} #{dut_path}\n")
 	[host_path, dut_path]
end

