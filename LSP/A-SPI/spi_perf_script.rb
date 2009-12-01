# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases
include LspReadWritePerfScript

def setup
  self.as(LspReadWritePerfScript).setup
end

def run
  self.as(LspReadWritePerfScript).run 
end

def clean
  self.as(LspReadWritePerfScript).clean
end

private
def run_perf_test(is_read, mnt_point, buffer_size, file_size, counter)
    result = 0
    action_cmd='', parse_txt=''
    if is_read
        action_cmd = 'SpiRead'
        parse_txt  = 'Read'
    else
        action_cmd= 'SpiWrite'
        parse_txt  = 'Write'
    end  
    dev_node = @test_params.params_chan.dev_node[0]
    sleep 2
    @equipment['dut1'].send_cmd("pspTest ThruPut #{action_cmd} #{dev_node} #{buffer_size} #{file_size}",
                                #/#{parse_txt}:\s+Kbits\/Sec:\s+[\d\.]+/,
                                /#{parse_txt}:\s+percentage\s+cpu\s+load:\s+[\d|\.]+%/,
                                120)   
    if @equipment['dut1'].timeout?
        result = 1
        return result
    end
    cpu = 'unknown'
    duration = /#{parse_txt}:.*in\s+uSec:\s+(\d+)/.match(@equipment['dut1'].response)[1]
    bw       = /#{parse_txt}:\s+Kbits\/Sec:\s+([\d|\.]+)/.match(@equipment['dut1'].response)[1]
    if /#{parse_txt}:\s+percentage\s+cpu\s+load:\s+([\d|\.]+%)/.match(@equipment['dut1'].response)
      cpu = /#{parse_txt}:\s+percentage\s+cpu\s+load:\s+([\d|\.]+%)/.match(@equipment['dut1'].response)[1] 
    end
    [result, duration, bw, cpu] 
end

def get_table_row(type, fs, buffer_size, file_size, dur, bw, cpu)
  rtn = [type, buffer_size, (file_size.to_i/1024).to_s, (dur.to_i/1000).to_s, bw, cpu] 
end

def get_res_table_header()
	rtn = ["Setup", "Buffer Size (B)", "File Size (KB)", "Duration (msecs)", "KBits/Sec", "CPU Load"]
end