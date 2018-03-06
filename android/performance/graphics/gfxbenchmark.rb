require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../media/f2f_utils'
require 'json'

include AndroidTest

def run
  apk_path = File.join(@linux_temp_folder, File.basename(@test_params.params_chan.apk_url[0]))
  wget_file(@test_params.params_chan.apk_url[0], apk_path)
  pkg = send_adb_cmd('shell pm list packages kishonti.gfxbench').strip().split(':')[1]
  send_adb_cmd("uninstall #{pkg}")
  send_adb_cmd("install -r #{apk_path}")
  pkg = send_adb_cmd('shell pm list packages kishonti.gfxbench').strip().split(':')[1]
  #clear the old files if any
  send_adb_cmd("shell rm -rf /sdcard/Android/data/#{pkg}/files/results/*")
  local_res_dir = File.join(@linux_temp_folder, 'gfxbenchmark')
  Dir.mkdir(local_res_dir) if !File.exist?(local_res_dir)
  @equipment['server1'].send_cmd("rm -rf #{local_res_dir}/*")
  send_adb_cmd("logcat -c")
  send_adb_cmd("shell am start -W -n #{pkg}/net.kishonti.app.MainActivity -a android.intent.action.MAIN -c android.intent.category.LAUNCHER")
  send_adb_cmd("logcat  -c")
  send_events_for(['__tab__', '__tab__', '__tab__', '__enter__'])
  30.times do |i|
    data = send_adb_cmd("logcat  -d")
    send_adb_cmd("logcat -c")
    break if data.match(/Initialization:\s*After\s*Init\s*net.kishonti.app.MainActivity/)
    raise "Benchmark was not able to start" if i == 29
    sleep 30
  end
  send_events_for(['__directional_pad_up__', '__enter__'])
  timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.instance_variable_defined?(:@timeout).to_i : 60
  (timeout*2).times do |i|
    data = send_adb_cmd("logcat  -d")
    send_adb_cmd("logcat -c")
    break if data.match(/ActivityManager:\s*START.*?act=net.kishonti.benchui.ACTION_SHOW_RESULT.*?cmp=#{pkg}\/net.kishonti.app.MainActivity/)
    sleep 30
  end
  results_dir = "/sdcard/Android/data/#{pkg}/files/results/" + send_adb_cmd("shell ls /sdcard/Android/data/#{pkg}/files/results/").strip()
  send_adb_cmd("pull -p #{results_dir} #{local_res_dir}/")
  perf_data = []
  res_string = ''
  result = FrameworkConstants::Result[:pass]
  Dir.foreach(local_res_dir) do |local_res_file|
    next if !local_res_file.match(/\.json$/)
    File.open(File.join(local_res_dir, local_res_file)) do |fd|
      test_results = JSON.load(fd)
      test = test_results['test_id']
      test_results['results'].each do |result|
        res = "#{result['gfx_result']['surface_width']}x#{result['gfx_result']['surface_height']}"
        perf_data << {'name' => "fps-#{res}-#{test}",
                      'units' => 'fps',
                      'values' => result['gfx_result']['fps']}
        perf_data << {'name' => "r-#{res}-#{test}",
                      'units' => result['unit'],
                      'values' => result['score']}
        if result['status'] != 'OK'
          result = FrameworkConstants::Result[:fail]
          res_string += "Test #{test} (#{result['error_string']})failed\n"
        end
      end
    end
  end
  set_result(result, res_string , perf_data)
end

def parse_units(units)
  return units if units.length <= 10
  s_units = units.split('/')
  return units if s_units.length < 2
  max_index = [9 - s_units.min.length, 5].max - 1
  return [s_units[0][0..max_index], s_units[1][0..max_index]].join('/') 
end
