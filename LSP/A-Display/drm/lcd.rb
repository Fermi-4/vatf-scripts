# -*- coding: ISO-8859-1 -*-
# Test lcd is working by setting color frames and measuring color with a
# colorimeter. Requires specifying the following colorimeter information
# in the dut params of the bench file.
# dut.params = {... 'colorimeter' =>
#                          { 'device' => <colorimeter's dev path>,
#                            ['color_chart' => { 'red' => <lcd's xyz measured values for red>,
#                                                'green' => <lcd's xyz measured values for green>,
#                                                'blue' => <lcd's xyz measured values for blue>,
#                                                'white' => <lcd's xyz measured values for white>,
#                                                'black' => <lcd's xyz measured values for black>, 
#                                              }] 
#                          }
# If the optional 'color_chart' data is not specified in the bench the
# default colorimeter data used in the test are the values measured with
# an xrite colormunki smile.
#  https://www.xrite.com/categories/calibration-profiling
#  https://www.xrite.com/categories/calibration-profiling/colormunki-smile
#
# The application used to measure color with the colorimeter is a modified
# version of spotread, included as part of the argyll package
# https://www.argyllcms.com/ (sudo apt-get install argyll in linux)

require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def setup
  super
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && /etc/init.d/weston stop && sleep 3',@equipment['dut1'].prompt,10)
end

def run
  colorimeter = File.realpath(@equipment['dut1'].params['colorimeter']['device'])
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  dut_app = '/tmp/color.py'
  send_script(dut_app)
  host_app = get_spotread() + " -e -x -c #{colorimeter} -O"
  result = ''
  color_data = get_color_data(@equipment['dut1'].name)
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Color",{:bgcolor => "4863A0"}, {:color => "white"}], 
                                            ["Expected xyz", {:bgcolor => "4863A0"}, {:color => "white"}],
                                            ["Measured xyz", {:bgcolor => "4863A0"}, {:color => "white"}],
                                            ["xy Error", {:bgcolor => "4863A0"}, {:color => "white"}],
                                            ["Result", {:bgcolor => "4863A0"}, {:color => "white"}]])

  color_data.each do |color, xyz|
    @equipment['dut1'].send_cmd("#{dut_app} #{color}", /Press any key to stop.../)
    if @equipment['dut1'].timeout?
      result += "Unable to set lcd to #{color}\n"
      next
    end
    sleep(1)
    @equipment['server1'].send_cmd(host_app, /Result\s*is\s*XYZ:[^\n\r]+/im, 30)
    if @equipment['server1'].timeout?
      result += "Timed out trying to measure color --#{@equipment['server1'].response}--\n"
      break
    end
    @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt)
    xyz_test = get_xyz_values(@equipment['server1'].response)
    error_vals = []
    xyz_test[0..1].each_with_index {|c, i| error_vals[i] = c - xyz[i]}
    error = 0
    error = error_vals.reduce(0) { |sum, v| sum += v**2 }
    error = error**0.5
    if error > 0.02
		result += "#{color.upcase()}: expected #{xyz}, measured #{xyz_test}, error #{error}\n"
    end
    @results_html_file.add_rows_to_table(res_table,[[[color.upcase(),{:bgcolor => color}, {:color => color == 'white' ? 'black' : 'white'}],
                                                     xyz.to_s,
                                                     xyz_test.to_s,
                                                     error,
												     error > 0.01 ?
												       ["Failed",{:bgcolor => "red"},{:color => 'black'}] :
												       ["Passed",{:bgcolor => "green"}, {:color => 'white'}]]])
  end
  if result == ''
    set_result(FrameworkConstants::Result[:pass], "LCD Test Passed\n")
  else
    set_result(FrameworkConstants::Result[:fail], "LCD Test Failed: #{result}\n")
  end
end

def get_xyz_values(log)
  x, y, z = log.match(/Result\s*is\s*XYZ:\s*([\d\.]+)\s*([\d\.]+)\s*([\d\.]+),/im).captures.map {|x| x.to_f}
  sum = x + y + z
  [x/sum, y/sum, z/sum]
end

def send_script(script)
@equipment['dut1'].send_cmd("rm #{script}", @equipment['dut1'].prompt)
"""#!/usr/bin/python3

import pykms
import time
import random
import sys
import re

# This hack makes drm initialize the fbcon, setting up the default connector
card = pykms.Card()
card = 0

card = pykms.Card()
res = pykms.ResourceManager(card)
conn = res.reserve_connector()
crtc = res.reserve_crtc(conn)
mode = conn.get_default_mode()

planes = []
for p in card.planes:
    if p.supports_crtc(crtc) == False:
        continue
    planes.append(p)

card.disable_planes()

w = mode.hdisplay
h = mode.vdisplay
l_div = len(planes) - 1


fbs = pykms.DumbFramebuffer(card, w, h, pykms.PixelFormat.XRGB8888)
if sys.argv[1] == 'red':
    pykms.draw_rect(fbs, 0, 0, w, h, pykms.RGB(255, 0, 0))
elif sys.argv[1] == 'green':
    pykms.draw_rect(fbs, 0, 0, w, h, pykms.RGB(0, 255, 0))
elif sys.argv[1] == 'blue':
    pykms.draw_rect(fbs, 0, 0, w, h, pykms.RGB(0, 0, 255))
elif sys.argv[1] == 'white':
    pykms.draw_rect(fbs, 0, 0, w, h, pykms.RGB(255, 255, 255))
elif sys.argv[1] == 'black':
    pykms.draw_rect(fbs, 0, 0, w, h, pykms.RGB(0, 0, 0))
else:
    print('User provided RGB color')
    r,g,b = [int(sys.argv[1][i*3:i*3+3]) for i in [0,1,2]]
    print('R: %s, G: %s, B: %s' % (r, g, b)) 
    pykms.draw_rect(fbs, 0, 0, w, h, pykms.RGB(r, g, b))

p_props = {
        'FB_ID': fbs.id,
        'CRTC_ID': crtc.id,
        'SRC_X': 0,
        'SRC_Y': 0,
        'SRC_W':  w << 16,
        'SRC_H':  h << 16,
        'CRTC_X': 0,
        'CRTC_Y': 0,
        'CRTC_W': w,
        'CRTC_H': h,
}

planes[0].set_props(p_props)

print('Press any key to stop...')
sys.stdin.read(1)
""".each_line { |line| @equipment['dut1'].send_cmd("echo \"#{line.rstrip()}\" >> #{script}", @equipment['dut1'].prompt) }
@equipment['dut1'].send_cmd("chmod 755 #{script}")
end

def get_color_data(dut_type)
  return @equipment['dut1'].params['colorimeter']['color_chart'] if @equipment['dut1'].params['colorimeter']['color_chart']
  data = {}
  data.default = {
                   'red' => [0.5611954023725733, 0.3337614596273832, 0.10504313800004357],
                   'green' => [0.32698439059063605, 0.5935020909326695, 0.07951351847669437],
                   'blue' => [0.15382385017688044, 0.09083841401312595, 0.7553377358099935],
                   'white' => [0.26248172057455527, 0.2736214804576619, 0.4638967989677828],
                   'black' => [0.22868023661240292, 0.23217141173924546, 0.5391483516483516]
                 }
  data['am335x-evm'] = {
                         'red' => [0.6014646611245587, 0.37286540424685133, 0.02566993462859014],
	                     'green' => [0.3521814660500555, 0.5912562901974594, 0.056562243752485156],
	                     'blue' => [0.16339965413540514, 0.13333220516326058, 0.7032681407013343],
	                     'white' => [0.30136136025531846, 0.331911204725682, 0.3667274350189995],
	                     'black' => [0.28683460447536946, 0.274245348071749, 0.43892004745288143]
                       }
  data['dra7xx-evm'] = {
                         'red' => [0.649564384888374, 0.32581050027413194, 0.024625114837493977],
	                     'green' => [0.32594707026089936, 0.5979309625561612, 0.07612196718293936],
	                     'blue' => [0.15178174728740326, 0.03340995912094482, 0.8148082935916519],
	                     'white' => [0.30479055465004196, 0.30778470046674933, 0.38742474488320866],
	                     'black' => [0.2508706203421461, 0.27341643495359347, 0.4757129447042606]
                       }
  data[dut_type]
end

def get_spotread()
  host = 'http://gtopentest-server.gt.design.ti.com/anonymous/common/Multimedia/host-utils'
  spotread = File.join(SiteInfo::UTILS_FOLDER, 'spotread')

  if !File.exists?(spotread)
    @equipment['server1'].send_cmd("rm -rf #{spotread}; wget --no-proxy #{host}/spotread  -O #{spotread} || " \
	   			     "wget #{host}/spotread -O #{spotread}",
		  		     @equipment['server1'].prompt,
				     180)
    raise "Unable to fetch capture utility" if !File.exists?(spotread)
    @equipment['server1'].send_cmd("chmod 755 #{spotread}", @equipment['server1'].prompt)
  end
  spotread
end
