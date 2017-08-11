# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/drm_utils'
require File.dirname(__FILE__)+'/capture_utils'
require File.dirname(__FILE__)+'/../../A-Audio/audio_utils'
require File.dirname(__FILE__)+'/../../default_target_test'

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && /etc/init.d/weston stop && sleep 3',@equipment['dut1'].prompt,10)
end

def run
  @results_html_file.add_paragraph("")
  drm_info = ''
  drm_info = get_properties()

  res_table = @results_html_file.add_table([["Test String",{:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])
  if drm_info['Planes:'].length() < 2 || drm_info['Connectors:'].length() < 2
    set_result("Not enough Planes (#{drm_info['Planes:'].length}) to validate that planes are universal")
    return
  end
  
  plane_ids = []
  drm_info['Planes:'].each{ |p| plane_ids << p['id'] }
  
  connectors = []
  drm_info['Connectors:'].each do |c|
    next if c['status'] != 'connected'
    connectors << {'id' => c['id'], 
                   'width' => c['modes:'][0]['hdisp'].to_i,
                   'height' => c['modes:'][0]['vdisp'].to_i}
  end
  
  fail_str = "TEST PASSED!!"
  fails = 0
  connectors.each do |connector|
    @equipment['dut1'].send_cmd("kmstest -c @#{connector['id']} 2>&1",/press enter to exit/im,30)
    primary_plane = @equipment['dut1'].response.match(/plane\s*\d+\/@(\d+)\)/im)[1]
    @equipment['dut1'].send_cmd("",@equipment['dut1'].prompt)

    plane_width = connector['width']/plane_ids.length
    plane_height = connector['height']/plane_ids.length
    off_set = [plane_width, plane_height].min
    test_pls = plane_ids - [primary_plane]
    x,y=0,0
    test_string = "kmstest -c @#{connector['id']}"
    test_pls.each do |t_pid|
      test_string+=" -p @#{t_pid}:#{x},#{y}-#{plane_width}x#{plane_height}"
      x+=plane_width
      if (x + plane_width) >= connector['width']
        x=0
        y+=plane_height
      end
    end
    @equipment['dut1'].send_cmd(test_string+ ' 2>&1 &',/press enter to exit/im,30)
    tout = @equipment['dut1'].timeout?
    test_response = @equipment['dut1'].response
    @equipment['dut1'].send_cmd("\nsleep 10; killall -9 kmstest",@equipment['dut1'].prompt,30)
    test_response += @equipment['dut1'].response
    tout |= test_response.match(/error|fail/im)
    if tout
      fails += 1
      fail_str="#{fails}/#{connectors.length} TEST FAILED!!!\r\n #{test_response}"
    end
    @results_html_file.add_rows_to_table(res_table,[[test_string,
                                         !tout ? ["Passed",{:bgcolor => "green"}] : 
                                         ["Failed",{:bgcolor => "red"}],
                                         test_response]])
  end
  set_result(fails > 0 ? FrameworkConstants::Result[:fail] : FrameworkConstants::Result[:pass],fail_str)
   

end

