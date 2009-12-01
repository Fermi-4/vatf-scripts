require File.dirname(__FILE__)+'/../LSP/boot'

module DvsdkTestScript 
  include Boot
  # Sets nfs filesystem in params['server']  and boots params['dut'] 
  # If no parameters are passed @equipment['server1'] and @equipment['dut1'] are used as the Linux server and DUT respectively.
  def boot_dut(boot_equip={})
    params = {'dut' => @equipment['dut1'], 'server' => @equipment['server1']}.merge(boot_equip)
    # Initialize some test variables       
    tester_from_cli  = @tester.downcase
    target_from_db   = @test_params.target.downcase
    platform_from_db = @test_params.platform.downcase
    # Install Filesystem (if specified)
    nfs 	 = @test_params.nfs if @test_params.respond_to?(:nfs)
    nandfs = @test_params.nandfs if @test_params.respond_to?(:nandfs)
    ramfs  = @test_params.ramfs if @test_params.respond_to?(:ramfs)
    samba_root_path = params['server'].samba_root_path
    nfs_root_path		= params['server'].nfs_root_path
    if nfs or nandfs or ramfs
      fs = ([nfs, nandfs, ramfs].select {|f| f != nil})[0]
      fs.gsub!(/\\/,'/')
      build_id, build_name = /\/([^\/\\]+?)\/([\w\.\-]+?)$/.match("#{fs.strip}").captures
      params['server'].send_cmd("mkdir -p -m 777  #{nfs_root_path}/autofs", params['server'].prompt, 10)  if !File.directory?("\\\\#{params['server'].telnet_ip}\\#{samba_root_path}\\autofs")		
      samba_root_path = samba_root_path + "\\autofs\\#{build_id}"
      nfs_root_path 	= nfs_root_path + "/autofs/#{build_id}"
      # Copy  nfs filesystem to linux server and untar it if it doesn't exist
      if nfs and  !File.directory?("\\\\#{params['server'].telnet_ip}\\#{samba_root_path}\\usr")
        params['server'].send_cmd("mkdir -p  #{nfs_root_path}", params['server'].prompt, 10) 		
        BuildClient.copy(@test_params.nfs, "\\\\#{params['server'].telnet_ip}\\#{samba_root_path}\\#{File.basename(@test_params.nfs)}")	
        params['server'].send_cmd("cd #{nfs_root_path}", params['server'].prompt, 10) 		
        params['server'].send_sudo_cmd("tar -xvzf #{build_name}", params['server'].prompt, 300)
        params['server'].send_sudo_cmd("mkdir -p -m 777 #{nfs_root_path}/test", params['server'].prompt, 10)
      end
      # Need to add logic to handle nandfs and ramfs
    end
    DvsdkTestScript.set_paths(samba_root_path, nfs_root_path)
    # Boot DUT
    samba_path = "\\\\#{params['server'].telnet_ip}\\#{samba_root_path}\\test\\#{tester_from_cli}\\#{target_from_db}\\#{platform_from_db}\\bin"
    nfs_path   = "/test/#{tester_from_cli}/#{target_from_db}/#{platform_from_db}/bin"
    boot_params = {'power_handler'=> @power_handler, 'platform' => platform_from_db, 'tester' => tester_from_cli, 'target' => target_from_db ,'image_path' => @test_params.kernel, 'server' => params['server'],  'samba_path' => samba_path, 'nfs_root' => nfs_root_path, 'nfs_path' => "#{nfs_root_path}#{nfs_path}"}
    boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
    @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
    params['dut'].boot(boot_params) if Boot::boot_required?(@old_keys, @new_keys) # call bootscript if required
  end
  
  def samba_root_path
    @samba_root_path
  end
    
  def nfs_root_path
    @nfs_root_path
  end
    
  def set_paths(samba, nfs)
    @samba_root_path = samba
    @nfs_root_path   = nfs
  end

  def get_keys
      # keys = @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
      # @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
      # @test_params.microType.to_s + @test_params.configID.to_s
      keys = @test_params.platform.to_s
      keys
  end
 
end  


