require 'find'
require '../media_filer_utils'

include MediaFilerUtils

class DvtbMpeg4G711DecFileFuncTestPlan < TestPlan
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
						'video_bit_rate'		  => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000],
					    'video_resolution'		  => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576', '128x96', '320x240', '640x480', '704x288', '704x480'],
					    'video_num_channels'				=> [1,8],
					    'audio_companding' => ['ulaw','alaw'],
					    'audio_num_channels' => [1,4],
					}
	@ulaw_audio_source_hash = get_source_files_hash("\\w+","u")
	@alaw_audio_source_hash = get_source_files_hash("\\w+","a")
	@video_source_hash = get_source_files_hash("\\w+_",common_params['video_resolution'],"\\w*_",common_params['video_bit_rate'],"bps\\w*","mpeg4")	
	file_bit_rate = Array.new
	common_params['video_bit_rate'].each do |video_br|
		if video_br.to_f/1000 >= 1000
			file_bit_rate << ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
		else
			file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
	end
	@video_source_hash.merge!(get_source_files_hash("\\w+_",common_params['video_resolution'],"\\w*_",file_bit_rate,"\\w*","mpeg4"))
	video_res_and_bit_rate = [{
		'video_resolution' => ['352x288'],
		'video_bit_rate'  => [1000000,2000000,512000,64000,128000,256000,1500000,350000,500000,800000,96000],
	},
	{
		'video_resolution' => ['720x576'],
		'video_bit_rate'  => [256000,4000000,1000000,8000000,2000000,800000,512000,6000000,10000000],
	},
	{
		'video_resolution' => ['176x144'],
		'video_bit_rate'  => [2000000,64000,800000,96000,256000,1000000],
	},
	{
		'video_resolution' => ['128x96'],
		'video_bit_rate'  => [64000],
	},
	{
		'video_resolution' => ['704x480'],
		'video_bit_rate'  => [128000,1000000,512000,2000000,1100000,1500000],
	},
	{
		'video_resolution' => ['352x240'],
		'video_bit_rate'  => [128000,64000,512000,1000000,500000,350000,800000,256000,1500000,96000],
	},
	{
		'video_resolution' => ['640x480'],
		'video_bit_rate'  => [4000000,2000000,512000,1000000,786000],
	},
	{
		'video_resolution' => ['176x120'],
		'video_bit_rate'  => [128000,256000,64000,800000,96000],
	},
	{
		'video_resolution' => ['320x240'],
		'video_bit_rate'  => [256000,512000,768000,1000000],
	},
	{
		'video_resolution' => ['720x480'],
		'video_bit_rate'  => [6000000,128000,384000,800000,2000000,4000000,256000,512000,1000000,10000000],
	},
	]
	combine_res_and_bit_rate(common_params, video_res_and_bit_rate)
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
	'description'		=>"MPEG4 + G711 Decode from file Functionality Test for video resolution = #{get_video_resolution(params)}, video bit rate = #{get_video_bit_rate(params)}, and audio companding = #{params['audio_companding']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mpeg4_g711_dec_file_func.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => false,
    'bestFinal'               => false,
    'script'                     => 'Common\A-DVTB_MPEG4_G711_DEC_FILE\dvtb_mpeg4_g711_dec_file_func.rb',

    # channel parameters
    'paramsChan'                => {
        	'video_bit_rate' => get_video_bit_rate(params),
			'video_height' => get_video_height(params),
			'video_width' => get_video_width(params),
			'video_source' => get_video_source(params),
			'audio_source' => get_audio_source(params),
			'audio_companding' => params['audio_companding'],
    }, 
    'paramsEquip'     => {
    },
    'paramsControl'     => {
    		'audio_num_channels' => params['audio_num_channels'],
			'video_num_channels' => params['video_num_channels'],
    },
    'configID'      => '..\Config\dvtb_mpeg4_g711_dec_file_func.ini',
    'last'            => true,
   }
  end
  # END_USR_CFG get_outputs
  
   private
  
    def get_audio_source(params)	
        if params['audio_companding'].eql?("ulaw")
	        @ulaw_audio_source_hash["\\w+"]
        elsif params['audio_companding'].eql?("alaw")
	        @alaw_audio_source_hash["\\w+"]
        end	
    end
  
  def get_video_source(params)
      video_resolution = get_video_resolution(params)
      video_bit_rate = get_video_bit_rate(params)
		result = @video_source_hash["\\w+_"+video_resolution+"\\w*_"+video_bit_rate+"bps\\w*"]
		if video_bit_rate.to_f/1000 >= 1000
			file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
		else
			file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
		result += ";" if result && @video_source_hash["\\w+_"+video_resolution+"\\w*_"+file_bit_rate+"\\w*"]
		result = result.to_s+@video_source_hash["\\w+_"+video_resolution+"\\w*_"+file_bit_rate+"\\w*"].to_s if @video_source_hash["\\w+_"+video_resolution+"\\w*_"+file_bit_rate+"\\w*"]
		result
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
