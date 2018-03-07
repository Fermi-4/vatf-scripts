require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../f2f_utils'
require 'rexml/document'

include AndroidTest
include REXML

def run
  apk_path = File.join(@linux_temp_folder, File.basename(@test_params.params_chan.apk_url[0]))
  wget_file(@test_params.params_chan.apk_url[0], apk_path)
  pkg = installPkg(apk_path, 'glbenchmark',true, 300)
  #clear the old files if any
  send_adb_cmd("shell rm /sdcard/Android/data/#{pkg}/cache/last_results_*.xml")
  local_res_file = File.join(@linux_temp_folder, 'glbenchmark_results.xml')
  send_adb_cmd("logcat -c")
  send_adb_cmd("shell am start -W -n #{pkg}/com.glbenchmark.activities.MainActivity -a android.intent.action.MAIN -c android.intent.category.LAUNCHER")
  test_menu = send_adb_cmd("logcat  -d").scan(/Log\s+:\s*(GLB\d+_\w+)\s+\|(\d+)/)
  send_adb_cmd("logcat  -c")
  send_events_for(['__directional_pad_up__', '__enter__', '__tab__', '__tab__', '__enter__', '__tab__', '__enter__'])
  timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.instance_variable_defined?(:@timeout).to_i : 60
  wait_for_logcat(/ActivityManager:\s*Displayed\s*#{pkg}\/com.glbenchmark.activities.ResultsActivity:/, timeout)
  results_file = send_adb_cmd('shell ls /sdcard/Android/data/com.glbenchmark.glbenchmark*/cache/last_results_*.xml').strip()
  send_adb_cmd("pull -p #{results_file} #{local_res_file}")
  perf_data = []
  res_string = ''
  result = FrameworkConstants::Result[:pass]
  File.open(local_res_file) do |fd|
    doc = Document.new(fd)
    index = 0
    doc.root.each_element('//test_result') do |res|
      result = {}
      res.each_element do |res_e|
        result[res_e.name] = res_e.has_text?() ? res_e.get_text().value : nil 
      end
      test = test_menu[index][0].sub(/^.*?_/,'')
      perf_data << {'name' => "num-#{test}",
                    'units' => 'none',
                    'values' => test_menu[index][1]}
      if result['fps']
        perf_data << {'name' => "fps-#{test}",
                      'units' => 'fps',
                      'values' => result['fps']}
      end
      perf_data << {'name' => "score-#{test}",
                    'units' => parse_units(result['uom']),
                    'values' => result['score']}
      if result['error'].to_i != 0
        result = FrameworkConstants::Result[:fail]
        res_string += "Test #{test} (#{test_menu[index][1]}) failed\n"
      end
      index += 1
    end
  end
  set_result(result, res_string , perf_data)
  ensure
    uninstallPkg(pkg) if pkg
end

def parse_units(units)
  return units if units.length <= 10
  s_units = units.split('/')
  return units if s_units.length < 2
  max_index = [9 - s_units.min.length, 5].max - 1
  return [s_units[0][0..max_index], s_units[1][0..max_index]].join('/') 
end
