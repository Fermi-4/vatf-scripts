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
        @hostScriptEquipment = equipment
        reset()

        if (test_params.params_chan.instance_variable_defined?(:@script))
            script = test_params.params_chan.instance_variable_get(:@script)[0]

            file = File.dirname(__FILE__) + "/" + script

            if (File.exists?(file) == true)
                @hostScriptEquipment['dut1'].log_info("Using script #{script}")
                @hostScriptName = script

                #Extract script arguments if they exist
                if (test_params.params_chan.instance_variable_defined?(:@scriptarg))
                    @hostScriptArgs.push(test_params.params_chan.instance_variable_get(:@scriptarg))
                end
            else
                @hostScriptEquipment['dut1'].log_info("Script #{script} was not found")
            end
        else
            puts "No host script was selected."
            equipment['dut1'].log_info("No host script was selected.")
        end
    end

    def reset()
        @appStatus = 'Not Executed!'
        @appStdOut = nil
        @appStdErr = nil
    end

    def execute(timeout=60)
        if (@hostScriptName != nil)
            puts "Executing script (Timeout: #{timeout}) #{@hostScriptName} #{@hostScriptArgs.join(" ")}"
            @hostScriptEquipment['dut1'].log_info("Executing script (Timeout: #{timeout}) #{@hostScriptName} #{@hostScriptArgs.join(" ")}")
            reset()


            stdin, stdout, stderr, wait_thr = Open3.popen3(@hostScriptName + " " +  @hostScriptArgs.join(" "),
                                                           :chdir => File.dirname(__FILE__),
                                                           :in => :close)

            puts "Waiting for host script to finish..."
            @hostScriptEquipment['dut1'].log_info("Waiting for host script to finish...")

            if wait_thr.join(timeout)
                puts "Host script finshed."
                @hostScriptEquipment['dut1'].log_info("Host script finished.")
                @appStatus = wait_thr.value.exitstatus.to_s
                @appStdOut = stdout.read
                @appStdErr = stderr.read
            else
                puts "Timeout waiting for the host script to finish."
                @hostScriptEquipment['dut1'].log_info("Timeout waiting for the host script to finish.")
                wait_thr.kill
                @appStatus = "Scripted timeout!"
                @appStdOut = stdout.read
                @appStdErr = stderr.read
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

