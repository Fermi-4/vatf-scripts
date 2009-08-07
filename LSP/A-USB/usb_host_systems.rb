class USBHost
    attr_accessor :executable_path
	
	def initialize(host_driver_instance)
		@host = host_driver_instance
		@executable_path = host_driver_instance.executable_path.sub(/(\/|\\)$/,'')+'/'
	end
end

class WinHost < USBHost
	
	def mount_usb_device(mnt_params)
		params = {"dev_drives" => '', "host_mount_point" => '', "timeout" => 20, "format_flag" => true}.merge(mnt_params)
		result = Array.new
		params["dev_drives"].each do |current_dev|
			@host.send_cmd('dir '+current_dev.to_s,/.+#{@host.prompt}/im)
			sleep 2
			format_device({"dev_drive" => current_dev.to_s, "timeout" => params["timeout"]}) if @host.response.downcase.include?('the volume does not contain a recognized file system') && params["format_flag"]
		
		puts " "
		puts "---------------------------------- usb_host_systems - mount_usb_device -- 20 ----------------------------------"
				puts result
		puts "----------------------------------- usb_host_systems - mount_usb_device --- 22 ---------------------------------"

		
		end
		params["dev_drives"]
	end

	def unmount_usb_device(params = {"dev_drives" => ''})
	end

	def check_usb_host_controller(ch_params)
		params = {"host_controller_type" => ''}.merge(ch_params)
		@host.send_cmd('driverquery',/^usb#{params["host_controller_type"]}/)
	end

	def check_host_drives
		@host.send_cmd('fsutil fsinfo drives',/#{@host.prompt}/)
	    @host.response.scan(/(\w+:)\\/)
	end

	def format_device(fmt_params)
		params = {"dev_drive" => '', "timeout" => 10}.merge(fmt_params)
		puts " "
    puts "usb_host_systems-1 - WinHost - Formatting drive: #{params["dev_drive"]}"
	  result = false
		
		puts " "
		puts "---------------------------------- usb_host_systems - format_device start -- 50 ----------------------------------"

		return result if !@host.send_cmd('format '+ params["dev_drive"] +' /X /FS:FAT32',/(DRIVE\s*#{params["dev_drive"]}\s*WILL\s*BE\s*LOST.\s*Proceed\s*with\s*Format\s*\(Y\/N\)\?)|(.*and\s+press\s+ENTER\s+when\s+ready)/im)
		
		puts result
		puts "----------------------------------- usb_host_systems - format_device end --- 55 ---------------------------------"
		
		if @host.response.match(/and\s+press\s+ENTER\s+when\s+ready/im)
			return result if !@host.send_cmd('',/Volume\s*label.*\?/,params["timeout"]) 
		else
			return result if !@host.send_cmd('y',/Volume\s*label.*\?/,params["timeout"])
		end
		
		puts "----------------------------------- usb_host_systems - format_device end --- 63 ---------------------------------"

		result = @host.send_cmd('',/Format\s*complete.*Volume\s*Serial\s*Number\s*is.*/im)
		
		ensure
		  result
	end

	def check_disk(ch_params)
	  params = {"dev_drive" => '', "host_mount_point" => '', "timeout" => 60}.merge(ch_params)
		result = false
		result = @host.send_cmd('chkdsk '+ params["dev_drive"] ,/.*\d+\s*allocation\s*units\s*available\s*on\s*disk.*/im,params["timeout"])
		ensure
		  result
	end

	def copy_file(cp_params)
	  params = {"src_file" => '', "dst_file" => '', "f_size" => '512'}.merge(cp_params)
    puts "usb_host_systems-2 - WinHost - Copying file: #{params["src_file"]}"
		result = false
		file_size = params["f_size"].sub('G','000000000')
		file_size = file_size.sub('M','000000')
		
		@host.send_cmd('dir #{params["src_file"]',/.*/im,15)
		sleep 5
		
		return result if !@host.send_cmd("copy /B /Y /V \"#{params["src_file"].gsub('/','\\')}\" \"#{params["dst_file"].gsub('/','\\')}\"",/[1-9]\d*\s*file\(s\)\s*copied.*/im,260*([10,file_size.to_i/1000000000].max))
		sleep 3
		puts "<------------------------------- usb_host_systems - copy_file --- 81 ------------------------------->"
		puts result
		puts "<------------------------------- usb_host_systems - copy_file --- 83 ------------------------------->"
		
		result = file_check({"ref_file" => params["src_file"].gsub('/','\\'), "test_file" => params["dst_file"].gsub('/','\\')})
		ensure
		  result
	end
	
	def file_check(fc_params)
	  params = {"ref_file" => '', "test_file" => ''}.merge(fc_params)
    puts "usb_host_systems-3 -WinHost - Checking file: #{params["ref_file"]}"
		result = false
		result = @host.send_cmd("fc /B \"#{params["ref_file"].gsub('/','\\')}\" \"#{params["test_file"].gsub('/','\\')}\"",/FC:\s*no\s*differences\s*encountered\s*/im)
		ensure
		  result
	end

	def make_dir(mk_params)
	    params = {"dir_path" => ''}.merge(mk_params)
		result = false
		return result if !@host.send_cmd("mkdir \"#{params["dir_path"].gsub('/','\\')}\"",/^\w:.*#{@host.prompt}/i)
		result = dir_check({"dir_path" => params["dir_path"]})
		ensure
		  result
	end

	def dir_check(ch_params)
	    params = {"dir_path" => ''}.merge(ch_params)
		result = false
		@host.send_cmd("dir \"#{params["dir_path"].gsub('/','\\').sub(/\\$/,'')}\"",/^\w:.*#{@host.prompt}/i)
		result = !@host.response.include?('File Not Found')
		ensure
		  result
	end

	def remove_dir(rm_params)
	    params = {"dir_path" => ''}.merge(rm_params)
		result = false
		@host.send_cmd("rmdir /S /Q \"#{params["dir_path"].gsub('/','\\').sub(/\*+$/,'')}\"",/#{@host.prompt}/im)
		result = !dir_check({"dir_path" => params["dir_path"].gsub('/','\\').sub(/\*+$/,'')})
		ensure
		  result
	end

	def delete_file(dl_params)
	    params = {"file_path" => ''}.merge(dl_params)
      puts "usb_host_systems-4 - WinHost - Deleting file: #{params["file_path"]}"
		result = false
		@host.send_cmd("del /Q \"#{params["file_path"].gsub('/','\\')}\"",/#{@host.prompt}/im)
		result = !dir_check({"dir_path" => params["file_path"].gsub('/','\\')})
		ensure
		  result
	end

	def move_file(mv_params)
	    params = {"file_path" => '', "new_file_path" => ''}.merge(mv_params)
      puts "usb_host_systems-5 -WinHost - Moving file: #{params["file_path"]}"
		result = false
		@host.send_cmd("move /Y \"#{params["file_path"].gsub('/','\\')}\" \"#{params["new_file_path"].gsub('/','\\')}\"",/#{@host.prompt}/im)
		result = dir_check({"dir_path" => params["new_file_path"].gsub('/','\\')}) && !dir_check({"dir_path" => params["file_path"].gsub('/','\\')})
		ensure
		  result
	end

	def rename_file(rn_params)
	    params = {"file_path" => '', "new_file_name" => ''}.merge(rn_params)
      puts "usb_host_systems-6 - WinHost - Copying file: #{params["file_path"]}"
		result = false
		@host.send_cmd("rename \"#{params["file_path"].gsub('/','\\')}\" \"#{params["new_file_name"].gsub('/','\\')}\"",/#{@host.prompt}/im)
		result = dir_check({"dir_path" => File.dirname(params["file_path"].gsub('\\','/')).gsub('/','\\')+'\\'+params["new_file_name"].gsub('/','\\')}) && !dir_check({"dir_path" => params["file_path"].gsub('/','\\')})
		ensure
		  result
	end

	def defrag_device(df_params)
	    params = {"dev_drive" => ''}.merge(df_params)
		result = false
		result = @host.send_cmd('defrag '+ params["dev_drive"],/Defragmentation\s*Report.*Total.*Free.*Fragmented.*fragmentation\)/im)
		ensure
		  result
	end

	def change_properties(pr_params)
		params = {"file_path" => ''}.merge(pr_params)
		result = false
		@host.send_cmd("attrib -S #{params["file_path"]}",/#{@host.prompt}/im) 
		@host.send_cmd("attrib +S #{params["file_path"]}",/#{@host.prompt}/im) 
		return result if !@host.send_cmd("move /Y \"#{params["file_path"].gsub('/','\\')}\" \"#{params["file_path"].gsub('/','\\')}\"",/.*The\s*system\s*cannot\s*find\s*the\s*file\s*specified.*/im)
		@host.send_cmd("attrib -S #{params["file_path"]}",/#{@host.prompt}/im)
		result = !@host.send_cmd("move /Y \"#{params["file_path"].gsub('/','\\')}\" \"#{params["file_path"].gsub('/','\\')}\"",/.*Access\s*is\s*denied.*/im)  
		ensure
		  result
	end
	
	def get_usb_system_string	
		@host.send_cmd('"'+@host.executable_path.sub(/(\/|\\)$/,'')+"/USBView2.exe"+'"',/#{@host.prompt}/)
		@host.response
	end

end

class LinuxHost < USBHost

  def send_cmd(command,timeout = 20)
		@host.send_cmd(command,/#{command.slice(/^[^\s]+/)}.+#{@host.prompt}/im,timeout)
		@host.send_cmd("echo $?",/echo\s+\$\?\s+0.*#{@host.prompt}/im,60)
	end

	def mount_usb_device(mnt_params)
    params = {"dev_drives" => '', "fs" => 'ext3', "host_mount_point" => '', "timeout" => 2700, "format_flag" => true}.merge(mnt_params) #this timeout was 60
		result = Array.new
		params["dev_drives"].each do |current_dev|
			current_mount_point = params["host_mount_point"].sub(/\/$/,'')+'/'+current_dev.to_s+'_mnt_dir'
			send_cmd('mkdir -p '+current_mount_point) if !send_cmd('ls '+current_mount_point)
      puts "usb_host_systems-12a - LnxHost - Mounting USB Device: #{current_mount_point}"
			
			if !send_cmd("mount -t #{params["fs"]} /dev/#{current_dev} #{current_mount_point}")
        puts "usb_host_systems-12b - LnxHost - Mounting USB Device: #{current_mount_point}"
				format_device({"dev_drive" => current_dev.to_s, "fs" => params["fs"], "timeout" => params["timeout"]}) if params["format_flag"]
				raise 'Unable to mount usb device on host' if !send_cmd("mount -t #{params["fs"]} /dev/#{current_dev} #{current_mount_point}")
			end
			result << current_mount_point
		end
		result
	end

	def unmount_usb_device(um_params)
        params = {"dev_drives" => '', "host_mount_point" => ''}.merge(um_params)
        
				if params["host_mount_point"] == '' or params["host_mount_point"] == nil
					params["dev_drives"].each do |current_dev|
          puts "usb_host_systems-7a - LnxHost - Unmounting: USB device /dev/#{current_dev}"
			    send_cmd("umount /dev/#{current_dev}")
		    end
	    else
			params["host_mount_point"].each do |mount_point|
          puts "usb_host_systems-7b - LnxHost - Unmounting: USB device #{mount_point}"
			    send_cmd("umount #{mount_point}")
		    end
		end
	end

	def check_usb_host_controller(ch_params)
		params = {"host_controller_type" => ''}.merge(ch_params)	
		@host.send_cmd('cat /proc/modules',/^#{params["host_controller_type"]}_hcd.+Live.+/)
	end

	def check_host_drives	
		@host.send_cmd('ls /dev',/.+\/dev.+#{@host.prompt}/im)
		result = @host.response.scan(/(sd.\d+)/)
		result = [] if !result
		result
	end

	def format_device(fmt_params)
    #params = {"dev_drive" => '', "fs" => 'ext3', "timeout" => 20}.merge(fmt_params)
		timeout = 30
		params = {"dev_drive" => '', "fs" => 'ext3', "timeout" => 2600}.merge(fmt_params)     # 03-12-2009 - increased time delay due to slower usb 1.1 transfer time (from 20 to 2600).
    puts "usb_host_systems-8a - LnxHost - Formatting: USB device /dev/#{params["dev_drive"]}"
	    result = false
	    send_cmd("mkfs -t #{params["fs"]} /dev/#{params["dev_drive"]}",params["timeout"])
		ensure
      #puts "usb_host_systems-8b - LnxHost - Formatting Completed: USB device /dev/#{params["dev_drive"]}. Result: #{result}"
		  result
	end

	def check_disk(ch_params)
	    params = {"dev_drive" => '',  "fs" => 'ext2', "host_mount_point" => '', "timeout" => 2600}.merge(ch_params)   # 03-12-2009 - increased time delay due to slower usb 1.1 transfer time (from 120 to 2600).
      puts "usb_host_systems-9a - LnxHost - Checking Disk: USB device /dev/#{params["dev_drive"]}"
	    return true if params['fs'] == 'vfat'
      result = false
      unmount_usb_device({"dev_drives" => [params["dev_drive"]]})
      result = send_cmd('e2fsck -n /dev/'+params["dev_drive"], 600)
      mount_usb_device({"dev_drives" => [params["dev_drive"]], "host_mount_point" => params["host_mount_point"]})
      result
    
      sleep 10
		ensure
      puts "usb_host_systems-9b - LnxHost - Disk Check Completed: USB device /dev/#{params["dev_drive"]}"
		  result
	end

	def copy_file(cp_params)
	    params = {"src_file" => '', "dst_file" => '', "f_size" => '512'}.merge(cp_params)
      puts "usb_host_systems-10a - LnxHost - Copying File: #{params["src_file"]} to #{params["dst_file"]}"
      result = false
      file_size = params["f_size"].sub('G','000000000')
      file_size = file_size.sub('M','000000')
      return result if !send_cmd("cp -f #{params["src_file"].gsub('\\','/')} #{params["dst_file"].gsub('\\','/')}",120*([10,file_size.to_i/1000000000].max)+2000)
      result = file_check({"ref_file" => params["src_file"].gsub('\\','/'), "test_file" => params["dst_file"].gsub('\\','/')})
      ensure
		  puts "usb_host_systems-10b - LnxHost - File Copying Completed: #{params["dst_file"]}. Result: #{result}"
      result
	end

	def file_check(fc_params)
	    params = {"ref_file" => '', "test_file" => ''}.merge(fc_params)
      puts "usb_host_systems-11 - LnxHost - Checking File: #{params["test_file"]}"
      result = false
      result = send_cmd("cmp #{params["ref_file"].gsub('\\','/')} #{params["test_file"].gsub('\\','/')}",2600)   #03-12-2009 - change from 600 to 2600 to account for usb1.1 delay
      ensure
		  result
	end

	def make_dir(mk_params)
	    params = {"dir_path" => ''}.merge(mk_params)
      result = false
      return result if !send_cmd("mkdir -p #{params["dir_path"].gsub('\\','/')}")
      result = dir_check({"dir_path" => params["dir_path"]})
      ensure
		  result
	end

	def dir_check(ch_params)
	    params = {"dir_path" => ''}.merge(ch_params)
      result = false
	    result = send_cmd("ls #{params["dir_path"].gsub('\\','/')}")
		ensure
		  result
	end

	def remove_dir(rm_params)
	    params = {"dir_path" => ''}.merge(rm_params)
      result = false
	    result = send_cmd("rm -rf #{params["dir_path"].gsub('\\','/')}")
		ensure
		  result
	end

	def delete_file(dl_params)
	    params = {"file_path" => ''}.merge(dl_params)
      result = false
      result = send_cmd("rm -f #{params["file_path"].gsub('\\','/')}")
		ensure
		  result
	end

	def move_file(mv_params)
	    params = {"file_path" => '', "new_file_path" => ''}.merge(mv_params)
      result = false
      puts "usb_host_systems-12 - LnxHost - Moving File: #{params["file_path"]} to #{params["new_file_path"]}"
      send_cmd("mv -f #{params["file_path"].gsub('\\','/')} #{params["new_file_path"].gsub('\\','/')}")
      result = dir_check({"dir_path" => params["new_file_path"].gsub('\\','/')}) && !dir_check({"dir_path" => params["file_path"].gsub('\\','/')})
		ensure
		  result
	end

	def rename_file(rn_params)
	    params = {"file_path" => '', "new_file_name" => ''}.merge(rn_params)
		result = false
	    result = move_file({"file_path" => params["file_path"], "new_file_path" => File.dirname(params["file_path"].gsub('\\','/'))+'/'+params["new_file_name"].gsub('\\','/')})
		ensure
		  result
	end

	def defrag_device(df_params)
	    params = {"dev_drive" => ''}.merge(df_params)
		true
	end

	def change_properties(pr_params)
		params = {"file_path" => ''}.merge(pr_params)
		result = false
    puts "usb_host_systems-13a - LnxHost - Changing File Properties: #{params["file_path"]}. Result: #{result}"
		return result if !send_cmd("chmod 000 #{params["file_path"].gsub('\\','/')}")
    puts "usb_host_systems-13b - LnxHost - Checking File Properties: #{params["file_path"]}. Result: #{result}"
		@host.send_cmd("ls -l #{params["file_path"].gsub('\\','/')}",/ls -l.+#{@host.prompt}/im)
		return result if !@host.response.match(/^-{10}\s+.+/i)
    puts "usb_host_systems-13c - LnxHost - Changing File Properties: #{params["file_path"]}. Result: #{result}"
		return result if !send_cmd("chmod 755 #{params["file_path"].gsub('\\','/')}")
		@host.send_cmd("ls -l #{params["file_path"].gsub('\\','/')}",/ls -l.+#{@host.prompt}/im)
		return true if @host.response.match(/^[-rwx]{10}\s+.+/i)
		ensure
      puts "usb_host_systems-13d - LnxHost - Completed Changing File Properties: #{params["file_path"]}. Result: #{result}"
		  result
	end

	def get_usb_system_string(pr_params={})
		params = {"vendor" => ''}.merge(pr_params)
		if params['vendor'] != ''
			@host.send_cmd("lsusb -d #{params['vendor']}: -v",/lsusb -d.*#{@host.prompt}/im)
		else
			@host.send_cmd('lsusb -v',/lsusb -v.*#{@host.prompt}/im)
		end
		@host.response
	end
end