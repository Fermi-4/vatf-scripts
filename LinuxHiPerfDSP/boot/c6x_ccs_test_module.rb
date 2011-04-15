# -*- coding: ISO-8859-1 -*-

require File.dirname(__FILE__)+'/boot'
DUT_DST_DIR='/var/local'


# Default Server-Side Test script implementation for c6x-Linux releases
module C6xCCSTestScript 

    include Boot
    # include C6xKernelModuleNames
    public
    @show_debug_messages = false
    
    def C6xCCSTestScript.nfs_root_path
      @nfs_root_path
    end
    
    def setup
      @equipment['dut1'].set_api('linux-c6x')
      nfs  = @test_params.nfs     if @test_params.instance_variable_defined?(:@nfs)
      kernel = @test_params.kernel     if @test_params.instance_variable_defined?(:@kernel)
      platform_from_db = @test_params.platform.downcase
      @testcase = @test_params.params_chan.instance_variable_get("@testname")[0].to_s
      @platform = platform_from_db
      syslink_bins = @test_params.syslink_bins
    
      nfs_root_path = @equipment['dut1'].nfs_root_path
      if @equipment.has_key?('server1')
      syslink_test_dir = @equipment['server1'].params["syslink_test_dir"]
      if !File.directory?("#{syslink_test_dir}")
        @equipment['server1'].send_sudo_cmd("mkdir -p -m 777  #{syslink_test_dir}", @equipment['server1'].prompt, 10)  
      end
      dss_dir = @equipment['server1'].params["dss_dir"]
      end
      # Telnet to Linux server
      if @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip) and !@equipment['server1'].target.telnet
        @equipment['server1'].connect({'type'=>'telnet'})
      elsif !@equipment['server1'].target.telnet 
        raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
      end
      
      case (platform_from_db)
      when "tomahawk"
        @usb_type = "TCI6486_USB"
      when "faraday"
        @usb_type = "TCI6488_USB"
      else
        raise "Syslink not supported on #{platform_from_db}"
      end
      syslink_apps_reqd = ['syslink.ko', "#{@testcase}app.exe", "#{@testcase}app.ko"]
      
      # Boot DUT
        #Untar NFS
        if nfs 
          fs = nfs
          fs.gsub!(/\\/,'/')
          @equipment['server1'].send_cmd("cp #{@test_params.nfs} #{nfs_root_path}")	
          @equipment['server1'].send_cmd("cd #{nfs_root_path}", @equipment['server1'].prompt, 10)   
          @equipment['server1'].send_sudo_cmd("tar -xvzf #{File.basename(nfs)} ", @equipment['server1'].prompt, 30)
        end
        
        if syslink_bins
          syslink_bins.gsub!(/\\/,'/')
          @equipment['server1'].send_cmd("mkdir -m 777 #{syslink_test_dir}/images/#{platform_from_db}")
          @equipment['server1'].send_cmd("rm -rf #{syslink_test_dir}/images/#{platform_from_db}/*")
          @equipment['server1'].send_cmd("cp #{syslink_bins} #{syslink_test_dir}/images/#{platform_from_db}")
          @equipment['server1'].send_cmd("cd #{syslink_test_dir}/images/#{platform_from_db}", @equipment['server1'].prompt, 10)   
          @equipment['server1'].send_sudo_cmd("tar -xvzf #{File.basename(syslink_bins)} ", @equipment['server1'].prompt, 30)
          syslink_apps_reqd.each { |app|
            @equipment['server1'].send_sudo_cmd("cp #{app} #{nfs_root_path}#{DUT_DST_DIR}", @equipment['server1'].prompt, 30)
          }
          @equipment['server1'].send_sudo_cmd("cp #{kernel} vmlinux", @equipment['server1'].prompt, 30)
        end

        @equipment['server1'].send_sudo_cmd("rm -rf /dev/shm/sem*", @equipment['server1'].prompt, 30)
        @equipment['server1'].send_sudo_cmd("rm -rf /dev/shm/JTI*", @equipment['server1'].prompt, 30)
        @equipment['server1'].send_sudo_cmd("SYSLINK_TEST_DIR=#{syslink_test_dir} #{dss_dir}/dss.sh #{File.dirname(__FILE__)+'/SysLinkTest6472.js'} #{@usb_type} #{@testcase} LE ",/Type any key once syslink test is complete/,660)
        @ipc_reset_vector = @equipment['server1'].response.match(/IpcResetVector for #{@testcase} is (0x([1-9]|[a-e]).+)\s+\*.+/).captures[0]
        @telnet_ip = @equipment['server1'].response.match(/my address is ((?:[0-9].*?\.){3}[0-9].*)/mi).captures[0].to_s  
        @equipment['dut1'].target.platform_info.telnet_ip = @telnet_ip
        @equipment['dut1'].connect({'type'=>'telnet'})
      # Copy executables to NFS server (if filesystem was not specified and there are @target_sources
      if @test_params.params_chan.instance_variable_defined?(:@syslink_bins) && @equipment.has_key?('server1') #&& !nfs && !@test_params.instance_variable_defined?(:@var_nfs) 
          files_array = Array.new
          src = @test_params.params_chan.target_binaries[0].to_s
          debug_puts "target source folder is: #{src}"
          @equipment['server1'].send_cmd("cd #{nfs_root_path}/opt", @equipment['server1'].prompt, 30)
          testbins = File.basename("#{@test_params.params_chan.target_binaries[0]}").match(/(\w+)\.tar\.gz/).captures[0]
          if (File.exists?"#{samba_root_path_temp}\\opt\\#{testbins}")
            @equipment['server1'].send_sudo_cmd("rm -rf #{testbins}")
          end
          @equipment['server1'].send_sudo_cmd("mkdir #{testbins}", @equipment['server1'].prompt, 30)
          @equipment['server1'].send_sudo_cmd("chmod 777 #{testbins}", @equipment['server1'].prompt, 30)
          @equipment['server1'].send_cmd("cd #{testbins}", @equipment['server1'].prompt, 30)
          dst_path = "#{samba_root_path}\\opt\\#{testbins}\\#{File.basename(src)}"
          debug_puts dst_path
          BuildClient.copy(src, dst_path)
          @equipment['server1'].send_cmd("tar -xvzf #{File.basename(src)}", @equipment['server1'].prompt, 30)        
      end 
      
    end

    
    def clean
      debug_puts "default.clean"
      kernel_modules = @test_params.kernel_modules   if @test_params.instance_variable_defined?(:@kernel_modules)
      if kernel_modules
        #kernel_modules_list = @test_params.params_chan.kernel_modules_list  
        if @test_params.params_chan.instance_variable_defined?(:@kernel_modules_list)
          @test_params.params_chan.kernel_modules_list.each {|mod|
            mod_name = C6xKernelModuleNames::translate_mod_name(@test_params.platform, mod.strip)
            @equipment['dut1'].send_cmd("rmmod #{mod_name}", /#{@equipment['dut1'].prompt}/, 30)  
          }
        end
      end

    end
    
  def copy_test_bins
  
  
  end
    
    def set_paths(samba, nfs)
      @samba_root_path_temp = samba
      @nfs_root_path   = nfs
    end
    
    def get_samba_path()
      @samba_root_path_temp
    end
    
    def connect_to_equipment(equipment)
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet
        this_equipment.connect({'type'=>'telnet'})
      elsif ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})
      elsif !this_equipment.target.telnet && !this_equipment.target.serial
        raise "You need Telnet or Serial port connectivity to #{equipment}. Please check your bench file" 
      end
    end

    def debug_puts(message)
    if @show_debug_messages == true
      puts(message)
    end
    end 
end
   






