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
  def boot(dut,ftp_server,boot_params)
    dut.send_cmd("shell ps",/dimtestvi/,2)
    processes = dut.response
    processes.each { |line|
    if(line.match(/dimtestvi/i))
      dimtest = line.match(/\d+/)[0]
      dut.send_cmd("shell kill -9 #{dimtest}",/.*/,2)
    end
    }
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
	  File.delete("\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\#{File.basename(dsp).split("_")[-1]}") if File.exists?("\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\#{File.basename(dsp).split("_")[-1]}") 
      File.copy(dsp,"\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\")
	  sleep(2)
      Dir.chdir("\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\")
      File.rename("#{File.basename(dsp)}",File.basename(dsp).split("_")[-1])
    rescue SystemCallError
      $stderr.print "File IO failed" + $!
      raise
    end
      dut.send_cmd("cd /APP",/.*/,2)
      dut.send_cmd("cd dspi",/.*/,2)
      dut.send_cmd("wget ftp\://gguser\:gguser@#{ftp_server.telnet_ip}/home/#{ftp_server.tftp_path.gsub('\\','/')}/#{File.basename(dsp).split("_")[-1]}",/100%/,10)
	  sleep(2)
    if(dut.timeout?)
      raise "wget: dsp failed"
    end 
  end
  
  def download_app(dut,ftp_server,app)
    begin
	puts "Deleting \\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\#{File.basename(app).split("_")[-1]}"
	  File.delete("\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\#{File.basename(app).split("_")[-1]}") if File.exists?("\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\#{File.basename(app).split("_")[-1]}")
      File.copy(app,"\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\")
	  sleep(2)
      Dir.chdir("\\\\#{ftp_server.telnet_ip}\\#{ftp_server.tftp_path}\\")
      File.rename("#{File.basename(app)}",File.basename(app).split("_")[-1])
    rescue SystemCallError
      $stderr.print "File IO failed" + $!
      raise
    end
      dut.send_cmd("cd /APP",/.*/,2)
      dut.send_cmd("wget ftp\://gguser\:gguser@#{ftp_server.telnet_ip}/home/#{ftp_server.tftp_path.gsub('\\','/')}/#{File.basename(app).split("_")[-1]}",/100%/,10)
	  sleep(2)
    if(dut.timeout?)
      raise "wget: dimtestvi failed"
    end 
      dut.send_cmd("chmod 777 dimtestvi",//,2)
  end
end