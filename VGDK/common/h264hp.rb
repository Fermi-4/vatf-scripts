 
 
module H264HPParams
 def get_h264hp_default_params
  # These parameters will be initialized on start up, the values of the H264_test_params will overwrite the corresponding
  # H264_default_params values later.
  @H264HP_default_params = {
    #Decoder params - h264hp
    'h264hpv_dec_coding_type'                        => 12,
    'h264hpv_dec_payload_type'                       => 96,
    'h264hpv_dec_img_width'                          => 1280,
    'h264hpv_dec_img_height'                         => 720,
    

    #IH264VDEC_Params static         
    'h264hpvdec_st_00_maxheight_msb'                  => 0, 
    'h264hpvdec_st_01_maxheight_lsb'                  => 1088, #max height = 576 pixels
    'h264hpvdec_st_02_maxwidth_msb'                   => 0,
    'h264hpvdec_st_03_maxwidth_lsb'                   => 1920, #max width = 720 pixels
    'h264hpvdec_st_04_maxframerate_msb'               => 0,
    'h264hpvdec_st_05_maxframerate_lsb'               => 30,
    'h264hpvdec_st_06_maxbitrate_msb'                 => "0x02FA",
    'h264hpvdec_st_07_maxbitrate_lsb'                 => "0xF080",
    'h264hpvdec_st_08_dataend_msb'                    => 0,
    'h264hpvdec_st_09_dataend_lsb'                    => 1, # 1->big endian (xdm_byte)
    'h264hpvdec_st_10_forcechrfmt_msb'                => 0,
    'h264hpvdec_st_11_forcechrfmt_lsb'                => 1, # 1->420p, 4->422i 
	'h264hpvdec_st_12_mcviddecparams_msb'			  => 0,
	'h264hpvdec_st_13_mcviddecparams_lsb'			  => 0,
	'h264hpvdec_st_14_displaydelay_msb'			      => 0,
	'h264hpvdec_st_15_displaydelay_lsb'			  	  => 0,	
    'h264hpvdec_st_16_ipstrformat_msb'                => 0,
    'h264hpvdec_st_17_ipstrformat_lsb'                => 0, # 0->bytestrfmt, 1->nal unit format
    
    #dynamic params
    'h264hpvdec_dyn_00_decodeheader_msb'               => 0,
    'h264hpvdec_dyn_01_decodeheader_lsb'               => 0, # 0->decode entire frame including all the headers, 1->decode only one nal unit
    'h264hpvdec_dyn_02_displaywidth_msb'               => 0,
    'h264hpvdec_dyn_03_displaywidth_lsb'               => 0, # 0->use decoded image width as pitch.(any other value greater than decoded image width is used as pitch)   
    'h264hpvdec_dyn_04_frameskipmode_msb'              => 0,
    'h264hpvdec_dyn_05_frameskipmode_lsb'              => 0, # 0->do not skip current frame 2->skip non-referenced frame
	'h264hpvdec_dyn_06_frorder_msb'				      => 0, 
	'h264hpvdec_dyn_07_frorder_lsb'				  	  => 0, 
	'h264hpvdec_dyn_08_newfrflag_msb'				  => 0,
	'h264hpvdec_dyn_09_newfrflag_lsb'				  => 0,
	'h264hpvdec_dyn_10_mbdataflag_msb'				  => 0,
	'h264hpvdec_dyn_11_mbdataflag_lsb'				  => 0,

    }
    end 
 def get_h264hp_test_params(codec_type)
  if(codec_type == "enc")
  
    elsif(codec_type == "dec")
      @H264HP_test_params = {
      # H264 DEC static test params    
    # 'h264hpvdec_st_maxframerate'                   => 30,
    # 'h264hpvdec_st_maxbitrate'                     => 10000000,
    # 'h264hpvdec_st_ipstrformat'                    => 1, # 0->bytestrfmt, 1->nal unit format
    }
    end
   end
   
   #put the rest of the params in the group_by_params category in to the matrix, except the group_by_param
 def get_h264hp_group_by_params(group_by_param) 
    @H264HP_group_by_params = { 
          # 'h264hpvenc_dyn_tgtbitrate'              =>       384000,
          # 'h264hpvenc_dyn_tgtfrrate'               =>       30000,
      }
    # case group_by_param
        # when "enc_framerate"
            # @H264BP_group_by_params.delete('h264hpvenc_dyn_tgtfrrate')
        # when "enc_bitrate"
            # @H264BP_group_by_params.delete('h264hpvenc_dyn_tgtbitrate')
        # else
            # # do nothing
    # end
    @H264HP_group_by_params
 end
 end