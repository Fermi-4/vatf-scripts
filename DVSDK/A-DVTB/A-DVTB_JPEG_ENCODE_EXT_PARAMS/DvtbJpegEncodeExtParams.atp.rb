require '../media_filer_utils'
include MediaFilerUtils

class DvtbJpegEncodeExtParamsTestPlan < TestPlan
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
  
	@res_params =  {
  'picture_resolution'		  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '352x288', '720x576', '320x240', '640x480', '704x480','704x576', '1280x720', '1920x1080', '2048x3172'],
	'picture_input_resolution' => ['equal', 'less_min_w_h'], # 'less_min_w_h' (substitute 'w' for min width and 'h' for min height) -> encodes a smaller portion (pixels) of the original image but not smaller in width than 'w' and not smaller in height than 'h', i.e. less_min_32_16 encode the first 32 columns and first 16 rows of the original image. 'equal' -> encoded image has the same resolution (pixels) as the original image
	'picture_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
	'picture_num_scans' => [0,1,3,10],
	'picture_quality' => [25,50,75,100],  #number in the range 0-100, 100=best quality
  'picture_input_chroma_format'  => ['411p','420p','422i','422p','444p','gray', '420sp'],
  'picture_output_chroma_format' => ['default', '411p','420p', '422p', '444p', 'gray', '420sp'],
  'picture_num_access_units' => ['default', 'all'],
	'picture_num_channels'				=> [1],
	'picture_rotation' => [0,90,180,270], #encoder rotate the picture by the degrees specified only 0,90,180 and 270 are supported
	'picture_reset_interval' => [-1, 3], #reset_interval in MCUs. reset_interval < 0 randomly generate reset interval, 0 default value, reset_interval > 0 used given num MCU as reset interval
	'picture_disable_eoi' => [0,1], #disable end of image marker, 0 do not disable EOI, 1 disable EOI marker
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
  [   
    'IF [picture_input_chroma_format] = "420p" THEN [picture_output_chroma_format] IN {"420p","gray"};',
    'IF [picture_input_chroma_format] = "422p" THEN [picture_output_chroma_format] IN {"422p","gray"};',
    'IF [picture_input_chroma_format] = "422i" THEN [picture_output_chroma_format] IN {"422p","420p","gray"};',
    'IF [picture_input_chroma_format] = "444p" THEN [picture_output_chroma_format] IN {"444p","gray"};',
    'IF [picture_input_chroma_format] = "411p" THEN [picture_output_chroma_format] IN {"411p","gray"};',
    'IF [picture_input_chroma_format] = "gray" THEN [picture_output_chroma_format] = "gray";',
    'IF [picture_resolution] = "640x480" THEN [picture_input_chroma_format] NOT IN {"444p","gray"};',
  ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"JPEG Encoder extended parameters test, picture_res=#{params['picture_resolution']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_jpeg_encode_ext_params.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'                  => false,
    'script'                     => 'vatf-scripts/DVSDK/A-DVTB/A-DVTB_JPEG_ENCODE_EXT_PARAMS/dvtb_jpeg_enc_ext_params.rb',

    # channel parameters
    'paramsChan'                 => get_params_chan(params),
    
    
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'picture_num_channels'				=> params['picture_num_channels'],
    },
    'configID'      => 'Config/dvtb_jpeg_enc.ini',
 #   'last'            => true, commented to comply with new db schema
   }
  end
  # END_USR_CFG get_outputs
  
  def get_params_chan(params)
    result = {}
    params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
    result['picture_width'] = get_picture_width(params)
		result['picture_height'] = get_picture_height(params)
		result['picture_input_height'] = get_picture_input_height(params)
		result['picture_input_width'] = get_picture_input_width(params)
		result['picture_source'] = get_picture_source(params)
		result['picture_num_access_units'] = get_num_access_units(params)
		result['picture_reset_interval'] = get_reset_interval(params)
    result.delete('picture_input_resolution')
    result
  end
   
  def get_picture_source(params)
		result = @picture_source_hash["\\w+"+params['picture_resolution']+"_"+params['picture_input_chroma_format']+"\\w{0,1}"]
		result = result.to_s+";" if result && @picture_source_hash["\\w+"+params['picture_input_chroma_format']+"_"+params['picture_resolution']]
		result = result.to_s+@picture_source_hash["\\w+"+params['picture_input_chroma_format']+"_"+params['picture_resolution']] if @picture_source_hash["\\w+"+params['picture_input_chroma_format']+"_"+params['picture_resolution']]
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
		(get_picture_width(params).to_i/8).ceil * rand((get_picture_height(params).to_i/32).floor)
	else
		params['picture_num_access_units'].strip.downcase.to_i
	end
  end
  
  def get_reset_interval(params)
      if params['picture_reset_interval'].to_i > 0
          params['picture_reset_interval']
      else
          a = rand
          access_units = get_num_access_units(params)
          if a > 0.66
               access_units
          elsif a > 0.33
              (access_units*2/3).floor
          else
              (access_units/3).floor
          end
      end
  end
end
