# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/../../../lib/result_forms'
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
  test_string = "#{@test_params.params_chan.width[0]}x" \
                "#{@test_params.params_chan.height[0]}@" \
                "#{@test_params.params_chan.frame_rate[0]}-" \
                "#{@test_params.params_chan.format[0]} fbdev test"
  test_result = FrameworkConstants::Result[:nry]
  while(test_result == FrameworkConstants::Result[:nry])
    if fbset(test_settings)
      gst_play_test_pattern(gst_settings)
      res_win = ResultWindow.new(test_string)
      res_win.show()
      test_result, test_comment = res_win.get_result()
      if test_result == FrameworkConstants::Result[:pass]
        set_result(test_result, "Test Passed #{test_comment}")
      elsif test_result == FrameworkConstants::Result[:fail]
        set_result(test_result, "Test Failed, #{test_comment}")
      end
    else
      set_result(FrameworkConstants::Result[:fail], "Test Failed, not able to change mode through fbdev")
      test_result = FrameworkConstants::Result[:fail]
    end
  end
  ensure
    restore_settings(default_settings) if default_settings
end




