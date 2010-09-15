require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

def run_collect_performance_data
  ser_out = get_serial_output.split(/[\n\r]+/)
  fps_array = []
  frame_counter = 0
  ser_out.each do |current_line|
   current_match = current_line.match(/frame\s*(\d+).*?FPS\s*([\d\.]+)\./i)
    if current_match 
      frame_counter += 1
      next if frame_counter < 5
      fps_array << current_match.captures[1].to_f
    end
  end
  perf_log = nil
  if (fps_array.length > 0)
    sample_mean = get_mean(fps_array)
    sample_stddev = Math.sqrt(get_variance(fps_array))
    sample_min = fps_array.min
    sample_max = fps_array.max
    sample_median = get_median(fps_array)
    
    perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
    perf_log.puts(@test_params.params_chan.cmd[0].gsub(/\.exe$/,'')+"_min_fps "+sample_min.to_s+" fps")
    perf_log.puts(@test_params.params_chan.cmd[0].gsub(/\.exe$/,'')+"_max_fps "+sample_max.to_s+" fps")
    perf_log.puts(@test_params.params_chan.cmd[0].gsub(/\.exe$/,'')+"_mean_fps "+sample_mean.to_s+" fps")
    perf_log.puts(@test_params.params_chan.cmd[0].gsub(/\.exe$/,'')+"_stddev_fps "+sample_stddev.to_s+" fps")
    perf_log.puts(@test_params.params_chan.cmd[0].gsub(/\.exe$/,'')+"_median_fps "+sample_median.to_s+" fps")
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([[@test_params.params_chan.cmd[0]+" fps",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["MIN",sample_min.to_s])
    @results_html_file.add_row_to_table(res_table,["MAX",sample_max.to_s])
    @results_html_file.add_row_to_table(res_table,["MEAN",sample_mean.to_s])
    @results_html_file.add_row_to_table(res_table,["STDDEV",sample_stddev.to_s])
    @results_html_file.add_row_to_table(res_table,["MEDIAN",sample_median.to_s])
  end
  ensure
  perf_log.close if perf_log
end

def run_determine_test_outcome
  if File.exists?(File.join(@wince_temp_folder,'perf.log'))
    [FrameworkConstants::Result[:pass], "This test pass"]
  else
    [FrameworkConstants::Result[:pass], "This failed no performance data was collected"]
  end
end

# This function is used to compute the mean value in an array
def get_mean(an_array)
  sum = 0
  an_array.each{|element| sum+= element}
  sum/(an_array.length)
end

# This function is used to compute the variance of the values in an array
def get_variance(an_array)
  mean = get_mean(an_array)
  sum = 0
  an_array.each{|element| sum+= (element-mean)**2}
  sum/(an_array.length-1)    
end

def get_median(an_array)
  sorted_array = an_array.sort
  array_length = sorted_array.length
  if sorted_array.length % 2 == 0
    (sorted_array[array_length/2] + sorted_array[(array_length/2)-1])/2
  else
    sorted_array[(array_length-1)/2]
  end
end

