require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../android_test_module'  
include AndroidTest
include AndroidKeyEvents

def run
  puts "ENTERING FUNCTION RUN"
  send_events_for("__back__") 
  cmd = "logcat  -c"
  send_adb_cmd cmd
  @equipment['dut1'].connect({'type'=>'serial'})
  puts "Connected to Serial ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.enable_eth[0])
  puts "Enabling ETH ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.enable_dhcp[0])
  puts "Enabling DHCP ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.set_dns[0])
  puts "Setting DNS ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.set_proxy[0])
  puts "Setting PROXY ..."
  sleep 0.5
  cmd = cmd = "install " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.app_name[0]
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil and !data.to_s.include?("INSTALL_FAILED_ALREADY_EXISTS")
   puts "#{data}"
   exit 
  end 
  cmd = @test_params.params_chan.intent[0] + " -e webaddress " + @test_params.params_chan.webaddress[0] + " -e testtype " +  @test_params.params_chan.test_type[0] 
 data = send_adb_cmd  cmd
 get_data
end 

def get_data
   puts "ENTERING FUNCTION get_data" 
   sleep @test_params.params_chan.delay[0].to_i
   cmd = "logcat  -d -s mWebView:*"
   response = "junk data"
   count = 0
   flag = 0 
   time =  Time.now.strftime("%s").to_i
   while !response.to_s.include?("mWebView")
    count = count + 1 
    puts "Inside the LOOP #{count}, Waiting for Application log"
    response = send_adb_cmd cmd
    time2 =  Time.now.strftime("%s").to_i
    delta_time = time2 - time
    if delta_time > 600
     flag = 1
     break;
    end 
   end
   if flag == 0 
    response = send_adb_cmd cmd
    set_result(FrameworkConstants::Result[:pass],"Test case PASS.",extract_data(response)) 
   else
    set_result(FrameworkConstants::Result[:fail],"Test case FAIL.","No data") 
   end 
end 

def extract_data(response)
    puts "ENTERING FUNCTION extract_data"
    perf_data = [];
    if @test_params.params_chan.test_type[0] == "acid"
      data = response.scan(/JavaScript output:\s*([0-9]+)/)[0]
     perf_data << {'name' => "acid", 'value' =>data[0], 'units' => "%"} 
    elsif @test_params.params_chan.test_type[0].to_s.strip == "sunspider" or   @test_params.params_chan.test_type[0].to_s.strip == "krakenbenchmark"
    puts "ENTERING condition sunspider"  
    response.split('%').each{|line| 
    data  = line.gsub(/.*?output:\s*/,"")
     data.scan(/(\w*:)\s*([0-9.]+)\s*.*?([0-9.]+)/){|name,mean,stderrs|
      puts "#{name} :  #{mean} : #{stderrs}"
     perf_data << {'name' => name, 'value' =>mean, 'units' => "ms"} 
     perf_data << {'name' => name + "_stderrs", 'value' =>stderrs, 'units' => "%"}  
    }
   }
   elsif @test_params.params_chan.test_type[0].to_s.strip == "themaninblue"
    data = response.scan(/JavaScript output:\s*([0-9.]+)/)[0]
    perf_data << {'name' => "themaninblue", 'value' =>data[0], 'units' => "fps"}
  elsif @test_params.params_chan.test_type[0].to_s.strip == "v8"
    filtered_data =  Array.new
    response.split("\n").each{|line|
     if line.to_s.include?("Score")
       filtered_data[0] = line 
     elsif  line.to_s.include?("Richards")
       filtered_data[1] = line 
     elsif  line.to_s.include?("DeltaBlue")
       filtered_data[2] = line 
     elsif  line.to_s.include?("Crypto")
       filtered_data[3] = line 
     elsif  line.to_s.include?("RayTrace")
       filtered_data[4] = line 
     elsif  line.to_s.include?("EarleyBoyer")
       filtered_data[5] = line 
     elsif  line.to_s.include?("RegExp")
       filtered_data[6] = line 
     elsif  line.to_s.include?("Splay")
       filtered_data[7] = line
     else 
     puts "No match for the reading"
     end  
    }
   filtered_data.each{|line|
   line.scan(/(\w*):\s*([0-9.]+)/){|name,value|
    perf_data << {'name' => name, 'value' =>value,'units' => "no unit"}
    }
   }
  else 
    puts "NO MATCH: Test case Not Defined"
  end 
   return perf_data    
end 



