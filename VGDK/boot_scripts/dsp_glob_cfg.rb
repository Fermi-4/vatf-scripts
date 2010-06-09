module DSPGlobConfig

    def send_dsp_glob_config(dut)
    dut.send_cmd("dimt dsp_glob_config 0 alloc_g 10",/DONE/,2) 
    dut.send_cmd("dimt dsp_glob_config 1 alloc_g 10",/DONE/,2) 
    dut.send_cmd("dimt dsp_glob_config 2 alloc_g 10",/DONE/,2) 
    dut.send_cmd("dimt dsp_glob_config 3 alloc_g 10",/DONE/,2) 
    dut.send_cmd("dimt dsp_glob_config 4 alloc_g 10",/DONE/,2) 
    dut.send_cmd("dimt dsp_glob_config 5 alloc_g 10",/DONE/,2) 
	#Configure streaming NEU to stream out MIPS data 
    dut.send_cmd("dimt set template 32 dsp_glob_config bulk_mem_encap_config mac_port_id 0",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 0 alloc_g 32 ",/DONE/,2) 
    end
    
end