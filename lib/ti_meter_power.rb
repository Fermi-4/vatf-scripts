require File.dirname(__FILE__)+'/plot'
include TestPlots

module TiMeterPower

def get_ti_meter_power_perf(read_time, multimeter=@equipment['ti_multimeter'])
  perf = []
  multimeter.read_for(read_time)
  multimeter_readings = run_get_multimeter_output(multimeter.response)     
  power_readings = calculate_power_consumption(multimeter_readings )
  # Generate the plot of the power consumption for the given application
  power_plots = {}
  power_plots['Total_power'] = power_consumption_plot(power_readings['Total_power'], 'Total_power')
  power_plots['EVM_0V9'] = power_consumption_plot(power_readings['EVM_0V9'], 'EVM_0V9')
  power_plots['EVM_1V8A'] = power_consumption_plot(power_readings['EVM_1V8A'], 'EVM_1V8A')
  power_plots['EVM_1V8B'] = power_consumption_plot(power_readings['EVM_1V8B'], 'EVM_1V8B')
  power_plots['EVM_VTT1V5ALT'] = power_consumption_plot(power_readings['EVM_VTT1V5ALT'], 'EVM_VTT1V5ALT')
  power_plots['EVM_3V3'] = power_consumption_plot(power_readings['EVM_3V3'], 'EVM_3V3')
  power_plots['EVM_5V0'] = power_consumption_plot(power_readings['EVM_5V0'], 'EVM_5V0')
  power_plots['EVM_1V5'] = power_consumption_plot(power_readings['EVM_1V5'], 'EVM_1V5')
  power_plots['EVM_1V0AVS'] = power_consumption_plot(power_readings['EVM_1V0AVS'], 'EVM_1V0AVS')
  power_plots['EVM_1V0CON'] = power_consumption_plot(power_readings['EVM_1V0CON'], 'EVM_1V0CON')
  power_plots['EVM_Expansion'] = power_consumption_plot(power_readings['EVM_Expansion'], 'EVM_Expansion')
  
  power_plots.each do |vdd, current_file|
    file_path, mygraphurl = upload_file(current_file)
    @results_html_file.add_paragraph("#{vdd} POWER CONSUMPTION PLOT POINT BY POINT",nil, nil,mygraphurl)
  end
  perf = save_results(power_readings, multimeter_readings)
  return perf
end

def save_results(power_consumption,voltage_reading)
  perf = []
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["POWER CONSUMPTION POINT BY POINT",{:bgcolor => "336666", :colspan => "6"},{:color => "white"}]],{:border => "1",:width=>"20%"})
  count = 0
  @results_html_file.add_row_to_table(res_table,["Data Idx", "EVM_0V9(mw)","EVM_1V8A(mw)","EVM_1V8B(mw)","EVM_VTT1V5ALT(mw)","EVM_3V3(mw)","EVM_5V0(mw)","EVM_1V5(mw)","EVM_1V0AVS(mw)","EVM_1V0CON(mw)","EVM_Expansion(mw)","EVM_Total(mw)"])
  power_consumption['EVM_0V9'].each{ |power|
    @results_html_file.add_row_to_table(res_table,[count.to_s,power.to_s, power_consumption['EVM_1V8A'][count].to_s, power_consumption['EVM_1V8B'][count].to_s, power_consumption['EVM_VTT1V5ALT'][count].to_s, power_consumption['EVM_3V3'][count].to_s, power_consumption['EVM_5V0'][count].to_s, power_consumption['EVM_1V5'][count].to_s, power_consumption['EVM_1V0AVS'][count].to_s, power_consumption['EVM_1V0CON'][count].to_s, power_consumption['EVM_Expansion'][count].to_s, power_consumption['Total_power'][count].to_s])
    count += 1
  }
  perf << {'name' => "EVM_0V9 Power", 'value' => power_consumption['EVM_0V9'], 'units' => "mw"}
  perf << {'name' => "EVM_1V8A Power", 'value' => power_consumption['EVM_1V8A'], 'units' => "mw"}
  perf << {'name' => "EVM_1V8B Power", 'value' => power_consumption['EVM_1V8B'], 'units' => "mw"}
  perf << {'name' => "EVM_VTT1V5ALT Power", 'value' => power_consumption['EVM_VTT1V5ALT'], 'units' => "mw"}
  perf << {'name' => "EVM_3V3_0V9 Power", 'value' => power_consumption['EVM_3V3'], 'units' => "mw"}
  perf << {'name' => "EVM_5V0_0V9 Power", 'value' => power_consumption['EVM_5V0'], 'units' => "mw"}
  perf << {'name' => "EVM_1V5 Power", 'value' => power_consumption['EVM_1V5'], 'units' => "mw"}
  perf << {'name' => "EVM_1V0AVS Power", 'value' => power_consumption['EVM_1V0AVS'], 'units' => "mw"}
  perf << {'name' => "EVM_1V0CON Power", 'value' => power_consumption['EVM_1V0CON'], 'units' => "mw"}
  perf << {'name' => "EVM_Expansion Power", 'value' => power_consumption['EVM_Expansion'], 'units' => "mw"}
  perf << {'name' => "Total_power Power", 'value' => power_consumption['Total_power'], 'units' => "mw"}
  return perf
end


def run_get_multimeter_output(response)
    v_cu_readings = Hash.new
    vdd_matches = {'u14' => 'evm_0V9', 'u11' => 'evm_1V8A', 'u7' => 'evm_1V8B', 'u59' => 'evm_VTT1V5ALT',
		  'u22' => 'evm_3V3', 'u17' => 'evm_5V0', 'u42' => 'evm_1V5', 'u23' => 'evm_1V0AVS',
                  'u18' => 'evm_1V0CON', 'expansion' => 'evm_Expansion'}
    module_regexp = /!Power Monitor.*?#Expansion\s*1\s*[0-9]+mV\s*[0-9]+uA/im

    idx = 0
    response.scan(module_regexp).each{|valid_response|
      valid_response.split("\n").each{|line|
        current_vdd = line.scan(/#(\w+)\s+([\(\)\/\w\s]+?)\s+([\d-]+)\w+\s+([\d-]+)\w+/)
	if !current_vdd.empty?
          vdd = current_vdd[0][0].strip.downcase

          if !v_cu_readings[vdd_matches[vdd]+'_v']
            v_cu_readings[vdd_matches[vdd]+'_v'] = []
            v_cu_readings[vdd_matches[vdd]+'_cur'] = []
          end 
	  v_cu_readings[vdd_matches[vdd]+'_v'] << current_vdd[0][2]
          v_cu_readings[vdd_matches[vdd]+'_cur'] << current_vdd[0][3]
        end
      }
      idx+=1
   }
   return v_cu_readings
end

def calculate_power_consumption(v_cu_readings)
    power_consumption = Hash.new
    evm_0V9_power= Array.new
    evm_1V8A_power= Array.new
    evm_1V8B_power= Array.new
    evm_VTT1V5ALT_power= Array.new
    evm_3V3_power= Array.new
    evm_5V0_power= Array.new
    evm_1V5_power= Array.new
    evm_1V0AVS_power= Array.new
    evm_1V0CON_power= Array.new
    evm_Expansion_power= Array.new
    total_power = Array.new
    v_cu_readings['evm_0V9_cur'].each_index{|i|
	    evm_0V9_power << (v_cu_readings['evm_0V9_v'][i].to_f * v_cu_readings['evm_0V9_cur'][i].to_f) / 1000000 
	    evm_1V8A_power << (v_cu_readings['evm_1V8A_v'][i].to_f  * v_cu_readings['evm_1V8A_cur'][i].to_f) / 1000000 
	    evm_1V8B_power << (v_cu_readings['evm_1V8B_v'][i].to_f  * v_cu_readings['evm_1V8B_cur'][i].to_f) / 1000000
	    evm_VTT1V5ALT_power << (v_cu_readings['evm_VTT1V5ALT_v'][i].to_f  * v_cu_readings['evm_VTT1V5ALT_cur'][i].to_f) / 1000000
	    evm_3V3_power << (v_cu_readings['evm_3V3_v'][i].to_f  * v_cu_readings['evm_3V3_cur'][i].to_f) / 1000000
	    evm_5V0_power << (v_cu_readings['evm_5V0_v'][i].to_f  * v_cu_readings['evm_5V0_cur'][i].to_f) / 1000000
	    evm_1V5_power << (v_cu_readings['evm_1V5_v'] [i].to_f  * v_cu_readings['evm_1V5_cur'][i].to_f) / 100000
	    evm_1V0AVS_power << (v_cu_readings['evm_1V0AVS_v'][i].to_f  * v_cu_readings['evm_1V0AVS_cur'][i].to_f) / 1000000
	    evm_1V0CON_power << (v_cu_readings['evm_1V0CON_v'][i].to_f  * v_cu_readings['evm_1V0CON_cur'][i].to_f) / 1000000
	    evm_Expansion_power << (v_cu_readings['evm_Expansion_v'][i].to_f  * v_cu_readings['evm_Expansion_cur'][i].to_f) / 1000000  
            total_power << evm_0V9_power[i] + evm_1V8A_power[i] + evm_1V8B_power[i] + evm_VTT1V5ALT_power[i] + evm_3V3_power[i] + evm_5V0_power[i] + evm_1V5_power[i] + evm_1V0AVS_power[i] + evm_1V0CON_power[i] + evm_Expansion_power[i]
    }
  
  power_consumption['EVM_0V9'] = evm_0V9_power
  power_consumption['EVM_1V8A'] = evm_1V8A_power
  power_consumption['EVM_1V8B'] = evm_1V8B_power
  power_consumption['EVM_VTT1V5ALT'] = evm_VTT1V5ALT_power
  power_consumption['EVM_3V3'] = evm_3V3_power
  power_consumption['EVM_5V0'] = evm_5V0_power
  power_consumption['EVM_1V5'] = evm_1V5_power
  power_consumption['EVM_1V0AVS'] = evm_1V0AVS_power
  power_consumption['EVM_1V0CON'] = evm_1V0CON_power
  power_consumption['EVM_Expansion'] = evm_Expansion_power
  power_consumption['Total_power'] = total_power
  return power_consumption
end 

# This function plots the power consumpotion point by point for the whole clip duration.
def power_consumption_plot(power_consumption, power_domain = 'Total_power')
 
  stat_plot(power_consumption, "#{power_domain} POWER CONSUMPTION Vs Time", "Samples", "Power (mw)", "serial" ,"#{power_domain}", "power")

end 

end



