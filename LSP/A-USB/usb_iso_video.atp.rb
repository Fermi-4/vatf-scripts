require '../../TestPlans/LSP/Common/default_perf.atp.rb'

#---
#:section: General
# Test Area:: USB ISO Video Capture
# Test Type:: Performance
# Test Owners:: Prathap (TII), Arun Mani (TIGT)
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




class Usb_iso_videoTestPlan < Default_perfTestPlan
 # BEG_USR_CFG get_params
  def get_params()
    this_params = 
    {
      'test_type'	  				=> ['Usb_iso_video'],
      'dev_node'      				=> ['/dev/video1'],
      'number_of_frames' 			=> ['500'],
      'file_save_frames_divider' 	=> ['5'],
      'file_name'	  				=> ['USB.yuv'],  
    }
    super().merge(this_params)
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
      this_params = {
         'description'  => "#{params['test_type']} Performance test", 
         'script'       => 'LSP\A-Video\default_perf_video_script.rb',
         'paramsChan'   => {
            'test_type'	 				=> "#{params['test_type']}",
            'dev_node'       			=> "#{params['dev_node']}",
            'number_of_frames' 			=> "#{params['number_of_frames']}",
            'file_save_frames_divider'  => "#{params['file_save_frames_divider']}",
            'file_name'      			=> "#{params['file_name']}",
            'target_sources' 			=> 'dsppsp-validation\psp_test_bench',
            }
        } 
    super(params).merge(this_params)
  end
  # END_USR_CFG get_outputs
  
end
