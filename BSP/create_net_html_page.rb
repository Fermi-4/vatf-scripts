#Initial release - 02-27-2012

module CreateNetHtmlPage
  ############################################################## process_perf_data #####################################################################
  # ---------------------------------------- Parse CETK test results for actual performance data ---------------------------------------- 
  def process_perf_data
    puts "\n Entering create_net_html_page::process_perf_data "+ __LINE__.to_s
    
    # ---------------------------------------- If protocol being tested is TCP ---------------------------------------- 
    if @test_protocol == "TCP"
      case
      #-------------------------- parse TCP ping test result data --------------------------
      when @test_type == "ping"
        @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i)
        p=4 ; unts="ms"
        
      #-------------------------- parse TCP throughput test result data (send, recv, sendrecv)--------------------------
      when @test_type == "throughputs"
        case
        when @direction == "sendrecv"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i)
          p=2 ; unts="kbps"
        when @direction == "send"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i)
          p=2 ; unts="kbps"
        when @direction == "recv"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i)
          p=2 ; unts="kbps"
        end
        
      when @test_type == "throughput"
        if @direction == "sendrecv"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i)
          p=2 ; unts="kbps"
        else
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i)
          p=2 ; unts="kbps"
        end
      else
        @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)$/i)
        p=2 ; unts="kbps"
      end
      
    # ---------------------------------------- If protocol being tested is UDP ---------------------------------------- 
    elsif @test_protocol == "UDP"
      case
      #-------------------------- parse UDP throughput test result data (send, recv, sendrecv)--------------------------
      when @test_name.match(/.+(Throughput)/i)
        case
        when @direction == "sendrecv"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)$/i)
          p=1 ; unts="kbps"
        when @direction == "send"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+\/[\d.]+)$/i)
          p=2 ; unts="kbps"
        when @direction == "recv"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\/\d+)/i)
          p=1 ; unts="kbps"
        else
          puts "\n ----------------- Test was not successful --------------------- "+ __LINE__.to_s
        end
        
      #-------------------------- Parse UDP ping test result data --------------------------
      when @test_type == "ping"
        @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)$/i)
        p=4 ; unts="ms"
        
      #-------------------------- Parse UDP loss test result data (sen, recv)--------------------------
      when @test_type == "loss"
        case
        when @direction == "send"
          @data<<@all_lines.scan(/\*\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+\/[\d.]+)/i)	
          p=2 ; unts="ms"
        when @direction == "recv"
          @data<<@all_lines.scan(/\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+\/[\d.]+)$/i)
          p=3 ; unts="ms"
        end
      end
    end
    
    puts "\n\n----------------------- Creating ws2_perfdata ----------------------- "+ __LINE__.to_s
    @array_lines=@data[0].length
    
    for x in 0..@data[0].length - 1 do
      @ws2_perfdata << {'name'=> "BW_#{@data[0][x][0]}", 'value'=> @data[0][x][p].to_f, 'units' => unts.to_s}
    end
    
  end
  
  
  ############################################################## collect_header_data #####################################################################
  # ---------------------------------------- Parse CETK test results for HEADER data and test status ----------------------------------------- 
  def collect_test_type_data
    puts "\n Entering net_common_mod::collect_header_data "+ __LINE__.to_s

    # ------------- determine type of performance test and data flow direction (ie send, receive, throughput, ping, etc) ------------
    case
      when @test_name.match(/.+(Throughputs)/i) || @test_name.match(/.+(Trhoughputs)/i)
        case
        when @test_name.match(/.+(Send\/Recv)/i)
          @test_type = "throughputs" ; @direction = "sendrecv"
        when @test_name.match(/.+(Send)/i)
          @test_type = "throughputs" ; @direction = "send"
        when @test_name.match(/.+(Recv)/i)
          @test_type = "throughputs" ; @direction = "recv"
        else
          puts "\n ----------------- Test was not successful --------------------- "+ __LINE__.to_s
        end

      when @test_name.match(/.+(Throughput)/i)
        case
        when @test_name.match(/.+(SendRecv)/i)
          @test_type = "throughput" ; @direction = "sendrecv"
        when @test_name.match(/.+(Send)/i)
          @test_type = "throughput" ; @direction = "send"
        when @test_name.match(/.+(Recv)/i)
          @test_type = "throughput" ; @direction = "recv"
        else
          puts "\n ----------------- Test was not successful --------------------- "+ __LINE__.to_s
        end

      when @test_name.match(/.+(Ping)/i)
        @test_type = "ping" ; @direction = "N/A"
        
      when @test_name.match(/.+(Loss)/i)
        case
        when @test_name.match(/.+(Send)/i)
          @test_type = "loss" ; @direction = "send"
        when @test_name.match(/.+(Recv)/i)
          @test_type = "loss" ; @direction = "recv"
        end
    end
      
    puts "\n -------------------- Test Type: #{@test_type} ------- Test Direction: #{@direction} -------------------- "+ __LINE__.to_s
  end
  
  
  ############################################################## create_test_result_header #####################################################################
  def create_test_result_header
    puts "\n Entering create_net_html_page::create_test_result_header "+ __LINE__.to_s
    
    # -------------------------------------- Create EVM test case information portion of the test results data page --------------------------------------
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Test Case Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    res_table = @results_html_file.add_table([["Test Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Test ID",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Test Execution Time (H:MM:SS:MS)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Operating System",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["OS Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Build Number",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    @results_html_file.add_rows_to_table(res_table,[[["#{@test_name}",{:bgcolor => "white"},{:size => "2.5"}],
                    ["#{@tst_id}",{:bgcolor => "white"},{:size => "2"}],
                    ["#{@exec_time}",{:bgcolor => "white"},{:size => "2"}],
                    ["#{@op_system}",{:bgcolor => "white"},{:size => "2"}],
                    ["#{@os_ver}",{:bgcolor => "white"},{:size => "2"}],
                    ["#{@build_number}",{:bgcolor => "white"},{:size => "2"}]]])
  
    # ---------------------------------------- Create EVM information portion of the test results data page ----------------------------------------
    res_table = @results_html_file.add_table([["EVM Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    res_table = @results_html_file.add_table([["Device Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Processor Architecture",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Processor Type",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Processor Level",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                    ["Processor Revision",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    @results_html_file.add_rows_to_table(res_table,[[["#{@dev_name}",{:bgcolor => "white"},{:size => "2.5"}],
                    ["#{@proc_arc}",{:bgcolor => "white"},{:size => "2.5"}],
                    ["#{@proc_type}",{:bgcolor => "white"},{:size => "2.5"}],
                    ["#{@proc_lvl}",{:bgcolor => "white"},{:size => "2.5"}],
                    ["#{@proc_rev}",{:bgcolor => "white"},{:size => "2"}]]])
  end


  ############################################################## create_html_header_page #####################################################################
  def create_html_header_page
    # ---------------------------------------- Create EVM performance information portion of the test results data page ----------------------------------------
    puts "\n Entering create_net_html_page::create_html_header_page "+ __LINE__.to_s
    res_table = @results_html_file.add_table([["Performance Information",{:bgcolor => "#008080", :align => "center", :colspan => "5"}, {:color => "white" ,:size => "4"}]])
    total_lines = @array_lines - 1
    format_flag = k = 0
    puts "\n\n----------------------- Processing test results ----------------------- "+ __LINE__.to_s
  
    # ---------------------------------------- If protocol being tested is TCP ---------------------------------------- 
    if @test_protocol == "TCP"
      puts "\n ----------------- #{@test_protocol} ------ #{@direction} --------------------- "+ __LINE__.to_s
      
      case
      #-------------------------- parse TCP ping test result data --------------------------
      when @test_type == "ping"
        select_header(res_table, total_lines,"ping")

      when @test_type == "throughput" || @test_type == "throughputs"
        if @direction == "sendrecv"
          select_header(res_table, total_lines,"tcp_sendrecv")
        else
          select_header(res_table, total_lines,"tcp_throughput")
        end
      else
        puts "\n ----------------- Test was not successful --------------------- "+ __LINE__.to_s
      end
    end
    
    # ---------------------------------------- If protocol being tested is UDP ---------------------------------------- 
    if @test_protocol == "UDP"
      puts "\n ------------------------ #{@test_protocol} ---- #{@test_type} ------------------------ "+ __LINE__.to_s
      
      if @test_type == "throughput"
        if @direction == "sendrecv"
          select_header(res_table, total_lines,"udp_sendrecv")
        elsif @direction == "send"	|| @direction == "recv"
          select_header(res_table, total_lines,"udp_throughput")
        end
        
      elsif @test_type == "ping" 
        select_header(res_table, total_lines,"ping")
      
      elsif @test_type == "loss"
        select_header(res_table, total_lines,"udp_loss")
      end
    end
  end
  
  
  ############################################################## select_header #####################################################################
  def select_header(res_table, total_lines, test_type)
    profile = 0
      
    case
    #-------------------------- parse TCP ping test result data --------------------------
    when test_type == "ping"
      profile = 4
      
      res_table = @results_html_file.add_table([["Send Packet (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Recv Packet (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Bytes Sent (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Bytes Rcvd (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Latency (ms)",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    when test_type == "tcp_sendrecv"
      profile = 4
        
      res_table = @results_html_file.add_table([["Send Packet (Bytes)",{:bgcolor => "white"},{:color => "blue",:size => "3"}],
              ["Send Rate (Kbps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
              ["Send CPU Util (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
              ["Recv Rate (Kbps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
              ["Recv CPU Utilization (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    when test_type == "tcp_throughput" || @test_type == "throughputs"
      profile = 3
        
      case
      when @direction == "send"
        pram1 = "Send" ; pram2 = "Sent" 
      when @direction == "recv"
        pram1 = "Recv" ; pram2 = "Rcvd"
      end

      res_table = @results_html_file.add_table([["#{pram1} Packet (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
              ["Bytes #{pram2} (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
              ["#{pram1} Rate (Kbps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
              ["CPU Utilization (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])	

    when test_type == "udp_throughput"
        profile = 6
          
        if @direction == "send"
          puts "\n---------- Enter OTHER SEND routine ------- "+ __LINE__.to_s
          @var1 = "Send Packet (Bytes)";@var2 = "Bytes Sent (Bytes)";@var3 = "Send Rate (Kbps)";@var4 = "Recv Rate (Kbps)"
          @var5 = "CPU utilization (%)";@var6 = "Pkts Recv Pct (%)";@var7 = "Pkts Rcvd/Sent (Recv/Sent)"
        elsif @direction == "recv"
          @var1 = "Recv Packet (Bytes)";@var2 = "Send Rate (Kbps)";@var3 = "Bytes Rcvd (Bytes)";@var4 = "Recv Rate (Kbps)"
          @var5 = "CPU Util (%)";@var6 = "Pkts Rcvd (%)";@var7 = "Pkts Rcvd (Rcvd/Sent)"
        end
          
        res_table = @results_html_file.add_table([["#{@var1}",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["#{@var2}",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["#{@var3}",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["#{@var4}",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["#{@var5}",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["#{@var6}",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["#{@var7}",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    when test_type == "udp_loss"
      if @direction == "send" 
        puts "\n---------- Enter UDP LOSS SEND routine ------- "+ __LINE__.to_s
        profile = 5
          
        res_table = @results_html_file.add_table([["Send Packet (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Bytes Sent (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Send Rate (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["CPU utilization (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Pkts Recv Pct (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Pkts Rcvd/Sent ( )",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

      elsif @direction == "recv"
        puts "\n---------- Enter UDP LOSS RECEIVE routine ------- "+ __LINE__.to_s
        profile = 6
          
        res_table = @results_html_file.add_table([["Receive Packet (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Send Rate (kbps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Bytes Rcvd (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Recv Rate (kbps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["CPU utilization (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Pkts Rcvd (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Pkts Rcvd/Sent ( Recv/Sent)",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
      end
      
    when test_type == "udp_sendrecv"
        #puts "\n---------- Enter UDP Send/Receive routine ------- "+ __LINE__.to_s
        profile = 6
          
        res_table = @results_html_file.add_table([["Send Packet (Bytes)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Send Rate (KBps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Packets Recvd (% recv/sent)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Send CPU Util (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Recv Rate (KBps)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Packets Recvd (% recv/sent)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                  ["Recv CPU Util (%)",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
    end
      
    for j in 0..total_lines do
      write_test_data(res_table,j,profile)
    end
  end
  
  
  ############################################################## write_data #####################################################################
  def write_test_data(res_table,j,format_flag)
    case
    when format_flag.to_i == 3
      @results_html_file.add_rows_to_table(res_table,[[[@data[0][j][0],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][1],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][2],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][3],{:bgcolor => "white"},{:size => "2"}]]])
      
    when format_flag.to_i == 4
        @results_html_file.add_rows_to_table(res_table,[[[@data[0][j][0],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][1],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][2],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][3],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][4],{:bgcolor => "white"},{:size => "2"}]]])
        
    when format_flag.to_i == 5
        @results_html_file.add_rows_to_table(res_table,[[[@data[0][j][0],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][1],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][2],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][3],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][4],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][5],{:bgcolor => "white"},{:size => "2"}]]])

    when format_flag.to_i == 6
        @results_html_file.add_rows_to_table(res_table,[[[@data[0][j][0],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][1],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][2],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][3],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][4],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][5],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][6],{:bgcolor => "white"},{:size => "2"}]]])

    when format_flag.to_i == 9
        @results_html_file.add_rows_to_table(res_table,[[[@data[0][j][0],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][1],{:bgcolor => "white"},{:size => "2"}], [@data[0][j][2],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][3],{:bgcolor => "white"},{:size => "2"}], [@data[0][j][4],{:bgcolor => "white"},{:size => "2"}],
              [@data[0][j][5],{:bgcolor => "white"},{:size => "2"}], [@data[0][j][6],{:bgcolor => "white"},{:size => "2"}]]])
    end
       
    sleep 1
  end
end



