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
    power_data['am335x-evm']  =  {'power_domains' => ['VDD_CORE', 'VDD_MPU', 'VDDS_RTC', 'VDDS_DDR', 'VDDS', 'VDDS_SRAM_CORE_BG', 'VDDS_SRAM_MPU_BB', 'VDDS_PLL_DDR', 'VDDS_PLL_CORE_LCD', 'VDDS_PLL_MPU', 'VDDS_OSC', 'VDDA_1P8V_USB0_1', 'VDDS_A3P3V_USB0_1', 'VDDA_ADC', 'VDDSHV1', 'VDDSHV2', 'VDDSHV3', 'VDDSHV4', 'VDDSHV5', 'VDDSHV6'],
                                 'domain_resistors' => {'VDD_CORE'=>'0.05', 'VDD_MPU'=>'0.05', 'VDDS_RTC'=>'2.0', 'VDDS_DDR'=>'0.24', 'VDDS'=>'0.24', 'VDDS_SRAM_CORE_BG'=>'2.0', 'VDDS_SRAM_MPU_BB'=>'2.0', 'VDDS_PLL_DDR'=>'2.0', 'VDDS_PLL_CORE_LCD'=>'2.0', 'VDDS_PLL_MPU'=>'2.0', 'VDDS_OSC'=>'2.0', 'VDDA_1P8V_USB0_1'=>'1.0', 'VDDS_A3P3V_USB0_1'=>'2.0', 'VDDA_ADC'=>'1.0', 'VDDSHV1'=>'0.24', 'VDDSHV2'=>'0.24', 'VDDSHV3'=>'0.24', 'VDDSHV4'=>'0.24', 'VDDSHV5'=>'0.24', 'VDDSHV6'=>'0.24'}}
    power_data['am43xx-epos_alpha'] =  {'power_domains' => ['VDD_CORE', 'VDD_MPU', 'VDDS_DDR', 'VDDS_SRAM_CORE_BG', 'VDDS_SRAM_MPU_BB',
                                                      'VDDS_PLL_DDR', 'VDDS_PLL_CORE_LCD', 'VDDS_PLL_MPU', 'VDDS_OSC', 'VDDS_CTM',
                                                      'VDDA_MC_ADC', 'VDDA_TS_ADC', 'VDDS', 'VDDA1P8V', 'VDDA3P3V',
                                                      'VDDSHV1', 'VDDSHV2', 'VDDSHV3', 'VDDSHV4', 'VDDSHV5', 'VDDSHV6', 
                                                      'VDDSHV7', 'VDDSHV8', 'VDDSHV9', 'VDDSHV10', 'VDDSHV11', 'VDDSHV12',
                                                      'VDD_TPM', 'VDDS_TPM'],
                                 'domain_resistors' => {'VDD_CORE' => '0.05', 'VDD_MPU' => '0.05', 'VDDS_DDR' => '0.05',
                                                       'VDDS_SRAM_CORE_BG' => '1', 'VDDS_SRAM_MPU_BB' => '1', 'VDDS_PLL_DDR' => '2',
                                                       'VDDS_PLL_CORE_LCD' => '1', 'VDDS_PLL_MPU' => '2', 'VDDS_OSC' => '2',
                                                       'VDDS_CTM' => '2', 'VDDA_MC_ADC' => '2', 'VDDA_TS_ADC' => '2',
                                                       'VDDS' => '1', 'VDDA1P8V' => '1', 'VDDA3P3V' => '1', 'VDDSHV1' => '1',
                                                       'VDDSHV2' => '1', 'VDDSHV3' => '1', 'VDDSHV4' => '1', 'VDDSHV5' => '1',
                                                       'VDDSHV6' => '1', 'VDDSHV7' => '1', 'VDDSHV8' => '1', 'VDDSHV9' => '1',
                                                       'VDDSHV10' => '1', 'VDDSHV11' => '1', 'VDDSHV12' => '1', 
                                                       'VDD_TPM' => '2', 'VDDS_TPM' => '2'}}
    power_data['am43xx-epos'] =  {'power_domains' => ['VDD_CORE', 'VDD_MPU', 'VDDS_DDR', 'V1_8D_AM437X', 'V3_3D_AM437X'],
                                  'domain_resistors' => {'VDD_CORE' => '0.05', 'VDD_MPU' => '0.05', 'VDDS_DDR' => '0.05',
                                                          'V1_8D_AM437X' => '0.1', 'V3_3D_AM437X' => '0.1'}}
    power_data['am43xx-gpevm'] =  {'power_domains' => ['VDD_CORE', 'VDD_MPU', 'VDDS_DDR', 'V1_8D_AM437X', 'V3_3D_AM437X', 'VDDS_DDR_MEM'],
                                   'domain_resistors' => {'VDD_CORE' => '0.05', 'VDD_MPU' => '0.05', 'VDDS_DDR' => '0.05',
                                                          'V1_8D_AM437X' => '0.1', 'V3_3D_AM437X' => '0.1', 'VDDS_DDR_MEM' => '0.05'}}
    

    # am37x related data
    #Power Domain   		Shunt   Jumper
    #VDD1                                    J6
    #VDD2                                    J5
    power_data['am37x-evm'] = {'power_domains' => ['VDD1', 'VDD2'], 'domain_resistors' => {'VDD1'=>'0.05', 'VDD2'=>'0.1'}}
    power_data['am335x-sk'] = {'power_domains' => ['VDD_MPU', 'VDDS_DDR3'], 'domain_resistors' => {'VDD_MPU'=>'0.1', 'VDDS_DDR3'=>'0.24'}}

    return power_data[key]
  end

  def get_nand_loc(key)
    nand_loc = {}
    nand_loc['am335x-evm'] = {'primary_bootloader' => 'SPL', 'secondary_bootloader' => 'u-boot', 'u-boot-env' => 'u-boot-env', 'kernel' => 'kernel', 'fs' => 'rootfs'}
    return nand_loc[key]
  end

  def get_platform_string(params)
    machines = {}
    machines['am335x-evm']  = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x EVM/}
    machines['am335x-sk']   = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x EVM-SK/}
    machines['beaglebone']  = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x BeagleBone/}
    machines['beaglebone-black'] = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x BeagleBone/}
    machines['dra7xx-evm']  = {'0.0' => /Machine: Generic DRA7XX \(Flattened Device Tree\), model: TI DRA7/}
    machines['omap5-evm']   = {'0.0' => /Machine: Generic OMAP5 \(Flattened Device Tree\), model: TI OMAP5 uEVM board/}
    machines['am43xx-epos'] = {'0.0' => /Machine: Generic AM43 \(Flattened Device Tree\), model: TI AM43x EPOS EVM/}
    machines['am43xx-gpevm'] = {'0.0' => /Machine: Generic AM43 \(Flattened Device Tree\), model: TI AM437x gp EVM/i}
                                          
    params.merge!({'dict' => machines})
    get_cmd(params)
  end

  def get_max_opp_string(params)
    machines = {}
    machines['am335x-evm']  = {'0.0' => '1000000'}
    machines['am335x-sk']   = {'0.0' => '1000000'}
    machines['beaglebone']  = {'0.0' => '720000'}
    machines['beaglebone-black'] = {'0.0' => '1000000'}
    machines['dra7xx-evm']  = {'0.0' => '1176000'}
    machines['omap5-evm']   = {'0.0' => '1500000'}
    machines['am43xx-epos'] = {'0.0' => '1000000'}
    machines['am43xx-gpevm'] = {'0.0' => '1000000'}
    params.merge!({'dict' => machines})
    get_cmd(params)
  end

  def get_expected_volt_reductions(params)
    machines = {}
    machines['am335x-evm']  = {'0.0' => {'VDD_CORE' => 0.95, 'VDD_MPU' => 0.95}}
    machines['am335x-sk']   = {'0.0' => nil}
    machines['beaglebone']  = {'0.0' => nil}
    machines['beaglebone-black'] = {'0.0' => nil}
    machines['dra7xx-evm']  = {'0.0' => nil}
    machines['omap5-evm']   = {'0.0' => nil}
    machines['am43xx-epos'] = {'0.0' => {'VDD_CORE' => 0.95, 'VDD_MPU' => 0.95}}
    machines['am43xx-gpevm'] = {'0.0' => {'VDD_CORE' => 0.95, 'VDD_MPU' => 0.95}}
    params.merge!({'dict' => machines})
    get_cmd(params)
  end


  def get_cmd(params)
    raise "'platform' and 'version' are both mandatory params" if !params.key?('platform') or !params.key?('version')
    platform = params['platform'] 
    version = params['version']
    cmds_hash = params['dict'][platform]
    versions = cmds_hash.keys.sort {|a,b| b <=> a}  # sort by version
    tmp = versions.select {|v| Gem::Version.new(v.dup) <= Gem::Version.new(version)}
    raise "get_cmd: Unable to find the version matching v<= #{version}\n" if tmp.empty?
    return cmds_hash[tmp[0]] 
  end


end 
