module MulticoreData

  # Data list for each test on each platform
  def get_data(platform, test, data)
    test = test.upcase
    data = data.upcase

    #initial table structure
    data_list = {}
    data_list['k2hk-evm'] = { 'PING'     => {'CORES' => %w[C66xx_0 C66xx_1 C66xx_2 C66xx_3 C66xx_4 C66xx_5 C66xx_6 C66xx_7 arm_A15_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""},
                              'MESSAGEQ' => {'CORES' => %w[arm_A15_0 arm_A15_1 arm_A15_2 arm_A15_3 C66xx_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""}
                            }
    data_list['k2h-evm'] = { 'PING'     => {'CORES' => %w[C66xx_0 C66xx_1 C66xx_2 C66xx_3 C66xx_4 C66xx_5 C66xx_6 C66xx_7 arm_A15_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""},
                              'MESSAGEQ' => {'CORES' => %w[arm_A15_0 arm_A15_1 arm_A15_2 arm_A15_3 C66xx_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""}
                            }
    data_list['k2e-evm'] = { 'PING'     => {'CORES' => %w[C66xx_0 arm_A15_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""},
                             'MESSAGEQ' => {'CORES' => %w[C66xx_0 arm_A15_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""}
                           }
    data_list['k2l-evm'] = { 'PING'     => {'CORES' => %w[C66xx_0 C66xx_1 C66xx_2 C66xx_3 arm_A15_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""},
                             'MESSAGEQ' => {'CORES' => %w[C66xx_0 arm_A15_0],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""}
                           }
    data_list['k2g-evm'] = { 'PING'     => {'CORES' => %w[C66xx CortexA15],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""},
                             'MESSAGEQ' => {'CORES' => %w[CortexA15 C66xx],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""}
                           }
	#For AM572x, A15 needs to be connected first.
    data_list['am572x-evm'] = { 'PING'   => {'CORES' => %w[CortexA15_0 C66xx_DSP1 C66xx_DSP2 Cortex_M4_IPU1_C0 Cortex_M4_IPU1_C1 Cortex_M4_IPU2_C0 Cortex_M4_IPU2_C1],
                                             'DSP_CORES'  => [1,2],
                                             'IPU1_CORES' => [3,4],
                                             'IPU2_CORES' => [5,6],
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""},
                              'MESSAGEQ' => {'CORES' => %w[CortexA15_0 C66xx_DSP1], 
                                             'BINARIES' => [],
                                             'ROV' => [],
                                             'LOGGERBUF_FIELD' => [],
                                             'OUTPUT' => ""}
                           }

    platform_token = {}
    platform_token['k2hk-evm'] = "TCI6636_bios_elf"
    platform_token['k2h-evm'] = "TCI6636_bios_elf"
    platform_token['k2e-evm'] = "66AK2E_bios_elf"
    platform_token['k2l-evm'] = "TCI6630_bios_elf"
    platform_token['k2g-evm'] = "66AK2G_bios_elf"
    platform_token['am572x-evm'] = "DRA7XX_bios_elf"
    
    key_platforms = ['k2hk-evm', 'k2e-evm', 'k2l-evm', 'k2h-evm'] 
    key_platforms_k2g = ['k2g-evm']
    key_platforms_am572x = ['am572x-evm']

    #populate the lists
    key_platforms.each { |evm|
    (0..data_list[evm]['PING']['CORES'].length - 2).each do |i|
      data_list[evm]['PING']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex11_ping/core#{i}/bin/debug/server_core#{i}.xe66"
      data_list[evm]['PING']['ROV'][i] = "/examples/#{platform_token[evm]}/ex11_ping/core#{i}/bin/debug/configuro/package/cfg/Core#{i}_pe66.rov.xs"
    end
    data_list[evm]['PING']['BINARIES'][data_list[evm]['PING']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex11_ping/host/bin/debug/server_host.xa15fg"
    data_list[evm]['PING']['ROV'][data_list[evm]['PING']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex11_ping/host/bin/debug/configuro/package/cfg/Host_pa15fg.rov.xs"
    data_list[evm]['PING']['OUTPUT'] = "Main(Core[0-9]|Host)_done"
    }

    key_platforms.each { |evm|
      (0..data_list[evm]['MESSAGEQ']['CORES'].length - 2).each do |i|
        data_list[evm]['MESSAGEQ']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex02_messageq/host/bin/debug/app_host.xa15fg"
        data_list[evm]['MESSAGEQ']['ROV'][i] = "/examples/#{platform_token[evm]}/ex02_messageq/host/bin/debug/configuro/package/cfg/Host_pa15fg.rov.xs"
        data_list[evm]['MESSAGEQ']['LOGGERBUF_FIELD'][i] = "ti.sysbios.smp.LoggerBuf Records"
      end

      data_list[evm]['MESSAGEQ']['BINARIES'][data_list[evm]['MESSAGEQ']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex02_messageq/core0/bin/debug/server_core0.xe66"
      data_list[evm]['MESSAGEQ']['ROV'][data_list[evm]['MESSAGEQ']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex02_messageq/core0/bin/debug/configuro/package/cfg/Core0_pe66.rov.xs"
      data_list[evm]['MESSAGEQ']['LOGGERBUF_FIELD'][data_list[evm]['MESSAGEQ']['CORES'].length - 1] = "xdc.runtime.LoggerBuf Records"

      data_list[evm]['MESSAGEQ']['OUTPUT'] = "(<-- Server_delete|App_delete: <--)"

    }

    key_platforms_k2g.each { |evm|
    (0..data_list[evm]['PING']['CORES'].length - 2).each do |i|
      data_list[evm]['PING']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex11_ping/core#{i}/bin/debug/server_core#{i}.xe66"
      data_list[evm]['PING']['ROV'][i] = "/examples/#{platform_token[evm]}/ex11_ping/core#{i}/bin/debug/configuro/package/cfg/Core#{i}_pe66.rov.xs"
    end
    data_list[evm]['PING']['BINARIES'][data_list[evm]['PING']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex11_ping/host/bin/debug/server_host.xa15fg"
    data_list[evm]['PING']['ROV'][data_list[evm]['PING']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex11_ping/host/bin/debug/configuro/package/cfg/Host_pa15fg.rov.xs"
    data_list[evm]['PING']['OUTPUT'] = "Main(Core[0-9]|Host)_done"
    }


    key_platforms_k2g.each { |evm|
      (0..data_list[evm]['MESSAGEQ']['CORES'].length - 2).each do |i|
        data_list[evm]['MESSAGEQ']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex02_messageq/host/bin/debug/app_host.xa15fg"
        data_list[evm]['MESSAGEQ']['ROV'][i] = "/examples/#{platform_token[evm]}/ex02_messageq/host/bin/debug/configuro/package/cfg/Host_pa15fg.rov.xs"
        #K2G does not have the sysbios loggerbuf field
	data_list[evm]['MESSAGEQ']['LOGGERBUF_FIELD'][0] = "xdc.runtime.LoggerBuf Records" 
      end

      data_list[evm]['MESSAGEQ']['BINARIES'][data_list[evm]['MESSAGEQ']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex02_messageq/core0/bin/debug/server_core0.xe66"
      data_list[evm]['MESSAGEQ']['ROV'][data_list[evm]['MESSAGEQ']['CORES'].length - 1] = "/examples/#{platform_token[evm]}/ex02_messageq/core0/bin/debug/configuro/package/cfg/Core0_pe66.rov.xs"
      data_list[evm]['MESSAGEQ']['LOGGERBUF_FIELD'][data_list[evm]['MESSAGEQ']['CORES'].length - 1] = "xdc.runtime.LoggerBuf Records"

      data_list[evm]['MESSAGEQ']['OUTPUT'] = "(<-- Server_delete|App_delete: <--)"
    }
   
    key_platforms_am572x.each { |evm|
    data_list[evm]['PING']['BINARIES'][0] = "/examples/#{platform_token[evm]}/ex11_ping/host/bin/debug/server_host.xa15fg"
    data_list[evm]['PING']['ROV'][0] = "/examples/#{platform_token[evm]}/ex11_ping/host/bin/debug/configuro/package/cfg/Host_pa15fg.rov.xs"
	(data_list[evm]['PING']['DSP_CORES']).each do |i|
      data_list[evm]['PING']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex11_ping/dsp#{i}/bin/debug/server_dsp#{i}.xe66"
      data_list[evm]['PING']['ROV'][i] = "/examples/#{platform_token[evm]}/ex11_ping/dsp#{i}/bin/debug/configuro/package/cfg/Dsp#{i}_pe66.rov.xs"
    end
	(data_list[evm]['PING']['IPU1_CORES']).each do |i|
      data_list[evm]['PING']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex11_ping/ipu1/bin/debug/server_ipu1.xem4"
      data_list[evm]['PING']['ROV'][i] = "/examples/#{platform_token[evm]}/ex11_ping/ipu1/bin/debug/configuro/package/cfg/Ipu1_pem4.rov.xs"
    end
    (data_list[evm]['PING']['IPU2_CORES']).each do |i|
      data_list[evm]['PING']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex11_ping/ipu2/bin/debug/server_ipu2.xem4"
      data_list[evm]['PING']['ROV'][i] = "/examples/#{platform_token[evm]}/ex11_ping/ipu2/bin/debug/configuro/package/cfg/Ipu2_pem4.rov.xs"
    end
    data_list[evm]['PING']['OUTPUT'] = "Main(Core[0-9]|Host)_done"
    }

    key_platforms_am572x.each { |evm|
    data_list[evm]['MESSAGEQ']['BINARIES'][0] = "/examples/#{platform_token[evm]}/ex02_messageq/host/bin/debug/app_host.xa15fg"
    data_list[evm]['MESSAGEQ']['ROV'][0] = "/examples/#{platform_token[evm]}/ex02_messageq/host/bin/debug/configuro/package/cfg/Host_pa15fg.rov.xs"
	data_list[evm]['MESSAGEQ']['LOGGERBUF_FIELD'][0] = "ti.sysbios.smp.LoggerBuf Records"

    (1..data_list[evm]['MESSAGEQ']['CORES'].length - 1).each do |i|
      data_list[evm]['MESSAGEQ']['BINARIES'][i] = "/examples/#{platform_token[evm]}/ex02_messageq/dsp#{i}/bin/debug/server_dsp#{i}.xe66"
      data_list[evm]['MESSAGEQ']['ROV'][i] = "/examples/#{platform_token[evm]}/ex02_messageq/dsp#{i}/bin/debug/configuro/package/cfg/Dsp#{i}_pe66.rov.xs"
      data_list[evm]['MESSAGEQ']['LOGGERBUF_FIELD'][i] = "xdc.runtime.LoggerBuf Records"
    end
    data_list[evm]['MESSAGEQ']['OUTPUT'] = "(<-- Server_delete|App_delete: <--)"
    }


    raise "The multicore data table does not have the entry for #{platform}; Please add the entry in 'ipc/multicore_ipc_data.rb'!" if !data_list.has_key?(platform)
    return data_list[platform][test][data]
  end
end
