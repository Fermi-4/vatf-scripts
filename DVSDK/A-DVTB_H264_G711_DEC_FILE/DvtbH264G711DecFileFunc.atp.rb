require 'find'
require '../media_filer_utils'

include MediaFilerUtils

class DvtbH264G711DecFileFuncTestPlan < TestPlan
  attr_reader :video_source_hash, :ulaw_audio_source_hash, :alaw_audio_source_hash
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@group_by = ['video_resolution_and_bit_rate']
	@sort_by = ['video_resolution_and_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
		common_params = {
		'video_bit_rate' => [1000000,1500000,10000000,128000,164000,176000,196000,2000000,256000,3000000,384000,4000000,5000000,512000,6000000,64000,768000,8000000,96000],
		'video_resolution' => ['80x60','128x96','152x136','176x120','176x144','300x300','320x240', '352x240', '352x288','602x402','640x480', '704x480', '704x576', '712x472','720x480', '720x576'],
		'video_num_channels' => [1,8],
		'audio_num_channels' => [1,8],
		'audio_companding' => ['ulaw','alaw'],
	}
	@ulaw_audio_source_hash = get_source_files_hash("\\w+","u")
	@alaw_audio_source_hash = get_source_files_hash("\\w+","a")
	file_bit_rate = Array.new
	common_params['video_bit_rate'].each do |video_br|
		if video_br.to_f/1000 >= 1000
			file_bit_rate << ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
		else
			file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
	end
	@video_source_hash = get_source_files_hash("\\w*",common_params['video_resolution'],"\\w*",file_bit_rate,"\\w*","264")	
	@video_source_hash.merge!(get_source_files_hash("\\w*",common_params['video_resolution'],"\\w*",common_params['video_bit_rate'],"bps\\w*","264"))
	video_res_and_bit_rates = [{'video_bit_rate' => [64000],
						  'video_resolution' => ['128x96'],
						},
	 {'video_bit_rate' => [256000],
						  'video_resolution' => ['152x136'],
						},
	 {'video_resolution' => ["176x120"],
						  'video_bit_rate' => [64000,96000,128000,256000],
						},
	 {'video_resolution' => ["176x144"],
						  'video_bit_rate' => [64000,96000,128000,256000,512000],
						},
	 {'video_resolution' => ["300x300"],
						  'video_bit_rate' => [512000],
						},
	 {'video_resolution' => ["320x240"],
						  'video_bit_rate' => [256000,512000,768000,1000000],
						},
	 {'video_resolution' => ["352x240"],
						  'video_bit_rate' => [64000,96000,128000,256000,384000,512000,768000,1000000,1500000,2000000],
						},
	 {'video_resolution' => ["352x288"],
						  'video_bit_rate' => [64000,256000,384000,512000,768000,1000000,2000000],
						},
	{'video_resolution' => ["602x402"],
						  'video_bit_rate' => [1000000],
						},
	{'video_resolution' => ["640x480"],
						  'video_bit_rate' => [512000,1000000,2000000,4000000],
						},
	{'video_resolution' => ["704x480"],
						  'video_bit_rate' => [256000,512000,2000000,3000000,4000000,8000000],
						},
	{'video_resolution' => ["704x576"],
						  'video_bit_rate' => [2000000,4000000,8000000],
						},
	{'video_resolution' => ["712x472"],
						  'video_bit_rate' => [2000000],
						},
	{'video_resolution' => ["720x480"],
						  'video_bit_rate' => [128000,256000,384000,512000,1000000,2000000,3000000,4000000,5000000,6000000,8000000,10000000],
						},
	{'video_resolution' => ["720x576"],
						  'video_bit_rate' => [1000000,2000000,4000000,5000000,10000000],
						},
	]
	combine_res_and_bit_rate(common_params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     [
		'{audio_num_channels, audio_companding} @ 2'
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_h264_g711_dec_file_func.#{@current_id}",
	     'description'    => "H.264+g711 Decoder Functionality Test using the encoders default values, a resolution of "+get_video_resolution(params)+",and a bit rate of "+get_video_bit_rate(params), 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_H264_G711_DEC_FILE\dvtb_h264_g711_dec_file_func.rb',
		 'configID' => 'dvtb_h264_g711_dec_file_func.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'video_bit_rate' =>get_video_bit_rate(params),
				'video_height' => get_video_height(params),
				'video_width' => get_video_width(params),
				'video_source' => get_source_file(params),
				'audio_source' => get_audio_source(params),
				'audio_companding' => params['audio_companding'],
	        },
		 'paramsEquip' => {
			},
		 'paramsControl' => {
			'audio_num_channels' => params['audio_num_channels'],
			'video_num_channels' => params['video_num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
def get_source_file(params)
       video_bit_rate = get_video_bit_rate(params)
       video_resolution = get_video_resolution(params)
	if video_bit_rate.to_f/1000 >= 1000
		file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
	else
		file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
	end
	video_source = @video_source_hash["\\w*"+video_resolution+"\\w*"+file_bit_rate+"\\w*"]
	video_source += ";" if video_source && @video_source_hash["\\w*"+video_resolution+"\\w*"+video_bit_rate+"bps\\w*"]
	video_source = video_source.to_s+@video_source_hash["\\w*"+video_resolution+"\\w*"+video_bit_rate+"bps\\w*"] if @video_source_hash["\\w*"+video_resolution+"\\w*"+video_bit_rate+"bps\\w*"]
	video_source
   end
   
   def get_audio_source(params)	
	if params['audio_companding'].eql?("ulaw")
		@ulaw_audio_source_hash["\\w+"]
	elsif params['audio_companding'].eql?("alaw")
		@alaw_audio_source_hash["\\w+"]
	end	
   end
  
   private
    def get_video_height(params)
      pat = /(\d+)x(\d+)/i
    res = pat.match(get_video_resolution(params))
	    res[2]
    end
  
    def get_video_width(params)
      pat = /(\d+)x(\d+)/i
    res = pat.match(get_video_resolution(params))
	    res[1]
    end
  
    def get_video_resolution(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
    end
  
    def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
    end
	
   def combine_res_and_bit_rate(dst_hash, array_of_hash=nil)
      result = Array.new
      array_of_hash = [{'video_bit_rate' => dst_hash['video_bit_rate'], 'video_resolution' => dst_hash['video_resolution']}] if !array_of_hash
      array_of_hash = [array_of_hash] if array_of_hash.kind_of?(Hash)
      array_of_hash.each do |val_hash|
          val_hash['video_resolution'].each do |video_resolution|
              val_hash['video_bit_rate'].each do |video_bit_rate|
              	result << video_resolution.to_s+"_"+video_bit_rate.to_s
              end
          end
      end
      dst_hash.delete('video_resolution')
      dst_hash.delete('video_bit_rate')
      dst_hash.merge!({'video_resolution_and_bit_rate' => result})
      dst_hash
  end  
end
