# --------------------------------------------------
# Configuration of video calls
# Remote party address configuration
# Transcoding path is between the PC to Tomahawk gateway to PC
# Tomahawk channels should be configured with PC as remote/destination gw
# Note the name of the string is fixed "dspMacVoiceTgt" prefixes
# dsp_core followed by MAC address index. 
# --------------------------------------------------
require File.dirname(__FILE__)+'/../utils/eth_info'
include ETHInfo
module XDPVarSetTgtPC

def send_xdp_var_set_tgt_pc(dut)
    # Destination MAC of PC
    platform_info = Eth_info.new(dut)
    pc_mac = platform_info.get_pc_mac
    pc_ip = platform_info.get_pc_ip

    dut.send_cmd("cc xdp_var set dspMacVoiceTgt0_0 #{pc_mac}",/OK/,2) 
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt1_0 #{pc_mac}",/OK/,2) 
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt2_0 #{pc_mac}",/OK/,2)  
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt3_0 #{pc_mac}",/OK/,2)  
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt4_0 #{pc_mac}",/OK/,2) 
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt5_0 #{pc_mac}",/OK/,2) 
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt6_0 #{pc_mac}",/OK/,2) 
    dut.send_cmd("cc xdp_var set dspMacVoiceTgt7_0 #{pc_mac}",/OK/,2) 
    # Destination IP of PC
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt0_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt1_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt2_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt3_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt4_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt5_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt6_0 #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpVoiceTgt7_0 #{pc_ip}",/OK/,2)

    dut.send_cmd("cc xdp_var set dspMacStrmTgt0 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt0   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt0 0x7802",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt1 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt1   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt1 0x7804",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt2 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt2   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt2 0x7806",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt3 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt3   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt3 0x7808",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt4 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt4   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt4 0x780A",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt5 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt5   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt5 0x780C",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt6 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt6   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt6 0x780E",/OK/,2)
    
    dut.send_cmd("cc xdp_var set dspMacStrmTgt7 #{pc_mac}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspIpStrmTgt7   #{pc_ip}",/OK/,2)
    dut.send_cmd("cc xdp_var set dspUdpStrmTgt7 0x7810",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt0 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt0  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt0 0xCE98",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt1 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt1  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt1 0xCE9A",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt2 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt2  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt2 0xCE9C",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt3 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt3  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt3 0xCE9E",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt4 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt4  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt4 0xCEA0",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt5 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt5  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt5 0xCEA2",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt6 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt6  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt6 0xCEA4",/OK/,2)

# dut.send_cmd("cc xdp_var set dspMacBlkTgt7 #{pc_mac}",/OK/,2) 
# dut.send_cmd("cc xdp_var set dspIpBlkTgt7  #{pc_ip}",/OK/,2)
# dut.send_cmd("cc xdp_var set dspUdpBlkTgt7 0xCEA6",/OK/,2)

end
end