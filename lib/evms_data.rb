module EvmData

  def get_default_params(e='dut1')
    params = {'platform' => @equipment[e].name}
    @equipment[e].send_cmd('uname -r', @equipment[e].prompt)
    params['version'] = @equipment[e].response.match(/^([\d\.]+)/i).captures[0]
    return params
  end

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

    power_data['dra7xx-evm'] = {'power_domains' => ['VDD_DSPEVE', 'VDD_MPU', 'DDR_CPU', 'VDDA_1V8_PLL', 'VDD_GPU', 'VUSB_3V3', 
                                                    'VDDS18V', 'VDD_SHV', 'CORE_VDD', 'VDD_IVA', 'DDR_MEM', 'VDDA_1V8_PHY'], 
                                'domain_resistors' => {'VDD_DSPEVE' => '0.001', 'VDD_MPU' => '0.001', 'DDR_CPU' => '0.005', 
                                                       'VDDA_1V8_PLL' => '0.01', 'VDD_GPU' => '0.002', 'VUSB_3V3' => '0.01',
                                                       'VDDS18V' => '0.01', 'VDD_SHV' => '0.001', 'CORE_VDD' => '0.002', 
                                                       'VDD_IVA' => '0.002', 'DDR_MEM' => '0.005', 'VDDA_1V8_PHY' => '0.01'}}
    power_data['dra72x-evm'] = {'power_domains' => ['VDD_MPU', 'VDD_GPU_IVA_DSPEVE', 'VDD_CORE', 'J6_VDD_1V8', 'EVM_VDD_1V8', 'J6_VDD_DDR',
                                                    'EVM_VDD_DDR', 'VDD_SHV8', 'VDD_SHV5', 'VDDA_PHY', 'VDDA_USB3V3', 'VDDA_PLL'], 
                                'domain_resistors' => {'VDD_MPU' => '0.001', 'VDD_GPU_IVA_DSPEVE' => '0.001', 'VDD_CORE' => '0.002', 
                                                       'J6_VDD_1V8' => '0.005', 'EVM_VDD_1V8' => '0.01', 'J6_VDD_DDR' => '0.005',
                                                       'EVM_VDD_DDR' => '0.005', 'VDD_SHV8' => '0.01', 'VDD_SHV5' => '0.005', 
                                                       'VDDA_PHY' => '0.01', 'VDDA_USB3V3' => '0.01', 'VDDA_PLL' => '0.01'}}
    power_data['am57xx-evm'] = {'power_domains' => ['3V3', 'VDD_DSP','CORE_VDD', '5V0', 'VDD_MPU'],
                                'domain_resistors' => {'3V3' => '0.002', 'VDD_DSP' => '0.002','CORE_VDD' => '0.002',
                                                       '5V0' => '0.002', 'VDD_MPU' => '0.001'}}

    return power_data[key]
  end

  def map_domain_to_measurement_rail(platform, domain)
    case platform
    when "am57xx-evm"
      case domain
      when "VDD_DSPEVE", "VDD_GPU", "VDD_IVA"
        return 'VDD_DSP'
      end
    end
    return domain
  end

  def get_nand_loc(platform)
    # default nand location names for each partitions
    case platform
    when "am335x-evm"
      # if there is difference from the default, add value here
      return {'primary_bootloader' => 'NAND.SPL', 'secondary_bootloader' => 'NAND.u-boot', 'u-boot-env' => 'NAND.u-boot-env', 'kernel' => 'NAND.kernel', 'dtb' => 'NAND.u-boot-spl-os', 'fs' => 'NAND.rootfs'}
    else
      # default nand location names for each partitions
      return {'primary_bootloader' => 'NAND.SPL', 'secondary_bootloader' => 'NAND.u-boot', 'u-boot-env' => 'NAND.u-boot-env', 'kernel' => 'NAND.kernel', 'dtb' => 'NAND.u-boot-spl-os', 'fs' => 'NAND.rootfs'}
    end
    return nand_loc
  end

  def get_rawmmc_loc(platform)
    case platform
    when "am335x-evm"
      # if there is difference from the default, add value here
      return {'primary_bootloader' => '0x0', 'secondary_bootloader' => '0x300', 'kernel' => '0x3000', 'dtb' => '0x2000', 'fs' => '0x8000'}
    else
      # default raw mmc location names for each partitions
      return {'primary_bootloader' => '0x0', 'secondary_bootloader' => '0x300', 'kernel' => '0x3000', 'dtb' => '0x2000', 'fs' => '0x8000'}
    end
    return rawmmc_loc
  end

  def get_dtb_name(platform)
    dtb_names = {
      'am335x-evm' => 'am335x-evm.dtb',
      'am43xx-gpevm' => 'am437x-gp-evm.dtb',
      'dra7xx-evm' => 'dra7-evm-lcd10.dtb',
      'am57xx-evm' => 'am57xx-evm.dtb',
    }
    raise "The dtbname table does not have the entry for #{platform}; Please add the entry in 'lib/get_dtb_name'!" if !dtb_names.has_key?(platform)
    return dtb_names["#{platform}"]
  end


  def get_platform_string(params)
    machines = {}
    machines['am335x-evm']  = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x EVM/,
                              '3.14' => /Machine model: TI AM335x EVM/,
                              }
    machines['am335x-sk']   = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x EVM-SK/,
                              '3.14' => /Machine model: TI AM335x EVM-SK/,
                              }
    machines['beaglebone']  = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x BeagleBone/,
                              '3.14' => /Machine model: TI AM335x BeagleBone/,
                              }
    machines['beaglebone-black'] = {'0.0' => /Machine: Generic AM33XX \(Flattened Device Tree\), model: TI AM335x BeagleBone/,
                                   '3.14' => /Machine model: TI AM335x BeagleBone/,
                                   }
    machines['dra7xx-evm']  = {'0.0' => /Machine: Generic DRA7XX \(Flattened Device Tree\), model: TI DRA7/,
                              '3.14' => /Machine model: TI DRA742/,
                              }
    machines['dra72x-evm']  = {'0.0' => /Machine: Generic DRA7XX \(Flattened Device Tree\), model: TI DRA7/,
                              '3.14' => /Machine model: TI DRA722/,
                              }
    machines['omap5-evm']   = {'0.0' => /Machine: Generic OMAP5 \(Flattened Device Tree\), model: TI OMAP5 uEVM board/,
                              '3.14' => /Machine model: TI OMAP5 uEVM board/,
                              }
    machines['am43xx-epos'] = {'0.0' => /Machine: Generic AM43 \(Flattened Device Tree\), model: TI AM43x EPOS EVM/,
                              '3.14' => /Machine model: TI AM43x EPOS EVM/,
                              }
    machines['am43xx-gpevm'] = {'0.0' => /Machine: Generic AM43 \(Flattened Device Tree\), model: TI AM437x gp EVM/i,
                               '3.14' => /Machine model: TI AM437x GP EVM/,
                              }
    machines['am437x-sk'] = {'3.14' => /Machine model: TI AM437x SK EVM/, }
    machines['am57xx-evm'] = {'0.0' => /Machine model: TI (AM572x EVM|AM5728 BeagleBoard-X15)/, }
                                          
    params.merge!({'dict' => machines})
    get_cmd(params)
  end

  def get_max_opp_string(params)
    machines = {}
    machines['am335x-evm']  = {'0.0' => '1000000'}
    machines['am335x-sk']   = {'0.0' => '1000000'}
    machines['beaglebone']  = {'0.0' => '720000'}
    machines['beaglebone-black'] = {'0.0' => '1000000'}
    machines['dra7xx-evm']  = {'0.0' => '1500000'}
    machines['dra72x-evm']  = {'0.0' => '1500000'}
    machines['omap5-evm']   = {'0.0' => '1500000'}
    machines['am43xx-epos'] = {'0.0' => '1000000'}
    machines['am43xx-gpevm'] = {'0.0' => '1000000'}
    machines['am437x-sk'] = {'0.0' => '1000000'}
    machines['am57xx-evm']  = {'0.0' => '1500000'}
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
    machines['am437x-sk'] = {'0.0' => {'VDD_CORE' => 0.95, 'VDD_MPU' => 0.95}}
    params.merge!({'dict' => machines})
    get_cmd(params)
  end

  def get_expected_poweroff_domains(params=nil)
    machines = {}
    params = get_default_params if !params
    data = get_power_domain_data(params['platform'])['power_domains']
    machines['am335x-evm']  = {'0.0' => data.select{|item| ! /RTC/.match(item)}}
    machines['am43xx-gpevm'] = {'0.0' => data}
    machines['dra7xx-evm']  = {'0.0' => data}
    machines['dra72x-evm']  = {'0.0' => data}
    machines['am57xx-evm']  = {'0.0' => data.select{|item| /VDD/.match(item)}}
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

  def get_required_display_modes(platform)
    machines = {}
    machines['am335x-evm']  = []
    machines['am335x-sk']   = []
    machines['beaglebone']  = []
    machines['beaglebone-black'] = ['1280x720@60','720x480@60']
    machines['dra7xx-evm']  = ['1920x1080@60','1920x540@60','1280x720@60','720x480@60']
    machines['omap5-evm']   = []
    machines['am43xx-epos'] = []
    machines['am43xx-gpevm'] = []
    machines[platform]
  end

  # Define AVS class 0 registers for each domain and OPP
  def get_avs_class0_data(platform)
    machines = {}
    machines['dra7xx-evm']  = {'VDD_IVA' => {'OPP_NOM'=>'0x4A0025CC','OPP_OD'=>'0x4A0025D0','OPP_HIGH'=>'0x4A0025D4'},
                               'VDD_DSPEVE' => {'OPP_NOM'=>'0x4A0025E0','OPP_OD'=>'0x4A0025E4'}, 
                               'CORE_VDD' => {'OPP_NOM'=>'0x4A0025F4'}, 
                               'VDD_GPU' => {'OPP_NOM'=>'0x4A003B08','OPP_OD'=>'0x4A003B0C','OPP_HIGH'=>'0x4A003B10'}, 
                               'VDD_MPU' => {'OPP_NOM'=>'0x4A003B20','OPP_OD'=>'0x4A003B24','OPP_HIGH'=>'0x4A003B28'}, 
                              }
    machines['dra72x-evm']  = {'VDD_CORE' => {'OPP_NOM'=>'0x4A0025F4'}, 
                               'VDD_GPU_IVA_DSPEVE' => {'OPP_NOM'=>'0x4A003B08','OPP_OD'=>'0x4A003B0C','OPP_HIGH'=>'0x4A003B10'}, 
                               'VDD_MPU' => {'OPP_NOM'=>'0x4A003B20','OPP_OD'=>'0x4A003B24','OPP_HIGH'=>'0x4A003B28'}, 
                              }
    machines['am57xx-evm']   = machines['dra7xx-evm']
    raise "AVS class0 data not defined for #{platform}" if !machines.key?(platform)
    machines[platform]
  end

  # Define usb controller instance for usb gadget
  def get_usb_gadget_number(platform)
    case platform.downcase
    when "am57xx-evm"
      return 1
    else
      return 0
    end
  end

  # Define AVS requirements for uboot
  def get_required_uboot_avs(platform)
    data = get_avs_class0_data(platform)
    case platform
    
    when "dra7xx-evm", "dra72x-evm", "am57xx-evm"
      return data.map{|domain,opps| { domain => opps.select{|name,address| name == "OPP_NOM"} } }
    
    else
      raise "AVS class0 uboot requirements are not defined for #{platform}" 
    end
  end

  # Define AVS requirements for Linux
  def get_required_linux_avs(platform)
    data = get_avs_class0_data(platform)
    case platform
    
    when "dra7xx-evm", "am57xx-evm"
      return data.map{|domain,opps| 
        if domain == 'VDD_MPU' or domain == 'VDD_GPU' or domain == 'VDD_IVA'
          { domain => opps.select{|name,address| name == "OPP_NOM" or name == "OPP_HIGH" or name == "OPP_OD"} }
        else
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }
    when "dra72x-evm"
      return data.map{|domain,opps| { domain => opps.select{|name,address| name == "OPP_NOM"} } }

    else
      raise "AVS class0 Linux requirements are not defined for #{platform}" 
    end
  end

  # Define translations from OPP name to frequency in KHz (unit expected by cpufreq)
  def get_frequency_for_opp(platform, opp, proc='cpu')
    proc = proc.upcase
    opp  = opp.upcase
    machines = {}
    machines['dra7xx-evm']  = {'CPU' => {'OPP_NOM'=>'1000000','OPP_OD'=>'1176000','OPP_HIGH'=>'1500000'},
                               'GPU' => {'OPP_NOM'=>'425600','OPP_OD'=>'500000', 'OPP_HIGH'=>'532000'},
                               'IVA' => {'OPP_NOM'=>'388300','OPP_OD'=>'430000','OPP_HIGH'=>'532000'},
                              }
    machines['dra72x-evm']  = machines['dra7xx-evm']      
    machines['am57xx-evm']  = machines['dra7xx-evm']

    raise "OPP #{opp} not defined for #{platform}[#{proc}]" if !machines.key?(platform) or !machines[platform][proc][opp]
    machines[platform][proc][opp]
  end

  def is_cpufreq_supported(platform)
    unsupported = ['k2hk-evm', 'k2l-evm', 'k2e-evm']
    ! unsupported.include? platform 
  end

  
end 
