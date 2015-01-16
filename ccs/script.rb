require "open3"
require "timeout"
include Open3

=begin
Basic Script class that simplifies the execution of host scripts for TI-RTOS
=end
class Script
    attr_reader :hostScriptArgs
    attr_reader :appStatus
    attr_reader :appStdOut
    attr_reader :appStdErr
=begin
This function will extract the script name from the test parameters if one was defined.
Need to pass in the @test_params and @equipment instances so we can extract them
=end
    def initialize(test_params, equipment)
        @hostScriptName = nil
        @hostScriptArgs = []
        @appStatus = nil
        @appStdOut = nil
        @appStdErr = nil

        if (test_params.params_chan.instance_variable_defined?(:@script))
            script = test_params.params_chan.instance_variable_get(:@script)[0]

            file = File.dirname(__FILE__) + "/" + script

            if (File.exists?(file) == true)
                equipment['dut1'].log_info("Using script #{script}")
                @hostScriptName = script

                #Extract script arguments if they exist
                if (test_params.params_chan.instance_variable_defined?(:@scriptarg))
                    @hostScriptArgs.push(test_params.params_chan.instance_variable_get(:@scriptarg))
                end
            else
                equipment['dut1'].log_info("Script #{script} was not found")
            end
        else
            puts "No host script was selected."
            equipment['dut1'].log_info("No host script was selected.")
        end
    end

    def execute(timeout = 60)
        if (@hostScriptName != nil)
            puts "Starting script executing #{@hostScriptName} #{@hostScriptArgs.join(" ")}"

            @appStatus = nil
            @appStdOut = nil
            @appStdErr = nil

            #status is of type Process::Status
            begin
                output = error = stat = nil

                Timeout::timeout(timeout) do
                    output, error, stat = Open3.capture3(@hostScriptName + " " +  @hostScriptArgs.join(" "), :chdir => File.dirname(__FILE__))
                end

                if stat.exited?
                    @appStatus = stat.exitstatus()
                    @appStdOut = output
                    @appStdErr = error
                end
            rescue Timeout::Error => e
                @appStdOut = output
                @appStdErr = error
                puts "Error running host script #{e}"
            end
        end
    end

    def addArg(arg = "")
        @hostScriptArgs.push(arg)
    end

    def exists()
       @hostScriptName != nil ? true : false
    end

    def status()
       @appStatus
    end

    def stdout()
       @appStdOut.to_s
    end

    def stderr()
       @appStdErr.to_s
    end

    def to_s
        string = 'script Name: "' + @hostScriptName.to_s + '"' + "\n" +
                 'script Args: '  + @hostScriptArgs.to_s + "\n" +
                 'status code: "' + @appStatus.to_s      + '"' + "\n" +
                 'stdout:' + @appStdOut.to_s + "\n" +
                 'stderr:' + @appStdErr.to_s + "\n"
        string
    end
end

