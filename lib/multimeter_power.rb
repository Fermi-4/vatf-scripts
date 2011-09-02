module MultimeterModule
def run_get_multimeter_output(multimeter=@equipment['ti_multimeter'])
  sleep 5    # Make sure multimeter is configured and DUT is in the right state
  volt_reading = []
  counter=0
  while counter < @test_params.params_chan.loop_count[0].to_i
    Kernel.print("Collecting sample #{counter}\n")
    multimeter.send_cmd("READ?", /.+?,.+?,.+?,.+?,[^\r\n]+/, @test_params.params_chan.timeout[0].to_i, false)
    d =  multimeter.response
    Kernel.print("#{d}\n")
    volt_reading << multimeter.response
    counter += 1
    #sleep 0.5
  end
  return sort_raw_data(volt_reading)
end

# Procedure to meaasure power on AM37x.
# chan1= vdrop at vdd1 , chan2=vdrop at vdd2, chan3=ignore, chan4=vdd1, chan5=vdd2
def sort_raw_data(volt_readings)
  chan_all_volt_reading = Hash.new
  chan_1_volt_readings = Array.new
  chan_2_volt_readings = Array.new
  chan_3_volt_readings = Array.new
  chan_4_volt_readings = Array.new
  chan_5_volt_readings = Array.new
  chan_1_current_readings = Array.new
  chan_2_current_readings = Array.new
  volt_reading_array = Array.new
  volt_readings.each do |current_line| 
    current_line_arr = current_line.strip.split(/[,\r\n]+/)
    if current_line_arr.length == 5 && current_line.match(/([+-]\d+\.\d+E[+-]\d+,){4}[+-]\d+\.\d+E[+-]\d+/)
      volt_reading_array.concat(current_line_arr)
    else 
    puts "NOTHING #{current_line}"
    end
  end
  volt_reading_array.each_index{|array_index|
   mod = array_index % 5 
   case mod
     when  0
     temp = volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     chan_1_volt_readings << temp
     chan_1_current_readings << temp/0.05
     when  1
     temp = volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     chan_2_volt_readings << temp
     chan_2_current_readings << temp/0.1
     when  2
     chan_3_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     when  3
     chan_4_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     when  4
     chan_5_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
   end 
  }
  # each reading for each channel
  chan_all_volt_reading["chan_1"] = chan_1_volt_readings
  chan_all_volt_reading["chan_2"] = chan_2_volt_readings
  chan_all_volt_reading["chan_3"] = chan_3_volt_readings
  chan_all_volt_reading["chan_4"] = chan_4_volt_readings
  chan_all_volt_reading["chan_5"] = chan_5_volt_readings
  chan_all_volt_reading["chan_1_current"] = chan_1_current_readings
  chan_all_volt_reading["chan_2_current"] = chan_2_current_readings
  
  return chan_all_volt_reading
 end

end 
