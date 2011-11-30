require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  #send_adb_cmd("shell am start -W -n #{@test_params.params_chan.file_copy_intent[0]} --activity-single-top")
  devices = {}
  test_result = ''
  @test_params.params_chan.devices.each do |current_device|
    cur_dev = current_device.split(':')
    devices[cur_dev[0]] = {'fs_type' => cur_dev[1]}
  end
  dev_mnt_regex = {'usb' => /(sd.)(\d+)/, 'mmc/sd' => /(mmcblk0p)(\d+)/, 'nand' => /(mtdblock)(\d+)/, 'sata' =>  /(sd.)(\d+)/}
  dev_string = send_adb_cmd('shell ls /dev/block')
  devices.each do |device, fs_type_node|
    fs_type = fs_type_node['fs_type']
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
    fs_type_node['dev_node'] = dev_node
    mnt_string = send_adb_cmd('shell mount')
    mnt_regex = mnt_string.match(/\/dev\/block\/#{dev_node}\s+.*?\s+(.*?)\s+\w+.+?/i)
    raise device + ' device file system does not match file system required for the test ' if mnt_regex && mnt_regex.captures[0].strip.downcase != fs_type.downcase
    if !mnt_regex
      send_adb_cmd("shell mkdir /mnt/#{device}_file_cp_tst")
      mount_resp = send_adb_cmd("shell mount -t  #{fs_type} /dev/block/#{dev_node} /mnt/#{device}_file_cp_tst")
      raise "Unable to mount " + device + " device for testing\n" + mount_resp if mount_resp.match(/^\w+/)
    end
  end
  cycle_duration = -1
  cycle_duration = @test_params.params_chan.test_duration_min[0].to_i * 60 if @test_params.params_chan.instance_variable_defined?(:@test_duration_min)
  srand(1234)
  @results_html_file.add_paragraph("")
  @results_html_file.add_paragraph("Random generator seed: 1234")
  start_time = Time.now
  old_iter_dev = ['start']
  dev_per_cycle = @test_params.params_chan.dev_per_cycle[0].to_f 
  begin 
    send_events_for('__home__')
    default_iter_dev = devices.keys
    iter_dev = []
    while default_iter_dev.length > 1 do
      iter_dev << default_iter_dev.delete_at(rand(default_iter_dev.length))
    end
    iter_dev << default_iter_dev[0]
    iter_dev = (iter_dev * (dev_per_cycle/iter_dev.length.to_f).ceil)[0..(dev_per_cycle-1)] if iter_dev.length < dev_per_cycle
    iter_dev.reverse! if iter_dev == old_iter_dev
    puts "Copy sequence is: #{iter_dev.to_s}"
    intent_string = "shell am start -W -n #{@test_params.params_chan.file_copy_intent[0]} --activity-single-top -e numDev #{iter_dev.length} -e fileSize #{@test_params.params_chan.file_size[0]} -e fileBaseName #{@test_params.params_chan.file_base_name[0]} -e source #{devices[iter_dev[0]]['dev_node']}"
    1.upto(iter_dev.length - 1) do |i|
      intent_string += " -e target#{i} #{devices[iter_dev[i]]['dev_node']}"
    end
    send_adb_cmd("logcat -c")
    send_adb_cmd(intent_string)
    copy_result=send_adb_cmd("logcat -d -s #{@test_params.params_chan.adb_copy_filter[0]}")
    last_index=0
    cp_time = Time.now
    while !copy_result.index(/Finished\s+copying\s+files\s+between\s+devices\s+!!!!!!!/im)
      sleep 5
      copy_result = send_adb_cmd("logcat -d -s #{@test_params.params_chan.adb_copy_filter[0]}")
      if (Time.now - cp_time) > @test_params.params_chan.file_cp_time_min[0].to_i * 60
          current_index = copy_result.index(/Copying\s+\S+\s+to\s\S+$/im,last_index)
          if current_index != last_index
             cp_time = Time.now
             last_index = current_index
          elsif !copy_result.index(/Finished\s+copying\s+files\s+between\s+devices\s+!!!!!!!/im)
             test_result += "Copy operation between 2 devices has not ended in #{@test_params.params_chan.file_cp_time_min[0]} minutes, during copy sequence #{iter_dev.to_s}"
             break
          end
      end
    end
    if test_result == ''
      source_file = copy_result.match(/Source\s*=\s*(\S+)/).captures[0]
      target_files = copy_result.scan(/Target\d+\s*=\s*(\S+)/)
      src_md5sum = get_md5sum_for(source_file)
      target_files.each_index do |idx|
        if src_md5sum != get_md5sum_for(target_files[idx][0])
          test_result += "Problem when copying file from #{iter_dev[idx]} to #{iter_dev[idx+1]} during sequence #{iter_dev.to_s}"
          break
        end
      end
    end
    old_iter_dev=iter_dev
  end while cycle_duration > (Time.now - start_time) && test_result == ''
  ensure
    if test_result == ''
      set_result(FrameworkConstants::Result[:pass], "File copied successfully")
    else
      set_result(FrameworkConstants::Result[:fail], "Problem while copying file:\n"+test_result)
    end
end

def get_md5sum_for(file)
  local_file = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s,'file_copy_temp.bin')
  FileUtils.mkdir_p(File.dirname(local_file))
  send_adb_cmd("pull #{file} #{local_file}")
  send_host_cmd("md5sum #{local_file}")
  send_host_cmd("rm #{local_file}")
end







