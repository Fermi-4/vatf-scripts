require "rexml/document"
require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  response = ''
  device = @test_params.params_chan.device[0].strip
  fs_type = @test_params.params_chan.file_system[0].strip
  file_size = @test_params.params_chan.test_option[0].match(/-e\s*fileSize\s*([\S]+)/i).captures[0]
  blk_size = @test_params.params_chan.test_option[0].match(/-e\s*blkSize\s*([\S]+)/i).captures[0]
  dev_mnt_regex = {'usb' => /(sd.)(\d+)/, 'mmc/sd' => /(mmcblk0p)(\d+)/, 'nand' => /(mtdblock)(\d+)/ }
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
  
  test_data = run_test(@test_params.params_chan.test_option[0].sub(/-e\s+location\s+#{device}\s+-e/,"-e location #{dev_node} -e"))
  perfdata = []
  current_test = 'storageio_'+blk_size
  if !test_data['perf_data'].empty?
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([[current_test,{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    
    test_data['perf_data'].each do |rege, raw_data|
      data = get_stats(raw_data)
      perfdata << {'name' => data[0][0].downcase.gsub(/\s+/,'_')+'_'+blk_size, 'value' => data[0][1].to_f, 'units' => data[0][2]}
      @results_html_file.add_row_to_table(res_table,[data[0][0], data[0][1], data[0][2]])
    end
  end
  @results_html_file.add_paragraph(test_data['response'],nil,nil,nil)
  ensure
    if test_data && test_data['perf_data']
      set_result(FrameworkConstants::Result[:pass], "StorageIO performance data collected successfully", perfdata)
    else
      set_result(FrameworkConstants::Result[:fail], response+' data is missing')
    end
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




