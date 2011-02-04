require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../webdriver_module' 
 
include AndroidTest
include WatirWebDriver

def setup
  super
  send_adb_cmd "forward tcp:8080 tcp:8080"  # Forward local tcp:8080 requests to android target
  install_selenium_server()
end

def run
  score=nil
  log_data "Creating Webdriver client"
  browser = Watir::Browser.new(:remote, :url=>'http://localhost:8080/hub')   # For running on Android DUT
  #browser = Watir::Browser.new()        # For running on Firefox in local PC
  log_data "Opening page"
  browser.goto "http://krakenbenchmark.mozilla.org/index.html"
  log_data "Page title: #{browser.title}"
  browser.link(:text, /Begin/i).click
  puts "\n==========#{browser.text}\n============"
  WatirWebDriver.wait_timeout = 3000      # Increase default 2 min timeout to 50 min to wait for test completion
  sleep 3000                    # TODO: Replace this fix delay with wait logic below.
                                #       The webdriver raises an "Element not found in the cache" error,
                                #       so using fix delay for now.
  #begin
  #  WatirWebDriver.wait_until { !browser.text.include? "In Progress" }
  #rescue Watir::Exception::Error => e
  #  puts "Rescue from Server Error"
  #  print e.backtrace.join("\n")
  #end
  
  puts "\n==========#{browser.text}\n============"
  score= /Total:\s+([\d\.]+)ms/.match(browser.text).captures[0]
  perfdata = []
  perfdata << {'name' => 'kraken', 'value' => score.to_f, 'units' => 'ms'} if score
  log_data "\n\n==========\n#{browser.text}\n============\n\n"
  log_data "Test Completed!!!"
   ensure
    if score && score.to_i < @test_params.params_control.max_exec_time[0].to_i
      set_result(FrameworkConstants::Result[:pass], "Test Passed. Total time #{score} < #{@test_params.params_control.max_exec_time[0]} ", perfdata)
    elsif score
      set_result(FrameworkConstants::Result[:fail], "Test Failed. Total time #{score} > #{@test_params.params_control.max_exec_time[0]} ", perfdata)
    else
      set_result(FrameworkConstants::Result[:fail], 'Performance data could not be obtained')
    end
end


def log_data(data)
  puts data
  @results_html_file.add_paragraph(data,nil,nil,nil)
end
