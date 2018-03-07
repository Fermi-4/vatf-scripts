require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../f2f_utils'
require 'json'

include AndroidTest

def run
  apk_path = File.join(@linux_temp_folder, File.basename(@test_params.params_chan.apk_url[0]))
  wget_file(@test_params.params_chan.apk_url[0], apk_path)
  pkg = installPkg(apk_path, 'kishonti.gfxbench',true, 300)
  #clear the old files if any
  send_adb_cmd("shell rm -rf /sdcard/Android/data/#{pkg}/files/results/*")
  local_res_dir = File.join(@linux_temp_folder, 'gfxbenchmark')
  Dir.mkdir(local_res_dir) if !File.exist?(local_res_dir)
  @equipment['server1'].send_cmd("rm -rf #{local_res_dir}/*")
  send_adb_cmd("logcat -c")
  send_adb_cmd("shell am start -W -n #{pkg}/net.kishonti.app.MainActivity -a android.intent.action.MAIN -c android.intent.category.LAUNCHER")
  send_adb_cmd("logcat  -c")
  send_events_for(['__tab__', '__tab__', '__tab__', '__enter__'])
  data = wait_for_logcat(/Initialization:\s*After\s*Init\s*net.kishonti.app.MainActivity/, 15)
  raise "Benchmark was not able to start" if !data.match(/Initialization:\s*After\s*Init\s*net.kishonti.app.MainActivity/)
  send_events_for(['__directional_pad_up__', '__enter__'])
  timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.instance_variable_defined?(:@timeout).to_i : 60
  wait_for_logcat(/ActivityManager:\s*START.*?act=net.kishonti.benchui.ACTION_SHOW_RESULT.*?cmp=#{pkg}\/net.kishonti.app.MainActivity/, timeout)
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
          res_string += "Test #{test} (#{result['error_string']}) failed\n"
        end
      end
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
