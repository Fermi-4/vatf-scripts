require '../../TestPlans/LSP/Common/default_perf.atp.rb'

class Audio_alsa_perfTestPlan < Default_perfTestPlan
 # BEG_USR_CFG get_params
  def get_params()
    @dev_node= 'plughw:0\,0'
    this_params = 
    {
      'sampling_rate' => ['8000 32000 44100 48000 96000'],
      'buffer_size'   => ['4096'],
      'data_size'	  => ['5242880'],    
      'test_type'	  => ['Alsa']
    }
    super().merge(this_params)
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
      this_params = {
          'script'       => 'LSP\A-Audio\default_perf_audio_script.rb',
      	  'paramsChan'   => {
            'dev_node'       => @dev_node,
            'sampling_rate'  => "#{params['sampling_rate']}",
            'buffer_size'    => "#{params['buffer_size']}",
            'data_size'      => "#{params['data_size']}",
            'test_type'	 => "#{params['test_type']}",
            'target_sources' => 'dsppsp-validation\psp_test_bench',
            }
        } 
    super(params).merge(this_params)
  end
  # END_USR_CFG get_outputs
end
