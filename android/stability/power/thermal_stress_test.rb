require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../f2f_utils'

include AndroidTest

def run
    puts "------------------------"
    puts "Running Thermal Validation Test"

    # we get the board id for passing dut serial number
    # to adb
    test_activity = "com.amazon.thermalvalidationtest"
    dut = @equipment['dut1']
    puts " Android DUT id: #{dut.board_id}"

    base_url = @test_params.instance_variable_defined?(:@var_test_libs_root) ? @test_params.var_test_libs_root : 'http://gtautoftp.gt.design.ti.com/anonymous/android/common'
    # get the APK package and install it
    # APK location is specified in TestLink via 'var_test_libs_root'
    # parameter in build specification
    apk_path = File.join(@linux_temp_folder, @test_params.params_chan.apk[0])
    wget_file(base_url + '/' + @test_params.params_chan.apk[0], apk_path)
    pkg = installPkg(apk_path, test_activity, true)
    
    # root the device
    send_adb_cmd("root")
    send_adb_cmd("wait-for-device")
    send_adb_cmd("remount")

    if @test_params.params_chan.instance_variable_defined?(:@libs)
        @test_params.params_chan.libs.each do |t_lib|
            lib_path = File.join(@linux_temp_folder, t_lib)
            wget_file(base_url + '/' + t_lib, lib_path)
            send_adb_cmd("push #{lib_path} /system/lib")
        end
    end

    # push the test video to device
    # create the data directory as the app wants it
    if @test_params.params_chan.instance_variable_defined?(:@video)
        media_base_url = @test_params.instance_variable_defined?(:@var_media_root) ? @test_params.var_media_root : 'http://gtautoftp.gt.design.ti.com/anonymous/android/data/video'
        test_data_dir = "/sdcard/ThermalValidationTest"
        send_adb_cmd("shell mkdir -p #{test_data_dir}")
        # TODO: Need to get this via `test_libs_data` from build spec
        video_source = File.join(@linux_temp_folder, @test_params.params_chan.video[0])
        wget_file(media_base_url + '/' + @test_params.params_chan.video[0], video_source)
        puts video_source
        send_adb_cmd("push #{video_source} #{test_data_dir}/testvideo.mp4")
    end

    # clear the logcat and go to home screen
    send_adb_cmd("logcat -c")
    send_events_for('__home__')

    # Set the temp sysfs entries so that the app can read them
    send_adb_cmd("shell setprop cpu.temp.sensor.sysfs.node /sys/class/thermal/thermal_zone0/temp")
    send_adb_cmd("shell setprop gpu.temp.sensor.sysfs.node /sys/class/thermal/thermal_zone1/temp")
    send_adb_cmd("shell setprop core.temp.sensor.sysfs.node /sys/class/thermal/thermal_zone2/temp")

    # make sure you can read the sysfs entries
    send_adb_cmd("shell chmod 0444 /sys/class/thermal/thermal_zone0/temp")
    send_adb_cmd("shell chmod 0444 /sys/class/thermal/thermal_zone1/temp")
    send_adb_cmd("shell chmod 0444 /sys/class/thermal/thermal_zone2/temp")

    send_adb_cmd("shell chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq")
    send_adb_cmd("shell chmod 444 /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq")

    # start the test
    send_adb_cmd("shell am start -a android.intent.action.MAIN -n #{test_activity}/.MainActivity")

    # Automated validation criteria still under discussion
    # for now let test run for 10 mins and see if it runs without turning off
    activity_log_cmd = "shell dumpsys activity #{test_activity}"
    activity_log = send_adb_cmd activity_log_cmd
    max_iters = 30
    iters = 0
    while activity_log.to_s.include?("#{test_activity}/.MainActivity")
        sleep(60)
        iters += 1
        puts " Test ran for #{iters} minutes"
        activity_log = send_adb_cmd activity_log_cmd
        break if iters > max_iters
    end

    unless iters > max_iters
        puts " Could not run the test for specified time"
        puts "   check logs for any errors"
        set_result(FrameworkConstants::Result[:fail], "Test stopped before specified time\n")
        return
    end

    # Test ran for specified amount of time
    set_result(FrameworkConstants::Result[:pass], "Test passed");

    # kill the test
    send_adb_cmd("shell am force-stop #{test_activity}")
    send_adb_cmd("shell am kill #{test_activity}")
    ensure
        uninstallPkg(pkg) if pkg
end
