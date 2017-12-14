# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../../../LSP/A-Video/play_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../../../LSP/A-Video/dev_utils'
  
include AndroidTest

def run
  send_adb_cmd("shell rm  #{@linux_dst_dir}/*") #Make sure we have enough disk space for the f2f operations
 
  #vpe_dev = '/dev/' + get_type_devices('vpe')[0] Commented out until vpetest supports passing vpe devices
  ref_file_url = @test_params.params_chan.instance_variable_defined?(:@ref_video_url) ? @test_params.params_chan.ref_video_url[0] : nil
  ref_path, dut_src_file = get_file_from_url(@test_params.params_chan.video_url[0], ref_file_url)
  src_format = @test_params.params_chan.src_format[0]
  test_format = @test_params.params_chan.test_format[0]
  video_width = @test_params.params_chan.video_width[0].to_i
  video_height = @test_params.params_chan.video_height[0].to_i
  src_video_height = video_height
  src_video_width = video_width
  scaling = @test_params.params_chan.instance_variable_defined?(:@scaling) ? @test_params.params_chan.scaling[0].to_f : 1
  cropping = @test_params.params_chan.instance_variable_defined?(:@cropping) ? @test_params.params_chan.cropping.map(&:to_i) : [0]*4
  video_width, video_height = get_scaled_resolution(src_video_width, src_video_height, scaling) if scaling != 1
  interlace = 0
  if @test_params.params_chan.instance_variable_defined?(:@deinterlace)
    interlace = 1
    src_video_height = (src_video_height/2).to_i
  end
  translen = 1 + rand(3)
  dut_test_file = File.join(@linux_dst_dir,'video_test_file.yuv')
  local_test_file = File.join(@linux_temp_folder, 'video_tst_file.yuv')
  send_adb_cmd("shell rm -rf #{dut_test_file}")
  @equipment['server1'].send_cmd("rm -rf #{local_test_file}",@equipment['server1'].prompt)
  response = send_adb_cmd("shell su root vpetest #{dut_src_file} #{src_video_width} #{src_video_height} #{src_format} #{dut_test_file} #{video_width} #{video_height} #{test_format} #{cropping.join(' ')} #{interlace} #{translen}")
  num_frames = response.match(/frames\s*left\s*(\d+)/im)[1].to_i + 1
  send_adb_cmd("pull #{dut_test_file} #{local_test_file}")
  format_length = case(test_format.downcase())
    when 'argb32','abgr32'
      4
    when 'rgb24','bgr24'
      3
    when 'yuyv','uyvy'
      2
    when 'nv12'
      1.5
  end
  ref_path = get_reference(@test_params.params_chan.video_url[0],
                            video_width,
                            video_height,
                            test_format,
                            interlace,
                            cropping)
  trunc_local_ref = ref_path
  if File.size(ref_path) != File.size(local_test_file)
    trunc_local_ref = ref_path+'.trunc'
    frame_size = (format_length * video_height * video_width).to_i
    @equipment['server1'].send_cmd("dd if=#{ref_path} of=#{trunc_local_ref} bs=#{frame_size} count=#{num_frames}", @equipment['server1'].prompt,600)
  end
  @equipment['server1'].send_cmd("md5sum #{trunc_local_ref} #{local_test_file} | grep -o '^[^ ]*'",@equipment['server1'].prompt, 600)
  qual_res = @equipment['server1'].response.split()
  if qual_res[0].strip() != qual_res[1].strip()
    set_result(FrameworkConstants::Result[:fail], "Test Failed, converted file failed test (#{num_frames} frames), #{qual_res[0]} != #{qual_res[1]}")
  else
    set_result(FrameworkConstants::Result[:pass], "Test passed (#{num_frames} frames)")
  end
end


def get_reference(video_url, width, height, format, interlace, cropping)
  ref_file = ['ref',
              File.basename(video_url), 
              'to',
              "#{width}x#{height}",
              format,
              interlace == 0 ? 'nodeinter' : 'deinter'].join('_')

  if cropping.inject(:+) > 0
    ref_file = [ref_file, 'crop', cropping].join('_')
  end

  ref_file += '.' + format + '.tar.xz'
  
  files = get_ref do |base_uri|
    base_uri + '/host-utils/vpe/ref-media/' + ref_file 
  end
  files[0]
end

