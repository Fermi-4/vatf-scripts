require 'FileUtils'
require File.dirname(__FILE__)+'/drvif_cfg.rb'
include DrvifCfg
require File.dirname(__FILE__)+'/evm_start.rb'
include EVMStart
require File.dirname(__FILE__)+'/xdp_var_set_src_evm.rb'
include XDPVarSetSrcEVM
require File.dirname(__FILE__)+'/xdp_var_set_tgt_PC.rb'
include XDPVarSetTgtPC
require File.dirname(__FILE__)+'/dsp_glob_cfg.rb'
include DSPGlobConfig
module BootScripts
  def boot(dut,ftp_server,boot_params,power_handler)
    power_port = dut.power_port
    if power_port !=nil
       debug_puts 'Switching off @using power switch'
       power_handler.switch_off(power_port)
       sleep(60)
    end
    power_handler.switch_on(power_port)
    sleep(60)
    dut.connect({'type'=>'serial'})
    0.upto 5 do
      dut.send_cmd("\n",dut.prompt, 30)
      debug_puts 'Sending esc character'
      sleep 1
      break if !dut.timeout?
    end

    if(boot_params != nil and ftp_server != nil)
      download_app(dut,ftp_server,boot_params['app'])
      download_dsp(dut,ftp_server,boot_params['dsp'])
    else
      puts " ======== No image download, using dimtestvi and DSP on platform"
    end
    send_board_config(dut)
  end

  def send_board_config(dut)
    send_drvif_cfg(dut)
    send_evm_start(dut)
    send_xdp_var_set_srm_evm(dut)
    send_xdp_var_set_tgt_pc(dut)
    send_dsp_glob_config(dut)
  end
  
  def download_dsp(dut,ftp_server,dsp)
    begin
      File.delete("#{ftp_server.tftp_path}\\sv01.ld") if File.exists?("#{ftp_server.tftp_path}\\sv01.ld") 
      FileUtils.cp(dsp,"#{ftp_server.tftp_path}\\")
      sleep(2)
      Dir.chdir("#{ftp_server.tftp_path}\\")
      File.rename("#{File.basename(dsp)}","sv01.ld")
    rescue SystemCallError
      $stderr.print "File IO failed" + $!
      raise
    end
      dut.send_cmd("cd /root/app/video",/.*/,2)
      dut.send_cmd("rm -f sv01\.ld",/.*/,2)
      dut.send_cmd("wget ftp\://#{ftp_server.telnet_login}\:#{ftp_server.telnet_passwd}@#{ftp_server.telnet_ip}/sv01.ld",/100%/,10)
      sleep(2)
    if(dut.timeout?)
      raise "wget: dsp failed"
    end 
  end
  
  def download_app(dut,ftp_server,app)
    begin
    puts "Deleting #{ftp_server.tftp_path}\\dimtestvi"
      File.delete("#{ftp_server.tftp_path}\\dimtestvi") if File.exists?("#{ftp_server.tftp_path}\\dimtestvi")
      FileUtils.cp(app,"#{ftp_server.tftp_path}\\")
      sleep(2)
      Dir.chdir("#{ftp_server.tftp_path}\\")
      File.rename("#{File.basename(app)}","dimtestvi")
    rescue SystemCallError
      $stderr.print "File IO failed" + $!
      raise
    end
      dut.send_cmd("cd /root/app/",/.*/,2)
      dut.send_cmd("rm -f dimtestvi",/.*/,2)
      dut.send_cmd("wget ftp\://#{ftp_server.telnet_login}\:#{ftp_server.telnet_passwd}@#{ftp_server.telnet_ip}/dimtestvi",/100%/,10)
      sleep(2)
    if(dut.timeout?)
      raise "wget: dimtestvi failed"
    end 
      dut.send_cmd("chmod 777 dimtestvi",//,2)
  end
end