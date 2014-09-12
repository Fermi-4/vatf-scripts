require File.dirname(__FILE__)+'/default_ccs'

include CcsTestScript

def setup
  self.as(CcsTestScript).setup
  install_package
end

def install_package
  raise "apps package was not defined. Check your build description" if !@test_params.instance_variable_defined?(:@apps)
  @apps_dir = File.join(@linux_temp_folder, get_checksum)
  if !File.exists? @apps_dir
    `mkdir -p #{@apps_dir}`
    `cp -vf #{@test_params.apps} #{@apps_dir}`
    `cd #{@apps_dir}; unzip #{File.basename @test_params.apps}`    
  end
  rescue Exception => e
    raise "Error installing apps\n"+e.to_s+"\n"+e.backtrace.to_s
end

def get_checksum
  if @test_params.apps.match(/_md5_([\da-f]+)/)
    return $1
  else
    return `md5sum #{@test_params.apps} | cut -d' ' -f 1 | tr -d '\n'`
  end
end

def get_apps_list(name)
  Dir.chdir @apps_dir
  apps = Dir.glob "**/#{name}/*"
  raise "\"#{name}\" directory was not included or is empty" if apps.empty?
  apps
end

def get_golden_json
  @golden_json = Dir.glob(File.join(@apps_dir, "**", "golden", "*.{json}"))
  @golden_json
end

def create_subtests_results_table
  table_title = Array.new()
  table_title << ['Test Case', {:width => "50%"}]
  table_title << ['Result', {:width => "10%"}]
  table_title << ['Notes', {:width => "40%"}]
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Sub-Tests Results",{:bgcolor => "336666", :colspan => table_title.length},{:color => "white"}]],{:border => "1",:width=>"100%"})
  table_title = table_title
  @results_html_file.add_row_to_table(res_table,table_title)
  res_table
end

def add_subtest_result(table,result)
  result_color = case result[1]
  when /PASSED/i
    "#00FF00"
  when /FAILED/i
    "#FF0000"
  when /SKIP/i
    "#FFFF00"
  end
  @results_html_file.add_row_to_table(table, [result[0], [result[1], {:bgcolor => result_color}], [result[2], {:align => "left"}]])
end



