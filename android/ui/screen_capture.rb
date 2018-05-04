require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../../LSP/A-Display/drm/capture_utils'
require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest
include CaptureUtils

def run
  install_utils()
  src_picture = @test_params.params_chan.picture_url[0] 
  ref_path, src_file = get_file_from_url(src_picture, nil)
  #send_adb_cmd("shell su root am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:://#{src_file}")
  #sleep 5
  dut_sc_file = File.join(@linux_dst_dir, 'screencap.png')
  local_sc_file = File.join(@linux_temp_folder, 'screencap.png')
  local_sysrq_file = File.join(@linux_temp_folder, 'screencap-sysrq.png')
  send_adb_cmd("shell am start -W -a android.intent.action.VIEW -d file://#{src_file} -t 'image/*'")
  send_adb_cmd("shell screencap -p #{dut_sc_file}")
  send_adb_cmd("pull #{dut_sc_file} #{local_sc_file}")
  local_ref_file = File.join(@linux_temp_folder, 'ref_sc.png')
  wget_file("http://gtopentest-server.gt.design.ti.com/anonymous/common/android/ref-files/screencap/#{@equipment['dut1'].name}.png", local_ref_file)
  ref_argb = File.join(@linux_temp_folder, 'ref_sc.argb')
  @equipment['server1'].send_cmd("avconv -i #{local_ref_file} -pix_fmt argb -f rawvideo #{ref_argb}", @equipment['server1'].prompt, 60)
  qual = check_file(ref_argb, local_sc_file)
  pre_sysrq = send_adb_cmd("shell ls /sdcard/Pictures/Screenshots").split(/\s+/)
  send_events_for("__sysrq__")
  sleep 5
  post_syrq = send_adb_cmd("shell ls /sdcard/Pictures/Screenshots").split(/\s+/)
  if (post_syrq - pre_sysrq).empty?
    sysrq_qual = "No sysrq capture file detected"
  else
    send_adb_cmd("pull /sdcard/Pictures/Screenshots/#{(post_syrq - pre_sysrq)[0]} #{local_sysrq_file}")
    sysrq_qual = check_file(ref_argb, local_sysrq_file)
  end
  if qual+sysrq_qual == ''
    set_result(FrameworkConstants::Result[:pass], 'Screen captures passed')
  else
    set_result(FrameworkConstants::Result[:fail], qual+sysrq_qual)
  end
end

def check_file(ref_argb, test_file)
  test_argb = File.join(@linux_temp_folder, 'test.argb')
  @equipment['server1'].send_cmd("avconv -i #{test_file} -pix_fmt argb -f rawvideo #{test_argb}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("file #{test_file}", @equipment['server1'].prompt, 10)
  width, height = @equipment['server1'].response.match(/,\s*(\d+)\s*x\s*(\d+)\s*,/).captures
  result = get_psnr_ssim_argb(ref_argb, test_argb, width, height, 4)
  return "test failed for #{test_file}\n" if result.empty?
  qual_string= ''
  result[0]['ssim'].each do |comp, val| 
    qual_string+="Component #{comp} failed SSIM #{val}%\n" if val < 98 && comp != 'a'
  end
  qual_string
end
