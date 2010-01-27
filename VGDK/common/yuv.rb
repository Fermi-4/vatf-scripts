 
 
module YUVParams
 def get_yuv_default_params
  @YUV_default_params = {
        #DEC params
        'yuvv_dec_coding_type'                        => 8,
        'yuvv_dec_payload_type'                       => 96,
        #ENCODER Params 
        
        'yuvv_enc_coding_type'                        =>  7,
        'yuvv_enc_payload_type'                       =>  96,
        'yuvv_enc_ovly_type'                          =>  0,

    }
 end 
  def get_yuv_test_params(codec_type)
  if(codec_type == "dec")
    @YUV_test_params = {
            'yuvv_enc_ovly_type'                          =>  0,
      }
  else
      @YUV_test_params = {
      }
  end
 end 
 def get_yuv_group_by_params(group_by_param)
   @YUV_group_by_params = {

    }

 end 
end