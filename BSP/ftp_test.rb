require 'net/ftp'
begin
 dut_ftp = Net::FTP.new(ARGV[0])
 dut_ftp.login(ARGV[1], ARGV[2])
 dut_ftp.nlst(ARGV[3]).each {|f|
      dst_f = File.join(ARGV[4],ARGV[5].to_s+'_'+f)
if (ARGV[6])	    

    puts "About to start binary get of file with name #{f}\n"
    dut_ftp.getbinaryfile(File.join(ARGV[3],f), dst_f)
 else
 puts "About to start ascii get of file with name #{f}\n"
dut_ftp.gettextfile(File.join(ARGV[3],f), dst_f)	 

end
 dut_ftp.close
#dst_log_files << dst_f
 }
 rescue SystemCallError
	  puts "System Call Error exception from ftp script\n"
 ensure
  dut_ftp.close
  #puts "Log_files from ftp script is #{dst_log_files}\n"
 #  return dst_log_files
  end
 