# -*- coding: ISO-8859-1 -*-

require File.dirname(__FILE__)+'/boot'
require File.dirname(__FILE__)+'/c6x_kernel_module_names'
BOOTBLOB = File.dirname(__FILE__)+'/bootblob'

# Default Server-Side Test script implementation for c6x-Linux releases
module C6xTestScript 
    class TargetCommand
        attr_accessor :cmd_to_send, :pass_regex, :fail_regex, :ruby_code
    end
    include Boot
    include C6xKernelModuleNames
    public
    @show_debug_messages = false
    def C6xTestScript.samba_root_path
      @samba_root_path_temp
    end
    
    def C6xTestScript.nfs_root_path
      @nfs_root_path_temp
    end
    
    def setup
      @equipment['dut1'].set_api('linux-c6x')
      tester_from_cli  = @tester.downcase
      target_from_db   = @test_params.target.downcase
      platform_from_db = @test_params.platform.downcase    
      nfs  = @test_params.nfs     if @test_params.instance_variable_defined?(:@nfs)
      bootblob = @test_params.var_bootblob     if @test_params.instance_variable_defined?(:@var_bootblob)
      kernel = @test_params.kernel     if @test_params.instance_variable_defined?(:@kernel)
      kernel_name = @equipment['dut1'].params["kernel"]
      nfs_root_path = @equipment['dut1'].nfs_root_path
      if @equipment.has_key?('server1')
      samba_root_path = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}"
      end
      # Telnet to Linux server
      if @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip) and !@equipment['server1'].target.telnet
        @equipment['server1'].connect({'type'=>'telnet'})
      elsif !@equipment['server1'].target.telnet 
        raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
      end
      # Boot DUT
      # Skip booting process if kernel is not specified      
      if(!@test_params.instance_variable_defined?(:@kernel))
        @new_keys = ''
      else
        @new_keys = (bootblob)? (get_keys() + bootblob) : (get_keys()) 
      end
      # call bootscript if required
      if Boot::boot_required?(@old_keys, @new_keys) 
        power_port = @equipment['dut1'].power_port
        if power_port !=nil
           debug_puts 'Switching off @using power switch'
           @power_handler.switch_off(power_port)
        end
        #Untar NFS
        if nfs 
          fs = nfs
          fs.gsub!(/\\/,'/')
          build_id, build_name = /\/([^\/\\]+?)\/([\w\.\-]+?)$/.match("#{fs.strip}").captures
          samba_root_path_temp = samba_root_path + "\\autofs\\#{build_id}"
          nfs_root_path_temp 	= nfs_root_path + "/autofs/#{build_id}"
          if !File.directory?("#{samba_root_path_temp}")		
            # Copy  nfs filesystem to linux server and untar it if it doesn't exist
            @equipment['server1'].send_sudo_cmd("mkdir -p -m 777  #{nfs_root_path_temp}", @equipment['server1'].prompt, 10)  
            BuildClient.copy(@test_params.nfs, "#{samba_root_path_temp}\\#{File.basename(@test_params.nfs)}")	
            @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}", @equipment['server1'].prompt, 10)   
            @equipment['server1'].send_sudo_cmd("tar -xvzf #{File.basename(@test_params.nfs)} ", @equipment['server1'].prompt, 30)
          end
        else
          # add logic to handle nandfs and ramfs
        end
        #Create kernel image and place in TFTP directory
        if bootblob and kernel
          @equipment['server1'].send_cmd("cd #{nfs_root_path}", @equipment['server1'].prompt, 10)
          BuildClient.copy(kernel, "#{samba_root_path}\\#{File.basename(kernel)}") if !File.exists?("#{samba_root_path}//#{File.basename(kernel)}")
          if !File.exists?("#{samba_root_path}//bootblob")
            BuildClient.copy(BOOTBLOB, "#{samba_root_path}\\bootblob") 
            @equipment['server1'].send_cmd("fromdos bootblob", @equipment['server1'].prompt, 10)
          end
            
          if(platform_from_db == "himalaya")
            bootblob_cmd = "set-cmdline #{File.basename(kernel)} \"#{bootblob} emac_addr=#{@equipment['dut1'].params["emac_addr"]} ip=#{@equipment['dut1'].telnet_ip} root=/dev/nfs nfsroot=#{@equipment['server1'].telnet_ip}:#{nfs_root_path_temp} rw\""    
          else        
            bootblob_cmd = "set-cmdline #{File.basename(kernel)} \"#{bootblob} ip=#{@equipment['dut1'].telnet_ip} root=/dev/nfs nfsroot=#{@equipment['server1'].telnet_ip}:#{nfs_root_path_temp} rw\""    
          end
          debug_puts bootblob_cmd
          @equipment['server1'].send_sudo_cmd("./bootblob #{bootblob_cmd}", @equipment['server1'].prompt, 30)
          @equipment['server1'].send_sudo_cmd("rm -f  #{@equipment['server1'].tftp_path}/#{kernel_name}", @equipment['server1'].prompt, 30) 
          @equipment['server1'].send_sudo_cmd("cp #{File.basename(kernel)} #{@equipment['server1'].tftp_path}/#{kernel_name}", @equipment['server1'].prompt, 30)
        end
        if @test_params.params_chan.instance_variable_defined?(:@test_driver) && @equipment.has_key?('server1') #&& !nfs && !@test_params.instance_variable_defined?(:@var_nfs) 
          files_array = Array.new
          src = "#{SiteInfo::LTP_TEMP_FOLDER}\\#{@test_params.params_chan.test_driver[0].to_s}"
          debug_puts "test driver is: #{src}"
          @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/#{DUT_DST_DIR}", @equipment['server1'].prompt, 10)
          @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt, 10)   
          if (File.exists?"#{samba_root_path_temp}\\#{DUT_DST_DIR}\\#{File.basename(src)}")
            @equipment['server1'].send_sudo_cmd("rm -rf #{File.basename(src)}")
          end
          dst_path = "#{samba_root_path_temp}\\#{DUT_DST_DIR}\\#{File.basename(src)}"
          BuildClient.copy(src, dst_path)     
          #@equipment['server1'].send_sudo_cmd("chmod 777 #{File.basename(src)}",@equipment['server1'].prompt, 30)             
        end 
        C6xTestScript.set_paths(samba_root_path_temp, nfs_root_path_temp) 
        # Connect to DUT via serial port
        # if @equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil
          # @equipment['dut1'].connect({'type'=>'serial'})
        # elsif @equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil
          # @equipment['dut1'].connect({'type'=>'serial'})
        # else
          # raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
        # end
        # Turn power ON
        if power_port !=nil
          debug_puts 'Switching on @using power switch'
          @power_handler.switch_on(power_port)
          sleep 90
          # Connect via telnet
          connect_to_equipment('dut1')
          0.upto 5 do
            @equipment['dut1'].send_cmd("\n",@equipment['dut1'].prompt, 30)
            debug_puts 'Sending esc character'
            sleep 1
            break if !@equipment['dut1'].timeout?
          end
        end
      end


      
      # by now, the dut should already login and is up; if not, dut may hang.
      raise "UUT may be hanging!" if !is_uut_up?
      
      # Copy executables to NFS server (if filesystem was not specified and there are @target_sources
      if @test_params.params_chan.instance_variable_defined?(:@target_binaries) && @equipment.has_key?('server1') #&& !nfs && !@test_params.instance_variable_defined?(:@var_nfs) 
          files_array = Array.new
          src = @test_params.params_chan.target_binaries[0].to_s
          debug_puts "target source folder is: #{src}"
          @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/opt", @equipment['server1'].prompt, 30)
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
      


      # Leave target in appropriate directory
   #   @equipment['dut1'].send_cmd("cd #{nfs_path}\n", /#{@equipment['dut1'].prompt}/, 10)  if ( @equipment.has_key?('server1') && !(nfs) && !(@test_params.instance_variable_defined?(:@var_nfs)) )
      
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
    

    
    def get_keys
      # keys = @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
      # @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
      # @test_params.microType.to_s + @test_params.configID.to_s
      keys = @test_params.platform.to_s
      keys
    end
    
    def set_paths(samba, nfs)
      @samba_root_path_temp = samba
      @nfs_root_path_temp   = nfs
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
	
    def add_log_to_html(log_file_name)
      # add log in result page
      all_lines = ''
      File.open(log_file_name, 'r').each {|line|
        all_lines += line 
      }
      @results_html_file.add_paragraph(all_lines,nil,nil,nil)
    end
    def debug_puts(message)
    if @show_debug_messages == true
      puts(message)
    end
    end 
end
   






