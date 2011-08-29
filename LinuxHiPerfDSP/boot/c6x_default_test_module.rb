# -*- coding: ISO-8859-1 -*-

require File.dirname(__FILE__)+'/boot'
require File.dirname(__FILE__)+'/c6x_kernel_module_names'
BOOTBLOB = File.dirname(__FILE__)+'/bootblob'
SYSLINK_DST_DIR='/opt'
DUT_DST_DIR = 'opt/ltp'

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
      platform_from_db = @test_params.platform.downcase    
      nfs  = @test_params.nfs     if @test_params.instance_variable_defined?(:@nfs)
      syslink_bins  = @test_params.syslink_bins    if @test_params.instance_variable_defined?(:@syslink_bins)
      benchmark_bins =  @test_params.benchmark_bins if @test_params.instance_variable_defined?(:@benchmark_bins)
      writer_image =  @test_params.writer_image if @test_params.instance_variable_defined?(:@writer_image)
      bootblob = @test_params.var_bootblob     if @test_params.instance_variable_defined?(:@var_bootblob)
      bootblob_util =  @test_params.bootblob_util     if @test_params.instance_variable_defined?(:@bootblob_util)
      testdriver = @test_params.testdriver     if @test_params.instance_variable_defined?(:@testdriver)
      if @test_params.instance_variable_defined?(:@kernel)
        kernel = @test_params.kernel     
        kernel_name = @equipment['dut1'].params["kernel"] 
      end
      nfs_root_path = @equipment['dut1'].nfs_root_path
      nfs_root_path_temp 	= nfs_root_path
      if @equipment.has_key?('server1')
      samba_root_path = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}"
      end
      samba_root_path_temp = samba_root_path
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
        @new_keys = (@test_params.params_chan.instance_variable_defined?(:@syslink_testname))? (@new_keys + @test_params.params_chan.instance_variable_get("@syslink_testname")[0].to_s) : (@new_keys) 
      end
      puts "+++++++++++++++++++++++"
      puts @old_keys
      puts @new_keys
      puts "+++++++++++++++++++++++"
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
            @equipment['server1'].send_cmd("mv #{File.basename(@test_params.nfs)} #{File.basename(@test_params.nfs)}.cpio.gz", @equipment['server1'].prompt, 10)               
            @equipment['server1'].send_sudo_cmd("gunzip #{File.basename(@test_params.nfs)}.cpio.gz", @equipment['server1'].prompt, 30)
            @equipment['server1'].send_sudo_cmd("cpio -idmv < *", @equipment['server1'].prompt, 30)
          end
        else
          @initramfs = true
        end
        #Create kernel image and place in TFTP directory
        if (bootblob and kernel) or (@initramfs)
          @equipment['server1'].send_cmd("cd #{nfs_root_path}", @equipment['server1'].prompt, 10)
          if File.exists?("#{samba_root_path}//#{File.basename(kernel)}")
            @equipment['server1'].send_sudo_cmd("rm #{File.basename(kernel)}", @equipment['server1'].prompt, 10)
          end
          BuildClient.copy(kernel, "#{samba_root_path}\\#{File.basename(kernel)}") 
          if !File.exists?("#{samba_root_path}//bootblob")
            BuildClient.copy(bootblob_util, "#{samba_root_path}\\bootblob") 
            #@equipment['server1'].send_cmd("fromdos bootblob", @equipment['server1'].prompt, 10)
          end
          if nfs 
            bootblob_str = ''
            bootblob_ip = nil
            bootblob.strip.split(";").each { |cmd|     
            if(cmd == "ip=dhcp")
              bootblob_ip = "ip=dhcp"
            else
              bootblob_str << cmd + " "
            end
            }
            if(bootblob_ip == nil) 
              bootblob_ip = "ip=#{@equipment['dut1'].telnet_ip}"
            end
            if(platform_from_db == "himalaya")
              bootblob_cmd = "set-cmdline #{File.basename(kernel)} \"#{bootblob_str} emac_addr=#{@equipment['dut1'].params["emac_addr"]} #{bootblob_ip} root=/dev/nfs nfsroot=#{@equipment['server1'].params["nfs_ip"]}:#{nfs_root_path_temp},tcp,v3 rw\""    
            else        
              bootblob_cmd = "set-cmdline #{File.basename(kernel)} \"#{bootblob_str} #{bootblob_ip} root=/dev/nfs nfsroot=#{@equipment['server1'].params["nfs_ip"]}:#{nfs_root_path_temp},tcp,v3 rw\""    
            end
          elsif @initramfs
            @equipment['server1'].send_sudo_cmd("./bootblob get-cmdline #{File.basename(kernel)}", @equipment['server1'].prompt, 30)
            bootblob_str = @equipment['server1'].response.scan(/[^console].*[rw$]/)[0].strip
            puts "+++++++++++++++++++++++"
            puts "Response: #{bootblob_str}"
            puts "+++++++++++++++++++++++"
            if(platform_from_db == "himalaya")
              bootblob_cmd = "set-cmdline #{File.basename(kernel)} \"emac_addr=#{@equipment['dut1'].params["emac_addr"]} #{bootblob_str}\""    
            else        
              bootblob_cmd = "set-cmdline #{File.basename(kernel)} \"#{bootblob_str}\""    
            end           
          end
          @equipment['server1'].send_sudo_cmd("./bootblob #{bootblob_cmd}", @equipment['server1'].prompt, 30)
          @equipment['server1'].send_sudo_cmd("rm -f  #{@equipment['server1'].tftp_path}/#{kernel_name}", @equipment['server1'].prompt, 30) 
          @equipment['server1'].send_sudo_cmd("cp #{File.basename(kernel)} #{@equipment['server1'].tftp_path}/#{kernel_name}", @equipment['server1'].prompt, 30)
        end
        # Turn power ON
        if power_port !=nil
          debug_puts 'Switching on @using power switch'
          sleep 7
          @power_handler.switch_on(power_port)
          sleep 90
          # Connect via telnet
        end
      else
        samba_root_path_temp = C6xTestScript.get_samba_path ? C6xTestScript.get_samba_path : samba_root_path_temp
        nfs_root_path_temp 	= C6xTestScript.get_nfs_path ? C6xTestScript.get_nfs_path : nfs_root_path_temp
      end
      if testdriver && @equipment.has_key?('server1') #&& !nfs && !@test_params.instance_variable_defined?(:@var_nfs) 
           if (!File.exists?"#{samba_root_path_temp}\\#{DUT_DST_DIR}\\testdriver")
            @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/#{DUT_DST_DIR}", @equipment['server1'].prompt, 10)
            @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt, 10)  
            dst_path = "#{samba_root_path_temp}\\#{DUT_DST_DIR}\\testdriver"
            BuildClient.copy(testdriver, dst_path)     
            @equipment['server1'].send_sudo_cmd("chmod 777 testdriver",@equipment['server1'].prompt, 30)  
          end            
      end
      if syslink_bins
        @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/", @equipment['server1'].prompt, 10)
        @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt, 10)   
        dst_path = "#{samba_root_path_temp}"
        BuildClient.copy(syslink_bins, dst_path)    
        @equipment['server1'].send_sudo_cmd("tar -xvzf #{File.basename(syslink_bins)}",@equipment['server1'].prompt, 10)   
      end
      if benchmark_bins
        @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/opt", @equipment['server1'].prompt, 10)
        @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt, 10)   
        dst_path = "#{samba_root_path_temp}\\opt"
        BuildClient.copy(benchmark_bins, dst_path)    
        @equipment['server1'].send_sudo_cmd("tar -xvzf #{File.basename(benchmark_bins)}",@equipment['server1'].prompt, 10)       
      end
      if writer_image
        @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/opt", @equipment['server1'].prompt, 10)
        @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt, 10)   
        dst_path = "#{samba_root_path_temp}/opt"
        BuildClient.copy(writer_image, dst_path)
	    @equipment['server1'].send_sudo_cmd("rm image.bin",@equipment['server1'].prompt, 10)  
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(writer_image)} image.bin",@equipment['server1'].prompt, 10)     
      end
      C6xTestScript.set_paths(samba_root_path_temp, nfs_root_path_temp) 
      connect_to_equipment('dut1')
      0.upto 5 do
        @equipment['dut1'].send_cmd("\n",@equipment['dut1'].prompt, 30)
        debug_puts 'Sending esc character'
        sleep 1
        break if !@equipment['dut1'].timeout?
      end

      
      # by now, the dut should already login and is up; if not, dut may hang.
      raise "UUT may be hanging!" if !is_uut_up?
   
    end

    
    def clean
      debug_puts "default.clean"

    end
    

    
    def get_keys
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
    
    def get_nfs_path()
      @nfs_root_path_temp
    end
    
    def connect_to_equipment(equipment)
      this_equipment = @equipment["#{equipment}"]
      if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})     
      elsif this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet
        this_equipment.connect({'type'=>'telnet'})
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
   






