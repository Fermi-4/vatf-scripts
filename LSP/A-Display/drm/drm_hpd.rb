# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/capture_utils'

=begin
 Test to validate HDMI Hot plug detection, requires:
   - HDMI switch, for example
     http://www.kramerelectronics.com/products/model.asp?pid=534
   - Adding "hdmiqual" capability the board's bench and 
     staf registration command.
=end

include LspTestScript
include CaptureUtils

def run
  num_passed = 0
  hpd_times = []
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Iteration",{:bgcolor => "4863A0"}], 
                                            ["Comment", {:bgcolor => "4863A0"}]])

  iterations = @test_params.params_chan.instance_variable_defined?(:@iters) ? @test_params.params_chan.iters[0].to_i : 10
  cap_edid = MediaCapture.new(@equipment['server1']).get_edid()
  hdmi_out_info = @equipment['dut1'].video_io_info.hdmi_outputs.keys[0]
  hdmi_in_info = @equipment['server1'].video_io_info.hdmi_inputs.keys[0]
  e_re = /UDEV.*\[([\d\.]+)\].*change.*UDEV.*\[([\d\.]+)\].*change.*USEC_INITIALIZED=\d+/im
  iterations.times do |iter|
    iter_comment = ''
    staf_mutex('video_capture', 36000000*iterations) do
      add_equipment('hdmi_sw', hdmi_out_info, true) do |e_class, log_path|
        e_class.new(hdmi_out_info, log_path)
      end
      @equipment['hdmi_sw'].connect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0], @equipment['server1'].video_io_info.hdmi_inputs.values[0])
      sleep(1)
      @equipment['dut1'].send_cmd("udevadm monitor --udev --property --subsystem-match=drm", /UDEV.*?processing/im,10)
      thr = Thread.new do
        @equipment['dut1'].wait_for(e_re,10)
      end
      @equipment['hdmi_sw'].disconnect_video_audio()
      sleep(1)
      @equipment['hdmi_sw'].connect_video_audio(@equipment['dut1'].video_io_info.hdmi_outputs.values[0], @equipment['server1'].video_io_info.hdmi_inputs.values[0])
      thr.join(20)
      hp_detected = !@equipment['dut1'].timeout?
      event_info = @equipment['dut1'].response
      @equipment['dut1'].send_cmd("\C-c", @equipment['dut1'].prompt,10,false)
      if hp_detected
        d_time, c_time = event_info.match(e_re).captures.map(&:to_f)
        e_time = c_time - d_time - 1
        @equipment['dut1'].send_cmd("hexdump /sys/class/drm/card0-HDMI-A-1/edid | grep -o ' [0-9a-fA-F].*'",@equipment['dut1'].prompt,10)
        dut_edid_data = @equipment['dut1'].response.match(/hexdump.*?\.\*'[\r\n]+(.+)/im).captures[0].rpartition(/[\r\n]+/)[0].strip().downcase().split(/\s+/)
        dut_edid = dut_edid_data.inject('') { |str, datum| str += datum[2..3] + datum[0..1] }
        if dut_edid == cap_edid.downcase
          num_passed += 1
          hpd_times << e_time
          iter_comment = "#{e_time} secs"
        else
          iter_comment = "EDID read failed got: #{dut_edid}\n expected: #{cap_edid}"
        end
      else
        iter_comment = "Hot plug detection failed\n#{event_info}"
      end
      @results_html_file.add_rows_to_table(res_table,[[iter, 
                                                       iter_comment]])
    end
  end

  set_result(num_passed != iterations ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],
             "#{num_passed}/#{iterations} passed ", {'name'=> 'hpd_time', 'value'=>hpd_times, 'units' => 'sec'})

end


