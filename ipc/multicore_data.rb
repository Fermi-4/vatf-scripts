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
    data_list['k2g-evm'] = { 'PING'     => {'CORES' => %w[C66xx_0 arm_A15_0],
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

    platform_token = {}
    platform_token['k2hk-evm'] = "TCI6636_bios_elf"
    platform_token['k2e-evm'] = "66AK2E_bios_elf"
    platform_token['k2l-evm'] = "TCI6630_bios_elf"
    platform_token['k2g-evm'] = "66AK2G_bios_elf"

    key_platforms = ['k2hk-evm', 'k2e-evm', 'k2l-evm', 'k2g-evm']

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

    raise "The multicore data table does not have the entry for #{platform}; Please add the entry in 'ipc/multicore_ipc_data.rb'!" if !data_list.has_key?(platform)
    return data_list[platform][test][data]
  end
end
