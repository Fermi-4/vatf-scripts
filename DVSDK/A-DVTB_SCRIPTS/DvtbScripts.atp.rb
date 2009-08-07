require '../media_filer_utils'

include MediaFilerUtils

class DvtbScriptsTestPlan < TestPlan
    
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
    @res_params = {
    'media_source' => ['dvd','camera'],
    'audio_in_ifaces' => ['rca;xlr;optical;mini35mm;mini25mm;phoneplug'],
    'audio_out_ifaces' => ['rca;xlr;optical;mini35mm;mini25mm;phoneplug'],
    'video_in_ifaces' => ['vga;component;composite;svideo;hdmi;dvi;sdi;scart'],
    'video_out_ifaces' => ['vga;component;composite;svideo;hdmi;dvi;sdi;scart'],
    'dvtb_scripts_dir' => ['dvtb_scripts'],
  }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    []
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
       'testcaseID'     => "dvtb_scripts.#{@current_id}",
       'description'    => "Dvtb Scripts Test",
       'ext' => false,
       'iter' => '1',
       'bft' => false,
       'basic' => true,
       'ext' => false,
       'bestFinal' => false,
       'script' => 'Common\A-DVTB_SCRIPTS\dvtb_scripts.rb',
       'configID' => '..\Config\dvtb_scripts.ini',
       'reg'                       => true,
       'auto'                     => true,
       'paramsChan' => {
        'media_source' => params['media_source'],
        'audio_in_ifaces' => params['audio_in_ifaces'],
        'audio_out_ifaces' => params['audio_out_ifaces'],
        'video_in_ifaces' => params['video_in_ifaces'],
        'video_out_ifaces' => params['video_out_ifaces'],
       },
       'paramsEquip' => {
       },
       'paramsControl' => {
          'dvtb_scripts_dir' => params['dvtb_scripts_dir']
       },
     }
   end
  # END_USR_CFG get_outputs

end
