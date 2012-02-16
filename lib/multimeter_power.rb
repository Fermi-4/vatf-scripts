module MultimeterModule
# Function caclulates power consumption for all domains.
# Input parameters: Hash table for voltage and current readings for all domaings.
# Return Parameter: Hash table Power consumptions for all domains   
def calculate_power_consumption(volt_reading, multimeter=@equipment['multimeter'])
  power_consumption = Hash.new
  for i in (0..multimeter.number_of_channels/2 -1 ) 
  power_consumption["domain_" + multimeter.dut_power_domains[i]+ "_power_readings"] = Array.new()
  end 
  power_consumption["all_domains"] = Array.new
  volt_reading['domain_' + multimeter.dut_power_domains[0] + '_volt_readings'].each_index{|i|
  for k in (1..multimeter.number_of_channels/2) 
   power_consumption["domain_" + multimeter.dut_power_domains[k - 1]+ "_power_readings"] << ((volt_reading["domain_" + multimeter.dut_power_domains[k - 1]+ "_volt_readings"][i] * volt_reading["domain_"+ multimeter.dut_power_domains[k - 1] + "_current_readings"][i])) * 1000
  end
  total_power = 0
  for k in (1..multimeter.number_of_channels/2) 
  total_power = total_power + power_consumption["domain_" + multimeter.dut_power_domains[k - 1]+ "_power_readings"][i]
  end
  power_consumption["all_domains"] << total_power
  }
  for i in (1..multimeter.number_of_channels/2)
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
