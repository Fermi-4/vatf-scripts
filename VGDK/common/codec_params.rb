
require File.dirname(__FILE__)+'/h264bp.rb'
require File.dirname(__FILE__)+'/h264mp.rb'
require File.dirname(__FILE__)+'/mpeg2.rb'
require File.dirname(__FILE__)+'/mpeg4.rb'
require File.dirname(__FILE__)+'/h263p.rb'
require File.dirname(__FILE__)+'/h264hp.rb'
require File.dirname(__FILE__)+'/yuv.rb'
require File.dirname(__FILE__)+'/graphicsovly.rb'
require File.dirname(__FILE__)+'/textovly.rb'

include H264BPParams
include H264MPParams
include MPEG4Params
include MPEG2Params
include H263PParams
include H264HPParams
include YUVParams
include G_OVLYParams
include T_OVLYParams


module CodecParams
 def initialize_codec_default_params(codec)
    case(codec)
    when "h264bp"
        get_h264bp_default_params()
    when "h264mp"
        get_h264mp_default_params()
    when "mpeg4"
        get_mpeg4_default_params()
    when "mpeg2"
        get_mpeg2_default_params()
    when "h263p"
        get_h263p_default_params()
    when "h264hp"
        get_h264hp_default_params()
    when "g_ovly"
        get_g_ovly_default_params()
    when "t_ovly"
        get_t_ovly_default_params()
    when /yuv/
        get_yuv_default_params()
    else
        raise "Error: not a recognized codec: #{codec.to_s}"
    end
    
end    
 def initialize_codec_test_params(codec,codec_type)
    case(codec.to_s)
    when "h264bp"
        get_h264bp_test_params(codec_type)
    when "h264mp"
        get_h264mp_test_params(codec_type)
    when "mpeg4"
        get_mpeg4_test_params(codec_type)
    when "mpeg2"
        get_mpeg2_test_params(codec_type)
    when "h263p"
        get_h263p_test_params(codec_type)
    when "h264hp"
        get_h264hp_test_params(codec_type)
    when "g_ovly"
        get_g_ovly_test_params(codec_type)
    when "t_ovly"
        get_t_ovly_test_params(codec_type)
    when /yuv/
        get_yuv_test_params(codec_type)
    else
        raise "Error: not a recognized codec: #{codec.to_s}"
    end
    
end 
 def initialize_codec_group_by_params(codec,group_by_param)
    case(codec.to_s)
    when "h264bp"
        get_h264bp_group_by_params(group_by_param)
    when "h264mp"
        get_h264mp_group_by_params(group_by_param)
    when "mpeg4"
        get_mpeg4_group_by_params(group_by_param)
    when "mpeg2"
        get_mpeg2_group_by_params(group_by_param)
    when "h263p"
        get_h263p_group_by_params(group_by_param)
    when "h264hp"
        get_h264hp_group_by_params(group_by_param)
    when "g_ovly"
        get_g_ovly_group_by_params(group_by_param)
    when "t_ovly"
        get_t_ovly_group_by_params(group_by_param)
    when /yuv/
        get_yuv_group_by_params(group_by_param)
    else
        raise "Error: not a recognized codec: #{codec.to_s}"
    end
 
end
end 