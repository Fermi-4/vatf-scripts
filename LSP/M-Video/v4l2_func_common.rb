# -*- coding: ISO-8859-1 -*-
module V4l2_sd_common
  def get_input(input)
      if input == '0'
          result = "Composite"
      elsif input == '1'
          result = "S-Video"
      elsif input == '2'
          result = "Component"
      end
      result
  end
  def get_output(output)
      if output == '0'
          result = "Composite"
      elsif output == '1'
          result = "S-Video"
      elsif output == '2'
          result = "Component"
      end
      result
  end
  def get_in_fmt(in_fmt)
      if in_fmt == '0'
          result = "NTSC"
      elsif in_fmt == '1'
          result = "PAL"
      elsif in_fmt == '2'
          result = "480P"
      elsif in_fmt == '3'
          result = "576P"
      end
      result
  end
  def get_out_fmt(out_fmt)
      if out_fmt == '0'
          result = "NTSC"
      elsif out_fmt == '1'
          result = "PAL"
      elsif out_fmt == '2'
          result = "480P"
      elsif out_fmt == '3'
          result = "576P"
      end
      result
  end
  def get_vid_plane(vid_plane)
      if vid_plane == '0'
          result = "Video0"
      elsif vid_plane == '1'
          result = "Video1"
      elsif vid_plane == '2'
          result = "Video0"
      elsif vid_plane == '3'
          result = "Video1"
      elsif vid_plane == '4'
          result = "Video0" 
      elsif vid_plane == '5'
          result = "Video1"               
      end
      result
  end
  def get_osd(vid_plane)
      if vid_plane == '0'
          result = "without"
      elsif vid_plane == '1'
          result = "without"
      elsif vid_plane == '2'
          result = "with"
      elsif vid_plane == '3'
          result = "with"
      elsif vid_plane == '4'
          result = "with" 
      elsif vid_plane == '5'
          result = "with"               
      end
      result
  end
  def get_blend(vid_plane)
      if vid_plane == '0'
          result = "no blending"
      elsif vid_plane == '1'
          result = "no blending"
      elsif vid_plane == '2'
          result = "no blending"
      elsif vid_plane == '3'
          result = "no blending"
      elsif vid_plane == '4'
          result = "blending" 
      elsif vid_plane == '5'
          result = "blending"               
      end
      result
  end
end
module V4l2_hd_common
   def get_in_fmt(in_fmt)
      if in_fmt == '5'
          result = "720P"
      elsif in_fmt == '6'
          result = "1080I"
      end
      result
  end
end

module V4l2_rszprev_common
   def get_rsz_mode_name(rsz_mode)
      if rsz_mode == 'otf'
          result = "On The Fly"
      elsif rsz_mode == 'ss'
          result = "Single Shot"
      end
      result
  end
  def get_cmd_name(rsz_mode)
      if rsz_mode == 'otf'
          result = "otf_yuv"
      elsif rsz_mode == 'ss'
          result = "ss_yuv"
      end
      result
  end
  def get_input(input)
      if input == 'NTSC'
          result = "0"
      elsif input == '720P'
          result = "2"
      elsif input == '1080I'
          result = "2"	
      end
      result
  end
  def get_output(output)
      if output == 'NTSC'
          result = "0"
      elsif output == '720P'
          result = "2"
      elsif output == '1080I'
          result = "3"	
      end
      result
  end
  def get_pix_fmt(ipipe_fmt)
      if ipipe_fmt == 'UYVY'
          result = "0"
      elsif ipipe_fmt == 'SEMIPLANAR'
          result = "1"
      end
      result
  end
end
module V4l2_ccdc_common
  def get_output(output)
      if output == '0'
          result = "Composite"
      elsif output == '1'
          result = "S-Video"
      elsif output == '2'
          result = "Component"
      end
      result
  end
  def get_out_fmt(out_fmt)
      if out_fmt == '0'
          result = "NTSC"
      elsif out_fmt == '1'
          result = "PAL"
      elsif out_fmt == '4'
          result = "480P"
      elsif out_fmt == '5'
          result = "576P"
      elsif out_fmt == '2'
          result = "720P"
      elsif out_fmt == '3'
          result = "1080I"    	
      end
      result
  end
end