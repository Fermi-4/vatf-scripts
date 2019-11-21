# Helper functions used by LSP test scripts
require File.dirname(__FILE__)+'/network_utils'

module LspHelpers
  include NetworkUtils
  
  def setup_nfs(params)
    nfs_root_path_temp  = params['dut'].nfs_root_path

    if params['server'].kind_of? LinuxLocalHostDriver
      params['server'].connect({})     # In this case, nothing happens as the server is running locally
    elsif params['server'].respond_to?(:telnet_port) and params['server'].respond_to?(:telnet_ip) and !params['server'].target.telnet
      params['server'].connect({'type'=>'telnet'})
    elsif !params['server'].target.telnet
      raise "You need Telnet connectivity to the Linux Server. Please check your bench file"
    end

    params['server'].send_cmd("mkdir -p #{@linux_temp_folder}", params['server'].prompt)
    if params['fs_type'] == 'nfs' and !params.has_key?('var_nfs')
      fs = params['fs']
      fs.gsub!(/\\/,'/')
      build_id = /\/([^\/\\]+?)\/[\w\.\-]+?$/.match("#{fs.strip}").captures[0]
      params['server'].send_sudo_cmd("mkdir -p -m 777  #{nfs_root_path_temp}/autofs", params['server'].prompt, 10)  if !File.directory?("#{nfs_root_path_temp}/autofs")
      nfs_root_path_temp  = nfs_root_path_temp + "/autofs/#{build_id}"
      # Untar nfs filesystem if it doesn't exist
      if !File.directory?("#{nfs_root_path_temp}/usr")
        tar_options = get_tar_options(fs,params)
        raise "Filesystem image is not a recognizable tar archive" if tar_options == "not tar"
        params['server'].send_sudo_cmd("mkdir -p  #{nfs_root_path_temp}", params['server'].prompt, 10)
        params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} #{tar_options} #{fs}", params['server'].prompt, 2400)
        raise "Error extracting tarball" if params['server'].response.match(/(tar:\s+Error|Sorry, try again)/)
      end
      # Add workaround for disabling weston
      weston_start_dst = "#{nfs_root_path_temp}/etc/init.d/weston.bak"
      matrix_start_dst = "#{nfs_root_path_temp}/etc/rc5.d/K97matrix-gui-2.0"
      weston_start_src = "#{nfs_root_path_temp}/etc/init.d/weston"
      matrix_start_src = "#{nfs_root_path_temp}/etc/rc5.d/S97matrix-gui-2.0"
      if @test_params.instance_variable_defined?(:@var_disable_weston) && @test_params.var_disable_weston.to_i == 1
        puts "Disabling Weston and Matrix"
        if !File.exists?(weston_start_dst) && !File.exists?(matrix_start_dst)
          params['server'].send_sudo_cmd("mv #{weston_start_src} #{weston_start_dst}", params['server'].prompt, 10)
          params['server'].send_sudo_cmd("mv #{matrix_start_src} #{matrix_start_dst}", params['server'].prompt, 10)
        end
      else
        if File.exists?(weston_start_dst) && File.exists?(matrix_start_dst)
          params['server'].send_sudo_cmd("mv #{weston_start_dst} #{weston_start_src}", params['server'].prompt, 10)
          params['server'].send_sudo_cmd("mv #{matrix_start_dst} #{matrix_start_src}", params['server'].prompt, 10)
        end
      end
      # Add workaround for touch screen calibration
      pointercal_rule_dst = "#{nfs_root_path_temp}/etc/rc5.d/S90-fake-pointercal"
      if !File.exists?(pointercal_rule_dst)
        pointercal_rule_src = File.join(File.dirname(__FILE__), 'TARGET', 'S90-fake-pointercal')
        params['server'].send_sudo_cmd("cp #{pointercal_rule_src} #{pointercal_rule_dst}", params['server'].prompt, 10)
      end
    end
    
    install_kernel_modules(params, nfs_root_path_temp)    
          
    params['server'].send_sudo_cmd("mkdir -p -m 777 #{nfs_root_path_temp}/test", params['server'].prompt) if !(params.has_key? 'var_nfs')
      
    LspTestScript.set_paths(nfs_root_path_temp, nfs_root_path_temp) 
    nfs_root_path_temp = "#{params['server'].telnet_ip}:#{nfs_root_path_temp}"
    nfs_root_path_temp = params['var_nfs']  if params.has_key? 'var_nfs'   # Optionally use external nfs server
    params['nfs_path'] = nfs_root_path_temp
  end
      
  def set_dtb_file_to_nfs_path_if_specified(params)
    # Only set dtb file to an NFS path when nfs_dtb_filter, nfs_dtb_filter_prefix or nfs_dtb_filter_suffix parameters are present in the test case
    if @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_filter) or @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_filter_prefix) or @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_filter_suffix)
      params['dut'].log_info("Setting dtb file to an NFS directory path...")
      # Set default parameter values so that in most cases only the dtb filter suffix need be specified
      nfs_dtb_subdirectory = "boot"
      nfs_dtb_filter_prefix = ""
      nfs_dtb_filter_suffix = ""
      dtb_platform = @test_params.platform.downcase.split(",")[0]
      # Set parameters from test case, if present
      nfs_dtb_subdirectory = @test_params.params_chan.nfs_dtb_subdirectory[0] if @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_subdirectory)
      nfs_dtb_filter_prefix = @test_params.params_chan.nfs_dtb_filter_prefix[0] if @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_filter_prefix)
      nfs_dtb_filter_suffix = @test_params.params_chan.nfs_dtb_filter_suffix[0] if @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_filter_suffix)
      # Set nfs_dtb_filter based on pre and post filters and automatically add the platform to filter specification
      nfs_dtb_filter = /.*#{nfs_dtb_filter_prefix}.*#{dtb_platform}.*#{nfs_dtb_filter_suffix}\.dtb$/i
      # Use directly specified nfs_dtb_filter, if present
      nfs_dtb_filter = @test_params.params_chan.nfs_dtb_filter[0] if @test_params.params_chan.instance_variable_defined?(:@nfs_dtb_filter)
      # Set dtb search path based on NFS root path
      nfs_root_dir = params['nfs_path'].split(":")[1]
      dtb_search_path = File.join(nfs_root_dir, nfs_dtb_subdirectory)
      params['dut'].log_info(" NFS search path: #{dtb_search_path}")
      # Find the dtb file within the NFS directory
      nfs_dtb = Find.find(dtb_search_path).select { |p| nfs_dtb_filter =~ p }[0]
      raise "NFS dtb file does not exist for file filter: #{nfs_dtb_filter}. Please check your test case parameters" if !nfs_dtb
      # Set dtb file path to the dtb file within the NFS directory
      params['dtb'] = nfs_dtb
      params['dut'].log_info(" dtb's NFS path : #{params['dtb']}")
    end
  end

  def find_nfsroot
    @equipment['dut1'].send_cmd("cat /proc/cmdline")
    nfsroot = /nfsroot=([\d\.:\/\w_-]+)/im.match(@equipment['dut1'].response).captures[0]
  end

  def mmc_rootfs?
    @equipment['dut1'].send_cmd("cat /proc/cmdline")
    return true if /root=\/dev\/mmcblk.*/.match(@equipment['dut1'].response)
    return false
  end

  def nfs_rootfs?
    @equipment['dut1'].send_cmd("cat /proc/cmdline")
    return true if /root=\/dev\/nfs/.match(@equipment['dut1'].response)
    return false
  end

  def cmd_exit_zero?(device=@equipment['dut1'])
    device.send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
    !device.timeout?
  end

  def get_tar_options(fs,params)
    params['server'].send_cmd("file #{fs}", params['server'].prompt)
    case params['server'].response
    when /gzip/
      tar_options = "-xvzf" 
    when /bzip2/
      tar_options = "-xvjf"
    when /tar archive/i
      tar_options = "-xvf"
    when /XZ compressed data/i
      tar_options = "-xvJf"
    else
      tar_options = "not tar"
    end
    tar_options
  end

  def copy_asset(server, src, dst_dir)
    if src != dst_dir
      raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
      server.send_sudo_cmd("mkdir -p -m 777 #{dst_dir}") if !File.exists?(dst_dir)
      if File.file?(src)
        FileUtils.cp(src, dst_dir)
      else
        FileUtils.cp_r(File.join(src,'.'), dst_dir)
      end
    end
  end

  # check if directory or file exist in dut target
  def dut_dir_exist?(directory)
    @equipment['dut1'].send_cmd("ls #{directory} > /dev/null", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
    !@equipment['dut1'].timeout?
  end

  def report_msg(msg, e='dut1')
    puts msg
    @equipment[e].log_info(msg)
  end


end

