require File.dirname(__FILE__)+'/evms_data'

module MultimeterModule
# Function caclulates power consumption for all domains.
# Input parameters: Hash table for voltage and current readings for all domaings.
# Return Parameter: Hash table Power consumptions for all domains   
def calculate_power_consumption(volt_reading, dut, multimeter=@equipment['multimeter'])
  power_consumption = Hash.new
  readings_included_power = volt_reading.key?('domain_' + multimeter.dut_power_domains[0] + '_power_readings')
  if readings_included_power
    volt_reading.each {|k,v|
      power_consumption[k] = v if k.match(/domain_.+_power_readings/)
    }
  end
  num_channels = (volt_reading.select {|k,v| k.match(/domain_.+_current_readings/)} ).size
  for i in (0..num_channels -1 ) 
    power_consumption["domain_" + multimeter.dut_power_domains[i]+ "_power_readings"] = Array.new() if !readings_included_power
  end 
  power_consumption["all_domains"] = Array.new
  volt_reading['domain_' + multimeter.dut_power_domains[0] + '_volt_readings'].each_index{|i|
    for k in (1..num_channels) 
     power_consumption["domain_" + multimeter.dut_power_domains[k - 1]+ "_power_readings"] << ((volt_reading["domain_" + multimeter.dut_power_domains[k - 1]+ "_volt_readings"][i] * volt_reading["domain_"+ multimeter.dut_power_domains[k - 1] + "_current_readings"][i])) * 1000 if !readings_included_power
    end
    total_power = 0
    for k in (1..num_channels) 
      next if exclude_power_domain_from_total?(dut.name, multimeter.dut_power_domains[k - 1])
      total_power = total_power + power_consumption["domain_" + multimeter.dut_power_domains[k - 1]+ "_power_readings"][i] if power_consumption["domain_" + multimeter.dut_power_domains[k - 1]+ "_power_readings"][i]
    end
    power_consumption["all_domains"] << total_power
  }
  for i in (1..num_channels)
  power_consumption["mean_" + multimeter.dut_power_domains[i - 1]] = mean(power_consumption["domain_" + multimeter.dut_power_domains[i - 1]+ "_power_readings"])
  end
  power_consumption['mean_all_domains'] = mean(power_consumption["all_domains"])
  return power_consumption
end 

def mean(a)
  array_sum = 0.0
  a.each{|elem|
    array_sum = array_sum + elem.to_f
  }
  mean = array_sum/a.size
  return mean
end


end 
