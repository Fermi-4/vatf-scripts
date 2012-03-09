require File.dirname(__FILE__)+'/suspend_resume_default'


def on_suspend_test() 
  run_graphic_test()
end 

def before_resume_test()
  fps_values = Array.new()
  fps_values = get_fps
  mean_fps = mean(fps_values)
  puts "Before RESUME FPS IS #{mean_fps}"
  return mean_fps
end 

def on_resume_test(initial_bw_value,initial_fps_value)
  fps_values = Array.new()
  fps_values = get_fps
  mean_fps = mean(fps_values)
  if mean_fps < (initial_fps_value - 8)
   puts "ON RESUME FPS IS #{mean_fps}" 
   return 0
  else 
   puts "ON RESUME FPS IS #{mean_fps}"
   return 1
  end 
end 

def mean(a)
 array_sum = 0.0
 a.each{|elem|
 array_sum = array_sum + elem.to_f
}
mean = array_sum/a.size
return mean
end
