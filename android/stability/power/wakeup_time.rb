require File.dirname(__FILE__)+'/suspend_resume_default'


def on_suspend_test() 
  run_video_test()
end 


def before_resume_test()
  fps_values = Array.new()
  fps_values = get_fps
  mean_fps = mean(fps_values)
  return mean_fps
end 

def on_resume_test(initial_bw_value,initial_fps_value)
  fps_values = Array.new()
  fps_values = get_fps
  cmd  = " logcat -d -s SoftwareRenderer" 
  puts "waiting for the video to resume"
  response = send_adb_cmd cmd 
  time1 = Time.now.to_f
  puts response
  puts "******** full wakeup time is: #{time1}"  
  return time1
end 
