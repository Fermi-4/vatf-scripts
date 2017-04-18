require File.dirname(__FILE__)+'/../../lib/multimeter_power'
include MultimeterModule
require File.dirname(__FILE__)+'/../../lib/evms_data'
include EvmData
require File.dirname(__FILE__)+'/../../LSP/A-Power/power_functions'
include PowerFunctions
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
include LspTestScript

def setup
  boot_dut(setup_host_side())
  multimeter = @equipment['dut1'].params['multimeter1']
  conn_type = multimeter.params && multimeter.params.has_key?('conn_type') ? multimeter.params['conn_type'] : 'serial'
  add_equipment('multimeter1') do |log_path|
    Object.const_get(multimeter.driver_class_name).new(multimeter,log_path)
  end
  # Connect to multimeter
  @equipment['multimeter1'].connect({'type'=>conn_type})
end


def run
  perf = []
  app_defined = false
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))

  # Get voltage values for all channels in a hash
volt_readings = @equipment['multimeter1'].get_multimeter_output(@test_params.params_control.loop_count[0].to_i, @test_params.params_equip.timeout[0].to_i)

 # Calculate power consumption
  power_readings = calculate_power_consumption(volt_readings, @equipment['dut1'], @equipment['multimeter1'])

  # Generate the plot of the power consumption for the given application
  perf = save_results(power_readings, volt_readings)

ensure
  if perf.size > 0 and (!app_defined or (app_defined and result[0] == FrameworkConstants::Result[:pass]))
    set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get Power Performance data")
  end
end

# Function saves power consumption result
# Input parameters: Hash table populated Power consumptions for all domains.
# Return Parameter: Performance Array table for all voltages readings and powers consumptions.
def save_results(power_consumption,voltage_reading,multimeter=@equipment['multimeter1'])
  perf = []; v1=[]; v2=[]; vtotal=[]
  count = 0
  table_title = Array.new()
  table_title << 'SAMPLE NO'
  table_title <<  'All domains(mw)'
  for i in (1..multimeter.number_of_channels/2)
   table_title <<   multimeter.dut_power_domains[i - 1] + "(mw)"
  end
  for i in (1..multimeter.number_of_channels/2)
   table_title <<   multimeter.dut_power_domains[i -1] + "drop(v)"
  end
  for i in (1..multimeter.number_of_channels/2)
   table_title <<  multimeter.dut_power_domains[i -1] + "(v)"
  end
  @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["TOTAL,  PER DOMAIN POWER and VOLTAGE CALCULATED POINT BY POINT",{:bgcolor => "336666", :colspan => table_title.length},{:color => "white"}]],{:border => "1",:width=>"20%"})
  table_title = table_title
 @results_html_file.add_row_to_table(res_table,table_title)
  count = 0
  power_consumption["all_domains"].each{|power|
  table_data =  Array.new
  table_data <<  count.to_s
  table_data << power.to_s
  for i in (1..multimeter.number_of_channels/2)
   table_data <<  power_consumption["domain_" +  multimeter.dut_power_domains[i - 1] + "_power_readings"] [count].to_s
  end
  for i in (1..multimeter.number_of_channels/2)
   table_data <<   voltage_reading["domain_" +  multimeter.dut_power_domains[i - 1] + "drop_volt_readings"][count].to_s
  end
  for i in (1..multimeter.number_of_channels/2)
   table_data <<  voltage_reading["domain_" +  multimeter.dut_power_domains[i - 1] + "_volt_readings"][count].to_s
  end
   table_data = table_data
    @results_html_file.add_row_to_table(res_table,table_data)
    count += 1
  }

 for i in (1..multimeter.number_of_channels/2)
  perf << {'name' => @equipment['multimeter1'].dut_power_domains[i - 1] + " Power", 'value' =>power_consumption["domain_" + @equipment['multimeter1'].dut_power_domains[i - 1] + "_power_readings"], 'units' => "mw"}
  end
  perf << {'name' => "Total Power", 'value' => power_consumption["all_domains"], 'units' => "mw"}
  return perf
end
