# Stress test recipe for NOR.
class Nor_stressTestPlan < Nor_func_premTestPlan
    
  # BEG_USR_CFG get_params
  def get_params()
    append_params = 
    {
      'file_size'   => [5*1024*1024, 10*1024*1024],
      'buffer_size' => [500*1024, 1*1024*1024],
      'make_name'   => ['AMD', 'Intel'],
      'test_type'   => ['write-read'],
      'test_duration' => ['12'], # in hours
    }
    super().merge(append_params)
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    this_outputs = 
    {
      'paramsChan'     => {
        'target_sources' => 'LSP\st_parser',
        'file_size'   => params['file_size'],
        'buffer_size' => params['buffer_size'],
        'test_type'   => params['test_type'],
        'test_file'   => params['test_file'],
        'mnt_point'   => params['mnt_point'],
        'device_node' => params['device_node'],
        'cmd'   => "mount -t #{params['fs_type']} #{params['device_node']} #{params['mnt_point']}" +
                    ";mount`++#{params['mnt_point']}`;[dut_timeout\\=30]" +
                    ";#{get_cmd(params['test_type'], params['file_size'], params['buffer_size'], params['test_file'])}",
        'test_duration' => params['test_duration'],
      },
    
      'script'        => 'LSP\default_fs_api_script.rb',
      'description'   => "Stress Test: Verify that the driver can handle File IO of #{params['file_size']} with buffer size" +
                        " #{params['buffer_size']} for preemption #{params['microType']} mode for #{params['test_duration']} hours.",      
    }
    super(params).merge(this_outputs)
  end
  # END_USR_CFG get_outputs
  
end #END_CLASS
