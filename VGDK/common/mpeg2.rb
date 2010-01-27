module MPEG2Params
 def get_mpeg2_default_params
    # These parameters will be initialized on start up, the values of the MPEG2_test_params will overwrite the corresponding
    # MPEG2_default_params values later.
  @mpeg2_default_params = {
        'mpeg2v_dec_coding_type'                            => 11,
        'mpeg2v_dec_payload_type'                           => 32,
        'mpeg2v_dec_img_width'                              => 176,
        'mpeg2v_dec_img_height'                             => 144,
                                                                     
        #mpeg2vv decoder dynamic parameters			     
        'mpeg2vdec_dyn_00_decodeheader_msb'                     =>    0,
        'mpeg2vdec_dyn_01_decodeheader_lsb'                     =>    0,
        'mpeg2vdec_dyn_02_displaywidth_msb'                     =>    0,
        'mpeg2vdec_dyn_03_displaywidth_lsb'                     =>    0,
        'mpeg2vdec_dyn_04_frameskipmode_msb'                    =>    0,
        'mpeg2vdec_dyn_05_frameskipmode_lsb'                    =>    0,
        'mpeg2vdec_dyn_06_frameorder_msb'               	    =>    0,
        'mpeg2vdec_dyn_07_frameorder_lsb'               	    =>    0,
        'mpeg2vdec_dyn_08_newframeflag_msb'		                =>    0,
        'mpeg2vdec_dyn_09_newframeflag_lsb'		                =>    0,
        'mpeg2vdec_dyn_10_mbdataflag_msb'		                =>    0,
        'mpeg2vdec_dyn_11_mbdataflag_lsb'		                =>    0,
        'mpeg2vdec_dyn_12_ppnone_msb'			                =>    0,
        'mpeg2vdec_dyn_13_ppnone_lsb'			                =>    0,
        'mpeg2vdec_dyn_14_dynachrfmt_msb'	                    =>    0,
        'mpeg2vdec_dyn_15_dynachrfrmt_lsb'	                    =>    1,
        'mpeg2vdec_dyn_16_disfldre_msb'	                        =>    0,
        'mpeg2vdec_dyn_17_disfldre_lsb'	                        =>    0,
        'mpeg2vdec_dyn_18_frlvlbysw_msb'	                    =>    0,
        'mpeg2vdec_dyn_19_frlvlbysw_lsb'	                    =>    0, 
        'mpeg2vdec_dyn_20_skipbfr_msb'		                    =>    0,
        'mpeg2vdec_dyn_21_skipbfr_lsb'		                    =>    0,
        'mpeg2vdec_dyn_22_gotonxtifr_msb'	                    =>    0,
        'mpeg2vdec_dyn_23_gotonxtifr_lsb'	                    =>    0,
        'mpeg2vdec_dyn_24_skipcurrfr_msb'		                =>    0,
        'mpeg2vdec_dyn_25_skipcurrfr_lsb'		                =>    0,
        'mpeg2vdec_dyn_26_seekfrend_msb'		                =>    0,
        'mpeg2vdec_dyn_27_seekfrend_lsb'		                =>    0,
        'mpeg2vdec_dyn_28_getdishdrinfo_msb'	    	        =>    0,
        'mpeg2vdec_dyn_29_getdishdrinfo_lsb'	    	        =>    0,
        'mpeg2vdec_dyn_30_revplay_msb'		                    =>    0,
        'mpeg2vdec_dyn_31_revplay_lsb'		                    =>    0,
        'mpeg2vdec_dyn_32_roblvl_msb'	                        =>    0,
        'mpeg2vdec_dyn_33_roblvl_lsb'	                        =>    1,
        'mpeg2vdec_dyn_34_nodelaydis_msb'	                    =>    0,
        'mpeg2vdec_dyn_35_nodelaydis_lsb'	                    =>    0,
				      
                                           
        #mpeg2vv decoder static parameters      			   
        'mpeg2vdec_st_00_maxheight_msb'                      =>    0,
        'mpeg2vdec_st_01_maxheight_lsb'                      =>    144,
        'mpeg2vdec_st_02_maxwidth_msb'                       =>    0,
        'mpeg2vdec_st_03_maxwidth_lsb'                       =>    176,
        'mpeg2vdec_st_04_maxframerate_msb'                   =>    0,
        'mpeg2vdec_st_05_maxframerate_lsb'                   =>    30,
        'mpeg2vdec_st_06_maxbitrate_msb'                     =>    "0x0098",
        'mpeg2vdec_st_07_maxbitrate_lsb'                     =>    "0x9680",
        'mpeg2vdec_st_08_dataend_msb'                        =>    0,
        'mpeg2vdec_st_09_dataend_lsb'                        =>    3,
        'mpeg2vdec_st_10_forcechrfmt_msb'                    =>    0,
        'mpeg2vdec_st_11_forcechrfmt_lsb'                    =>    1,
                                                        
         }
end
 def get_mpeg2_test_params(codec_type)
  # These parameter values will overwrite the corresponding mpeg2_default_params values later.These are a subset of mpeg2_default_params
  if(codec_type == "dec")
    @mpeg2_test_params = {
        #DEC static
        'mpeg2vdec_st_maxframerate'                         =>    30,
        'mpeg2vdec_st_maxbitrate'                           =>    10000000,

        }
  elsif(codec_type == "enc")
    raise "MPEG2 encoder is not supported"
  end
 end
 def get_mpeg2_group_by_params(group_by_param) 
    @mpeg2_group_by_params = { 
      }

 end
end  