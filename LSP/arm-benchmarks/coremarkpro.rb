require File.dirname(__FILE__)+'/../TARGET/dev_test_perf_gov'

def calculate_coremarkpro_score()
    cmp_data = {}
    if File.exists?(File.join(@linux_temp_folder,'test.log'))
        data = File.new(File.join(@linux_temp_folder,'test.log'),'r').read
        data.scan(/Info: Starting Run.+?Done:[^\n]+/m) { |section|
            benchmark = section.match(/Workload:(\w+?)[-_=\d]/).captures[0]
            bfile = File.new(File.join(@linux_temp_folder,"cmp-#{benchmark}.out"),'w')
            bfile.write(section)
            bfile.close
        }
        @equipment['server1'].send_cmd("cd #{File.dirname(__FILE__)+'/script'}; DIR=#{@linux_temp_folder} ./get-coremarkpro-score.sh", "THIS IS NOT A VALID COREMARK-PRO SCORE")
        cmp_value = @equipment['server1'].response.match(/^CoreMark-PRO\s+([\d\.]+)\s/).captures[0]
        cmp_data = {'name' => 'CoreMark-Pro', 'value' => cmp_value, 'units' => ''}
    end
    return cmp_data
end


def run_save_results(return_non_zero)
    puts "\n Coremarkpro::run_save_results"
    result = run_determine_test_outcome(return_non_zero)
    if result.length == 3 && result[2] != nil
      perfdata = result[2]
      perfdata = perfdata << calculate_coremarkpro_score()
      perfdata = perfdata.concat(@target_sys_stats) if @target_sys_stats
      set_result(result[0],result[1],perfdata)
    elsif File.exists?(File.join(@linux_temp_folder,'perf.log'))
      perfdata = []
      data = File.new(File.join(@linux_temp_folder,'perf.log'),'r').readlines
      data.each {|line|
        if /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line)
          name,value,units = /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line).captures
          perfdata << {'name' => name, 'value' => value, 'units' => units}
        end
      }
      perfdata = perfdata.concat(@target_sys_stats) if @target_sys_stats
      set_result(result[0],result[1],perfdata)
    else
      set_result(result[0],result[1], @target_sys_stats)
    end
end
