
module DrvifCfg
def send_drvif_cfg(dut)
    dut.send_cmd("\/root\/app\/dimtestvi",/Registering with XDPHW5/,2)
end

end
