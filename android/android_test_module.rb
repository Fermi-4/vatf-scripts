require 'date'
require File.dirname(__FILE__)+'/metrics'
require File.dirname(__FILE__)+'/../lib/plot'
require File.dirname(__FILE__)+'/keyevents_module'
require File.dirname(__FILE__)+'/../LSP/default_test_module' 

include Metrics
include TestPlots
include AndroidKeyEvents
include LspTestScript


LOG_TAG = "VATF::ANDROID::RESULT::"
  
def setup
  @linux_dst_dir='/sdcard/test'
  @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s, 'android')
  FileUtils.mkdir_p @linux_temp_folder
  self.as(LspTestScript).setup
  sleep 40
  @android_boot_params['server'].send_sudo_cmd("rm #{@linux_temp_folder}/*", @android_boot_params['server'].prompt, 120) #Cleanup for next test
  @equipment['dut1'].set_android_tools(@android_boot_params)
  @equipment['dut1'].send_cmd("export PATH=$PATH:/data/nativetest/modetest", @equipment['dut1'].prompt, 10)
  send_adb_cmd("shell mkdir #{@linux_dst_dir}")
  send_events_for('__menu__')
  send_events_for('__home__')
  send_adb_cmd("shell su root svc power stayon true")
  send_adb_cmd("shell su root setprop debug.hwc.showfps 1")
  setupTest(:@test_libs,:@var_test_libs_root)
end

def clean
end

def setup_host_side(params={})
  params['dut'] = @equipment['dut1'] if !params['dut']
  params['server'] = @equipment['server1']  if !params['server']
  params['dut'].set_api('psp')
  params['workdir'] = @linux_temp_folder

  boot_params = init_boot_params(params)

  translated_boot_params = translate_boot_params(boot_params)

  tarballs = []
  translated_boot_params['lxc-info'] = {'config' => {}}
  @test_params.instance_variables.each  do |i_v|
    if i_v.to_s.match(/^(?:var_|test_script_root|assign_to|@params)/)
      next
    elsif i_v.to_s.end_with?('_tarball')
      tarballs << @test_params.instance_variable_get(i_v)
    else
      img = i_v.to_s.gsub(/^[:@]+/,'')
      if img.start_with?('var_lxc_')
        translated_boot_params['lxc-info']['config'][img.sub(/^var_lxc_/i,'')] = @test_params.instance_variable_get(i_v)
      else
        translated_boot_params[img] = @test_params.instance_variable_get(i_v)
      end
    end
  end

  translated_boot_params = setup_tarballs(tarballs, @linux_temp_folder+ '/tar_folder', translated_boot_params)

  if tarballs.length < 1
    setup_nfs translated_boot_params if @test_params.instance_variable_defined?(:@var_nfs) || @test_params.instance_variable_defined?(:@nfs)
  end

  copy_sw_assets_to_tftproot translated_boot_params

  @android_boot_params = translated_boot_params

  return translated_boot_params

end

module AndroidTest

  #Process the tarballs containing the binaries used for a test. The
  #function inflates the tarballs and sets the patch of the .imgs files
  #primary bootloader, secondary bootloader, dtb files and android tools
  #if not already defined.
  #Takes: tbs, an array containing the path of the tarballs to be processed
  #       dest, path of the folder where the tarball will be inflated
  #       params, Hash where the values of the assets found will be stored
  def setup_tarballs(tbs, dest, params)
    new_params = params.clone
    new_params['fastboot_path'] = dest
    if tbs.length < 1
      new_params['fastboot'] = 'fastboot' if !new_params['fastboot']
      new_params['make_ext4fs'] = 'make_ext4fs' if !new_params['make_ext4fs']
      new_params['simg2img'] = 'simg2img' if !new_params['simg2img']
      new_params['adb'] = 'adb' if !new_params['adb']
      return new_params
    end

    tb_check = "#{dest}/tarball_check.md5"
    installed_check = "#{dest}/installed.md5"
    new_params['server'].send_cmd("ls #{dest} || mkdir -p #{dest}")
    new_params['server'].send_cmd("ls #{tb_check} && rm #{tb_check}")
    new_params['server'].send_cmd("ls #{installed_check} || echo 'New installation so creating entry to trigger install' > #{installed_check}")
    new_params['server'].send_cmd("md5sum  #{tbs.join(' ')} |  cut -d' ' -f 1 | sort &> #{tb_check}")
    new_params['server'].send_cmd("diff #{tb_check} #{installed_check} 2>&1")
    if  new_params['server'].response != ''
      new_params['run_fastboot.sh'] = true
      new_params['server'].send_cmd("rm -rf #{dest}/*")
      tbs.each do |path|
        tar_opts = get_tar_options(path,params)
        raise "Unable to setup #{path} file (#{tar_opts})" if tar_opts.downcase().match(/not\s*tar/)
        new_params['server'].send_cmd("tar -C #{dest} #{get_tar_options(path,params)} #{path}", /.*/, 2400)
        raise "Unable to setup #{path}" if new_params['server'].timeout? 
      end
      new_params['server'].send_cmd("md5sum  #{tbs.join(' ')} |  cut -d' ' -f 1 | sort > #{installed_check}")
    end
    new_params['server'].send_cmd("cat #{installed_check}")
    new_params['tarball_md5'] = new_params['server'].response

    ['fastboot', 'make_ext4fs', 'simg2img', 'adb'].each do |a_u|
      if !new_params[a_u]
        new_params['server'].send_cmd("ls #{dest}/#{a_u}")
        new_params[a_u] = params['server'].response.strip if !new_params['server'].response.match(/No\s*such\s*file\s*or\s*directory/im)
      end
      new_params['server'].send_cmd("chmod 755 #{dest}/#{a_u}")
    end
    new_params['server'].send_cmd("ls #{dest}/*.img")
    new_params['server'].response.split(/[\r\n]+/).each do |img|
      img_name =File.basename(img,'.img').gsub('-','_')
      new_params[img_name] = img if !new_params[img_name]
    end
    return new_params if new_params['dut'].name.match(/am65.*/i) # AM65x uses fastboot.sh to flash images
    loaders = case new_params['dut'].name
      when /-hsevm$/i
        ["u-boot-spl_HS_X-LOADER","HS_u-boot.img"]
      else
        ["MLO","u-boot.img"]
    end
    dtb = case new_params['dut'].name
      when /^dra7xx-/i
        case params['dut'].id
          when /revh/i
            "dra7-evm-lcd-osd.dtb"
          else
            "dra7-evm-lcd-lg.dtb"
        end
      when /^dra72x-/i
        case new_params['dut'].id
          when /revc/i
            "dra72-evm-revc-lcd-osd101t2045.dtb"
          else
            "dra72-evm-lcd-lg.dtb"
        end
      when /^dra71x-/i
        "dra71-evm-lcd-auo-g101evn01.0.dtb"
      when /^am57xx-/i
        "am57xx-evm-reva3.dtb"
    end
    new_params['server'].send_cmd("ls #{dest}/#{loaders[0]}")
    new_params['primary_bootloader'] = params['server'].response.strip if !new_params['server'].response.match(/No\s*such\s*file\s*or\s*directory/im)
    new_params['server'].send_cmd("ls #{dest}/#{loaders[1]}")
    new_params['secondary_bootloader'] = params['server'].response.strip if !new_params['server'].response.match(/No\s*such\s*file\s*or\s*directory/im)
    new_params['server'].send_cmd("ls #{dest}/boot_fit.img")
    if !new_params['server'].response.match(/No\s*such\s*file\s*or\s*directory/im)
      new_params['boot'] = params['server'].response.strip
      new_params['dtb'] = nil
    else
      new_params['server'].send_cmd("ls #{dest}/#{dtb}")
      new_params['dtb'] = params['server'].response.strip if !new_params['server'].response.match(/No\s*such\s*file\s*or\s*directory/im)
    end
    new_params
  end

  # Send command to an android device
  def send_adb_cmd (cmd, device=@equipment['dut1']) 
    device.send_adb_cmd(cmd)
  end
  
  # Send command to host (TEE) PC
  def send_host_cmd (cmd, expected_match=/.*/, timeout=10, check_cmd_echo=true, device=@equipment['server1'])
    device.send_cmd(cmd, expected_match, timeout, check_cmd_echo)
    device.response
  end
    
  # Returns true if named package is installed
  def isPkgInstalled?(pkgName)
    pkg = send_adb_cmd("shell pm list packages #{pkgName}").strip().split(':')[-1]
    pkg = nil if pkg && !pkg.match(/#{pkgName}/i) 
    pkg
  end
    
  #Un-installs android package. Raise error if it can't
  def uninstallPkg(pkgName)
    if isPkgInstalled?(pkgName)
      puts "PACKAGE #{pkgName} is installed. Going to uninstall it"
      send_adb_cmd("uninstall #{pkgName}")
    end
    raise "Could not uninstall PACKAGE: #{pkgName}" if isPkgInstalled?(pkgName)
  end
    
  #Installs android package. Raise error if it can't
  def installPkg(apk,pkgName,force=false, tout=60)
    Timeout::timeout(tout) do
      pkg = isPkgInstalled?(pkgName)
      if force && pkg
        uninstallPkg(pkg)
        pkg = nil
      end
      send_adb_cmd("install #{apk}") if !pkg
      pkg = isPkgInstalled?(pkgName)
      raise "Could not install PACKAGE: #{pkgName}" if !pkg
      return pkg
    end
    rescue Timeout::Error => e
      raise "Could not install PACKAGE: #{pkgName}\n"+e.backtrace.to_s
  end

  def setupTest(libs_var, libs_root)
    if @test_params.params_chan.instance_variable_defined?(libs_var)
      src_dir = @test_params.instance_variable_get(libs_root)
      puts "apps source dir set to #{src_dir}"
      @test_params.params_chan.instance_variable_get(libs_var).each {|lib|
        lib_info = lib.split(':')
        installPkg(File.join(src_dir,lib_info[0]), lib_info[1], false)
      }
    end
  end

  def run_test(tst_option = nil, wait=true)
    perf_matches = {}
    res_file = nil
    send_adb_cmd "shell rm #{@test_params.params_chan.res_file[0]}" if @test_params.params_chan.instance_variable_defined?(:@res_file)
    if wait
      adb_test_cmd = "shell am instrument -w #{tst_option}"
      adb_test_cmd = "shell am instrument -w #{@test_params.params_chan.test_option[0]}" if !tst_option
    else
      adb_test_cmd = "shell am instrument #{tst_option}"
      adb_test_cmd = "shell am instrument #{@test_params.params_chan.test_option[0]}" if !tst_option
    end
    send_adb_cmd "logcat -c"
    send_adb_cmd adb_test_cmd
    log_option = '*:I *:S'
    log_option = @test_params.params_chan.log_option[0] if @test_params.params_chan.instance_variable_defined?(:@log_option)
    response = send_adb_cmd "logcat -d #{log_option}"
    if @test_params.params_chan.instance_variable_defined?(:@res_file)
      puts `mkdir -p #{File.join("../",@test_params.staf_service_name.to_s)} 2>&1`
      res_file = File.join("../",@test_params.staf_service_name.to_s,File.basename(@test_params.params_chan.res_file[0]))
      File.delete(res_file) if File.exist?(res_file)
      send_adb_cmd "pull #{@test_params.params_chan.res_file[0]} #{res_file}"
      res_file = nil if !File.exist?(res_file)
    elsif @test_params.params_chan.instance_variable_defined?(:@perf_matches)
      @test_params.params_chan.perf_matches.each do |current_match|
        perf_matches[current_match] = response.scan(Regexp.new(current_match,Regexp::MULTILINE | Regexp::IGNORECASE))
      end
    end
    {'response' => response, 'perf_data' => perf_matches, 'res_file' => res_file}
  end

  def install_selenium_server
    response = send_adb_cmd "shell ps"
    if !/org\.openqa\.selenium\.android\.app/m.match(response)
      send_adb_cmd "shell am start -W -n org.openqa.selenium.android.app/.MainActivity --activity-clear-top"
      sleep 5  # Wait for server to start
    end
  end
  
  def wait_for_logcat(expected_regex, timeout) #timeout in mins
    result = send_adb_cmd("logcat  -d")
    return result if result.match(/#{expected_regex}/)
    last_date = DateTime.strptime(result.scan(/^([\d\-]+\s+[\d\.:]+)/).flatten()[-1], '%m-%d %H:%M:%S.%L').strftime('%Q').to_i + 1
    (timeout*2).times do |i|
      data = send_adb_cmd("logcat  -d -T '#{DateTime.strptime("#{last_date}", '%Q').strftime('%m-%d %H:%M:%S.%L')}'")
      if data.to_s.strip() != '' && data.match(/^[\d\-]+\s+[\d\.:]+/) 
        result += data
        last_date = DateTime.strptime(data.scan(/^([\d\-]+\s+[\d\.:]+)/).flatten()[-1], '%m-%d %H:%M:%S.%L').strftime('%Q').to_i + 1
      end
      break if data.match(/#{expected_regex}/)
      sleep 30
    end 
    return result
  end
end  # End of module

