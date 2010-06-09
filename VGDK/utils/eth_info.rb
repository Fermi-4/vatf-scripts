
module ETHInfo
    class Eth_info
        @@platform_ip = {}
		@@platform_mac = {}
		@@eth_dev = nil
		@@pc_ip = nil
		@@pc_mac = nil
        def initialize(dut = nil)

        end
		def init_eth_info(dut)
			cores = 6
			@@pc_ip = dut.params["pc_ip"]
			@@pc_mac = dut.params["pc_mac"]
			@@eth_dev = dut.params["pc_eth_dev"]
			cores.times do |i|
			  @@platform_ip["CORE_#{i}"] = dut.params["platform_ip"]["CORE_#{i}"]
			end
			cores.times do |i|
			  @@platform_mac["CORE_#{i}"] = dut.params["platform_mac"]["CORE_#{i}"]
			end
		end
        def get_platform_ip
           @@platform_ip
        end
        def get_platform_mac
           @@platform_mac
        end
        def get_eth_dev
          @@eth_dev
        end
        def get_pc_ip
          @@pc_ip
        end
        def get_pc_mac
          @@pc_mac
        end
  end
end