 # DECODER only, ENCODER not supported
 
module H264MPParams
 def get_h264mp_default_params
  # These parameters will be initialized on start up, the values of the H264_test_params will overwrite the corresponding
  # H264_default_params values later.
  @H264MP_default_params = {
    #Decoder params - h264mp
    'h264mpv_dec_coding_type'                        => 10,
    'h264mpv_dec_payload_type'                       => 96,
    'h264mpv_dec_img_width'                          => 352,
    'h264mpv_dec_img_height'                         => 288,
    
    #IH264VDEC_Params static         
    'h264mpvdec_st_00_maxheight_msb'                  => 0, 
    'h264mpvdec_st_01_maxheight_lsb'                  => 352, #max height = 576 pixels
    'h264mpvdec_st_02_maxwidth_msb'                   => 0,
    'h264mpvdec_st_03_maxwidth_lsb'                   => 288, #max width = 720 pixels
    'h264mpvdec_st_04_maxframerate_msb'               => 0,
    'h264mpvdec_st_05_maxframerate_lsb'               => 30,
    'h264mpvdec_st_06_maxbitrate_msb'                 => "0x0098",
    'h264mpvdec_st_07_maxbitrate_lsb'                 => "0x9680",
    'h264mpvdec_st_08_dataend_msb'                    => 0,
    'h264mpvdec_st_09_dataend_lsb'                    => 1, # 1->big endian (xdm_byte)
    'h264mpvdec_st_10_forcechrfmt_msb'                => 0,
    'h264mpvdec_st_11_forcechrfmt_lsb'                => 1, # 1->420p, 4->422i 

    
    #dynamic params
    'h264mpvdec_dyn_0_decodeheader_msb'               => 0,
    'h264mpvdec_dyn_1_decodeheader_lsb'               => 0, # 0->decode entire frame including all the headers, 1->decode only one nal unit
    'h264mpvdec_dyn_2_displaywidth_msb'               => 0,
    'h264mpvdec_dyn_3_displaywidth_lsb'               => 0, # 0->use decoded image width as pitch.(any other value greater than decoded image width is used as pitch)   
    'h264mpvdec_dyn_4_frameskipmode_msb'              => 0,
    'h264mpvdec_dyn_5_frameskipmode_lsb'              => 0, # 0->do not skip current frame 2->skip non-referenced frame

    }
    end 
 def get_h264mp_test_params(codec_type)
  # These parameter values will overwrite the corresponding H264_default_params values later.These are a subset of H264_default_params
    if(codec_type == "dec")
      @H264MP_test_params = {
      # H264 DEC static test params    
      'h264mpvdec_st_maxframerate'                   => 30,
      'h264mpvdec_st_maxbitrate'                     => 10000000,
      }
    elsif(codec_type == "enc")
      raise "H264MP encoder is not supported"
    end
 end
   
   #put the rest of the params in the group_by_params category in to the matrix, except the group_by_param
 def get_h264mp_group_by_params(group_by_param) 
        @H264MP_group_by_params = { 

      }

 end
 end