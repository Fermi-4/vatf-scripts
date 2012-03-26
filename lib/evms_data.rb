module EvmData

def get_power_domain_data(key)

power_data =  Hash.new()

# am335x related data
#Power Domain   		Shunt   Jumper 
#1 VDD_CORE			R32		
#2 VDD_MPU*	   		R46		
#3 VDDS_RTC	   		R505	J35	
#4 VDDS_DDR	   		R508	J20	
#5 VDDS	       			R498	J21	
#6 VDDS_SRAM_CORE_BG		R500	J23	
#7 VDDS_SRAM_MPU_BB		R499	J25	
#8 VDDS_PLL_DDR	    		R507	J33	
#9 VDDS_PLL_CORE_LCD		R503	J24	
#10 VDDS_PLL_MPU			R497	J22	
#11 VDDS_OSC		    	R506	J29	
#12 VDDA1P8V_USB0/1	    	R502	J28	
#13 VDDA3P3V_USB0/1		R504	J31	
#14 VDDA_ADC			R501	J27	
#15 VDDSHV1	1.8 / 		R493	J26	
#16 VDDSHV2	1.8 / 		R545	J38	
#17 VDDSHV3	1.8 / 		R546	J39	
#18 VDDSHV4	1.8 / 		R494	J30	
#19 VDDSHV5	1.8 / 		R495	J32	
#20 VDDSHV6	1.8 / 		R496	J34	
power_data['am335x-evm'] =  {'power_domains' => ['VDD_CORE', 'VDD_MPU', 'VDDS_RTC', 'VDDS_DDR', 'VDDS', 'VDDS_SRAM_CORE_BG', 'VDDS_SRAM_MPU_BB', 'VDDS_PLL_DDR', 'VDDS_PLL_CORE_LCD', 'VDDS_PLL_MPU', 'VDDS_OSC', 'VDDA_1P8V_USB0_1', 'VDDS_A3P3V_USB0_1', 'VDDA_ADC', 'VDDSHV1', 'VDDSHV2', 'VDDSHV3', 'VDDSHV4', 'VDDSHV5', 'VDDSHV6'],
                             'domain_resistors' =>{'VDD_CORE'=>'0.05', 'VDD_MPU'=>'0.05', 'VDDS_RTC'=>'2.0', 'VDDS_DDR'=>'0.24', 'VDDS'=>'0.24', 'VDDS_SRAM_CORE_BG'=>'2.0', 'VDDS_SRAM_MPU_BB'=>'2.0', 'VDDS_PLL_DDR'=>'2.0', 'VDDS_PLL_CORE_LCD'=>'2.0', 'VDDS_PLL_MPU'=>'2.0', 'VDDS_OSC'=>'2.0', 'VDDA_1P8V_USB0_1'=>'1.0', 'VDDS_A3P3V_USB0_1'=>'2.0', 'VDDA_ADC'=>'1.0', 'VDDSHV1'=>'0.24', 'VDDSHV2'=>'0.24', 'VDDSHV3'=>'0.24', 'VDDSHV4'=>'0.24', 'VDDSHV5'=>'0.24', 'VDDSHV6'=>'0.24'}}

# am37x related data
#Power Domain   		Shunt   Jumper
#VDD1                                    J6
#VDD2                                    J5
power_data['am37x-evm'] = {'power_domains' => ['VDD1', 'VDD2'], 'domain_resistors' => {'VDD1'=>'0.05', 'VDD2'=>'0.1'}}

return power_data[key]
end
end 
