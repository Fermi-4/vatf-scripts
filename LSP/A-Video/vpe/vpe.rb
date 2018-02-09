# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_target_test'  
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../dev_utils'

include LspTargetTestScript

def run
  @equipment['dut1'].send_cmd("mkdir #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm  #{@linux_dst_dir}/*", @equipment['dut1'].prompt) #Make sure we have enough disk space for the f2f operations
  @equipment['dut1'].send_cmd('modprobe ti-vpe',@equipment['dut1'].prompt,10)
  if @equipment['dut1'].response.index(/fatal/i)
    set_result(FrameworkConstants::Result[:fail], "Unable to load vpe modules")
    return
  end
  vpe_dev = '/dev/' + get_type_devices('vpe')[0]
  dut_src_file = []
  dut_test_file = []
  local_test_file = []
  test_format = []
  test_cmd = ''
  video_height = []
  video_width = []
  interlace = []
  scaling = []
  test_cmds = []
  @test_params.params_chan.video_url.each_with_index do |video_url, i|
    d_src_file = get_file_from_url(video_url, nil)[1]
    dut_src_file << d_src_file
    dut_test_file << File.join(@linux_dst_dir,"video_test_file#{i}.yuv")
    local_test_file << File.join(@linux_temp_folder, "video_tst_file#{i}.yuv")
    @equipment['dut1'].send_cmd("rm -rf #{dut_test_file[i]}", @equipment['dut1'].prompt)
    @equipment['server1'].send_cmd("rm -rf #{local_test_file[i]}",@equipment['server1'].prompt)
    test_format << @test_params.params_chan.test_format[i]
    src_format = @test_params.params_chan.src_format[i]
    v_width = @test_params.params_chan.video_width[i].to_i
    v_height = @test_params.params_chan.video_height[i].to_i
    src_video_height = v_height
    src_video_width = v_width
    scaling << (@test_params.params_chan.instance_variable_defined?(:@scaling) ? @test_params.params_chan.scaling[i].to_f : 1)
    v_width, v_height = get_scaled_resolution(src_video_width, src_video_height, scaling[i]) if scaling != 1
    video_height << v_height
    video_width << v_width
    ilace = 0
    if @test_params.params_chan.instance_variable_defined?(:@deinterlace)
      ilace = @test_params.params_chan.deinterlace[i].to_i
      src_video_height = (src_video_height/2).to_i if ilace != 0
    end
    interlace << ilace
    translen = 1 + rand(3)
    test_cmds << "test-v4l2-m2m #{vpe_dev} #{dut_src_file[i]} #{src_video_width} #{src_video_height} #{src_format} #{dut_test_file[i]} #{video_width[i]} #{video_height[i]} #{test_format[i]} #{interlace[i]} #{translen}"
  end
  test_cmd = test_cmds.join(' > /dev/null & ') 
  @equipment['dut1'].send_cmd(test_cmd, @equipment['dut1'].prompt, 300)
  num_frames = @equipment['dut1'].response.match(/frames\s*left\s*(\d+)/im)[1].to_i + 1
  dut_ip = get_ip_addr()
  result = ''
  test_format.each_with_index do |test_fmt, i|
    scp_pull_file(dut_ip, dut_test_file[i], local_test_file[i])
    format_length = case(test_fmt.downcase())
      when 'argb32','abgr32'
        4
      when 'rgb24','bgr24'
        3
      when 'yuyv','uyvy'
        2
      when 'nv12'
        1.5
    end
    ref_path = get_reference(@test_params.params_chan.video_url[i],
                              video_width[i],
                              video_height[i],
                              test_fmt,
                              interlace[i])
    trunc_local_ref = ref_path
    if File.size(ref_path) != File.size(local_test_file[i])
      trunc_local_ref = ref_path+'.trunc'
      frame_size = (format_length * video_height[i] * video_width[i]).to_i
      @equipment['server1'].send_cmd("dd if=#{ref_path} of=#{trunc_local_ref} bs=#{frame_size} count=#{num_frames}", @equipment['server1'].prompt,600)
    end
    @equipment['server1'].send_cmd("md5sum #{trunc_local_ref} #{local_test_file[i]} | grep -o '^[^ ]*'",@equipment['server1'].prompt, 600)
    qual_res = @equipment['server1'].response.split()
    result += ", VPE-M2M operation failed  for case #{i} (#{num_frames} frames), #{qual_res[0]} != #{qual_res[1]}" if qual_res[0].strip() != qual_res[1].strip()
  end
  if result != ''
    set_result(FrameworkConstants::Result[:fail], "Test Failed, #{result}")
  else
    set_result(FrameworkConstants::Result[:pass], "Test passed for #{test_format.length} VPE-M2M operation(s) (#{num_frames} frames)")
  end
  ensure
    @equipment['dut1'].send_cmd('modprobe -r ti-vpe', @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      raise "Unable to remove module, system may have hung" if !is_uut_up?(@equipment['dut1'])
    end
end


def get_reference(video_url, width, height, format, interlace)
  ref_file = ['ref',
              File.basename(video_url), 
              'to',
              "#{width}x#{height}",
              format,
              interlace == 0 ? 'nodeinter' : 'deinter'].join('_') 
  ref_file += '.' + format + '.tar.xz'
  
  files = get_ref do |base_uri|
    base_uri + '/host-utils/vpe/ref-media/' + ref_file 
  end
  files[0]
end

