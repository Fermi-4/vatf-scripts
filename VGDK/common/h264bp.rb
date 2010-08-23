 
 
module H264BPParams
 def get_h264bp_default_params
  # These parameters will be initialized on start up, the values of the H264_test_params will overwrite the corresponding
  # H264_default_params values later.
  @H264BP_default_params = {
    #Decoder params - h264bp
    'h264bpv_dec_coding_type'                        => 2,
    'h264bpv_dec_payload_type'                       => 96,
    'h264bpv_dec_img_width'                          => 352,
    'h264bpv_dec_img_height'                         => 288,
    
    #ENCODER Params - H264
        
    'h264bpv_enc_coding_type'                        =>  1,
    'h264bpv_enc_payload_type'                       =>  96,
    'h264bpv_enc_img_width'                          =>  352,
    'h264bpv_enc_img_height'                         =>  288,
    'h264bpv_enc_ovly_type'                          =>   0,
    'h264bpv_enc_max_payload_size'                   =>   1460,
    #IH264VDEC_Params static         
    'h264bpvdec_st_00_maxheight_msb'                  => 0, 
    'h264bpvdec_st_01_maxheight_lsb'                  => 352, #max height = 576 pixels
    'h264bpvdec_st_02_maxwidth_msb'                   => 0,
    'h264bpvdec_st_03_maxwidth_lsb'                   => 288, #max width = 720 pixels
    'h264bpvdec_st_04_maxframerate_msb'               => 0,
    'h264bpvdec_st_05_maxframerate_lsb'               => 30,
    'h264bpvdec_st_06_maxbitrate_msb'                 => "0x003D",
    'h264bpvdec_st_07_maxbitrate_lsb'                 => "0x0900",
    'h264bpvdec_st_08_dataend_msb'                    => 0,
    'h264bpvdec_st_09_dataend_lsb'                    => 1, # 1->big endian (xdm_byte)
    'h264bpvdec_st_10_forcechrfmt_msb'                => 0,
    'h264bpvdec_st_11_forcechrfmt_lsb'                => 1, # 1->420p, 4->422i 
    'h264bpvdec_st_12_ipstrformat_msb'                => 0,
    'h264bpvdec_st_13_ipstrformat_lsb'                => 0, # 0->bytestrfmt, 1->nal unit format
    
    #dynamic params
    'h264bpvdec_dyn_0_decodeheader_msb'               => 0,
    'h264bpvdec_dyn_1_decodeheader_lsb'               => 0, # 0->decode entire frame including all the headers, 1->decode only one nal unit
    'h264bpvdec_dyn_2_displaywidth_msb'               => 0,
    'h264bpvdec_dyn_3_displaywidth_lsb'               => 0, # 0->use decoded image width as pitch.(any other value greater than decoded image width is used as pitch)   
    'h264bpvdec_dyn_4_frameskipmode_msb'              => 0,
    'h264bpvdec_dyn_5_frameskipmode_lsb'              => 0, # 0->do not skip current frame 2->skip non-referenced frame


        
    #h264bp encoder static params
        
    'h264bpvenc_st_00_encodingpreset_msb'                 =>    0,
    'h264bpvenc_st_01_encodingpreset_lsb'                 =>    3,
    'h264bpvenc_st_02_ratectrlpr_msb'                     =>    0,
    'h264bpvenc_st_03_ratectrlpr_lsb'                     =>    1,
    'h264bpvenc_st_04_maxheight_msb'                      =>    0,
    'h264bpvenc_st_05_maxheight_lsb'                      =>    288,
    'h264bpvenc_st_06_maxwidth_msb'                       =>    0,
    'h264bpvenc_st_07_maxwidth_lsb'                       =>    352,
    'h264bpvenc_st_08_maxframerate_msb'                   =>    0,
    'h264bpvenc_st_09_maxframerate_lsb'                   =>    30000,
    'h264bpvenc_st_10_maxbitrate_msb'                     =>     "0x003D",
    'h264bpvenc_st_11_maxbitrate_lsb'                     =>     "0x0900",
    'h264bpvenc_st_12_dataend_msb'                        =>     0,
    'h264bpvenc_st_13_dataend_lsb'                        =>     1,
    'h264bpvenc_st_14_maxintfrint_msb'                    =>     0,
    'h264bpvenc_st_15_maxintfrint_lsb'                    =>     0,
    'h264bpvenc_st_16_ipchrfmt_msb'                       =>     0,
    'h264bpvenc_st_17_ipchrfmt_lsb'                       =>     1,
    'h264bpvenc_st_18_ipcontype_msb'                      =>     0,
    'h264bpvenc_st_19_ipcontype_lsb'                      =>     0,
    'h264bpvenc_st_20_profileidc_msb'                     =>     0,
    'h264bpvenc_st_21_profileidc_lsb'                     =>     66,
    'h264bpvenc_st_22_levelidc_msb'                       =>     0,
    'h264bpvenc_st_23_levelidc_lsb'                       =>     30,
    'h264bpvenc_st_24_rcalgo_msb'                         =>     0,
    'h264bpvenc_st_25_rcalgo_lsb'                         =>     4,
    'h264bpvenc_st_26_srchrnge_msb'                       =>     0,
    'h264bpvenc_st_27_srchrnge_lsb'                       =>     16,
                                              
     #H264 encoder dynamic params             
    'h264bpvenc_dyn_000_inputht_msb'                      =>     0, 
    'h264bpvenc_dyn_001_inputht_lsb'                      =>     288, 
    'h264bpvenc_dyn_002_inputwdth_msb'                    =>     0, 
    'h264bpvenc_dyn_003_inputwdth_lsb'                    =>     352, 
    'h264bpvenc_dyn_004_reffrrate_msb'                    =>     0, 
    'h264bpvenc_dyn_005_reffrrate_lsb'                    =>     30000, 
    'h264bpvenc_dyn_006_tgtfrrate_msb'                    =>     0, 
    'h264bpvenc_dyn_007_tgtfrrate_lsb'                    =>     30000, 
    'h264bpvenc_dyn_008_tgtbitrate_msb'                   =>     "0x0005", 
    'h264bpvenc_dyn_009_tgtbitrate_lsb'                   =>     "0xDC00", 
    'h264bpvenc_dyn_010_intrafrint_msb'                   =>     0, 
    'h264bpvenc_dyn_011_intrafrint_lsb'                   =>     30, 
    'h264bpvenc_dyn_012_genhdr_msb'                       =>     0,  
    'h264bpvenc_dyn_013_genhdr_lsb'                       =>     0,  
    'h264bpvenc_dyn_014_capwidth_msb'                     =>     0,  
    'h264bpvenc_dyn_015_capwidth_lsb'                     =>     0,  
    'h264bpvenc_dyn_016_frcifr_msb'                       =>     0,  
    'h264bpvenc_dyn_017_frcifr_lsb'                       =>     0,   
    'h264bpvenc_dyn_018_qpintra_msb'                      =>     0,   
    'h264bpvenc_dyn_019_qpintra_lsb'                      =>     28, 
    'h264bpvenc_dyn_020_qpinter_msb'                      =>     0, 
    'h264bpvenc_dyn_021_qpinter_lsb'                      =>     28, 
    'h264bpvenc_dyn_022_qpmax_msb'                        =>     0, 
    'h264bpvenc_dyn_023_qpmax_lsb'                        =>     51, 
    'h264bpvenc_dyn_024_qpmin_msb'                        =>     0, 
    'h264bpvenc_dyn_025_qpmin_lsb'                        =>     0, 
    'h264bpvenc_dyn_026_lfdisidc_msb'                     =>     0, 
    'h264bpvenc_dyn_027_lfdisidc_lsb'                     =>     0, 
    'h264bpvenc_dyn_028_qtpeldis_msb'                     =>     0, 
    'h264bpvenc_dyn_029_qtpeldis_lsb'                     =>     0, 
    'h264bpvenc_dyn_030_airmbper_msb'                     =>     0, 
    'h264bpvenc_dyn_031_airmbper_lsb'                     =>     0, 
    'h264bpvenc_dyn_032_maxmbpersl_msb'                   =>     0, 
    'h264bpvenc_dyn_033_maxmbpersl_lsb'                   =>     0, 
    'h264bpvenc_dyn_034_maxbypersl_msb'                   =>     0, 
    'h264bpvenc_dyn_035_maxbypersl_lsb'                   =>     0, 
    'h264bpvenc_dyn_036_rerowstno_msb'                    =>     0,
    'h264bpvenc_dyn_037_rerowstno_lsb'                    =>     0,
    'h264bpvenc_dyn_038_slrerowno_msb'                    =>     0,
    'h264bpvenc_dyn_039_slrerowno_lsb'                    =>     0,
    'h264bpvenc_dyn_040_filoffa_msb'                      =>     0,
    'h264bpvenc_dyn_041_filoffa_lsb'                      =>     0, 
    'h264bpvenc_dyn_042_filoffb_msb'                      =>     0, 
    'h264bpvenc_dyn_043_filoffb_lsb'                      =>     0, 
    'h264bpvenc_dyn_044_lg2mxfnummin4_msb'                =>     0, 
    'h264bpvenc_dyn_045_lg2mxfnummin4_lsb'                =>     0, 
    'h264bpvenc_dyn_046_chrqpidxoff_msb'                  =>     0, 
    'h264bpvenc_dyn_047_chrqpidxoff_lsb'                  =>     0, 
    'h264bpvenc_dyn_048_intpreden_msb'                    =>     0, 
    'h264bpvenc_dyn_049_intpreden_lsb'                    =>     0, 
    'h264bpvenc_dyn_050_picoodrcntty_msb'                 =>     0, 
    'h264bpvenc_dyn_051_picoodrcntty_lsb'                 =>     2, 
    'h264bpvenc_dyn_052_maxmvpermb_msb'                   =>     0, 
    'h264bpvenc_dyn_053_maxmvpermb_lsb'                   =>     1, 
    'h264bpvenc_dyn_054_int4x4enidc_msb'                  =>     0, 
    'h264bpvenc_dyn_055_int4x4enidc_lsb'                  =>     0, 
    'h264bpvenc_dyn_056_mvdataen_msb'                     =>     0, 
    'h264bpvenc_dyn_057_mvdataen_lsb'                     =>     0, 
    'h264bpvenc_dyn_058_hiercoden_msb'                    =>     0, 
    'h264bpvenc_dyn_059_hiercoden_lsb'                    =>     0, 
    'h264bpvenc_dyn_060_strfmt_msb'                       =>     0, 
    'h264bpvenc_dyn_061_strfmt_lsb'                       =>     0, 
    'h264bpvenc_dyn_062_intrefmet_msb'                    =>     0, 
    'h264bpvenc_dyn_063_intrefmet_lsb'                    =>     0, 
    'h264bpvenc_dyn_064_cbfnptr_msb'                      =>     0, 
    'h264bpvenc_dyn_065_cbfnptr_lsb'                      =>     0, 
    'h264bpvenc_dyn_066_numsliceaso_msb'                  =>     0,
    'h264bpvenc_dyn_067_numsliceaso_lsb'                  =>     0,
    'h264bpvenc_dyn_068_asosliord1_msb'               =>     0,
    'h264bpvenc_dyn_069_asosliord1_lsb'               =>     0,
    'h264bpvenc_dyn_070_asosliord2_msb'               =>     0,
    'h264bpvenc_dyn_071_asosliord2_lsb'               =>     0,
    'h264bpvenc_dyn_072_asosliord3_msb'               =>     0,
    'h264bpvenc_dyn_073_asosliord3_lsb'               =>     0,
    'h264bpvenc_dyn_074_asosliord4_msb'               =>     0,
    'h264bpvenc_dyn_075_asosliord4_lsb'               =>     0,
    'h264bpvenc_dyn_076_asosliord5_msb'               =>     0,
    'h264bpvenc_dyn_077_asosliord5_lsb'               =>     0,
    'h264bpvenc_dyn_078_asosliord6_msb'               =>     0,
    'h264bpvenc_dyn_079_asosliord6_lsb'               =>     0,
    'h264bpvenc_dyn_080_asosliord7_msb'               =>     0,
    'h264bpvenc_dyn_081_asosliord7_lsb'               =>     0,
    'h264bpvenc_dyn_082_asosliord8_msb'               =>     0,
    'h264bpvenc_dyn_083_asosliord8_lsb'               =>     0,
    'h264bpvenc_dyn_084_numsligrps_msb'               =>     0,
    'h264bpvenc_dyn_085_numsligrps_lsb'               =>     0,
    'h264bpvenc_dyn_086_slgrpmapty_msb'               =>     0, 
    'h264bpvenc_dyn_087_slgrpmapty_lsb'               =>     0, 
    'h264bpvenc_dyn_088_grpchdirfl_msb'               =>     0,
    'h264bpvenc_dyn_089_grpchdirfl_lsb'               =>     0,
    'h264bpvenc_dyn_090_slgrpchrt_msb'                =>     0,
    'h264bpvenc_dyn_091_slgrpchrt_lsb'                =>     0,
    'h264bpvenc_dyn_092_slgrpchcy_msb'                =>     0,
    'h264bpvenc_dyn_093_slgrpchcy_lsb'                =>     0,
    'h264bpvenc_dyn_094_slgrppars1_msb'               =>     0,
    'h264bpvenc_dyn_095_slgrppars1_lsb'               =>     0,
    'h264bpvenc_dyn_096_slgrppars2_msb'               =>     0, 
    'h264bpvenc_dyn_097_slgrppars2_lsb'               =>     0, 
    'h264bpvenc_dyn_098_slgrppars3_msb'               =>     0, 
    'h264bpvenc_dyn_099_slgrppars3_lsb'               =>     0, 
    'h264bpvenc_dyn_100_slgrppars4_msb'               =>     0, 
    'h264bpvenc_dyn_101_slgrppars4_lsb'               =>     0, 
    'h264bpvenc_dyn_102_slgrppars5_msb'               =>     0, 
    'h264bpvenc_dyn_103_slgrppars5_lsb'               =>     0, 
    'h264bpvenc_dyn_104_slgrppars6_msb'               =>     0, 
    'h264bpvenc_dyn_105_slgrppars6_lsb'               =>     0, 
    'h264bpvenc_dyn_106_slgrppars7_msb'               =>     0,  
    'h264bpvenc_dyn_107_slgrppars7_lsb'               =>     0,  
    'h264bpvenc_dyn_108_slgrppars8_msb'               =>     0,  
    'h264bpvenc_dyn_109_slgrppars8_lsb'               =>     0, 
    'h264bpvenc_dyn_110_intraqpmod_msb'               =>     0, 
    'h264bpvenc_dyn_111_intraqpmod_lsb'               =>     0,  
    'h264bpvenc_dyn_112_maxdelay_msb'                 =>     0,
    'h264bpvenc_dyn_113_maxdelay_lsb'                 =>     15,
    'h264bpvenc_dyn_114_idrenable_msb'                =>     0, # New parameters added for 1.0.1_video_gdk
    'h264bpvenc_dyn_115_idrenable_lsb'                =>     1, # New parameters added for 1.0.1_video_gdk    
    }
    end 
 def get_h264bp_test_params(codec_type)
  if(codec_type == "enc")
  # These parameter values will overwrite the corresponding H264_default_params values later.These are a subset of H264_default_params
  @H264BP_test_params = {
    'h264bpv_enc_ovly_type'                        =>     0,
    'h264bpv_enc_max_payload_size'                 =>   1460,
  # H264 ENC static test params
    # 'h264bpvenc_st_encodingpreset'                 =>     3,
    # 'h264bpvenc_st_ratectrlpr'                     =>     1,
    # 'h264bpvenc_st_maxframerate'                   =>     30000,
    # 'h264bpvenc_st_maxintfrint'                    =>     0,
    # 'h264bpvenc_st_levelidc'                       =>     30,
    # 'h264bpvenc_st_rcalgo'                         =>     4,
    # 'h264bpvenc_st_srchrnge'                       =>     16,
    
    # # H264 ENC dynamic test params  
    # 'h264bpvenc_dyn_reffrrate'                     =>     30000, 
    # # 'h264bpvenc_dyn_tgtfrrate'                   =>     30000,
    # # 'h264bpvenc_dyn_tgtbitrate'                  =>     384000,     

    # 'h264bpvenc_dyn_intrafrint'                    =>     30,     
    # 'h264bpvenc_dyn_qtpeldis'                      =>     0, 
    # 'h264bpvenc_dyn_airmbper'                      =>     0, 
    # 'h264bpvenc_dyn_intpreden'                     =>     0, 
    # 'h264bpvenc_dyn_maxmvpermb'                    =>     1, 
    # 'h264bpvenc_dyn_int4x4enidc'                   =>     0, 
    # 'h264bpvenc_dyn_hiercoden'                     =>     0, 
    }
    elsif(codec_type == "dec")
      @H264BP_test_params = {
      # H264 DEC static test params    
    # 'h264bpvdec_st_maxframerate'                   => 30,
    # 'h264bpvdec_st_maxbitrate'                     => 10000000,
    # 'h264bpvdec_st_ipstrformat'                    => 1, # 0->bytestrfmt, 1->nal unit format
    }
    end
   end
   
   #put the rest of the params in the group_by_params category in to the matrix, except the group_by_param
 def get_h264bp_group_by_params(group_by_param) 
    @H264BP_group_by_params = { 
          'h264bpvenc_dyn_tgtbitrate'              =>       384000,
          'h264bpvenc_dyn_tgtfrrate'               =>       30000,
      }
    case group_by_param
        when "enc_framerate"
            @H264BP_group_by_params.delete('h264bpvenc_dyn_tgtfrrate')
        when "enc_bitrate"
            @H264BP_group_by_params.delete('h264bpvenc_dyn_tgtbitrate')
        else
            # do nothing
    end
    @H264BP_group_by_params
 end
 end