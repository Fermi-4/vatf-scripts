module MPEG4Params
 def get_mpeg4_default_params
    # These parameters will be initialized on start up, the values of the H264_test_params will overwrite the corresponding
    # H264_default_params values later.
  @MPEG4_default_params = {
        'mpeg4v_dec_coding_type'                            => 4,
        'mpeg4v_dec_payload_type'                           => 96,
        'mpeg4v_dec_img_width'                              => 176,
        'mpeg4v_dec_img_height'                             => 144,
        
        #ENCODER Params - mpeg4
        
        'mpeg4v_enc_coding_type'                            => 3,
        'mpeg4v_enc_payload_type'                           => 96,
        'mpeg4v_enc_img_width'                              => 176,
        'mpeg4v_enc_img_height'                             => 144,
        'mpeg4v_enc_ovly_type'                              =>  0,
        'mpeg4v_enc_max_payload_size'                       =>  1460,
        
        'mpeg4venc_dyn_00_inputht_msb'                       =>        0,
        'mpeg4venc_dyn_01_inputht_lsb'                       =>        144,
        'mpeg4venc_dyn_02_inputwdth_msb'                     =>        0,
        'mpeg4venc_dyn_03_inputwdth_lsb'                     =>        176,
        'mpeg4venc_dyn_04_reffrrate_msb'                     =>        0,
        'mpeg4venc_dyn_05_reffrrate_lsb'                     =>        30000,
        'mpeg4venc_dyn_06_tgtfrrate_msb'                     =>        0,
        'mpeg4venc_dyn_07_tgtfrrate_lsb'                     =>        30000,
        'mpeg4venc_dyn_08_tgtbitrate_msb'                    =>        "0x0003",
        'mpeg4venc_dyn_09_tgtbitrate_lsb'                    =>        "0xE800",
        'mpeg4venc_dyn_10_intrafrint_msb'                    =>        0,
        'mpeg4venc_dyn_11_intrafrint_lsb'                    =>        30,
        'mpeg4venc_dyn_12_genhdr_msb'                        =>        0,
        'mpeg4venc_dyn_13_genhdr_lsb'                        =>        0,
        'mpeg4venc_dyn_14_capwidth_msb'                      =>        0,
        'mpeg4venc_dyn_15_capwidth_lsb'                      =>        0,
        'mpeg4venc_dyn_16_forceframe_msb'                    =>        "0xffff",
        'mpeg4venc_dyn_17_forceframe_lsb'                    =>        "0xffff",
        'mpeg4venc_dyn_18_intfrint_msb'                      =>        0,
        'mpeg4venc_dyn_19_intfrint_lsb'                      =>        1,
        'mpeg4venc_dyn_20_mbdataflag_msb'                    =>        0,
        'mpeg4venc_dyn_21_mbdataflag_lsb'                    =>        0,
        'mpeg4venc_dyn_22_resyncinterval_msb'                =>        0,
        'mpeg4venc_dyn_23_resyncinterval_lsb'                =>        2000,
        'mpeg4venc_dyn_24_hecinterval_msb'                   =>        0,
        'mpeg4venc_dyn_25_hecinterval_lsb'                   =>        0,
        'mpeg4venc_dyn_26_airrate_msb'                       =>        0,
        'mpeg4venc_dyn_27_airrate_lsb'                       =>        0,
        'mpeg4venc_dyn_28_mirrate_msb'                       =>        0,
        'mpeg4venc_dyn_29_mirrate_lsb'                       =>        0,
        'mpeg4venc_dyn_30_qpintra_msb'                       =>        0,
        'mpeg4venc_dyn_31_qpintra_lsb'                       =>        8,
        'mpeg4venc_dyn_32_qpinter_msb'                       =>        0,
        'mpeg4venc_dyn_33_qpinter_lsb'                       =>        8,
        'mpeg4venc_dyn_34_fcode_msb'                         =>        0,
        'mpeg4venc_dyn_35_fcode_lsb'                         =>        5,
        'mpeg4venc_dyn_36_usehpi_msb'                        =>        0,
        'mpeg4venc_dyn_37_usehpi_lsb'                        =>        1,
        'mpeg4venc_dyn_38_useacpred_msb'                     =>        0,
        'mpeg4venc_dyn_39_useacpred_lsb'                     =>        0,
        'mpeg4venc_dyn_40_lastframe_msb'                     =>        0,
        'mpeg4venc_dyn_41_lastframe_lsb'                     =>        0,
        'mpeg4venc_dyn_42_mvdataen_msb'                      =>        0,
        'mpeg4venc_dyn_43_mvdataen_lsb'                      =>        0,
        'mpeg4venc_dyn_44_useumv_msb'                        =>        0,
        'mpeg4venc_dyn_45_useumv_lsb'                        =>        1,
        'mpeg4venc_dyn_46_qpmax_msb'                         =>        0,
        'mpeg4venc_dyn_47_qpmax_lsb'                         =>        31,
        'mpeg4venc_dyn_48_qpmin_msb'                         =>        0,
        'mpeg4venc_dyn_49_qpmin_lsb'                         =>        2,
        'mpeg4venc_dyn_50_mbindexenable_msb'                 =>         0, 
        'mpeg4venc_dyn_51_mbindexenable_lsb'                 =>         0,  
        'mpeg4venc_dyn_52_gobindexenable_msb'                =>         0,
        'mpeg4venc_dyn_53_gobindexenable_lsb'                =>         0,
        'mpeg4venc_dyn_54_gobheaderenable_msb'               =>         0,
        'mpeg4venc_dyn_54_gobheaderenable_lsb'               =>         0,
                                                                     
        'mpeg4venc_st_00_encodingpreset_msb'                 =>        0,
        'mpeg4venc_st_01_encodingpreset_lsb'                 =>        2,
        'mpeg4venc_st_02_ratectrlpr_msb'                     =>        0,
        'mpeg4venc_st_03_ratectrlpr_lsb'                     =>        1,
        'mpeg4venc_st_04_maxheight_msb'                      =>        0,
        'mpeg4venc_st_05_maxheight_lsb'                      =>        144,
        'mpeg4venc_st_06_maxwidth_msb'                       =>        0,
        'mpeg4venc_st_07_maxwidth_lsb'                       =>        176,
        'mpeg4venc_st_08_maxframerate_msb'                   =>        0,
        'mpeg4venc_st_09_maxframerate_lsb'                   =>        30000,
        'mpeg4venc_st_10_maxbitrate_msb'                     =>        "0x003D",
        'mpeg4venc_st_11_maxbitrate_lsb'                     =>        "0x0900",
        'mpeg4venc_st_12_dataend_msb'                        =>        0,
        'mpeg4venc_st_13_dataend_lsb'                        =>        1,
        'mpeg4venc_st_14_maxintfrint_msb'                    =>        0,
        'mpeg4venc_st_15_maxintfrint_lsb'                    =>        0,
        'mpeg4venc_st_16_ipchrfmt_msb'                       =>        0,
        'mpeg4venc_st_17_ipchrfmt_lsb'                       =>        1,
        'mpeg4venc_st_18_ipcontype_msb'                      =>        0,
        'mpeg4venc_st_19_ipcontype_lsb'                      =>        0,
        'mpeg4venc_st_20_reconChromaFormat_msb'              =>        "0xFFFF",
        'mpeg4venc_st_21_reconChromaFormat_lsb'              =>        "0xFFFF",      
        'mpeg4venc_st_22_encodemode_msb'                     =>        0,
        'mpeg4venc_st_23_encodemode_lsb'                     =>        1,
        'mpeg4venc_st_24_levelidc_msb'                       =>        0,
        'mpeg4venc_st_25_levelidc_lsb'                       =>        5,
        'mpeg4venc_st_26_numframes_msb'                      =>        0,
        'mpeg4venc_st_27_numframes_lsb'                      =>        240,
        'mpeg4venc_st_28_rcalgo_msb'                         =>        0,
        'mpeg4venc_st_29_rcalgo_lsb'                         =>        8,
        'mpeg4venc_st_30_vbvbuffersize_msb'                  =>        0,
        'mpeg4venc_st_31_vbvbuffersize_lsb'                  =>        112,
        'mpeg4venc_st_32_usevos_msb'                         =>        0,
        'mpeg4venc_st_33_usevos_lsb'                         =>        1,
        'mpeg4venc_st_34_usegov_msb'                         =>        0,
        'mpeg4venc_st_35_usegov_lsb'                         =>        0,
        'mpeg4venc_st_36_usedatapartition_msb'               =>        0,
        'mpeg4venc_st_37_usedatapartition_lsb'               =>        0,
        'mpeg4venc_st_38_uservlc_msb'                        =>        0,
        'mpeg4venc_st_39_uservlc_lsb'                        =>        0,
        'mpeg4venc_st_40_maxdelay_msb'                       =>        0,
        'mpeg4venc_st_41_maxdelay_lsb'                       =>        1000,
        'mpeg4venc_st_42_enablescd_msb'                      =>        0,     
        'mpeg4venc_st_43_enablescd_lsb'                      =>        0,
                                                                     
        #mpeg4vv decoder dynamic parameters			     
                                             
        'mpeg4vdec_dyn_00_decodeheader_msb'                  =>   0,  
        'mpeg4vdec_dyn_01_decodeheader_lsb'                  =>   0,
        'mpeg4vdec_dyn_02_displaywidth_msb'                  =>   0,
        'mpeg4vdec_dyn_03_displaywidth_lsb'                  =>   0,
        'mpeg4vdec_dyn_04_frameskipmode_msb'                 =>   0,
        'mpeg4vdec_dyn_05_frameskipmode_lsb'                 =>   0,
        'mpeg4vdec_dyn_06_frameorder_msb'                    =>   0,
        'mpeg4vdec_dyn_07_frameorder_lsb'                    =>   0,
        'mpeg4vdec_dyn_08_newframeflag_msb'                  =>   0,
        'mpeg4vdec_dyn_09_newframeflag_lsb'                  =>   0,
        'mpeg4vdec_dyn_10_mbdataflag_msb'                    =>   0,
        'mpeg4vdec_dyn_11_mbdataflag_lsb'                    =>   0,
        'mpeg4vdec_dyn_12_postdeblock_msb'                   =>   0,
        'mpeg4vdec_dyn_13_postdeblock_lsb'                   =>   0,
        'mpeg4vdec_dyn_14_postdering_msb'                    =>   0,
        'mpeg4vdec_dyn_15_postdering_lsb'                    =>   0,
        'mpeg4vdec_dyn_16_errorConceal_msb'                  =>   0,
        'mpeg4vdec_dyn_17_errorConceal_lsb'                  =>   0,
        'mpeg4vdec_dyn_18_frlvlbysw_msb'                     =>   0,
        'mpeg4vdec_dyn_19_frlvlbysw_lsb'                     =>   1,
                                           
        #mpeg4vv decoder static parameters      			   
        'mpeg4vdec_st_00_maxheight_msb'                      =>    0,
        'mpeg4vdec_st_01_maxheight_lsb'                      =>    144,
        'mpeg4vdec_st_02_maxwidth_msb'                       =>    0,
        'mpeg4vdec_st_03_maxwidth_lsb'                       =>    176,
        'mpeg4vdec_st_04_maxframerate_msb'                   =>    0,
        'mpeg4vdec_st_05_maxframerate_lsb'                   =>    30,
        'mpeg4vdec_st_06_maxbitrate_msb'                     =>    "0x003D",
        'mpeg4vdec_st_07_maxbitrate_lsb'                     =>    "0x0900",
        'mpeg4vdec_st_08_dataend_msb'                        =>    0,
        'mpeg4vdec_st_09_dataend_lsb'                        =>    1,
        'mpeg4vdec_st_10_forcechrfmt_msb'                    =>    0,
        'mpeg4vdec_st_11_forcechrfmt_lsb'                    =>    1,
                                                        
         }
end
 def get_mpeg4_test_params(codec_type)
  # These parameter values will overwrite the corresponding MPEG4_default_params values later.These are a subset of MPEG4_default_params
    if(codec_type == "enc")
      @MPEG4_test_params = {
  
        'mpeg4v_enc_ovly_type'                       =>         0,
        'mpeg4v_enc_max_payload_size'                =>         1460,
        #ENC static
        # 'mpeg4venc_st_encodingpreset'                 =>        2,
        # 'mpeg4venc_st_ratectrlpr'                     =>        1,
        # 'mpeg4venc_st_maxframerate'                   =>        30000,
        # 'mpeg4venc_st_maxintfrint'                    =>        0,       
        # 'mpeg4venc_st_levelidc'                       =>        5,      
        # 'mpeg4venc_st_rcalgo'                         =>        8,
        # 'mpeg4venc_st_maxdelay'                       =>        1000,
        # 'mpeg4venc_st_maxframerate'                   =>        30000,        
        # #ENC dynamic
        # 'mpeg4venc_dyn_reffrrate'                     =>        30000,
        # 'mpeg4venc_dyn_intrafrint'                    =>        30,
        }
    elsif(codec_type == "dec")
          @MPEG4_test_params = {
        #DEC static
        # 'mpeg4vdec_st_maxframerate'                         =>    30,
        # 'mpeg4vdec_st_maxbitrate'                           =>    10000000,
        }
    end
 end
  def get_mpeg4_group_by_params(group_by_param) 
    @MPEG4_group_by_params = { 
          'mpeg4venc_dyn_tgtbitrate'      =>       256000,
          'mpeg4venc_dyn_tgtfrrate'       =>       30000,
      }
    case group_by_param
        when "enc_framerate"
            @MPEG4_group_by_params.delete('mpeg4venc_dyn_tgtfrrate')
        when "enc_bitrate"
            @MPEG4_group_by_params.delete('mpeg4venc_dyn_tgtbitrate')
        else
            # do nothing
    end
    @MPEG4_group_by_params
 end
end         
