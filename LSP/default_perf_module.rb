# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_test_module'

# Default Server-Side Test script implementation for LSP releases
module LspReadWritePerfScript
  include LspTestScript  

  def setup
    super
  end

  def run
      # Initialize DUT to run file-based performance test
      result = 0 	#0=pass, 1=timeout, 2=fail message detected
      perfData = []
      ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
      if @test_params.params_chan.instance_variable_defined?(:@init_cmds)
          commands = parse_cmd('init_cmds')
          result, cmd = execute_cmd(commands)
      end
      if result > 0 
          set_result(FrameworkConstants::Result[:fail], "Error preparing DUT to run performance test while executing cmd: #{cmd.cmd_to_send}")
          return
      end
      # Execute file-based performance test
      @results_html_file.add_paragraph("")
      res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"20%"})
      res_table_header = get_res_table_header()
      @results_html_file.add_row_to_table(res_table, res_table_header)
      #@results_html_file.add_row_to_table(res_table, ["Setup", "Buffer Size (KB)", "File Size (MB)", "Duration (Secs)", "MBytes/Sec"])
      file_sizes   = @test_params.params_chan.file_size[0].split(' ')
      buffer_sizes = @test_params.params_chan.buffer_size[0].split(' ')
      mnt_point = fs = ''
      mnt_point    = @test_params.params_chan.mount_point[0] if @test_params.params_chan.instance_variable_defined?(:@mount_point)
      fs           = @test_params.params_chan.filesystem[0] if @test_params.params_chan.instance_variable_defined?(:@filesystem)
      dev_node		= @test_params.params_chan.dev_node[0]
      m_regex = Regexp.new(mnt_point)

      ['Write', 'Read'].each {|type|
          if @test_params.params_chan.instance_variable_defined?(:@mount_point) then
      	    # mount before each write. do mount even if it is already mounted.
            @equipment['dut1'].send_cmd("mount -t #{fs} #{dev_node} #{mnt_point}", @equipment['dut1'].prompt, 20)
            # make sure mount ok
            @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
            if !m_regex.match(@equipment['dut1'].response) then
              #raise "device mount failed!!"     # Disabling for now due to LspTargetController bug
            end
          end
        
          i=0
          file_sizes.each {|file_size|
              buffer_sizes.each {|buffer_size|
                  (type=='Read') ? (is_read=true) : (is_read=false)
                  result, dur, bw, cpu, name = run_perf_test(is_read, mnt_point, buffer_size, file_size, i)
                  raise "Error executing #{mnt_point} performance test" if result > 0
  
                  table_row = get_table_row(type, fs, buffer_size, file_size, dur, bw, cpu)
                  @results_html_file.add_row_to_table(res_table, table_row)
                  #@results_html_file.add_row_to_table(res_table,["#{type}, fs=#{fs}",(buffer_size.to_i/1024).to_s, (file_size.to_i/1048576).to_s, (dur.to_i/1000000).to_s, bw])
                  
                  perfData << {'name' => "#{name.to_s}_BW", 'value' => table_row[4], 'units' => get_res_table_header()[4]}
                  perfData << {'name' => "#{name.to_s}_CPU", 'value' => table_row[5] , 'units' => '%'}
                  i+=1	        
              }
          }
        
          # umount the device to make writeback happen
          if @test_params.params_chan.instance_variable_defined?(:@mount_point) then
            @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 10)
            # make sure umount ok
            @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
            if m_regex.match(@equipment['dut1'].response) then
              # raise "device umount failed!!"  # Disabling for now due to LspTargetController bug
            end
          end
      }
      
      # temp: to be removed, hardcode test file here.
      if @test_params.params_chan.instance_variable_defined?(:@mount_point) then
        @equipment['dut1'].send_cmd("mount #{dev_node} #{mnt_point} -t #{fs}", @equipment['dut1'].prompt, 20)
        @equipment['dut1'].send_cmd("rm #{mnt_point}/test*", @equipment['dut1'].prompt, 120)
        @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 60)
        @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 60)
      end
      
      if result == 0 
          if perfData.size > 0
            set_result(FrameworkConstants::Result[:pass], "Test Pass.", perfData)
          else
            set_result(FrameworkConstants::Result[:pass], "Test Pass.")
          end  
      elsif result == 1
          set_result(FrameworkConstants::Result[:fail], "Timeout executing performance test")
      elsif result == 2
          set_result(FrameworkConstants::Result[:fail], "Fail message received executing performance test")
      else
          set_result(FrameworkConstants::Result[:nry])
      end
    
      ensure 
          result, cmd = execute_cmd(ensure_commands) if @test_params.params_chan.instance_variable_defined?(:@ensure)
  
  end

  def clean
    super
  end

end

