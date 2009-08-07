class Alsa_funcTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['sample_rate', 'bits', 'fsize', 'audio_hw_in', 'audio_hw_out', 'test_duration', 'dsp'] 
    @sort_by = ['sample_rate', 'bits', 'fsize', 'audio_hw_in', 'audio_hw_out', 'test_duration', 'dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
    {
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['dma'],    # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
        'custom'    => ['default'],
		
		
        # DEBUG-- Remove these after debugging & uncomment above line -- 'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        # 'platform' => ['dm355'],
        # 'os' => ['linux'],
        # 'target' => ['210_lsp'],
    },
      ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
		'audio_mode_in'	=> ['mono_one_channel', 'stereo_two_channel', 'none'],
		'audio_hw_in'	=> ['mic', 'stereo_single_ended', 'stereo_differential', 'none'],
		'audio_hw_out'  => ['differential_line_out', 'single_ended_headphone', 'spdif', 'none'],
		'audio_mode_out' => ['mono_one_channel', 'stereo_two_channel', 'none'],
		'bits'	=> ['8', '16','24', '32'],
		'sample_rate'  => ['8', '16', '22.05', '32', '44.1', '48', '64', '88.4', '96'], #in kbps
		'test_duration'	=> ['5', '10', '20'], #test run time in ms, remember to code this time properly!!!!
    	'fsize'     => ['16', '64', '256', '1024', '4096', '8192'],    # in bytes
		'test_type'	=> ['capture', 'playback', 'capture & playback'],
		'test_mix' => ['stereo_in & stereo_out', 'mono_one_channel_in & stereo_two_channel_out', 'stereo_two_channel_in & mono_one_channel_out', 'none'],
		
		
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
	#{} @ 2
	 'IF [audio_hw_in]= "mic" THEN [audio_mode_in] IN {"mono_one_channel"};',
	 'IF [audio_hw_in]= "mic" THEN [audio_hw_out] IN {"single_ended_headphone"};',
	 'IF [audio_hw_in]= "mic" THEN [test_mix] IN {"mono_one_channel_in & stereo_two_channel_out"};',
	 'IF [test_type]= "capture" THEN [audio_hw_in] NOT IN  {"none"};',
	 'IF [test_type]= "capture" THEN [audio_hw_out]  IN  {"none"};',
	 'IF [test_type]= "capture" THEN [test_mix]  IN  {"none"};',
	 'IF [test_type]= "capture" THEN [audio_mode_out] IN  {"none"};',
	 'IF [test_type]= "capture" THEN [audio_mode_in] NOT IN  {"none"};',
	 'IF [test_type]= "capture & playback" THEN [test_mix] <>  "none";',
	 'IF [test_type]= "capture & playback" THEN [audio_hw_out] <>  "none";',
	 'IF [test_type]= "capture & playback" THEN [audio_hw_in] <>  "none";',
	 'IF [test_type]= "capture & playback" THEN [audio_mode_in] <>  "none";',
	 'IF [test_type]= "capture & playback" THEN [audio_mode_out] <> "none";',
	 'IF [test_type]= "playback" THEN [audio_mode_in] IN  {"none"};',
	 'IF [test_type]= "playback" THEN [audio_hw_in] IN  {"none"};',
	 'IF [test_type]= "playback" THEN [test_mix] IN  {"none"};',
	
	 #'IF [audio_input_driver] = "none" THEN [audio_output_driver] <> "none";',
	 #'IF [audio_type] = "stereo" THEN [audio_sampling_rate] NOT IN {24000};',
	 #'IF [audio_type] = "mono" THEN [audio_sampling_rate] NOT IN {12000,32000,88000};'
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)

    {
      'paramsChan'     => {
		'audio_mode_in' => params['audio_mode_in'],
		'audio_hw_in' => params['audio_hw_in'],
		'audio_mode_out' => params['audio_mode_out'],
		'audio_hw_out' => params['audio_hw_out'],
		'bits'		   => params['bits'],
		'sample_rate'  => params['sample_rate'],
		'test_duration' => params['test_duration'],
		'fsize' 		=> params['fsize'],
		'test_mix'		=> params['test_mix'],
        # 'target_sources' => 'LSP\st_parser',
        # 'op_mode'   => params['op_mode'],
        # 'power_mode'  => params['power_mode'],
        # 'lba_mode'  => params['lba_mode'],
        # 'file_size' => params['file_size'],
        # 'append_size' => params['append_size'],
        # 'buffer_size' => params['buffer_size'],
        # 'test_type'   => params['test_type'],
        # 'test_file'   => params['test_file'],
        # 'mnt_point'   => params['mnt_point'],
        # 'device_node' => params['device_node'],
        # 'cmd'   => "#{get_power_mode_cmd(params['power_mode'])};#{set_opmode(params['op_mode'])};[dut_timeout\\=30];#{get_cmd(params['test_type'], params['file_size'], params['buffer_size'], params['append_size'], params['test_file'])}",
        # 'ensure'  => "[dut_timeout\\=30];rm #{params['test_file']}"
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      # 'description'    => get_desc("Verify for #{params['chan_type'].upcase} channel with #{params['transfer_type'].upcase}" +
                          # " + #{params['addr_mode'].upcase} + #{params['features'].upcase}, data with size #{params['file_size']} bytes transfer sucessfully", params['test_switch']),
      # 'description'     => "Verify the #{params['test_type']} operation on a file of size #{params['file_size']}" +
                          # " with buffer size #{params['buffer_size']} on operation mode #{params['op_mode']} on hard disk.",
            'description'  =>"Verify the Audio Device #{params['test_type']} works fine when #{what_test_type(params['test_type'], params['audio_hw_in'], params['audio_hw_out'])} #{what_test_mix(params['test_mix'])}."+ 
				"\r\n Test Procedure configuration >>>"+
				"\r\n 1.Configure required op-mode"+ #defaults options found in add_params, excluded from this list.
				"\r\n 2.bits #{params['bits']}"+
				"\r\n 3.sample_rate kbps #{params['sample_rate']} "+
				"\r\n 4.audio_mode_in #{params['audio_mode_in']}"+
				"\r\n 5.audio_hw_in #{params['audio_hw_in']}"+
				"\r\n 6.audio_mode_out #{params['audio_mode_out']}"+
				"\r\n 7.audio_hw_out #{params['audio_hw_out']}"+			
				"\r\n 8.set test_duration #{params['test_duration']}"+
				"\r\n 9.Close the device",	
      'testcaseID'      => "alsa_func_#{@current_id}",
      'script'          => 'LSP\A-ATA\ata.rb', #hn don't forget to change this
      
      'configID'        => '..\Config\lsp_generic.ini', # don't forget to check if this has to be changed
      'iter'            => "1",

    }
  end
  # END_USR_CFG get_outputs
  
  # private
   # def GetNextTestId
	# @test_id_start++ # format this however is required
  # end

	

=begin
	def get_desc2(mode)
		rtn = case mode
		when 'mono': "1 mono channel"
		when 'stereo': "2 stereo channels"
	end
=end	

def what_test_type(test_type, audio_hw_in, audio_hw_out)
	rtn = case test_type
		when 'capture': "taking input from #{audio_hw_in}"
		when 'playback': "output is sent to #{audio_hw_out}"
		when 'capture & playback': "taking input from #{audio_hw_in} and  output to #{audio_hw_out}"
	end
end	
def what_test_mix(test_mix)
	rtn = case test_mix
		when 'stereo_in & stereo_out': "stereo_in & stereo_out"
		when 'mono_one_channel_in & stereo_two_channel_out': "mono_one_channel_in & stereo_two_channel_out"
		when 'line in mono & line out stereo': "line in mono & line out stereo"
		end
end
end
