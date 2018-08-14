# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  
require File.dirname(__FILE__)+'/../../lib/utils'
require File.dirname(__FILE__)+'/dev_utils'

include LspTargetTestScript

def run
  @equipment['dut1'].send_cmd("mkdir #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  video_devices = get_type_devices(@test_params.params_chan.ip_type[0])
  test_string = ''
  passed = 0
  total = 0
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Device",{:bgcolor => "4863A0"}],
                                            ["Resolution", {:bgcolor => "4863A0"}],
                                            ["Fmt", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])
  multiplanar = @test_params.params_chan.instance_variable_defined?(:@multiplanar) ? 2 : 1
  valid_formats = ['UYVY', 'YUYV', 'VYUY', 'YVYU']
  valid_formats = ['RGB3', 'RGB4', 'BGR3', 'BGR4'] if multiplanar == 2
  @equipment['dut1'].send_cmd("modprobe vivid n_devs=1 node_types=0x100 num_outputs=1 output_types=0x01 multiplanar=#{multiplanar} allocators=1 no_error_inj", @equipment['dut1'].prompt, 10)
  vivid_dev = get_type_devices('vivid')[0]
  vivid_stds = {}
  @equipment['dut1'].send_cmd("v4l2-ctl -d /dev/#{vivid_dev} --list-dv-timings", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].response.scan(/Index:\s*(\d+).*?Active width:\s*(\d+).*?Active height:\s*(\d+)/im).each do |st|
    res = st[1..-1].join('x')
    vivid_stds[res] = st[0] if !vivid_stds.has_key?(res)
  end
  num_frames = 100
  mmap_buffs = 6
  dmabuf_type = @test_params.params_chan.test_type[0].downcase() == 'export' ? "--stream-mmap=#{mmap_buffs} --stream-out-dmabuf" : "--stream-out-mmap=#{mmap_buffs} --stream-dmabuf" 
  video_devices.each do |dev|
    device = '/dev/'+dev
    @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --list-formats", @equipment['dut1'].prompt, 10)
    pix_fmts = @equipment['dut1'].response.scan(/(?<=Pixel\sFormat:\s')\w+/im)
    pix_fmts.select! { |p| valid_formats.include?(p) }
    pix_fmts.each do |src_format|
      @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --list-framesizes=#{src_format}", @equipment['dut1'].prompt, 10)
      @equipment['dut1'].response.scan(/(?<=Size:\sDiscrete\s)[\dx]+/im).each do |res|
        t_result = false
        next if !vivid_stds.has_key?(res)
        @equipment['dut1'].send_cmd("v4l2-ctl -d /dev/#{vivid_dev} --set-dv-bt-timings=index=#{vivid_stds[res]}", @equipment['dut1'].prompt, 10)
        next if !@equipment['dut1'].response.match(/BT\s*timings\s*set/im)
        total+=1
        width, height = res.split('x')
        @equipment['dut1'].send_cmd("v4l2-ctl -d #{device} --set-fmt-video=width=#{width},height=#{height},pixelformat=#{src_format.upcase()} -e /dev/#{vivid_dev} --stream-count=#{num_frames} #{dmabuf_type}", @equipment['dut1'].prompt, 20)        
        if !@equipment['dut1'].response.match(/error|fail|invalid/im) && @equipment['dut1'].response.match(/[\d\.]+\s*fps/im)
          passed += 1
          t_result = true
        else
          test_string += "#{src_format} failed: #{@equipment['dut1'].response}"
        end
        @results_html_file.add_rows_to_table(res_table,[[device,
                                           res, 
                                           src_format,
                                           t_result ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           @equipment['dut1'].response]])
      end
    end
	end
  set_result( passed > 0 && passed == total ? FrameworkConstants::Result[:pass] : FrameworkConstants::Result[:fail], "#{passed}/#{total} passed\n" + test_string)
end
