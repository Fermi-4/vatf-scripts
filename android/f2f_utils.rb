require File.dirname(__FILE__)+'/../LSP/A-Video/f2f_utils'
#Function to fetch the test file in the dut and host
def get_file_from_url(url, ref_file_url=nil, dut=@equipment['dut1'], host=@equipment['server1'])
  r_file_url = ref_file_url ? ref_file_url : url
  file_name = File.basename(url)
  r_file_name = File.basename(r_file_url)
  host_path = File.join(@linux_temp_folder, r_file_name)
  dut_path = File.join(@linux_dst_dir, file_name)
  wget_file(r_file_url, host_path, host)
  response = dut.send_adb_cmd("push -p #{host_path} #{dut_path}")
 	[host_path, dut_path]
end

def wget_file(url, path, sys=@equipment['server1'])
  sys.send_cmd("wget --no-proxy --tries=1 -T10 #{url} -O #{path}", sys.prompt, 300)
  sys.send_cmd("wget #{url} -O #{path}", sys.prompt, 300) if sys.response.match(/failed/im)
  raise "Host is unable to fetch file from #{url}" if sys.response.match(/error/im)
end

