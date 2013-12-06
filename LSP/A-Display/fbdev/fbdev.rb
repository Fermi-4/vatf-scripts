# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/fbdev_utils'   

include LspTestScript

def run
  dev_node = get_fb_dev_node()
  default_settings = get_settings(dev_node)
  test_settings = {
    'fb' => dev_node,
    'pixclock' => @test_params.params_chan.pixclock[0],
    'left' => @test_params.params_chan.left_margin[0], 
    'right' => @test_params.params_chan.right_margin[0], 
    'lower' => @test_params.params_chan.lower_margin[0],
    'upper' => @test_params.params_chan.upper_margin[0],
    'hslen' => @test_params.params_chan.hsync_length[0],
    'vslen' => @test_params.params_chan.vsync_length[0],
    'xres' => @test_params.params_chan.width[0], 
    'yres' => @test_params.params_chan.height[0],
    'vxres' => @test_params.params_chan.vxres[0], 
    'vyres' => @test_params.params_chan.vyres[0],
    'vsync' => @test_params.params_chan.vsync[0],
    'hsync' => @test_params.params_chan.hsync[0],
    'depth' => @test_params.params_chan.bpp[0]}
  gst_settings = {
    'frames' => @test_params.params_chan.num_frames[0], 
    'pattern' => @test_params.params_chan.pattern[0],
    'data_type' => @test_params.params_chan.data_type[0],
    'format' => @test_params.params_chan.format[0],
    'width' => @test_params.params_chan.width[0], 
    'height' => @test_params.params_chan.height[0],
    'bpp' => @test_params.params_chan.bpp[0],
    'framerate' => @test_params.params_chan.frame_rate[0],
    'sink' => 'fbdevsink ' + dev_node
     
  }
  if fbset(test_settings)
    gst_play_test_pattern(gst_settings)
    print "Did the video display correctly [y/n]?"
    answer = STDIN.gets()
    if answer.downcase().start_with?('y')
      set_result(FrameworkConstants::Result[:pass], "Test Passed")
    else
      print "Failure reason? "
      reason = STDIN.gets()
      set_result(FrameworkConstants::Result[:fail], "Test Failed, #{reason.strip()}")
    end
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed, not able to change mode through fbdev")
  end
  ensure
    restore_settings(default_settings) if default_settings
end




