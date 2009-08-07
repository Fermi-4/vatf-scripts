require '../../TestPlans/LSP/Common/default_perf.atp.rb'

#---
#:section: General
# Test Area:: Video V4L2 Capture
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




class Video_perf_v4l2_captureTestPlan < Default_perfTestPlan
 # BEG_USR_CFG get_params
  def get_params()
    this_params = 
    {
      'dev_node'      		=> ['/dev/video0'],
      'test_type'	  		=> ['V4l2_capture'],
      'number_of_buffers' 	=> ['3'],
      'number_of_frames'   	=> ['500'],
      'mode'	  			=> ['NTSC', 'PAL', '480P-60', '576P-50'],  
    }
    super().merge(this_params)
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
      this_params = {
         'description'  => "#{params['test_type']} #{params['mode']} Performance test", 
         'script'       => 'LSP\A-Video\default_perf_video_script.rb',
         'paramsChan'   => {
            'dev_node'       	=> "#{params['dev_node']}",
            'number_of_buffers' => "#{params['number_of_buffers']}",
            'number_of_frames'  => "#{params['number_of_frames']}",
            'mode'      		=> "#{params['mode']}",
            'test_type'	 		=> "#{params['test_type']}",
            'target_sources' 	=> 'dsppsp-validation\psp_test_bench',
            }
        } 
    super(params).merge(this_params)
  end
  # END_USR_CFG get_outputs
  
end
