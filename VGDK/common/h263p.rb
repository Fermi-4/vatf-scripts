module H263PParams
 attr :H263P_params
 def get_h263p_default_params
  @H263P_params = {
          #DECODER Params - h263p        
        'h263pv_dec_coding_type'                        =>  6,
        'h263pv_dec_payload_type'                       =>  96,
        'h263pv_dec_img_width'                          =>  176,
        'h263pv_dec_img_height'                         =>  144,
        
        #ENCODER Params - h263p
        
        'h263pv_enc_coding_type'                        =>  5,
        'h263pv_enc_payload_type'                       =>  96,
        'h263pv_enc_img_width'                          =>  176,
        'h263pv_enc_img_height'                         =>  144,
        'h263pv_enc_ovly_type'                          =>  0,
        'h263pv_enc_max_payload_size'                   =>  1460,
        
        'h263pvenc_dyn_00_inputht_msb'                       =>      0,   
        'h263pvenc_dyn_01_inputht_lsb'                       =>      144,   
        'h263pvenc_dyn_02_inputwdth_msb'                     =>      0,   
        'h263pvenc_dyn_03_inputwdth_lsb'                     =>      176,   
        'h263pvenc_dyn_04_reffrrate_msb'                     =>      0,   
        'h263pvenc_dyn_05_reffrrate_lsb'                     =>      30000,   
        'h263pvenc_dyn_06_tgtfrrate_msb'                     =>      0,   
        'h263pvenc_dyn_07_tgtfrrate_lsb'                     =>      30000,   
        'h263pvenc_dyn_08_tgtbitrate_msb'                    =>      "0x0003",   
        'h263pvenc_dyn_09_tgtbitrate_lsb'                    =>      "0xE800",   
        'h263pvenc_dyn_10_intrafrint_msb'                    =>      0,   
        'h263pvenc_dyn_11_intrafrint_lsb'                    =>      30,   
        'h263pvenc_dyn_12_genhdr_msb'                        =>      0,   
        'h263pvenc_dyn_13_genhdr_lsb'                        =>      0,   
        'h263pvenc_dyn_14_capwidth_msb'                      =>      0,   
        'h263pvenc_dyn_15_capwidth_lsb'                      =>      0,   
        'h263pvenc_dyn_16_forceframe_msb'                    =>      "0xFFFF",   
        'h263pvenc_dyn_17_forceframe_lsb'                    =>      "0xFFFF",   
        'h263pvenc_dyn_18_intfrint_msb'                      =>      0,
        'h263pvenc_dyn_19_intfrint_lsb'                      =>      1,
        'h263pvenc_dyn_20_mbdataflag_msb'                    =>      0,
        'h263pvenc_dyn_21_mbdataflag_lsb'                    =>      0,
        'h263pvenc_dyn_22_resyncinterval_msb'                =>      0,   
        'h263pvenc_dyn_23_resyncinterval_lsb'                =>      2000,   
        'h263pvenc_dyn_24_hecinterval_msb'                   =>      0,   
        'h263pvenc_dyn_25_hecinterval_lsb'                   =>      0,   
        'h263pvenc_dyn_26_airrate_msb'                       =>      0,    
        'h263pvenc_dyn_27_airrate_lsb'                       =>      0,    
        'h263pvenc_dyn_28_mirrate_msb'                       =>      0,    
        'h263pvenc_dyn_29_mirrate_lsb'                       =>      0,    
        'h263pvenc_dyn_30_qpintra_msb'                       =>      0,    
        'h263pvenc_dyn_31_qpintra_lsb'                       =>      8,    
        'h263pvenc_dyn_32_qpinter_msb'                       =>      0,    
        'h263pvenc_dyn_33_qpinter_lsb'                       =>      8,    
        'h263pvenc_dyn_34_fcode_msb'                         =>      0,    
        'h263pvenc_dyn_35_fcode_lsb'                         =>      1,    
        'h263pvenc_dyn_36_usehpi_msb'                        =>      0,    
        'h263pvenc_dyn_37_usehpi_lsb'                        =>      1,    
        'h263pvenc_dyn_38_useacpred_msb'                     =>      0,    
        'h263pvenc_dyn_39_useacpred_lsb'                     =>      0,    
        'h263pvenc_dyn_40_lastframe_msb'                     =>      0,    
        'h263pvenc_dyn_41_lastframe_lsb'                     =>      0,    
        'h263pvenc_dyn_42_mvdataen_msb'                      =>      0,    
        'h263pvenc_dyn_43_mvdataen_lsb'                      =>      0,    
        'h263pvenc_dyn_44_useumv_msb'                        =>      0,    
        'h263pvenc_dyn_45_useumv_lsb'                        =>      0,   
        'h263pvenc_dyn_46_qpmax_msb'                         =>      0,
        'h263pvenc_dyn_47_qpmax_lsb'                         =>      31,
        'h263pvenc_dyn_48_qpmin_msb'                         =>      0,
        'h263pvenc_dyn_49_qpmin_lsb'                         =>      2,
        'h263pvenc_dyn_50_mbindexenable_msb'                 =>      0, 
        'h263pvenc_dyn_51_mbindexenable_lsb'                 =>      1,  
        'h263pvenc_dyn_52_gobindexenable_msb'                =>      0,
        'h263pvenc_dyn_53_gobindexenable_lsb'                =>      1,
        'h263pvenc_dyn_54_gobheaderenable_msb'               =>      0,
        'h263pvenc_dyn_55_gobheaderenable_lsb'               =>      1,        

        
        'h263pvenc_st_00_encodingpreset_msb'                 =>       0,
        'h263pvenc_st_01_encodingpreset_lsb'                 =>       1,
        'h263pvenc_st_02_ratectrlpr_msb'                     =>       0,
        'h263pvenc_st_03_ratectrlpr_lsb'                     =>       1,
        'h263pvenc_st_04_maxheight_msb'                      =>       0,
        'h263pvenc_st_05_maxheight_lsb'                      =>       144,
        'h263pvenc_st_06_maxwidth_msb'                       =>       0,
        'h263pvenc_st_07_maxwidth_lsb'                       =>       176,
        'h263pvenc_st_08_maxframerate_msb'                   =>       0,
        'h263pvenc_st_09_maxframerate_lsb'                   =>       30000,
        'h263pvenc_st_10_maxbitrate_msb'                     =>       "0x0003",
        'h263pvenc_st_11_maxbitrate_lsb'                     =>       "0xE800",
        'h263pvenc_st_12_dataend_msb'                        =>       0,
        'h263pvenc_st_13_dataend_lsb'                        =>       1,
        'h263pvenc_st_14_maxintfrint_msb'                    =>       0,
        'h263pvenc_st_15_maxintfrint_lsb'                    =>       0,
        'h263pvenc_st_16_ipchrfmt_msb'                       =>       0,
        'h263pvenc_st_17_ipchrfmt_lsb'                       =>       1,
        'h263pvenc_st_18_ipcontype_msb'                      =>       0,
        'h263pvenc_st_19_ipcontype_lsb'                      =>       0,
        'h263pvenc_st_20_reconchromaformat_msb'              =>       "0xffff",
        'h263pvenc_st_21_reconchromaformat_lsb'              =>       "0xffff",
        'h263pvenc_st_22_encodemode_msb'                     =>       0,
        'h263pvenc_st_23_encodemode_lsb'                     =>       0,
        'h263pvenc_st_24_levelidc_msb'                       =>       0,
        'h263pvenc_st_25_levelidc_lsb'                       =>       5,
        'h263pvenc_st_26_numframes_msb'                      =>       0,
        'h263pvenc_st_27_numframes_lsb'                      =>       240,
        'h263pvenc_st_28_rcalgo_msb'                         =>       0,
        'h263pvenc_st_29_rcalgo_lsb'                         =>       4,
        'h263pvenc_st_30_vbvbuffersize_msb'                  =>       0,
        'h263pvenc_st_31_vbvbuffersize_lsb'                  =>       112,
        'h263pvenc_st_32_usevos_msb'                         =>       0,
        'h263pvenc_st_33_usevos_lsb'                         =>       0,
        'h263pvenc_st_34_usegov_msb'                         =>       0,
        'h263pvenc_st_35_usegov_lsb'                         =>       0,
        'h263pvenc_st_36_usedatapartition_msb'               =>       0,
        'h263pvenc_st_37_usedatapartition_lsb'               =>       0,
        'h263pvenc_st_38_uservlc_msb'                        =>       0,
        'h263pvenc_st_39_uservlc_lsb'                        =>       0,
        'h263pvenc_st_40_maxdelay_msb'                       =>       0,
        'h263pvenc_st_41_maxdelay_lsb'                       =>       1000,
        'h263pvenc_st_42_enablescd_msb'                      =>       0,
        'h263pvenc_st_43_enablescd_lsb'                      =>       0,
                                                                     
        #h263pvv decoder dynamic parameters     
                                             
        'h263pvdec_dyn_00_decodeheader_msb'                  =>       0,
        'h263pvdec_dyn_01_decodeheader_lsb'                  =>       0,
        'h263pvdec_dyn_02_displaywidth_msb'                  =>       0,
        'h263pvdec_dyn_03_displaywidth_lsb'                  =>       0,
        'h263pvdec_dyn_04_frameskipmode_msb'                 =>       0,
        'h263pvdec_dyn_05_frameskipmode_lsb'                 =>       0,
        'h263pvdec_dyn_06_frameorder_msb'                    =>       0,
        'h263pvdec_dyn_07_frameorder_lsb'                    =>       0, 
        'h263pvdec_dyn_08_newframeflag_msb'                  =>       0,
        'h263pvdec_dyn_09_newframeflag_lsb'                  =>       0,
        'h263pvdec_dyn_10_mbdataflag_msb'                    =>       0,
        'h263pvdec_dyn_11_mbdataflag_lsb'                    =>       0,
        'h263pvdec_dyn_12_postdeblock_msb'                   =>       0,
        'h263pvdec_dyn_13_postdeblock_lsb'                   =>       0,
        'h263pvdec_dyn_14_postdering_msb'                    =>       0,
        'h263pvdec_dyn_15_postdering_lsb'                    =>       0,
        'h263pvdec_dyn_16_errorconceal_msb'                  =>       0,                 
        'h263pvdec_dyn_17_errorconceal_lsb'                  =>       0,
        'h263pvdec_dyn_18_frlvlbysw_msb'                     =>       0,
        'h263pvdec_dyn_19_frlvlbysw_lsb'                     =>       1,     

          
        #h263pvv decoder static parameters    
        'h263pvdec_st_00_maxheight_msb'                      =>        0,
        'h263pvdec_st_01_maxheight_lsb'                      =>        144,
        'h263pvdec_st_02_maxwidth_msb'                       =>        0,
        'h263pvdec_st_03_maxwidth_lsb'                       =>        176,
        'h263pvdec_st_04_maxframerate_msb'                   =>        0,
        'h263pvdec_st_05_maxframerate_lsb'                   =>        30,
        'h263pvdec_st_06_maxbitrate_msb'                     =>        "0x0098",
        'h263pvdec_st_07_maxbitrate_lsb'                     =>        "0x9680",
        'h263pvdec_st_08_dataend_msb'                        =>        0,
        'h263pvdec_st_09_dataend_lsb'                        =>        1,
        'h263pvdec_st_10_forcechrfmt_msb'                    =>        0,
        'h263pvdec_st_11_forcechrfmt_lsb'                    =>        1,
                                                               
         }    
end
def get_h263p_test_params(codec_type)
  # These parameter values will overwrite the corresponding H263P_default_params values later.These are a subset of H263P_default_params
  if(codec_type == "enc")
    @H263P_test_params = {
        'h263pv_enc_ovly_type'                          =>  0,
        'h263pv_enc_max_payload_size'                   =>  1460,
        #ENC static
        'h263pvenc_st_encodingpreset'                 =>        1,
        'h263pvenc_st_ratectrlpr'                     =>        5,
        'h263pvenc_st_maxframerate'                   =>        30000,
        'h263pvenc_st_maxintfrint'                    =>        0,       
        'h263pvenc_st_levelidc'                       =>        5,      
        'h263pvenc_st_rcalgo'                         =>        8,
        'h263pvenc_st_maxdelay'                       =>        1000,
        
        #ENC dynamic
        'h263pvenc_dyn_reffrrate'                       =>        30000,       
        'h263pvenc_dyn_intrafrint'                      =>        30,
        }
        elsif(codec_type == "dec")
          @H263P_test_params = {
        #DEC static
        'h263pvdec_st_maxframerate'                   =>    30,
        'h263pvdec_st_maxbitrate'                     =>    10000000,
        }
        end
 end
  def get_h263p_group_by_params(group_by_param) 
    @H263P_group_by_params = { 
          'h263pvenc_dyn_tgtbitrate'      =>       256000,
          'h263pvenc_dyn_tgtfrrate'       =>       30000,
      }
    case group_by_param
        when "enc_framerate"
            @H263P_group_by_params.delete('h263pvenc_dyn_tgtfrrate')
        when "enc_bitrate"
            @H263P_group_by_params.delete('h263pvenc_dyn_tgtbitrate')
        else
            # do nothing
    end
    @H263P_group_by_params
 end
end         
