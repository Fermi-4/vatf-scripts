#Function to change fbdev settings on device referenced by fb, takes:
#  params, a Hash whose entries are:
#  fb => <device>       : processed frame buffer device, (default is /dev/fb0)
#Display geometry: 
#    xres => <value>      : horizontal resolution (in pixels)
#    yres => <value>      : vertical resolution (in pixels)
#    vxres => <value>     : virtual horizontal resolution (in pixels)
#    vyres => <value>     : virtual vertical resolution (in pixels)
#    depth => <value>     : display depth (in bits per pixel)
#    nonstd => <value>    : select nonstandard video mode
#Display timings:  
#    pixclock => <value>  : pixel clock (in picoseconds)
#    left => <value>      : left margin (in pixels)
#    right => <value>     : right margin (in pixels)
#    upper => <value>     : upper margin (in pixel lines)
#    lower => <value>     : lower margin (in pixel lines)
#    hslen => <value>     : horizontal sync length (in pixels)
#    vslen => <value>     : vertical sync length (in pixel lines)
#Display flags:
#    accel => <value>     : hardware text acceleration enable (false or true)
#    hsync => <value>     : horizontal sync polarity (low or high)
#    vsync => <value>     : vertical sync polarity (low or high)
#    csync => <value>     : composite sync polarity (low or high)
#    gsync => <value>     : synch on green (false or true)
#    extsync => <value>   : external sync enable (false or true)
#    bcast => <value>     : broadcast enable (false or true)
#    laced => <value>     : interlace enable (false or true)
#    double => <value>    : doublescan enable (false or true)
#    rgba => <r,g,b,a>    : recommended length of color entries
#    grayscale => <value> : grayscale enable (false or true)
#Display positioning:
#    move => <direction>  : move the visible part (left, right, up or down)
#    step => <value>      : step increment (in pixels or pixel lines)
#                         (default is 8 horizontal, 2 vertical)
#  dut, the test equipment driver object used to send the fbset command
#Returns true is the parameters were set succesfully, false otherwise
def fbset(params, dut=@equipment['dut1'])
  fb_cmd = 'fbset'
  params.each{|key,val| fb_cmd += ' -' + key + ' ' + val}
  dut.send_cmd(fb_cmd, dut.prompt, 10)
  puts dut.response.match(/(\w+.*?)#{dut.prompt}/im).captures[0]
  result = !dut.response.match(/#{fb_cmd[-4..-1]}\s*\w+.*?#{dut.prompt}/im)
  settings_res = get_settings(params['fb'])['-g'].match(/^#{params['xres']} #{params['yres']}.*/)
  result && settings_res
end

#Function to play a video test pattern using gstreamer, takes:
#  params, a Hash whose entries are:
#    frames => <value>         : the number of frames to playout
#    pattern => <value>        : the test pattern to playout needs to be one of the following
#                                  smpte            - SMPTE 100% color bars
#                                  snow             - Random (television snow)
#                                  black            - 100% Black
#                                  white            - 100% White
#                                  red              - Red
#                                  green            - Green
#                                  blue             - Blue
#                                  checkers-1       - Checkers 1px
#                                  checkers-2       - Checkers 2px
#                                  checkers-4       - Checkers 4px
#                                  checkers-8       - Checkers 8px
#                                  circular         - Circular
#                                  blink            - Blink
#                                  smpte75          - SMPTE 75% color bars
#                                  zone-plate       - Zone plate
#                                  gamut            - Gamut checkers
#                                  chroma-zone-plate - Chroma zone plate
#                                  solid-color      - Solid color
#                                  ball             - Moving ball
#                                  smpte100         - SMPTE 100% color bars
#                                  bar              - Bar
#  data_type => <value>        : the type of data in each frame, one of the following
#                                  yuv, gray, rgb, bayer
#  format => <value>           : format of the data in each frame, one of the following
#                                  YUY2, UYVY, YVYU, v308, AYUV, v210, v216, UYVP, AY64,
#                                  YVU9, YUV9, YV12, I420, NV12, NV21, Y41B, Y42B, Y444,
#                                  Y800, bggr, rggb, grbg, gbrg
#  width => <value>            : width of the frame in pixels
#  height => <value>           : height of the frame in pixels
#  bpp => <value>              : bits per pixel
#  framerate => <value>        : frames per second
#  sink => <value>             : sink of the video stream, i.e "filesink <filepath>", "fbdevsink [virtual video node]", etc
#  dut, the test equipment driver object used to send the fbset command
def gst_play_test_pattern(params, dut=@equipment['dut1'])
  gst_cmd = "gst-launch -v -m videotestsrc num-buffers=#{params['frames']} pattern=#{params['pattern']} ! " \
            "video/x-raw-#{params['data_type']}, format=#{params['format']}, framerate=#{params['framerate']}/1, width=#{params['width']}, height=#{params['height']} ! " \
            "#{params['sink']}"
  dut.send_cmd(gst_cmd, dut.prompt, params['frames'].to_i*2)
end

def get_settings(dev_node, dut=@equipment['dut1'])
  settings = dut.send_cmd("fbset -fb #{dev_node}",dut.prompt,10)
  timings = settings.match(/\s*timings\s*([^\r\n]+)/).captures[0]
  geometry = settings.match(/\s*geometry\s*([^\r\n]+)/).captures[0]
  rgba = settings.match(/\s*rgba\s*([^\r\n]+)/).captures[0]
  {'-fb' => dev_node, '-t' => timings, '-g' => geometry, '-rgba' => rgba}
end

def restore_settings(settings, dut=@equipment['dut1'])
  cmd = 'fbset'
  settings.each do |flag, value|
    cmd += " #{flag} #{value}"
  end
  dut.send_cmd(cmd, dut.prompt, 10)
end

def get_fb_dev_node(dut=@equipment['dut1'])
  dut.send_cmd('cat /proc/fb', dut.prompt,5)
  fb = '/dev/fb' + dut.response.match(/^(\d+)\s*.*?/).captures[0]
  fb
end



