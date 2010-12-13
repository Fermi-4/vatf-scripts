
module WatirWebDriver
  attr_accessor :wait_timeout
  require "rubygems"
  require "watir-webdriver"
  require "watir-webdriver/extensions/wait"

  @wait_timeout=120
  
  def wait_until (&block)
    start_time = Time.now
    until (block.call)  do
      sleep 0.2
      if Time.now - start_time> @wait_timeout
        raise RuntimeError, "Timed out after #{@wait_timeout} seconds"
      end
    end
  end

end