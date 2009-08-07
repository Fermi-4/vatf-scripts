require '../../TestPlans/LSP/Common/default_perf.atp.rb'

#---
#:section: General
# Test Area:: Video FBDEV Display
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




class Video_perf_fbdev_displayTestPlan < Default_perfTestPlan
   # BEG_USR_CFG get_params
  def get_params()
    this_params = 
    {
      'test_type'	  		=> ['Fbdev_display'],
      'dev_node'      		=> ['/dev/fb/0'],
      'number_of_buffers' 	=> ['2'],
      'number_of_frames'   	=> ['500'],
      'mode'	  			=> ['NTSC', 'PAL', '480P-60', '576P-50'],  
      'interface'			=> ['COMPOSITE', 'SVIDEO', 'COMPONENT']
    }
    super().merge(this_params)
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
	[
	'IF [interface] = "COMPOSITE" OR [interface] = "SVIDEO" THEN [mode] IN {"NTSC","PAL"};',
	'IF [interface] = "COMPONENT" THEN [mode] IN {"480P-60","576P-50"};',
	]
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
      this_params = {
         'description'  => "#{params['test_type']} #{params['mode']} #{params['interface']} Performance test", 
         'script'       => 'LSP\A-Video\default_perf_video_script.rb',
         'paramsChan'   => {
            'test_type'	 		=> "#{params['test_type']}",
            'dev_node'       	=> "#{params['dev_node']}",
            'number_of_buffers' => "#{params['number_of_buffers']}",
            'number_of_frames'  => "#{params['number_of_frames']}",
            'mode'      		=> "#{params['mode']}",
            'interface'			=> "#{params['interface']}",
            'target_sources' 	=> 'dsppsp-validation\psp_test_bench',
            'bootargs'			=> 'console\=ttyS0\,115200n8 noinitrd ip\=dhcp root\=/dev/nfs rw nfsroot\=${nfs_root_path}\,nolock mem\=116M ' + 'video\=davincifb:osd0\=720x576x16\,2025K:vid0\=720x576x16\,2500k:osd1\=720x576x16\,2025K:vid1\=720x576x16\,2500k'
            }
        } 
    super(params).merge(this_params)
  end
  # END_USR_CFG get_outputs
end
