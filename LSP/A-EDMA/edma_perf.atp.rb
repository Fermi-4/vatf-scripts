require '../../TestPlans/LSP/Common/default_perf.atp.rb'

#---
#:section: General
# Test Area:: EDMA 
# Test Type:: Performance
# Test Owners::  (TII), Yan Liu (TIGT)
#---

#---
#:section: Overview
#---

#---
#:section: References
# None.
#---

#---
#:section: Required Hardware
#---

#---
#:section: Setup
#---

#---
#:section: Test Focus
#---

#---
#:section: Tests not included/ Future Enhancements
#---

#---
#:section: Test Parameters & Constraints
# See get_params() method at Ata_perfTestPlan class
#---




class Edma_perfTestPlan < Default_perfTestPlan
   # BEG_USR_CFG get_params
  def get_params()
    this_params = 
    {
      'test_type'	  		=> ['Edma'],  
      'test_module'	  		=> ['edmaAsyncIncr.ko', 'edmaABsyncIncr.ko', 'qdmaAsyncIncr.ko', 'qdmaABsyncIncr.ko'],
    }
    super().merge(this_params)
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
      this_params = {
         'description'  => "#{params['test_module'].gsub(/\.ko/,'')}  Performance test", 
         'script'       => 'LSP\A-EDMA\edma_perf_script.rb',
         'paramsChan'   => {
            'test_type'	 		=> "#{params['test_type']}",
            'test_module'	 	=> "#{params['test_module']}",
            'target_sources' 	=> 'dsppsp-validation\psp_test_bench',
            }
        } 
    super(params).merge(this_params)
  end
  # END_USR_CFG get_outputs
  
end
