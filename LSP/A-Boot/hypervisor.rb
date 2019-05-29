require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def run

    cpu_mode_match = @equipment['dut1'].boot_log.match(/CPU: All CPU.*? started (in|at)\s+(\w+)/)
    if (cpu_mode_match)
       if (cpu_mode_match.captures[0] == "EL2")
         set_result(FrameworkConstants::Result[:pass], "CPUs start in EL2 confirming basic HYP mode support")
       else
         set_result(FrameworkConstants::Result[:fail], "Check starting mode of CPUs - not EL2 as expected")
       end
    else
      set_result(FrameworkConstants::Result[:fail], "Expected string for CPU starting mode is not seen. Check if ATF is missing some capability")
    end   

end


