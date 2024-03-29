# ; Source MAC address for Voice Channel
# ; Note the name of the string is fixed dspMacVoiceSrc prefixes
# ; dsp_core followed by MAC address index. 
require File.dirname(__FILE__)+'/../utils/eth_info'
include ETHInfo
module XDPVarSetSrcEVM
def send_xdp_var_set_srm_evm(dut)
    platform_info = Eth_info.new()
    platform_info.init_eth_info(dut)
    platform_mac = platform_info.get_platform_mac
    platform_ip = platform_info.get_platform_ip
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc0_0 #{platform_mac["CORE_0"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc1_0 #{platform_mac["CORE_1"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc2_0 #{platform_mac["CORE_2"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc3_0 #{platform_mac["CORE_3"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc4_0 #{platform_mac["CORE_4"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc5_0 #{platform_mac["CORE_5"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc6_0 #{platform_mac["CORE_6"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspMacVoiceSrc7_0 #{platform_mac["CORE_7"]}",/OK/,2)


    dut.send_cmd("cc xdp_var set dspIpVoiceSrc0_0 #{platform_ip["CORE_0"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc1_0 #{platform_ip["CORE_1"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc2_0 #{platform_ip["CORE_2"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc3_0 #{platform_ip["CORE_3"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc4_0 #{platform_ip["CORE_4"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc5_0 #{platform_ip["CORE_5"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc6_0 #{platform_ip["CORE_6"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceSrc7_0 #{platform_ip["CORE_7"]}",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc0  #{platform_mac["CORE_0"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc0  #{platform_ip["CORE_0"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc0 0xCE98",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc1  #{platform_mac["CORE_1"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc1  #{platform_ip["CORE_1"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc1 0xCE9A",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc2  #{platform_mac["CORE_2"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc2  #{platform_ip["CORE_2"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc2 0xCE9C",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc3  #{platform_mac["CORE_3"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc3  #{platform_ip["CORE_3"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc3 0xCE9E",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc4  #{platform_mac["CORE_4"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc4  #{platform_ip["CORE_4"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc4 0xCEA0",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc5  #{platform_mac["CORE_5"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc5  #{platform_ip["CORE_5"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc5 0xCEA2",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc6  #{platform_mac["CORE_6"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc6  #{platform_ip["CORE_6"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc6 0xCEA4",/OK/,2)
    
    # dut.send_cmd("cc xdp_var set dspMacBlkSrc7  #{platform_mac["CORE_7"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspIpBlkSrc7  #{platform_ip["CORE_7"]}",/OK/,2)
    # dut.send_cmd("cc xdp_var set dspUdpBlkSrc7 0xCEA6",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc0 #{platform_mac["CORE_0"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc0   #{platform_ip["CORE_0"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc0 0x7802",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc1 #{platform_mac["CORE_1"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc1   #{platform_ip["CORE_1"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc1 0x7804",/OK/,2)
  
    dut.send_cmd("cc xdp_var set dspMacStrmSrc2 #{platform_mac["CORE_2"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc2   #{platform_ip["CORE_2"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc2 0x7806",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc3 #{platform_mac["CORE_3"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc3   #{platform_ip["CORE_3"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc3 0x7808",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc4 #{platform_mac["CORE_4"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc4   #{platform_ip["CORE_4"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc4 0x780A",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc5 #{platform_mac["CORE_5"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc5   #{platform_ip["CORE_5"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc5 0x780C",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc6 #{platform_mac["CORE_6"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc6   #{platform_ip["CORE_6"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc6 0x780E",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmSrc7 #{platform_mac["CORE_7"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmSrc7   #{platform_ip["CORE_7"]}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmSrc7 0x7810",/OK/,2)

end
end
# ; Blk Memory Configuration 

