require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg4TestPlan < TestPlan
  attr_reader :video_source_hash
  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
    params = {  
    'video_frame_rate'		  => [5, 10, 15, 25, 30],
    'video_bit_rate'		  => [64000, 128000, 192000, 256000, 384000, 512000, 768000, 1000000, 1500000, 2000000, 2500000, 3000000, 4000000,  6000000, 8000000, 10000000],
    'video_resolution'		  => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576', '128x96', '320x240', '640x480', '704x288', '704x480'],
	'video_motion'		      => ['none', 'slow', 'fast'],
	'video_source'			  => ['camera', 'dvd', 'media_filer'],
	'video_rate_control'=> [1,2,3,4,5], # 1 -> CBR, 2 -> VBR, 3 -> two-pass, 5 -> user defined 
	'video_encoder_preset' => [0,1,2,3], # 0 -> default, 1 -> high quality, 2 -> high speed, 3 -> user defined
    'video_input_chroma_format' => ['420p', '422i'],
	'video_region'				=> ['ntsc', 'pal'],
    'video_input_driver' => ['vpfe+encode','none'],
	'video_output_driver' => ['decode+vpbe','none'], 
    'video_num_channels'				=> [1,8],
    }
	@video_source_hash = get_source_files_hash("\\w+_",params['video_resolution'],"\\w*_",params['video_bit_rate'],"bps\\w*","mpeg4")	
	file_bit_rate = Array.new
	params['video_bit_rate'].each do |video_br|
		if video_br.to_f/1000 >= 1000
			file_bit_rate << ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
		else
			file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
	end
	@video_source_hash.merge!(get_source_files_hash("\\w+_",params['video_resolution'],"\\w*_",file_bit_rate,"\\w*","mpeg4"))
	params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    [
     # Constraints based on test type
     # Constraints for Video Region
    'IF [video_region] IN {"ntsc"} THEN [video_resolution] IN {"128x96", "176x120", "320x240", "352x240", "640x480", "704x480", "720x480"};',
	'IF [video_region] IN {"ntsc"} THEN [video_frame_rate] <> 25;',
	'IF [video_region] IN {"pal"} THEN [video_resolution] IN {"128x96", "176x144", "320x240", "352x288", "640x480", "704x288", "720x576"};',
	'IF [video_region] IN {"pal"} THEN [video_frame_rate] <> 30;',
	'IF [video_source] = "camera" THEN [video_input_chroma_format] = "422i";',
    # Constraints for CIF bit-rate
   'IF [video_resolution] IN {"352x288"} AND [video_source] = "media_filer" THEN [video_bit_rate] IN {1000000,2000000,512000,64000,128000,256000,1500000,350000,500000,800000,96000};',
   # Constraints for STD bit-rate
   'IF [video_resolution] = "720x576" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {256000,4000000,1000000,8000000,5000000,2000000,800000,512000,6000000,10000000};',
   'IF [video_resolution] = "176x144" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {2000000,64000,800000,96000,256000,1000000};',
   'IF [video_resolution] = "128x96" AND [video_source] = "media_filer" THEN [video_bit_rate] <= 64000;',
   'IF [video_resolution] = "704x480" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {128000,1000000,512000,2000000,1100000,1500000};',
   'IF [video_resolution] = "352x240" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {128000,64000,512000,1000000,500000,350000,800000,256000,1500000,96000};',
   'IF [video_resolution] = "640x480" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {4000000,2000000,512000,1000000,786000};',
   'IF [video_resolution] = "176x120" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {128000,256000,64000,800000,96000};',
   'IF [video_resolution] = "320x240" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {256000,512000,768000,1000000};',
   'IF [video_resolution] = "720x480" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {6000000,128000,384000,800000,2000000,4000000,256000,512000,1000000,10000000};',
   'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";',
   'IF [video_input_driver] = "none" THEN [video_source] = "media_filer";',
   'IF [video_input_driver] <> "none" THEN [video_source] <> "media_filer";'
   ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"test_type=#{(params['video_input_driver']+"+"+params['video_output_driver']).gsub(/\+{0,1}none/,"")}, video_res=#{params['video_resolution']}, frame_rate=#{params['video_frame_rate']},bit_rate=#{params['video_bit_rate']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mpeg4.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => false,
    'bestFinal'                  => false,
    'script'                     => 'common\A-DVTB_MPEG4\dvtb_mpeg4.rb',

    # channel parameters
    'paramsChan'                 => {
      'video_codec'              => 'mpeg4',
	  'test_type' => (params['video_input_driver']+"+"+params['video_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
      'video_frame_rate'		=> params['video_frame_rate'],
      'video_bit_rate'          => params['video_bit_rate'],
	  'video_rate_control'=>params['video_rate_control'],
	  'video_encoder_preset' => params['video_encoder_preset'],
	  'video_height'				=> get_video_height(params['video_resolution']), 
	  'video_width'					=> get_video_width(params['video_resolution']), 
	  'video_motion'				=> params['video_motion'],
	  'video_region'				=> params['video_region'],
      'video_input_chroma_format' => params['video_input_chroma_format'],
	  'video_source'           =>     get_video_source(params)
	  },
    
    
    'paramsEquip'     => {
    },
    'paramsControl'     => {
      'video_num_channels'              => params['video_num_channels'], 
    },
    'configID'      => 'dvtb_mpeg4.ini',
    'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

  def get_video_source(params)
	if params['video_source'].eql?("media_filer")
		result = @video_source_hash["\\w+_"+params['video_resolution']+"\\w*_"+params['video_bit_rate']+"bps\\w*"]
		if params['video_bit_rate'].to_f/1000 >= 1000
			file_bit_rate = ((params['video_bit_rate'].to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
		else
			file_bit_rate = ((params['video_bit_rate'].to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
		result += ";" if result && @video_source_hash["\\w+_"+params['video_resolution']+"\\w*_"+file_bit_rate+"\\w*"]
		result = result.to_s+@video_source_hash["\\w+_"+params['video_resolution']+"\\w*_"+file_bit_rate+"\\w*"].to_s if @video_source_hash["\\w+_"+params['video_resolution']+"\\w*_"+file_bit_rate+"\\w*"]
		result
	else
		result = params['video_source']
	end
	result
  end
  
  private
  def get_video_height(resolution)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
		res[2]
  end
  
  def get_video_width(resolution)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
		res[1]
  end
  
end
