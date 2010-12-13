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
  browser.goto "http://v8.googlecode.com/svn/data/benchmarks/v6/run.html"
  log_data "Page title: #{browser.title}"
  WatirWebDriver.wait_timeout = 300       # Increase default 2 min timeout to 5 min to wait for test completion
  WatirWebDriver.wait_until { browser.div(:id, "status").text.include? "Score" }
  score= /Score:\s*([\d\.]+)/.match(browser.div(:id, "status").text).captures[0]
  perfdata = []
  perfdata << {'name' => 'v8', 'value' => score.to_f, 'units' => ''} if score
  log_data "\n\n==========\n#{browser.div(:id, "results").text}\n============\n\n"
  log_data "Test Completed!!!"
   ensure
    if score && score.to_i >= @test_params.params_control.min_score[0].to_i
      set_result(FrameworkConstants::Result[:pass], "Test Passed. #{score} >= #{@test_params.params_control.min_score[0]} ", perfdata)
    elsif score
      set_result(FrameworkConstants::Result[:fail], "Test Failed. #{score} < #{@test_params.params_control.min_score[0]} ", perfdata)
    else
      set_result(FrameworkConstants::Result[:fail], 'Performance data is missing')
    end
end


def log_data(data)
  puts data
  @results_html_file.add_paragraph(data,nil,nil,nil)
end


