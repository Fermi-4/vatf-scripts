require '../media_filer_utils'
include MediaFilerUtils

class DvtbJpegEncodeTestPlan < TestPlan
	attr_reader :picture_source_hash
  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
	@group_by = ['picture_resolution']
	@sort_by = ['picture_resolution']
  end
  # END_USR_CFG setup
  

  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
   @signal_format_max_res = {
         '525' => [720,480],
         '625' => [720,576], 
         '720p50' => [1280,720],
         '720p59' => [1280,720],
         '720p60' => [1280,720],          
    }
	@res_params =  {
    'picture_resolution'		  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '352x288', '720x576', '320x240', '640x480', '704x480','704x576', '1280x720', '1920x1080', '2048x3172'],
	'picture_input_resolution' => ['equal', 'less_min_w_h'], # 'less_min_w_h' (substitute 'w' for min width and 'h' for min height) -> encodes a smaller portion (pixels) of the original image but not smaller in width than 'w' and not smaller in height than 'h', i.e. less_min_32_16 encode the first 32 columns and first 16 rows of the original image. 'equal' -> encoded image has the same resolution (pixels) as the original image
	'picture_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
	'picture_num_scans' => [0,1,3,10],
	'picture_quality' => [25,50,75,100],  #number in the range 0-100, 100=best quality
    'picture_input_chroma_format'  => ['411p','420p','422i','422p','444p','gray','420sp'],
    'picture_output_chroma_format' => ['default', '411p','420p', '422p', '444p', 'gray', '420sp'],
    'picture_source' => ['camera', 'dvd', 'media_filer'],
	'picture_num_access_units' => ['default', 'all'],
	'picture_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
    'picture_num_channels'				=> [1],
	'picture_rotation' => [0,90,180,270], #encoder rotate the picture by the degrees specified only 0,90,180 and 270 are supported
	'picture_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
    }
	@picture_source_hash = get_source_files_hash("\\w+",@res_params['picture_resolution'],"_",@res_params['picture_input_chroma_format'],"\\w{0,1}","yuv")
	@picture_source_hash.merge!(get_source_files_hash("\\w+",@res_params['picture_input_chroma_format'],"_",@res_params['picture_resolution'],"yuv"))	
	@res_params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    const_hash = {}
     const_hash.default = []
     @res_params['picture_resolution'].each do |res|
	     resolution = res.split(/x/i)
         @res_params['picture_signal_format'].each do |format|
             if @signal_format_max_res[format] && (@signal_format_max_res[format][0] < resolution[0].to_i || @signal_format_max_res[format][1] < resolution[1].to_i)
                 const_hash[format] = const_hash[format]|[res]
             end
         end
     end
     format_constraints = Array.new
     const_hash.each do |format,res|
         current_group ='"'+res[0]+'"'
         1.upto(res.length-1){|i| current_group+=', "'+res[i]+'"'}
         format_constraints << 'IF [picture_source] <> "media_filer" AND [picture_signal_format] = "'+ format + '" THEN [picture_resolution] NOT IN {'+ current_group +'};'
     end
	format_constraints | [   
	'IF [picture_source] <> "media_filer" THEN [picture_input_chroma_format] = "422i";',
	'IF [picture_input_chroma_format] = "420p" THEN [picture_output_chroma_format] IN {"420p","gray"};',
	'IF [picture_input_chroma_format] = "422p" THEN [picture_output_chroma_format] IN {"422p","gray"};',
	'IF [picture_input_chroma_format] = "422i" THEN [picture_output_chroma_format] IN {"422p","420p","gray"};',
	'IF [picture_input_chroma_format] = "444p" THEN [picture_output_chroma_format] IN {"444p","gray"};',
	'IF [picture_input_chroma_format] = "411p" THEN [picture_output_chroma_format] IN {"411p","gray"};',
	'IF [picture_input_chroma_format] = "gray" THEN [picture_output_chroma_format] = "gray";',
	'IF [picture_resolution] IN {"2048x3172"} THEN [picture_source] = "media_filer";',
	'IF [picture_input_chroma_format] = "411p" AND [picture_source] = "media_filer" THEN [picture_resolution] IN {"192x144","720x480"};',
	'IF [picture_input_chroma_format] IN {"420p","444p","422p","gray"} AND [picture_source] = "media_filer"  THEN [picture_resolution] NOT IN {"192x144","704x480"};',
	'IF [picture_resolution] = "640x480" THEN [picture_input_chroma_format] NOT IN {"444p","gray"};',
	'IF [picture_input_chroma_format] = "422i" AND [picture_source] = "media_filer" THEN [picture_resolution] NOT IN {"704x480", "352x240","640x480","192x144"};',
	'IF [picture_iface_type] IN {"composite","svideo","scart"} THEN [picture_signal_format] IN {"525","625"};',
	'IF [picture_iface_type] IN {"vga","component","hdmi","dvi","sdi"} THEN [picture_signal_format] IN {"1080i50", "1080i59", "1080i60", "720p50", "720p59", "720p60", "1080p23", "1080p24", "1080p25", "1080p29", "1080p30", "1080p50", "1080p59", "1080p60"};',
	]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"JPEG Encoder test, picture_res=#{params['picture_resolution']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_jpeg_encode.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'                  => false,
    'script'    =>  'DVSDK/A-DVTB_JPEG_ENCODE/dvtb_jpeg_enc.rb',

    # channel parameters
    'paramsChan'                 => {
		'picture_width'		  => get_picture_width(params),
		'picture_height'	  => get_picture_height(params),
		'picture_input_height' => get_picture_input_height(params),
		'picture_input_width' => get_picture_input_width(params),
		'picture_source'		      => get_picture_source(params),
		'picture_num_scans' => params['picture_num_scans'],
		'picture_data_endianness' => params['picture_data_endianness'],
		'picture_input_chroma_format'  => params['picture_input_chroma_format'],
		'picture_output_chroma_format' => params['picture_output_chroma_format'],
		'picture_num_access_units' => get_num_access_units(params),
		'picture_quality' => params['picture_quality'],
		'picture_signal_format'				    => params['picture_signal_format'],
		'picture_rotation' => params['picture_rotation'],
		'picture_iface_type' => params['picture_iface_type']
    },
    
    
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'picture_num_channels'				=> params['picture_num_channels'],
    },
    'configID'      => '../Config/dvtb_jpeg_enc.ini',
 #   'last'            => true, commented to comply with new db schema
   }
  end
  # END_USR_CFG get_outputs

  def get_picture_source(params)
    result = params['picture_source']
    if params['picture_source'].eql?('media_filer')
		result = @picture_source_hash["\\w+"+params['picture_resolution']+"_"+params['picture_input_chroma_format']+"\\w{0,1}"]
		result = result.to_s+";" if result && @picture_source_hash["\\w+"+params['picture_input_chroma_format']+"_"+params['picture_resolution']]
		result = result.to_s+@picture_source_hash["\\w+"+params['picture_input_chroma_format']+"_"+params['picture_resolution']] if @picture_source_hash["\\w+"+params['picture_input_chroma_format']+"_"+params['picture_resolution']]
	end
	result
  end
  
  private
  def get_picture_height(params)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(params['picture_resolution'])
		res[2]
  end
  
  def get_picture_width(params)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(params['picture_resolution'])
		res[1]
  end
  
  def get_picture_input_height(params)
	height = get_picture_height(params).to_i
	
	if params['picture_input_resolution'].downcase.include?('less_min')
	    res_array = params['picture_input_resolution'].strip.split('_')
	    res_array[3].to_i+rand(height-res_array[3].to_i)
	elsif params['picture_input_resolution'].eql?('equal')
	    height
	else
	   raise 'Unsupported picture_input_resolution value '+params['picture_input_resolution']
	end
	
  end
  
  def get_picture_input_width(params)
    width = get_picture_width(params).to_i	
	if params['picture_input_resolution'].downcase.include?('less_min')
	    res_array = params['picture_input_resolution'].strip.split('_')
	    res_array[2].to_i+rand(width-res_array[2].to_i)
	elsif params['picture_input_resolution'].eql?('equal')
	    width
	else
	   raise 'Unsupported picture_input_resolution value '+params['picture_input_resolution']
	end
	
  end
  
  def get_num_access_units(params)
	if params['picture_num_access_units'].strip.downcase.eql?('default')
		0
	elsif params['picture_num_access_units'].strip.downcase.eql?('all')
		(get_picture_height(params).to_i*get_picture_width(params).to_i/16).ceil
	else
		params['picture_num_access_units'].strip.downcase.to_i
	end
  end
end
