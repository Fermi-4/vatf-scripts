require "rexml/document"
require File.dirname(__FILE__)+'/android_test_module' 

include AndroidTest
module StorageModule

def run_storage_test(server = @equipment['server1'],initial_bw,flag)  
  response = ''
  pass_fail = 0
  device = @test_params.params_chan.device[0].strip
  fs_type = @test_params.params_chan.file_system[0].strip
  file_size = @test_params.params_chan.test_option[0].match(/-e\s*fileSize\s*([\S]+)/i).captures[0]
  blk_size = @test_params.params_chan.test_option[0].match(/-e\s*blkSize\s*([\S]+)/i).captures[0]
  dev_mnt_regex = {'usb' => /(sd.)(\d+)/, 'mmc/sd' => /(mmcblk0p)(\d+)/, 'nand' => /(mtdblock)(\d+)/, 'sata' =>  /(sd.)(\d+)/}
  dev_string = send_adb_cmd('shell ls /dev/block')
  dev_array = dev_string.scan(dev_mnt_regex[device.downcase])
  dev_node = ''
  dev_partition = -1
  dev_array.each do |dev_info|
    if dev_info[1].to_i > dev_partition
      dev_partition = dev_info[1].to_i
      dev_node = dev_info[0].strip+dev_info[1].strip
    end
  end
  raise device + ' device has not been detected by the kernel' if dev_node == ''
  mnt_string = send_adb_cmd('shell mount')
  
  mnt_regex = mnt_string.match(/\/dev\/block\/#{dev_node}\s+.*?\s+(.*?)\s+\w+.+?/i)
  raise device + ' device file system does not match file system required for the test ' if mnt_regex && mnt_regex.captures[0].strip.downcase != fs_type.downcase
  if !mnt_regex
    send_adb_cmd("shell mkdir /mnt/sio_tst")
    mount_resp = send_adb_cmd("shell mount -t  #{fs_type} /dev/block/#{dev_node} /mnt/sio_tst")
    raise "Unable to mount " + device + " device for testing\n" + mount_resp if mount_resp.match(/^\w+/)
  end
  test_data = nil
  test_data = run_test(@test_params.params_chan.test_option[0].sub(/-e\s+location\s+#{device}\s+-e/,"-e location #{dev_node} -e"))
  perfdata = []   
  current_test = 'storageio_'+blk_size
  if !test_data['perf_data'].empty?
    test_data['perf_data'].each do |rege, raw_data|
      data = get_stats(raw_data)
       perfdata << data[0][1]
    end
  end
 return [perfdata,pass_fail]
end


def run_storage_test_on_resume(server = @equipment['server1'],initial_bw,flag)  
  response = ''
  device = @test_params.params_chan.device[0].strip
  fs_type = @test_params.params_chan.file_system[0].strip
  file_size = @test_params.params_chan.test_option[0].match(/-e\s*fileSize\s*([\S]+)/i).captures[0]
  blk_size = @test_params.params_chan.test_option[0].match(/-e\s*blkSize\s*([\S]+)/i).captures[0]
  dev_mnt_regex = {'usb' => /(sd.)(\d+)/, 'mmc/sd' => /(mmcblk0p)(\d+)/, 'nand' => /(mtdblock)(\d+)/, 'sata' =>  /(sd.)(\d+)/}
  dev_string = send_adb_cmd('shell ls /dev/block')
  dev_array = dev_string.scan(dev_mnt_regex[device.downcase])
  dev_node = ''
  dev_partition = -1
  dev_array.each do |dev_info|
    if dev_info[1].to_i > dev_partition
      dev_partition = dev_info[1].to_i
      dev_node = dev_info[0].strip+dev_info[1].strip
    end
  end
  raise device + ' device has not been detected by the kernel' if dev_node == ''
  mnt_string = send_adb_cmd('shell mount')
  
  mnt_regex = mnt_string.match(/\/dev\/block\/#{dev_node}\s+.*?\s+(.*?)\s+\w+.+?/i)
  raise device + ' device file system does not match file system required for the test ' if mnt_regex && mnt_regex.captures[0].strip.downcase !=  fs_type.downcase
  test_data = nil
  test_data = run_test(@test_params.params_chan.test_option[0].sub(/-e\s+location\s+#{device}\s+-e/,"-e location #{dev_node} -e"))
  perfdata = []
  current_test = 'storageio_'+blk_size
  if !test_data['perf_data'].empty?
    test_data['perf_data'].each do |rege, raw_data|
      data = get_stats(raw_data)
       perfdata << data[0][1]
    end
  end
 
  write_data = perfdata[0].to_i - (initial_bw[0].to_i - 1000)
  read_data  = perfdata[1].to_i - (initial_bw[1].to_i - 1000)
  if  write_data > 0  and read_data > 0
    puts "After Resume #{perfdata[0].to_i}"
    puts "After Resume #{perfdata[1].to_i}"
    puts "After Resume #{initial_bw[0].to_i}"
    puts "After Resume #{initial_bw[1].to_i}"
    pass_fail = 1
  else
    puts "After Resume #{perfdata[0].to_i}"
    puts "After Resume #{perfdata[1].to_i}"
    puts "After Resume #{initial_bw[0].to_i}"
    puts "After Resume #{initial_bw[1].to_i}"
   pass_fail = 0
  end 
 
 return [perfdata,pass_fail]
end


def get_stats(data)
  cur_match = data[0]
  cur_stat = ''
  current_stats = []
  1.upto((data.length)-1) do |i|
    if cur_match.include?(data[i])
      cur_stat += '_' if cur_stat != ''
      cur_stat += data[i] 
    else
      if(cur_stat != '')
        current_stats << cur_stat
        cur_stat = ''
      else
        current_stats << cur_match
      end
      cur_match = data[i]
    end
  end
  if(cur_stat != '')
    current_stats << cur_stat
    cur_stat = ''
  else
    current_stats << cur_match
  end
  current_stats
end

end


