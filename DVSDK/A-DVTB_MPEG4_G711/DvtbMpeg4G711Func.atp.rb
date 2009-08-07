require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg4G711FuncTestPlan < TestPlan
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
						'video_rate_control'=> [1,2,3,4,5], # 1 -> CBR, 2 -> VBR  , 3 -> two-pass (not supported in mpeg4sp), 4 -> no rate control is used, 5 -> user defined 
						'video_encoder_preset' => [0,1,2,3], # 0 -> default, 1 -> high quality, 2 -> high speed, 3 -> user defined. Only high quality is supported in mpeg4sp
						'video_frame_rate'		  => [5, 10, 15, 'std'],
						'video_bit_rate'		  => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000, 11000000, 12000000, 14000000, 15000000],
					    'video_resolution'		  => ['128x96', '176x120', '176x144', '320x240', '352x240', '352x288', '640x480', '704x288', '704x480', '704x576', '720x480', '720x576', '800x600', '1024x768', '1280x720', '1280x960'],
						'video_source'			  => ['camera', 'dvd', 'media_filer'],
					    'video_input_chroma_format' => ['420p', '422i'],
						'video_output_chroma_format' => ['420p', '422i'],
					    'video_input_driver' => ['vpfe+encode', 'vpfe+resizer+encode', 'encode', 'none'],
						'video_output_driver' => ['decode+vpbe','decode', 'none'], 
						'video_picture_rotation' => [0,90,180,270], #degrees of picture rotation
					    'video_num_channels' => [1,8],
						'media_time' => [30],
						'audio_input_driver' => ['apfe+encode', 'encode', 'none'],
		                'audio_output_driver' => ['decode+apbe', 'decode', 'none'],
		                'audio_companding' => ['ulaw','alaw'],
		                'audio_sampling_rate' => [8000],
		                'audio_source' => ['dvd','camera','media_filer'],
		                'audio_num_channels' => [1],
		                'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
						'audio_iface_type' => ['rca', 'xlr', 'optical', 'mini35mm',  'mini25mm', 'phoneplug'],
					}
					
	@video_source_hash = get_source_files_hash("\\w*",common_params['video_resolution'],"_\\w*_{0,1}",common_params['video_input_chroma_format'],"\\w*frames","yuv")
	file_bit_rate = Array.new
	common_params['video_bit_rate'].each do |bit_rate| 
		if bit_rate/1000 >= 1000
		   file_bit_rate << ((bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
		else
			file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
	end
	@video_source_hash = @video_source_hash.merge!(get_source_files_hash("\\w+",common_params['video_resolution'],"_",common_params['video_input_chroma_format'],"\\w*",common_params['video_bit_rate'],"bps","mpeg4"))
	@video_source_hash = @video_source_hash.merge!(get_source_files_hash("\\w+",common_params['video_resolution'],"_(ASP|SP)\\w*",file_bit_rate,"\\w*","mpeg4"))
	@ulaw_audio_source_hash = get_source_files_hash("\\w+","u")
	@alaw_audio_source_hash = get_source_files_hash("\\w+","a")
	@pcm_audio_source_hash = get_source_files_hash("\\w+_8KHz_\\w*Mono\\w*","pcm")
	video_res_and_bit_rates = [
		{
			'video_resolution' => ['128x96'],
			'video_bit_rate'  => [64000],
						},
		{
			'video_resolution' => ['176x120'],
			'video_bit_rate'  => [128000,256000,64000,800000,96000],
						},
		{
			'video_resolution' => ['176x144'],
			'video_bit_rate'  => [2000000,64000,800000,96000,256000,1000000],
						},
		{
			'video_resolution' => ['320x240'],
			'video_bit_rate'  => [256000,512000,768000,1000000],
						},
		{
			'video_resolution' => ['352x240'],
			'video_bit_rate'  => [128000,64000,512000,1000000,500000,350000,800000,256000,1500000,96000],
						},
		{
			'video_resolution' => ['352x288'],
			'video_bit_rate'  => [1000000,2000000,512000,64000,128000,256000,1500000,350000,500000,800000,96000],
						},
		{
			'video_resolution' => ['640x480'],
			'video_bit_rate'  => [4000000,2000000,512000,1000000,786000],
						},
		{
			'video_resolution' => ['704x480'],
			'video_bit_rate'  => [128000,1000000,512000,2000000,1100000,1500000],
						},
		{
			'video_resolution' => ['704x576'],
			'video_bit_rate'  => [128000,1000000,512000,2000000,1100000,1500000],
						},
		{
			'video_resolution' => ['720x480'],
			'video_bit_rate'  => [6000000,128000,384000,800000,2000000,4000000,256000,512000,1000000,10000000],
						},
		{
			'video_resolution' => ['720x576'],
			'video_bit_rate'  => [256000,4000000,1000000,8000000,2000000,800000,512000,6000000,10000000],
						},
		{
			'video_resolution' => ['800x600'],
			'video_bit_rate' =>  [1000000,2000000,4000000,7000000,10000000,11000000,12000000,14000000,15000000]	
						},
		{
			'video_resolution' => ['1024x768'],
			'video_bit_rate' =>  [1000000,2000000,4000000,8000000,10000000,11000000,12000000,14000000,15000000]		
						},
		{
			'video_resolution' => ['1280x720'],
			'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]		
						},
		{	'video_resolution' => ['1280x960'],
			'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]		
						},
	]
	@res_params = combine_res_and_bit_rate(common_params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    res_rate_string = ''
    @res_params['video_resolution_and_bit_rate'].each do |res_n_rate| 
		res_rate_string+='"'+res_n_rate+'",' if /(800x600)|(1024x768)|(1280x720)/.match(res_n_rate)
	end
    res_rate_string.gsub!(/,$/,'')
    [
	'IF [video_source] IN {"camera","dvd"} THEN [video_input_chroma_format] = "422i";',
	'IF [video_input_driver] NOT IN {"none","encode"} THEN [video_source] <> "media_filer";', 
	'IF [video_input_driver] IN {"none","encode"} THEN [video_source] = "media_filer";',
	'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";',
	'IF [video_output_driver] = "none" THEN [audio_output_driver] = "none";',
	'IF [audio_input_driver] <> "none" AND [video_output_driver] <> "none" THEN [audio_output_driver] <> "none";',
	'IF [audio_output_driver] <> "none" AND [video_input_driver] <> "none" THEN [audio_input_driver] <> "none";',
	'IF [video_input_driver] = "none" THEN [audio_input_driver] = "none";',
    'IF [video_input_driver] = "encode" THEN [video_output_driver] IN {"none","decode"} AND [audio_input_driver] IN {"none","encode"};',
    'IF [video_input_driver] <> "encode" THEN [audio_input_driver] <> "encode";',
	'IF [video_input_driver] NOT IN {"none", "encode"} THEN [video_output_driver] <> "decode";', 
	'IF [video_output_driver] = "decode" THEN [audio_output_driver] IN {"none","decode"};',
	'IF [video_output_driver] <> "decode" THEN [audio_output_driver] <> "decode";',
	'IF [audio_input_driver] IN {"none","encode"} THEN [audio_source] = "media_filer";',
	'IF [audio_input_driver] NOT IN {"none","encode"} THEN [audio_source] <> "media_filer";',
    'IF [audio_input_driver] = "encode" THEN [audio_output_driver] IN {"none","decode"};',
    'IF [audio_input_driver] NOT IN {"none","encode"} THEN [audio_output_driver] <> "decode";',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"test_type=#{get_test_type(params)}, video_res=#{get_video_resolution(params)}, frame_rate=#{get_video_frame_rate(params)},bit_rate=#{get_video_bit_rate(params)}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mpeg4_g711_func.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'               => false,
    'script'                     => 'Common\A-DVTB_MPEG4_G711\dvtb_mpeg4_g711.rb',

    # channel parameters
    'paramsChan'                =>  {
		  'video_rate_control'=>params['video_rate_control'],
		  'video_encoder_preset' => params['video_encoder_preset'],
     	  'video_frame_rate'		=> get_video_frame_rate(params),
          'video_bit_rate'          => get_video_bit_rate(params),
	      'video_height'				=> get_video_height(params), 
	      'video_width'					=> get_video_width(params), 
          'video_input_chroma_format' => params['video_input_chroma_format'],
		  'video_output_chroma_format' => params['video_output_chroma_format'],
	      'video_source'       => get_video_source(params),
		  'video_picture_rotation' => params['video_picture_rotation'],
	      'audio_companding' => params['audio_companding'],
	      'audio_codec' => "g711",
	      'audio_bit_rate' => 64000,
	      'audio_source' => get_audio_source(params),
	      'audio_sampling_rate' => params['audio_sampling_rate'],
	      'video_region' => get_video_region(params),
	      'test_type' => get_test_type(params),
	      'video_iface_type' => params['video_iface_type'],
		  'audio_iface_type' => params['audio_iface_type'],
	},   
    'paramsEquip'     => {
    },
    'paramsControl'     => {
          'media_time' => params['media_time'],
          'video_num_channels' => params['video_num_channels'],
          'audio_num_channels' => params['audio_num_channels'],
    },
    'configID'      => '..\Config\dvtb_mpeg4_g711.ini',
   }
  end
  # END_USR_CFG get_outputs

  def get_test_type(params)
	(params['video_input_driver']+"+"+params['video_output_driver']+"_"+params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"").gsub(/^_/,"").gsub(/_$/,"")
  end
  
  private
  def get_audio_source(params)
	if params['audio_source'].eql?('media_filer')
	  if params['audio_input_driver'].include?('encode')
		@pcm_audio_source_hash["\\w+_8KHz_\\w*Mono\\w*"]
	  else
		  if params['audio_companding'].eql?("ulaw")
			@ulaw_audio_source_hash["\\w+"]
		  elsif params['audio_companding'].eql?("alaw")
			@alaw_audio_source_hash["\\w+"]
		  end
	  end
	else
		params['video_source']
	end
  end
  
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
  
  def get_video_frame_rate(params)
    if params['video_frame_rate'].eql?('std')
      	case get_video_resolution(params)
      	    when '176x120', '352x240', '720x480', '704x480'
                30
      	    when '176x144', '352x288', '720x576', '704x576'
                25
			else
				if rand() > 0.5
					25
				else
					30
				end
        end
    else
        params['video_frame_rate']
    end   	
  end
  
  def get_video_source(params)
      video_bit_rate = get_video_bit_rate(params)
      video_resolution = get_video_resolution(params)
	if params['video_source'].eql?("media_filer")
		if params['video_input_driver'].include?('encode')
			result = @video_source_hash["\\w*"+get_video_resolution(params)+"_\\w*_{0,1}"+params['video_input_chroma_format']+"\\w*frames"]
		elsif params['video_input_driver'] == 'none'
			video_resolution = get_video_resolution(params)
			video_bit_rate = get_video_bit_rate(params)
			if video_bit_rate.to_f/1000 >= 1000
				file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
			else
				file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
			end 
		   video_source = @video_source_hash["\\w+"+video_resolution+"_"+params['video_input_chroma_format']+"\\w*"+video_bit_rate+"bps"]
		   video_source += ";" if video_source && @video_source_hash["\\w+"+video_resolution+"_(ASP|SP)\\w*"+file_bit_rate+"\\w*"]
		   result = video_source.to_s + @video_source_hash["\\w+"+video_resolution+"_(ASP|SP)\\w*"+file_bit_rate+"\\w*"].to_s
		end
	else
		result = params['video_source']
	end
	result
  end
  
  def get_video_region(params)
      case get_video_resolution(params).strip.downcase
      	when '176x120', '352x240', '720x480', '704x480'
            'ntsc'
      	when '176x144', '352x288', '720x576', '704x576'
            'pal'
		else
			if rand() > 0.5
				'ntsc'
			else
				'pal'
			end
      end
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
