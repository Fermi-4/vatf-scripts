require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../webdriver_module' 
 
include AndroidTest
include WatirWebDriver

def run
  score=nil
  
  log_data "Creating Webdriver client"
  #browser = Watir::Browser.new(:remote, :url=>'http://localhost:8080/hub')   # For running on Android DUT
  browser = Watir::Browser.new()        # For running on Firefox in local PC
  log_data "Opening page"
  browser.goto "http://www2.webkit.org/perf/sunspider/sunspider.html"
  log_data "Page title: #{browser.title}"
  browser.link(:text, /Start\s+SunSpider\s+[\d\.]+\s+now/i).click
  WatirWebDriver.wait_until { !browser.text.include? "In Progress..." }
  
  score= /Total:\s+([\d\.]+)ms/.match(browser.text).captures[0]
  perfdata = []
  perfdata << {'name' => 'sunspider', 'value' => score.to_f, 'units' => 'ms'} if score
  
  log_data "\n\n==========\n#{browser.text}\n============\n\n"
  log_data "Test Completed!!!"
   ensure
    if score && score < @test_params.params_control.max_exec_time[0]
      set_result(FrameworkConstants::Result[:pass], "Test Passed. Total time #{score} < #{@test_params.params_control.max_exec_time[0]} ", perfdata)
    elsif score
      set_result(FrameworkConstants::Result[:fail], "Test Failed. Total time #{score} > #{@test_params.params_control.max_exec_time[0]} ", perfdata)
    else
      set_result(FrameworkConstants::Result[:fail], 'Performance data is missing')
    end
end


def log_data(data)
  puts data
  @results_html_file.add_paragraph(data,nil,nil,nil)
end









