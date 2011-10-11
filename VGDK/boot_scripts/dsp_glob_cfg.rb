module DSPGlobConfig

    def send_dsp_glob_config(dut)
    dut.send_cmd("dimt dsp_glob_config 0 alloc_g 10",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 1 alloc_g 10",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 2 alloc_g 10",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 3 alloc_g 10",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 4 alloc_g 10",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 5 alloc_g 10",/OK/,2) 
        
    dut.send_cmd("dimt dsp_glob_config 6 alloc_g 10",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 7 alloc_g 10",/OK/,2) 
    #Configure streaming NEU to stream out MIPS data 
    dut.send_cmd("dimt set template 32 dsp_glob_config bulk_mem_encap_config mac_port_id 0",/OK/,2) 

    dut.send_cmd("dimt dsp_glob_config 0 alloc_g 32 ",/OK/,2) 
    dut.send_cmd("dimt dsp_glob_config 1 alloc_g 32 ",/OK/,2) 

    dut.send_cmd("xdp rtcp 1", /OK/, 2)
    dut.send_cmd("cc rtcp_dsp_sdes 0 1 @telogy_0.com", /OK/, 2)
    dut.send_cmd("cc rtcp_dsp_sdes 1 1 @telogy_1.com", /OK/, 2)
    dut.send_cmd("cc rtcp_dsp_sdes 2 1 @telogy_2.com", /OK/, 2)
    dut.send_cmd("cc rtcp_dsp_sdes 3 1 @telogy_3.com", /OK/, 2)
    dut.send_cmd("cc rtcp_dsp_sdes 4 1 @telogy_4.com", /OK/, 2)
    dut.send_cmd("cc rtcp_dsp_sdes 5 1 @telogy_5.com", /OK/, 2)
    end
    
end