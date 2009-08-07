require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg4AspTestPlan < TestPlan
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
    
  #Test Matrix Comments/Review
     # - Which audio files are used for audio decode test cases
     # - Can we changed the video reference files. Is there a file that we MUST use
     # - Is there a parameter to differentiate between constant & variable bit rate
     # - Are 3,6 & 8mbps valid bit rates (they are used in decode test cases)?
    
    
    'video_frame_rate'		  => [5, 10, 15, 25, 30],
    'video_bit_rate'		  => [64000, 128000, 192000, 256000, 384000, 512000, 768000, 1000000, 1500000, 2000000, 2500000, 3000000, 4000000,  6000000, 8000000, 10000000],
    'video_resolution'		  => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576',   '128x96', '320x240', '640x480', '704x288', '704x480'],
	'video_motion'		      => ['none', 'slow', 'fast'],
	'video_source'			  => ['camera', 'dvd', 'media_filer'],
    'video_input_chroma_format' => ['420p', '422i'],
	'video_region'				=> ['ntsc', 'pal'],
    'video_input_driver' => ['vpfe+encode','none'],
	'video_output_driver' => ['decode+vpbe','none'], 
    'num_channels'				=> [1,8],
    }
	file_bit_rate = Array.new
	params['video_bit_rate'].each{|bit_rate| file_bit_rate << bit_rate/1000}
	@video_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_SP_",file_bit_rate,"kbps\\w*","mpeg4")	
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
    #'IF [test_type] IN {"vid_capture-encode-decode-play", "vid_capture-encode-store", "vid_decode-play"} THEN ([audio_companding] = "mulaw" AND [audio_input] = "mic");',		# Ignore audio params for video-only tests
		#'IF [test_type] IN {"aud_capture-encode-decode-play", "aud_capture-encode-store", "aud_decode-play"} THEN ([video_frame_rate] = 25 AND [video_bit_rate] = 1000000 AND [video_resolution] = "720x576" AND [video_motion] = "none" AND [video_input] = "camera" AND [video_region] = "pal" AND [video_chroma_format] = "420p" AND [video_ref_files] ="football");',		# Ignore video params for audio-only tests
        # Constraints for Video Region
    'IF [video_region] IN {"ntsc"} THEN [video_resolution] IN {"128x96", "176x120", "320x240", "352x240", "640x480", "704x480", "720x480"};',
	'IF [video_region] IN {"ntsc"} THEN [video_frame_rate] <> 25;',
	'IF [video_region] IN {"pal"} THEN [video_resolution] IN {"128x96", "176x144", "320x240", "352x288", "640x480", "704x288", "720x576"};',
	'IF [video_region] IN {"pal"} THEN [video_frame_rate] <> 30;',
   # Constraints for STD bit-rate
   'IF [video_resolution] = "352x240" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {1000000,512000,256000};',
   'IF [video_resolution] = "720x480" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {1000000,2000000,2500000,4000000,5000000,8000000,512000,6000000};',
   'IF [video_resolution] = "176x144" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {10000,512000,1000000,32000,64000,96000,128000,256000};',
   'IF [video_resolution] = "352x288" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {64000,128000,1000000,2000000,256000,512000,1500000};',
   'IF [video_resolution] = "720x576" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {1000000,4000000,8000000,2000000,5000000};',
   'IF [video_resolution] = "320x240" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {1000000,256000,64000,128000,2000000,512000};',
   'IF [video_resolution] = "640x480" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {2000000,512000,1000000,4000000};',
   'IF [video_resolution] = "704x480" AND [video_source] = "media_filer" THEN [video_bit_rate] IN {1000000,512000,2000000,8000000,4000000,5000000,6000000,2500000};',
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
    'testcaseID'                 => "dvtb_mpeg4_asp.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => false,
    'bestFinal'                  => false,
    'script'                     => 'common\A-DVTB_MPEG4_ASP\dvtb_mpeg4_asp.rb',

    # channel parameters
    'paramsChan'                 => {
      'video_codec'              => 'mpeg4',
      'video_frame_rate'		=> params['video_frame_rate'],
      'video_bit_rate'          => params['video_bit_rate'],
	  'video_height'				=> get_video_height(params['video_resolution']), 
	  'video_width'					=> get_video_width(params['video_resolution']), 
	  'video_motion'				=> params['video_motion'],
	  'video_region'				=> params['video_region'],
      'video_input_chroma_format' => params['video_input_chroma_format'],
	  'video_source'           =>     get_video_source(params)
	  },
    
    
    'paramsEquip'     => {
      'NetworkDelay'             => 0,
    },
    'paramsControl'     => {
      'Iterations'                => 1, 
    },
    'configID'      => 'dvtb_mpeg4.ini',
    'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

  def get_video_source(params)
	if params['video_source'].eql?("media_filer")
		@video_source_hash["\\w+"+params['video_resolution']+"_SP_"+(params['video_bit_rate'].to_i/1000).to_s+"kbps\\w*"]
	else
		params['video_source']
	end
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
