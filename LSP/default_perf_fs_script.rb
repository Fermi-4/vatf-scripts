# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_perf_module'
# Default Server-Side Test script implementation for LSP releases
include LspReadWritePerfScript

def setup
  #super
	BuildClient.enable_config_step
  self.as(LspReadWritePerfScript).setup
end

def run
  #super  
  self.as(LspReadWritePerfScript).run
end

def clean
  #super
  self.as(LspReadWritePerfScript).clean
end

private
def run_perf_test(is_read, mnt_point, buffer_size, file_size, counter)
    result = 0
    action_cmd='', parse_txt=''
    if is_read
        action_cmd = 'TPfsread'
        parse_txt  = 'fileread'
    else
        action_cmd= 'TPfswrite'
        parse_txt  = 'filewrite'
    end 
    @equipment['dut1'].send_cmd("df -h", @equipment['dut1'].prompt, 10)
    sleep 5
    @equipment['dut1'].send_cmd("pspTest ThruPut #{action_cmd} #{mnt_point}/test#{counter} #{buffer_size} #{file_size}",
                                /#{parse_txt}:\s+percentage\s+cpu\s+load:\s+[\d|\.]+%/,
                                900) #orignal is 5400. too long. 900 should be enough. if 0.2MB/S for 100MB, it only need 500s.
    if @equipment['dut1'].timeout?
        result = 1
        return result
    end
    duration = /#{parse_txt}:.*in\s+[um]+secs:\s+(-*\d+)/.match(@equipment['dut1'].response)[1]
    bw       = /#{parse_txt}:\s+Mega\s+Bytes\/Sec:\s+([\d|\.]+)/.match(@equipment['dut1'].response)[1]
    cpu      = /#{parse_txt}:\s+percentage\s+cpu\s+load:\s+([\d|\.]+%)/.match(@equipment['dut1'].response)[1]
    @equipment['dut1'].send_cmd("df -h", @equipment['dut1'].prompt, 10)
    [result, duration, bw, cpu] 
end

def get_table_row(type, fs, buffer_size, file_size, dur, bw, cpu)
  rtn = ["#{type}, fs=#{fs}","%0.2f"%(buffer_size.to_f/1024).to_s, "%0.2f"%(file_size.to_f/1048576).to_s, dur, bw, cpu] 
end

def get_res_table_header()
	rtn = ["Setup", "Buffer Size (KB)", "File Size (MB)", "Duration (uSecs)", "MBytes/Sec", "CPU Load"]
end