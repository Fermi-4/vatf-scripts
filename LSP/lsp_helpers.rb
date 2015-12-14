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
        params['server'].send_sudo_cmd("mkdir -p  #{nfs_root_path_temp}", params['server'].prompt, 10)
        params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} #{tar_options} #{fs}", params['server'].prompt, 1200)
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

