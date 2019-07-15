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
    power_data['am335x-ice']  =  {'power_domains' => ['VDD_CORE', 'VDD_MPU', 'VDDS_RTC', 'VDDS_DDR', 'VDDS', 'VDDS_SRAM_CORE_BG', 'VDDS_SRAM_MPU_BB', 'VDDS_PLL_DDR', 'VDDS_PLL_CORE_LCD', 'VDDS_PLL_MPU', 'VDDS_OSC', 'VDDA_1P8V_USB0_1', 'VDDS_A3P3V_USB0_1', 'VDDA_ADC', 'VDDSHV1', 'VDDSHV2', 'VDDSHV3', 'VDDSHV4', 'VDDSHV5', 'VDDSHV6'],
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
                                'domain_resistors' => {'VDD_DSPEVE' => '0.01', 'VDD_MPU' => '0.01', 'DDR_CPU' => '0.01',
                                                       'VDDA_1V8_PLL' => '0.01', 'VDD_GPU' => '0.01', 'VUSB_3V3' => '0.01',
                                                       'VDDS18V' => '0.01', 'VDD_SHV' => '0.01', 'CORE_VDD' => '0.01',
                                                       'VDD_IVA' => '0.01', 'DDR_MEM' => '0.01', 'VDDA_1V8_PHY' => '0.01'}}
    power_data['dra72x-evm'] = {'power_domains' => ['VDD_MPU', 'VDD_GPU_IVA_DSPEVE', 'VDD_CORE', 'J6_VDD_1V8', 'EVM_VDD_1V8', 'J6_VDD_DDR',
                                                    'EVM_VDD_DDR', 'VDD_SHV8', 'VDD_SHV5', 'VDDA_PHY', 'VDDA_USB3V3', 'VDDA_PLL', 'VDDA_1V8_PHY2'],
                                'domain_resistors' => {'VDD_MPU' => '0.01', 'VDD_GPU_IVA_DSPEVE' => '0.01', 'VDD_CORE' => '0.01',
                                                       'J6_VDD_1V8' => '0.01', 'EVM_VDD_1V8' => '0.01', 'J6_VDD_DDR' => '0.01',
                                                       'EVM_VDD_DDR' => '0.01', 'VDD_SHV8' => '0.01', 'VDD_SHV5' => '0.01',
                                                       'VDDA_PHY' => '0.01', 'VDDA_USB3V3' => '0.01', 'VDDA_PLL' => '0.01', 'VDDA_1V8_PHY2' => '0.01'}}
    power_data['dra71x-evm'] = {'power_domains' => ['VDD_CORE', 'VDD_DSP', 'VDDS_1V8', 'VDD_DDR_1V35', 'VDA_1V8_PLL', 'VDA_1V8_PHY',
                                                    'VDDSHV8', 'VDDA_USB3V3', 'VDDSHV_3V3', 'VDD_DDR'],
                                'domain_resistors' => {'VDD_CORE' => '0.01', 'VDD_DSP' => '0.01', 'VDDS_1V8' => '0.01', 'VDD_DDR_1V35' => '0.01',
                                                       'VDA_1V8_PLL' => '0.01', 'VDA_1V8_PHY' => '0.01', 'VDDSHV8' => '0.01',
                                                       'VDDA_USB3V3' => '0.01', 'VDDSHV_3V3' => '0.01', 'VDD_DDR' => '0.01'}}
    power_data['am57xx-evm'] = {'power_domains' => ['3V3', 'VDD_DSP','CORE_VDD', '5V0', 'VDD_MPU'],
                                'domain_resistors' => {'3V3' => '0.01', 'VDD_DSP' => '0.01','CORE_VDD' => '0.02',
                                                       '5V0' => '0.01', 'VDD_MPU' => '0.01'}}
    power_data['dra76x-evm'] = {'power_domains' => ['VDD_MPU', 'VDD_GPU', 'VDD_DSPEVE', 'VDD_CORE',
                                                    'VDD_IVA', 'VDDR', 'VDDR_SOC',
                                                    'VDDS_1V8', 'VDD_SDIO', 'VDA_USB',
                                                    'VDA_PLL', 'VDA_PHY2', 'VDA_PHY1'],
                                'domain_resistors' => {'VDD_MPU' => '0.01', 'VDD_GPU' => '0.01', 'VDD_DSPEVE' => '0.01', 'VDD_CORE' => '0.01',
                                                       'VDD_IVA' => '0.01', 'VDDR' => '0.01', 'VDDR_SOC' => '0.01',
                                                       'VDDS_1V8' => '0.01', 'VDD_SDIO' => '0.01', 'VDA_USB' => '0.01',
                                                       'VDA_PLL' => '0.01', 'VDA_PHY2' => '0.01', 'VDA_PHY1' => '0.01'}}
    power_data['am654x-evm'] = {'power_domains' => [
                          'VDD_CORE',
                          'VDD_MCU',
                          'VDD_MPU',
                          'SOC_DVDD3V3',
                          'SOC_DVDD1V8',
                          'SOC_AVDD1V8',
                          'SOC_VDDS_DDR',
                          'VDD_DDR'
                          ],
                              'domain_resistors' => {
                          #SOC
                          'VDD_CORE' => '0.002',
                          'VDD_MCU' => '0.010',
                          'VDD_MPU' => '0.002',
                          'SOC_DVDD3V3' => '0.002',
                          'SOC_DVDD1V8' => '0.010',
                          'SOC_AVDD1V8' => '0.010',
                          'SOC_VDDS_DDR' => '0.010',
                          'VDD_DDR' => '0.010'
                          }}

    power_data['am654x-idk'] = power_data['am654x-evm']

    power_data['j721e-evm'] = {'power_domains' => [ 
													'VDD_CPU_AVS',
													'VDD_MCU_0V85',
													'VDD_MCU_RAM_0V85',
													'VDA_MCU_1V8',
													'VDD_MCUIO_3V3',
													'VDD_MCUIO_1V8',
													'VDD_CORE_0V8',
													'VDD_CORE_RAM_0V85',
													'VDD_CPU_RAM_0V85',
													'VDDR_BIAS_1V1',
													'VDDR_IO_DV',
													'VDD_PHYCORE_0V8',
													'VDA_PLL_1V8',
													'VDD_PHYIO_1V8',
													'VDA_USB_3V3',		
													'VDD_IO_1V8',
													'VDD_IO_3V3',
													'VDD_SD_DV',
												  ],
                                'domain_resistors' => {
													#SOC 
													'VDD_CPU_AVS' => '0.010',
													'VDD_MCU_0V85' => '0.010',
													'VDD_MCU_RAM_0V85' => '0.010',
													'VDA_MCU_1V8' => '0.010',
													'VDD_MCUIO_3V3' => '0.010',
													'VDD_MCUIO_1V8' => '0.010',
													'VDD_CORE_0V8' => '0.010',
													'VDD_CORE_RAM_0V85' => '0.010',
													'VDD_CPU_RAM_0V85' => '0.010',
													'VDDR_BIAS_1V1' => '0.010',
													'VDDR_IO_DV' => '0.010',
													'VDD_PHYCORE_0V8' => '0.010',
													'VDA_PLL_1V8' => '0.010',
													'VDD_PHYIO_1V8' => '0.010',
													'VDA_USB_3V3' => '0.010',
													'SPARE' => '0.000',		
													'VDD_IO_1V8' => '0.010',
													'VDD_IO_3V3' => '0.010',
													'VDD_SD_DV' => '0.010',
													#Others
													'VDD1_LP4_1V8' => '0.010',
													'VDD2_LP4_1V1' => '0.010',
													'VDDQ_LP4_DV' => '0.010',
													'VSYS_MCUIO_1V8' => '0.010',
													'VSYS_MCUIO_3V3' => '0.010',
													'VSYS_IO_1V8' => '0.010',
													'VSYS_IO_3V3' => '0.010',
													'VCC_12V0' => '0.010',
													'VSYS_5V0' => '0.010',
													'VSYS_3V3' => '0.010',
													'VSYS_3V3_SOM' => '0.010',
													'VDDA_DLL_0V8' => '0.010',
													'EXP_3V3' => '0.010',
                                }}

    return power_data[key]
  end

  def exclude_power_domain_from_total?(key, domain)
    exclusion_list = Hash.new
    exclusion_list['am43xx-gpevm']=['VDDS_DDR_MEM']

    (exclusion_list.has_key? key and exclusion_list[key].include?(domain))
  end

  def map_domain_to_measurement_rail(platform, domain)
    case platform
    when "am57xx-evm"
      case domain
      when "VDD_DSPEVE", "VDD_GPU", "VDD_IVA"
        return 'VDD_DSP'
      end
    when "dra72x-evm"
      case domain
      when "VDD_DSPEVE", "VDD_GPU", "VDD_IVA"
        return 'VDD_GPU_IVA_DSPEVE'
      end
    when "dra71x-evm"
      case domain
      when "VDD_DSPEVE", "VDD_IVA"
        return 'VDD_DSP'
      when "VDD_MPU", "VDD_GPU"
        return 'VDD_CORE'
      end
    end
    return domain
  end

  def get_nand_loc(platform)
    # default nand location names for each partitions
    puts "platform: "+platform
    case platform
    when /am335x-evm/
      # if there is difference from the default, add value here
      return {'primary_bootloader' => 'NAND.SPL', 'secondary_bootloader' => 'NAND.u-boot', 'u-boot-env' => 'NAND.u-boot-env', 'kernel' => 'NAND.kernel', 'dtb' => 'NAND.u-boot-spl-os', 'fs' => 'NAND.file-system'}
    when /omapl138-lcdk/
      return {'secondary_bootloader' => '0x20000', 'u-boot-env' => '0'}
    when /^k2.{0,2}-(hs){0,1}evm/
      # there is no kernel and dtb partition for k2 device
      return {'secondary_bootloader' => 'bootloader', 'u-boot-env' => 'params', 'fs' => 'ubifs'}
    else
      # default nand location names for each partitions
      return {'primary_bootloader' => 'NAND.SPL', 'secondary_bootloader' => 'NAND.u-boot', 'u-boot-env' => 'NAND.u-boot-env', 'kernel' => 'NAND.kernel', 'dtb' => 'NAND.u-boot-spl-os', 'fs' => 'NAND.file-system'}
    end
  end

  def get_spi_loc(platform)
    case platform
    when /^k2.{0,2}-(hs){0,1}evm/
      return {'secondary_bootloader' => '0'}
    else
      raise "get_spi_loc: No location is being specified for SPI partitions for #{platform}"
    end
  end

  def get_ospi_loc(platform)
    case platform
    when /am654x/,/j721e/
      return {'initial_bootloader' => '0', 'primary_bootloader' => '0x80000', 'secondary_bootloader' => '0x280000', 'sysfw'=>'0x6c0000'}
    else
      raise "get_ospi_loc: No location is being specified for OSPI partitions for #{platform}"
    end
  end

  def get_qspi_loc(platform)
    case platform
    when /^k2.{0,2}-(hs){0,1}evm/
      return {'secondary_bootloader' => '0'}
    when /dra7|am571x-idk|am572x-idk|am574x-idk/
      return {'primary_bootloader' => '0', 'secondary_bootloader' => '0x40000', 'dtb' => '0x140000', 'kernel' => '0x1e0000'}
    when /am437/
      return {'primary_bootloader' => '0', 'dtb' => '0x100000', 'kernel' => '0x130000'}
    else
      raise "get_qspi_loc: No location is being specified for QSPI partitions for #{platform}"
    end
  end

  def get_hflash_loc(platform)
    case platform
    when /j721e/
      return {'initial_bootloader' => '0', 'primary_bootloader' => '0x80000', 'secondary_bootloader' => '0x280000', 'sysfw'=>'0x6c0000'}
    else
      raise "get_hflash_loc: No location is being specified for hyperflash partitions for #{platform}"
    end
  end

  def get_rawmmc_loc(platform)
    case platform
    when /am654x|j721e/
      # if there is difference from the default, add value here
      return {'initial_bootloader'=> '0x0', 'primary_bootloader' => '0x400', 'secondary_bootloader' => '0x1400', 'sysfw'=>'0x3600'}
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
      'am43xx-hsevm' => 'am437x-gp-evm.dtb',
      'dra7xx-evm' => 'dra7-evm.dtb',
      'dra7xx-hsevm' => 'dra7-evm.dtb',
      'dra72x-evm' => 'dra72-evm.dtb',
      'dra72x-hsevm' => 'dra72-evm.dtb',
      'dra71x-evm' => 'dra71-evm.dtb',
      'am57xx-evm' => 'am57xx-evm.dtb',
      'am571x-idk' => 'am571x-idk.dtb',
      'am572x-idk' => 'am572x-idk.dtb',
      'beaglebone-black' => 'am335x-boneblack.dtb',
      'am335x-sk' => 'am335x-evmsk.dtb',
      'am437x-sk' => 'am437x-sk-evm.dtb',
      'am43xx-epos' => 'am43x-epos-evm.dtb',
      'k2g-evm' => 'k2g-evm.dtb',
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
    machines['dra71x-evm']  = {'0.0' => /Machine model: TI DRA71/ }
    machines['dra71x-hsevm']  = {'0.0' => /Machine model: TI DRA71/ }
    machines['dra72x-evm']  = {'0.0' => /Machine: Generic DRA7XX \(Flattened Device Tree\), model: TI DRA7/,
                              '3.14' => /Machine model: TI DRA722/,
                              }
    machines['dra7xx-hsevm']  = {'0.0' => /Machine: Generic DRA7XX \(Flattened Device Tree\), model: TI DRA7/,
                              '3.14' => /Machine model: TI DRA742/,
                              }
    machines['dra76x-evm']  = {'0.0' => /Machine model: TI DRA76.* EVM/ }
    machines['dra72x-hsevm']  = {'0.0' => /Machine: Generic DRA7XX \(Flattened Device Tree\), model: TI DRA7/,
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
    machines['am43xx-hsevm'] = {'0.0' => /Machine: Generic AM43 \(Flattened Device Tree\), model: TI AM437x gp EVM/i,
                               '3.14' => /Machine model: TI AM437x GP EVM/,
                              }
    machines['am437x-sk'] = {'3.14' => /Machine model: TI AM437x SK EVM/, }
    machines['am437x-idk'] = {'3.14' => /Machine model: TI AM437x Industrial Development Kit/, }
    machines['am57xx-evm'] = {'0.0' => /Machine model: TI (AM572x EVM|AM5728 BeagleBoard-X15|AM5728 EVM)/, }
    machines['am57xx-hsevm'] = {'0.0' => /Machine model: TI (AM572x EVM|AM5728 BeagleBoard-X15|AM5728 EVM)/, }
    machines['am572x-idk'] = {'0.0' => /Machine model: TI AM572x IDK/, }
    machines['am571x-idk'] = {'0.0' => /Machine model: TI (AM5718 IDK|AM571x IDK)/, }
    machines['am574x-idk'] = {'0.0' => /Machine model: TI (AM5748|AM574x) IDK/, }
    machines['k2hk-evm'] = {'0.0' => /Machine model:.*Keystone 2 Kepler\/Hawking EVM/, }
    machines['k2e-evm'] = {'0.0' => /Machine model:.*Keystone 2 Edison EVM/, }
    machines['k2l-evm'] = {'0.0' => /Machine model:.*Keystone 2 Lamarr EVM/, }
    machines['am654x-evm'] = {'0.0' => /Machine model: Texas Instruments AM654 Base Board/ }
                                          
    params.merge!({'dict' => machines})
    get_cmd(params)
  end

  def get_max_opp_string(params)
    machines = {}
    machines['am335x-evm']  = {'0.0' => '1000000'}
    machines['am335x-sk']   = {'0.0' => '1000000'}
    machines['beaglebone']  = {'0.0' => '720000'}
    machines['beaglebone-black'] = {'0.0' => '1000000'}
    machines['dra76x-evm']  = {'0.0' => '1800000'}
    machines['dra7xx-evm']  = {'0.0' => '1500000'}
    machines['dra72x-evm']  = {'0.0' => '1500000'}
    machines['dra7xx-hsevm']  = {'0.0' => '1500000'}
    machines['dra72x-hsevm']  = {'0.0' => '1500000'}
    machines['dra71x-evm']  = {'0.0' => '1000000'}
    machines['dra71x-hsevm']  = {'0.0' => '1000000'}
    machines['omap5-evm']   = {'0.0' => '1500000'}
    machines['am43xx-epos'] = {'0.0' => '1000000'}
    machines['am43xx-gpevm'] = {'0.0' => '1000000'}
    machines['am43xx-hsevm'] = {'0.0' => '1000000'}
    machines['am437x-sk'] = {'0.0' => '1000000'}
    machines['am437x-idk'] = {'0.0' => '1000000'}
    machines['am57xx-evm']  = {'0.0' => '1500000'}
    machines['am57xx-hsevm']  = {'0.0' => '1500000'}
    machines['am571x-idk']  = {'0.0' => '1500000'}
    machines['am572x-idk']  = {'0.0' => '1500000'}
    machines['am574x-idk']  = {'0.0' => '1500000'}
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
    machines['dra76x-evm']  = {'0.0' => nil}
    machines['am57xx-evm']  = {'0.0' => nil}
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
    machines['dra76x-evm']  = {'0.0' => data}
    machines['dra72x-evm']  = {'0.0' => data}
    machines['dra71x-evm']  = {'0.0' => data}
    machines['am57xx-evm']  = {'0.0' => data.select{|item| /VDD/.match(item)}}
    params.merge!({'dict' => machines})
    get_cmd(params)
  end

  def get_regulators_remain_on(params=nil)
    machines = {}
    params = get_default_params if !params
    return [] if not params['platform'].match(/(^am5|^dra7)/)
    data = get_power_domain_data(params['platform'])['power_domains']
    data.select! {|name| name.match /(CORE|MPU|DSP|IVA|GPU)/}
    machines[params['platform']]  = {'0.0' => data}
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
                               'VDD_DSPEVE' => {'OPP_NOM'=>'0x4A0025E0','OPP_OD'=>'0x4A0025E4','OPP_HIGH'=>'0x4A0025E8'},
                               'CORE_VDD' => {'OPP_NOM'=>'0x4A0025F4'}, 
                               'VDD_GPU' => {'OPP_NOM'=>'0x4A003B08','OPP_OD'=>'0x4A003B0C','OPP_HIGH'=>'0x4A003B10'}, 
                               'VDD_MPU' => {'OPP_NOM'=>'0x4A003B20','OPP_OD'=>'0x4A003B24','OPP_HIGH'=>'0x4A003B28'}, 
                              }
    machines['dra72x-evm']  = {'VDD_CORE' => {'OPP_NOM'=>'0x4A0025F4'}, 
                               'VDD_GPU' => {'OPP_NOM'=>'0x4A003B08','OPP_OD'=>'0x4A003B0C','OPP_HIGH'=>'0x4A003B10'},
                               'VDD_IVA' => {'OPP_NOM'=>'0x4A0025CC','OPP_OD'=>'0x4A0025D0','OPP_HIGH'=>'0x4A0025D4'},
                               'VDD_DSPEVE' => {'OPP_NOM'=>'0x4A0025E0','OPP_OD'=>'0x4A0025E4','OPP_HIGH'=>'0x4A0025E8'},
                               'VDD_MPU' => {'OPP_NOM'=>'0x4A003B20','OPP_OD'=>'0x4A003B24','OPP_HIGH'=>'0x4A003B28'}, 
                              }
    machines['dra76x-evm']  = {'VDD_IVA' => {'OPP_NOM'=>'0x4A0025CC','OPP_OD'=>'0x4A0025D0','OPP_HIGH'=>'0x4A0025D4', 'OPP_PLUS'=>'0x4A0025D8'},
                               'VDD_DSPEVE' => {'OPP_NOM'=>'0x4A0025E0','OPP_OD'=>'0x4A0025E4','OPP_HIGH'=>'0x4A0025E8','OPP_PLUS'=>'0x4A0025EC'},
                               'VDD_CORE' => {'OPP_NOM'=>'0x4A0025F4'},
                               'VDD_GPU' => {'OPP_NOM'=>'0x4A003B08','OPP_OD'=>'0x4A003B0C','OPP_HIGH'=>'0x4A003B10','OPP_PLUS'=>'0x4A003B14'},
                               'VDD_MPU' => {'OPP_NOM'=>'0x4A003B20','OPP_OD'=>'0x4A003B24','OPP_HIGH'=>'0x4A003B28','OPP_PLUS'=>'0x4A003B2C'},
                              }
    machines['am654x-evm']  = {'VDD_MPU' => {'OPP_LOW'=>'0x42050164', 'OPP_NOM'=>'0x42050164', 'OPP_OD'=>'0x42050164', 'OPP_HIGH'=>'0x42050164'},
                               'VDD_MPU2' => {'OPP_LOW'=>'0x42050184', 'OPP_NOM'=>'0x42050184', 'OPP_OD'=>'0x42050184', 'OPP_HIGH'=>'0x42050184'},
                              }
    machines['j721e-evm']  = {'VDD_MPU' => {'OPP_LOW'=>'0x42040104', 'OPP_NOM'=>'0x42040104', 'OPP_OD'=>'0x42040104', 'OPP_HIGH'=>'0x42040104'},
                             }

    machines['am57xx-evm']   = machines['dra7xx-evm']
    machines['dra71x-evm']   = machines['dra72x-evm']
    machines['am654x-idk']   = machines['am654x-evm']
    machines['j721e-idk-gw']   = machines['j721e-evm']
    machines['j721e-evm-ivi']   = machines['j721e-evm']

    raise "AVS class0 data not defined for #{platform}" if !machines.key?(platform)
    machines[platform]
  end

  #Define ganged rails in the EVM
  def get_ganged_rails(platform, domain, opp)
    data = get_avs_class0_data(platform)
    case platform.downcase
    when "dra71x-evm"
      case domain
      when "VDD_GPU"
        return [data['VDD_CORE']['OPP_NOM'], data['VDD_MPU'][opp]]
      when "VDD_CORE"
        return [data['VDD_GPU'][opp], data['VDD_MPU'][opp]]
      when "VDD_MPU"
        return [data['VDD_GPU'][opp], data['VDD_CORE']['OPP_NOM']]
      when "VDD_DSPEVE"
        return [data['VDD_IVA'][opp]]
      when "VDD_IVA"
        return [data['VDD_DSPEVE'][opp]]
      else
        return []
      end

    when "dra72x-evm"
      case domain
      when "VDD_GPU"
        return [data['VDD_IVA'][opp], data['VDD_DSPEVE'][opp]]
      when "VDD_IVA"
        return [data['VDD_GPU'][opp], data['VDD_DSPEVE'][opp]]
      when "VDD_DSPEVE"
        return [data['VDD_IVA'][opp], data['VDD_GPU'][opp]]
      else
        return []
      end

    when "am654x-evm", "am654x-idk"
      case domain
      when "VDD_MPU"
        return [data['VDD_MPU2'][opp]]
      when "VDD_MPU2"
        return [data['VDD_MPU'][opp]]
      else
        return []
      end

    else
      return []
    end
  end


  def map_vtm_vid_value_to_voltage(platform, value)
    case platform.downcase
    when "am654x-evm", "am654x-idk"
      min_volt = 300
      step1 = 15; step1_size = 20
      step2 = 115; step2_size = 5
      step3 = 171; step3_size = 10
      step4 = 255; step4_size = 20
      raise "Invalid VTM VID efuse value #{value} for #{platform}" if value == 0 or value > step4
      if value <= step1
        return (value * step1_size) + min_volt
      elsif value <= step2
        return ((value - step1) * step2_size) + (step1 * step1_size) + min_volt
      elsif value <= step3
        return ((value - step2) * step3_size) + ((step2 - step1) * step2_size) + (step1 * step1_size) + min_volt
      else
        return ((value - step3) * step4_size) + ((step3 - step2) * step3_size) + ((step2 - step1) * step2_size) + (step1 * step1_size) + min_volt
      end

    else
      return value
    end
  end

  def get_opp_vtm_bits(platform, opp, value)
    case platform.downcase
    when "am654x-evm", "am654x-idk"
      case opp.upcase
      when "OPP_LOW"
        return value & 0xff
      when "OPP_NOM"
        return (value & 0xff00) >> 8
      when "OPP_OD"
        return (value & 0xff0000) >> 16
      when "OPP_HIGH"
        return (value & 0xff000000) >> 24
      else
        raise "Invalid operating point #{opp} for #{platform}"
      end

    else
      return value & 0xfff
    end
  end


  # Define usb controller instance for usb gadget
  def get_usb_gadget_number(platform)
    case platform.downcase
    when /am57/
      return 1
    else
      return 0
    end
  end

  # Define AVS requirements for uboot
  def get_required_uboot_avs(platform)
    data = get_avs_class0_data(platform)
    case platform
    
    when "dra7xx-evm", "dra72x-evm", "am57xx-evm", "dra76x-evm"
      return data.map{|domain,opps|
        if domain == 'VDD_IVA' or domain == 'VDD_DSPEVE' or domain == 'VDD_GPU'
          { domain => opps.select{|name,address| name == "OPP_HIGH"} }
        else
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }
    
    when "dra71x-evm"
      return data.map{|domain,opps|
        if domain == 'VDD_IVA' or domain == 'VDD_DSPEVE'
          { domain => opps.select{|name,address| name == "OPP_HIGH"} }
        else
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }

    when "am654x-evm", "am654x-idk"
      return data.map{|domain,opps|
        if domain == 'VDD_MPU'
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }

    else
      raise "AVS class0 uboot requirements are not defined for #{platform}" 
    end
  end

  # Define AVS requirements for Linux
  def get_required_linux_avs(platform)
    data = get_avs_class0_data(platform)
    case platform
    
    when "dra7xx-evm", "am57xx-evm", "dra72x-evm", "dra76x-evm"
      return data.map{|domain,opps| 
        if domain == 'VDD_MPU'
          { domain => opps.select{|name,address| name == "OPP_NOM" or name == "OPP_HIGH" or name == "OPP_OD" or name == "OPP_PLUS"} }
        elsif domain == 'VDD_IVA' or domain == 'VDD_DSPEVE' or domain == 'VDD_GPU'
          { domain => opps.select{|name,address| name == "OPP_HIGH"} }
        else
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }

    when "dra71x-evm"
      return data.map{|domain,opps|
        if domain == 'VDD_IVA' or domain == 'VDD_DSPEVE'
          { domain => opps.select{|name,address| name == "OPP_HIGH"} }
        else
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }

    when "am654x-evm", "am654x-idk"
      return data.map{|domain,opps|
        if domain == 'VDD_MPU'
          { domain => opps.select{|name,address| name == "OPP_NOM"} }
        end
      }

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
    machines['dra71x-evm']  = {'CPU' => {'OPP_NOM'=>'1000000'},
                               'GPU' => {'OPP_NOM'=>'425600'},
                               'IVA' => {'OPP_NOM'=>'388300','OPP_HIGH'=>'532000'},
                               'DSP' => {'OPP_NOM'=>'600000','OPP_HIGH'=>'750000'},
                              }
    machines['dra76x-evm']  = {'CPU' => {'OPP_NOM'=>'1000000','OPP_OD'=>'1176000','OPP_HIGH'=>'1500000', 'OPP_PLUS'=>'1800000'},
                               'GPU' => {'OPP_NOM'=>'425600','OPP_OD'=>'500000', 'OPP_HIGH'=>'532000', 'OPP_PLUS'=>'665000'},
                               'IVA' => {'OPP_NOM'=>'388300','OPP_OD'=>'430000','OPP_HIGH'=>'532000', 'OPP_PLUS'=>'617000'},
                               'DSP' => {'OPP_NOM'=>'600000','OPP_OD'=>'700000','OPP_HIGH'=>'850000', 'OPP_PLUS'=>'1000000'},
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

  def get_pci_deviceid(platform)
    case platform.downcase
      when /j7/
        return "0xb00d"
      when /k2g/
        return "0xb00b"
      when /am654x/
        return "0xb00c"
      when /dra7xx/i
        return "0xb500"
      when /dra71x|dra72x/i
        return "0xb501"
      else
        raise "PCI Device ID is not defined for #{platform}"
    end
  end

  # Define eth boot method name
  def get_eth_boot_method(platform)
    case platform.downcase
    when /^k2.{0,2}-(hs){0,1}evm/
      return :LOAD_FROM_ETHERNET_BY_BMC
    else
      return :LOAD_FROM_ETHERNET
    end
  end

  # Define uart boot method name
  def get_uart_boot_method(platform)
    case platform.downcase
    when /^k2.{0,2}-(hs){0,1}evm/
      return :LOAD_FROM_SERIAL_UBOOT
    when /^am65.+/,/^j7.+/
      return :LOAD_FROM_SERIAL_TI_BOOT3
    when /^am57.+/
      return :LOAD_FROM_SERIAL_TI_OMAP
    else
      return :LOAD_FROM_SERIAL
    end
  end

  # Define nand boot method name
  def get_nand_boot_method(platform)
    case platform.downcase
    when /^k2.{0,2}-(hs){0,1}evm/
      return :LOAD_FROM_NAND_BY_BMC
    else
      return :LOAD_FROM_NAND
    end
  end

  # Define qspi boot method name
  def get_qspi_boot_method(platform)
    case platform.downcase
    when /^k2.{0,2}-(hs){0,1}evm/
      return :LOAD_FROM_QSPI_BY_BMC
    else
      return :LOAD_FROM_QSPI
    end
  end

  # Define spi boot method name
  def get_spi_boot_method(platform)
    case platform.downcase
    when /^k2.{0,2}-(hs){0,1}evm/
      return :LOAD_FROM_SPI_BY_BMC
    else
      return :LOAD_FROM_SPI
    end
  end

  # Define no boot method name
  def get_no_boot_method(platform)
    case platform.downcase
    when /^k2.{0,2}-(hs){0,1}evm/
      return :LOAD_FROM_NO_BOOT_DSP_BY_BMC
    else
      raise "dont know how boot"
    end
  end

  #function to get pru port information per platform
  def get_default_eth_ports(platform)
    pru_data = {
                'am335x-ice' => {'eth0' => 'cpsw', 'eth1' => 'cpsw'},
                'am437x-idk' => {'eth0' => 'cpsw', 'eth1' => 'PRUSS', 'eth2' => 'PRUSS'},
                'am571x-idk' => {'eth0' => 'cpsw', 'eth1' => 'cpsw', 'eth2' => 'PRUSS', 'eth3' => 'PRUSS', 'eth4' => 'PRUSS', 'eth5' => 'PRUSS'},
                'am572x-idk' => {'eth0' => 'cpsw', 'eth1' => 'cpsw', 'eth2' => 'PRUSS', 'eth3' => 'PRUSS'},
                'am574x-idk' => {'eth0' => 'cpsw', 'eth1' => 'cpsw', 'eth2' => 'PRUSS', 'eth3' => 'PRUSS'},
                'k2g-ice'    => {'eth0' => 'TI KeyStone', 'eth1' => 'PRUSS', 'eth2' => 'PRUSS', 'eth3' => 'PRUSS', 'eth4' => 'PRUSS'},
                'am654x-idk' => {'eth0' => 'am65-cpsw-nuss', 'eth1' => 'icssg-prueth', 'eth2' => 'icssg-prueth', 'eth3' => 'icssg-prueth', 'eth4' => 'icssg-prueth', 'eth5' => 'icssg-prueth', 'eth6' => 'icssg-prueth'},
                'am654x-evm' => {'eth0' => 'am65-cpsw-nuss', 'eth1' => 'icssg-prueth', 'eth2' => 'icssg-prueth'}
	       }
     return  pru_data["#{platform}"]
  end
  
end
