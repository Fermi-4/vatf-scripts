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
      @platform = @test_params.platform.downcase    
      #nfs  = @test_params.nfs     if @test_params.instance_variable_defined?(:@nfs)
      syslink_bins  = @test_params.syslink_bins    if @test_params.instance_variable_defined?(:@syslink_bins)
      benchmark_bins =  @test_params.benchmark_bins if @test_params.instance_variable_defined?(:@benchmark_bins)
      writer_image =  @test_params.writer_image if @test_params.instance_variable_defined?(:@writer_image)
      bootblob = @test_params.var_bootblob     if @test_params.instance_variable_defined?(:@var_bootblob)
      bootblob_util =  @test_params.bootblob_util     if @test_params.instance_variable_defined?(:@bootblob_util)
      syslink_modules =  @test_params.syslink_modules     if @test_params.instance_variable_defined?(:@syslink_modules)
      modules = @test_params.modules     if @test_params.instance_variable_defined?(:@modules)
      filesystem =  @test_params.filesystem     if @test_params.instance_variable_defined?(:@filesystem)      
      test_modules =  @test_params.test_modules     if @test_params.instance_variable_defined?(:@test_modules)
      bootblob_templates =  @test_params.bootblob_templates     if @test_params.instance_variable_defined?(:@bootblob_templates)
      testdriver = @test_params.testdriver     if @test_params.instance_variable_defined?(:@testdriver)
      make_filesystem = @test_params.make_filesystem     if @test_params.instance_variable_defined?(:@make_filesystem)
      @endian = (@equipment['dut1'].id.split("_")[1] == "littleendian") ? "el" : "eb"
      if @test_params.instance_variable_defined?(:@var_float)
        @float = @test_params.var_float == "hard" ? "-hf" : ""
      else
        @float = ""
      end
      template = @test_params.var_template     if @test_params.instance_variable_defined?(:@var_template)
      case @platform
        when "tomahawk"
           @evm = "evmc6472"
        when "faraday"
           @evm = "evmc6474"
        when "himlaya"
           @evm = "dsk6455"
        when "curie"
           @evm = "evmc6457"
        when "faradaylite"
           @evm = "evmc6474-lite"
        when "nyquist"
           @evm = "evmc6670"
        when "shannon"
           @evm = "evmc6678"
      end
      
      if @test_params.instance_variable_defined?(:@kernel)
        kernel = @test_params.kernel     
        kernel_name = @equipment['dut1'].params["kernel"] 
      end
      nfs_root_path = @equipment['dut1'].nfs_root_path
      nfs_root_path_temp 	= nfs_root_path
      if @equipment.has_key?('server1')
        @samba_root_path = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}"
      end
      samba_root_path_temp = @samba_root_path
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
        # Prepare kernel and NFS

        if kernel and filesystem and bootblob_templates
          @equipment['server1'].send_cmd("cd #{nfs_root_path}", @equipment['server1'].prompt, 10)
          prepare_kernel_fs(kernel,filesystem,modules,test_modules,syslink_modules,bootblob_util,make_filesystem,bootblob_templates,template) 
        end
        #Untar NFS
        if @nfs 
          fs = @nfs
          # fs.gsub!(/\\/,'/')
          # build_id, build_name = /\/([^\/\\]+?)\/([\w\.\-]+?)$/.match("#{fs.strip}").captures
          samba_root_path_temp = @samba_root_path + "\\autofs\\#{@nfs_id}"
          nfs_root_path_temp 	= nfs_root_path + "/autofs/#{@nfs_id}"
          if !File.directory?("#{samba_root_path_temp}")		
            # Copy  nfs filesystem to linux server and untar it if it doesn't exist
            @equipment['server1'].send_sudo_cmd("mkdir -p -m 777  #{nfs_root_path_temp}", @equipment['server1'].prompt, 10)  
            BuildClient.copy(@nfs, "#{samba_root_path_temp}\\#{File.basename(@nfs)}")	
            @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}", @equipment['server1'].prompt, 10)
            #@equipment['server1'].send_cmd("mv #{File.basename(@nfs)} #{File.basename(@nfs)}.cpio.gz", @equipment['server1'].prompt, 10)               
            @equipment['server1'].send_sudo_cmd("gunzip #{File.basename(@nfs)}", @equipment['server1'].prompt, 30)
            @equipment['server1'].send_sudo_cmd("cpio -idmv < *", @equipment['server1'].prompt, 30)
          end
        end
        #Create kernel image and place in TFTP directory
        if (bootblob and @kernel and @nfs) or (@initramfs)
          @equipment['server1'].send_cmd("cd #{nfs_root_path}", @equipment['server1'].prompt, 10)
          # if File.exists?("#{@samba_root_path}//#{File.basename(kernel)}")
            # @equipment['server1'].send_sudo_cmd("rm #{File.basename(kernel)}", @equipment['server1'].prompt, 10)
          # end
          # BuildClient.copy(kernel, "#{@samba_root_path}\\#{File.basename(kernel)}") 
          # if !File.exists?("#{@samba_root_path}//bootblob")
            # BuildClient.copy(bootblob_util, "#{@samba_root_path}\\bootblob") 
            # #@equipment['server1'].send_cmd("fromdos bootblob", @equipment['server1'].prompt, 10)
          # end
          if @nfs 
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
            if(@platform == "himalaya")
              bootblob_cmd = "set-cmdline #{File.basename(@kernel)} \"#{bootblob_str} emac_addr=#{@equipment['dut1'].params["emac_addr"]} #{bootblob_ip} root=/dev/nfs nfsroot=#{@equipment['server1'].params["nfs_ip"]}:#{nfs_root_path_temp},tcp,v3 rw\""    
            else        
              bootblob_cmd = "set-cmdline #{File.basename(@kernel)} \"#{bootblob_str} #{bootblob_ip} root=/dev/nfs nfsroot=#{@equipment['server1'].params["nfs_ip"]}:#{nfs_root_path_temp},tcp,v3 rw\""    
            end
          elsif @initramfs
            @equipment['server1'].send_sudo_cmd("./bootblob get-cmdline #{File.basename(@initramfs)}", @equipment['server1'].prompt, 30)
            bootblob_str = @equipment['server1'].response.scan(/^console.*$/)[0].strip
            puts "+++++++++++++++++++++++"
            puts "Response: #{bootblob_str}"
            puts "+++++++++++++++++++++++"
            if(@platform == "himalaya")
              bootblob_cmd = "set-cmdline #{File.basename(@initramfs)} \"emac_addr=#{@equipment['dut1'].params["emac_addr"]} #{bootblob_str}\""    
            else        
              bootblob_cmd = "set-cmdline #{File.basename(@initramfs)} \"#{bootblob_str}\""    
            end           
          end
          @equipment['server1'].send_sudo_cmd("./bootblob #{bootblob_cmd}", @equipment['server1'].prompt, 30)
          @equipment['server1'].send_sudo_cmd("rm -f  #{@equipment['server1'].tftp_path}/#{kernel_name}", @equipment['server1'].prompt, 30) 
          @equipment['server1'].send_sudo_cmd("cp #{File.basename(@initramfs)} #{@equipment['server1'].tftp_path}/#{kernel_name}", @equipment['server1'].prompt, 30)
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
        @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/#{SYSLINK_DST_DIR}", @equipment['server1'].prompt, 10)
        @equipment['server1'].send_sudo_cmd("chmod 777 .",@equipment['server1'].prompt, 10)   
        dst_path = "#{samba_root_path_temp}\\#{SYSLINK_DST_DIR}"
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
    
    def prepare_kernel_fs(kernel,filesystem,modules,test_modules,syslink_modules,bootblob_util,make_filesystem,bootblob_templates,template)  
      BuildClient.copy(kernel, "#{@samba_root_path}\\#{File.basename(kernel)}") 
      @equipment['server1'].send_sudo_cmd("mv #{File.basename(kernel)} vmlinux-2.6.34-#{@evm}.#{@endian}.bin",@equipment['server1'].prompt, 10)
      BuildClient.copy(filesystem, "#{@samba_root_path}\\#{File.basename(filesystem)}") 
      fs_name = get_fs_name(template)
      @equipment['server1'].send_sudo_cmd("mv #{File.basename(filesystem)} #{fs_name}",@equipment['server1'].prompt, 10)
      if modules
        BuildClient.copy(modules, "#{@samba_root_path}\\#{File.basename(modules)}") 
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(modules)} modules-2.6.34-#{@evm}.#{@endian}.tar.gz",@equipment['server1'].prompt, 10)
      end
      if test_modules
        BuildClient.copy(test_modules, "#{@samba_root_path}\\#{File.basename(test_modules)}") 
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(test_modules)} test-modules-2.6.34-#{@evm}.#{@endian}.tar.gz",@equipment['server1'].prompt, 10)
      end
      if syslink_modules
        BuildClient.copy(syslink_modules, "#{@samba_root_path}\\#{File.basename(syslink_modules)}") 
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(syslink_modules)} syslink-all-#{@evm}.#{@endian}#{@float}.tar.gz",@equipment['server1'].prompt, 10)
      end
      if !File.exists?("#{@samba_root_path}//bootblob")
        BuildClient.copy(bootblob_util, "#{@samba_root_path}\\#{File.basename(bootblob_util)}") 
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(bootblob_util)} bootblob",@equipment['server1'].prompt, 10)
      end
      if !File.exists?("#{@samba_root_path}//make-filesystem")
        BuildClient.copy(make_filesystem, "#{@samba_root_path}\\#{File.basename(make_filesystem)}") 
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(make_filesystem)} make-filesystem",@equipment['server1'].prompt, 10)
      end
      if !File.exists?("#{@samba_root_path}//bootblob_templates")
        BuildClient.copy(bootblob_templates, "#{@samba_root_path}\\#{File.basename(bootblob_templates)}") 
        @equipment['server1'].send_sudo_cmd("mv #{File.basename(bootblob_templates)} bootblob_templates.tar.gz",@equipment['server1'].prompt, 10)
        @equipment['server1'].send_sudo_cmd("tar -xvzf bootblob_templates.tar.gz",@equipment['server1'].prompt, 10)
      end
      @equipment['server1'].send_sudo_cmd("chmod +x bootblob",@equipment['server1'].prompt, 10)
      @equipment['server1'].send_sudo_cmd("chmod +x make-filesystem",@equipment['server1'].prompt, 10)
      @equipment['server1'].send_sudo_cmd("rm #{template}.#{@endian}.cpio.gz",@equipment['server1'].prompt, 10)
      @equipment['server1'].send_sudo_cmd("rm #{template}.#{@endian}.bin",@equipment['server1'].prompt, 10)
      @equipment['server1'].send_sudo_cmd("FLOAT=#{@test_params.var_float} ./bootblob #{template}",/some attempted template combinations were skipped or failed/, 120)
      
      case get_fs_type(template)
        when "nfs"
          @equipment['server1'].send_cmd("md5sum #{template}.#{@endian}#{@float}.cpio.gz",@equipment['server1'].prompt, 10)
          @nfs_id = /([a-z0-9]{32})/.match(@equipment['server1'].response).captures[0]
          @equipment['server1'].send_sudo_cmd("mv #{template}.#{@endian}#{@float}.cpio.gz #{@nfs_id}.cpio.gz",@equipment['server1'].prompt, 10)
          @nfs = "#{@samba_root_path}\\#{@nfs_id}.cpio.gz"
          
          @equipment['server1'].send_cmd("md5sum #{template}.#{@endian}#{@float}.bin",@equipment['server1'].prompt, 10)
          @kernel_id = /([a-z0-9]{32})/.match(@equipment['server1'].response).captures[0]
          @equipment['server1'].send_sudo_cmd("mv #{template}.#{@endian}#{@float}.bin #{@kernel_id}.bin",@equipment['server1'].prompt, 10)
          @kernel = "#{@samba_root_path}\\#{@kernel_id}.bin"
        when "initramfs"
          @initramfs = "#{@samba_root_path}\\#{template}.#{@endian}#{@float}.bin"
      end

      
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
    
    def get_fs_name(template)

      case template
        when /ltp/
          fs_name = (@endian == "el") ? "ltp-root-c6x#{@float}.cpio.gz" : "ltp-root-c6xeb#{@float}.cpio.gz"
        when /demo/
          fs_name = (@endian == "el") ? "mcsdk-demo-root-c6x#{@float}.cpio.gz" : "ltp-root-c6xeb#{@float}.cpio.gz"
        when /demo/
          fs_name = (@endian == "el") ? "mcsdk-demo-root-c6x#{@float}.cpio.gz" : "ltp-root-c6xeb#{@float}.cpio.gz"
      end
      fs_name

    end
    
    def get_fs_type(template)
    case template
       when /nfs/
         fs_type = "nfs"
       when /initramfs/
         fs_type = "initramfs"
    end
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
   






