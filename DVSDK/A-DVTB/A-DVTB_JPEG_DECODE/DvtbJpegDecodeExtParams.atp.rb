require '../media_filer_utils'
include MediaFilerUtils

class DvtbJpegDecodeExtParamsTestPlan < TestPlan
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
  'picture_resolution'		  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '176x144', '352x288', '720x576', '320x240', '640x480','704x576', '1280x720', '2048x3172'],
  'picture_input_chroma_format'  => ['411p','420p','422i','422p','444p','gray', '420sp'],
	'picture_output_chroma_format' => ['default', '422i', 'rgb'], #Only these output formats have been confirmed to be supported
	'picture_num_scans' => [0,1,3,10],
	'picture_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
	'picture_num_ticks' => [3500],
	'picture_num_channels'	=> [1],
	'picture_output_scale_factor' => [0,1,2,3,4,5,6,7,8], 
	'picture_rotation' => [0,90,180,270],
	'picture_subregion' => ['less', 'equal'],
	'picture_disable_eoi' => [0,1],
  'picture_progerssive_dec_flag' => [0,1], # Set flag value 1 if progressive decoding is required in addition to baseline sequential mode.
  'picture_prog_display' => [0,1], # Set the display option for progressive mode: 1 - Output buffer contains the partially (progressively) decoded image after each scan is decoded. 0 - Output buffer contains the decoded image only after all the scans are decoded.
  'picture_rgb_format' => ['bgr24', 'bgr32', 'rgb16'], # Set the output RGB format. 0 - BGR24. 1 - BGR32. 2 - RGB16
  'picture_num_mcu_row' => [0, -1], # Number of rows of access units to decode. Setting this field to XDM_DEFAULT decodes the complete frame. Any value other than XDM_DEFAULT will decode that many number of rows.Set numMCU_row to any integer value other then zero for sectional decoding
  'picture_alpha_rgb' => [0,127,255], # Alpha value to fill rgb32. Default value: 0
  'picture_out_img_res' => ['actual', 'even'], # Set the output image resolution. 0 - Always Even Image resolution. 1 - Outputs Actual Image resolution
  }
	@picture_source_hash = get_source_files_hash("\\w+",@res_params['picture_resolution'],"_",@res_params['picture_input_chroma_format'],"\\w{0,1}\.{0,1}","jpg")	
	@res_params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
  res = [
		'IF [picture_input_chroma_format] = "444p" THEN [picture_resolution] NOT IN {"192x144","640x480","704x480"};',
		'IF [picture_input_chroma_format] = "gray" THEN [picture_resolution] NOT IN {"640x480","704x480","192x144"};',
		'IF [picture_input_chroma_format] = "411p" THEN [picture_resolution] NOT IN {"1280x720","320x240","640x480","704x480","704x576","352x240","720x576","352x288"};',
		'IF [picture_input_chroma_format] = "420p" THEN [picture_resolution] NOT IN {"320x240","640x480","704x480","192x144"};',
		'IF [picture_input_chroma_format] = "422p" THEN [picture_resolution] NOT IN {"192x144","704x480"};',
  ]
  res << 'IF [picture_output_scale_factor] <> 0 THEN [picture_num_mcu_row] = 0;' if @res_params['picture_output_scale_factor'] && @res_params['picture_num_mcu_row'] && @res_params['picture_num_mcu_row'][0].strip.downcase != 'nsup'
  res << 'IF [picture_output_chroma_format] <> "rgb" THEN [picture_rgb_format] = "' + @res_params['picture_rgb_format'][0] + '";' if @res_params['picture_output_chroma_format'] && @res_params['picture_rgb_format'] && @res_params['picture_rgb_format'][0].strip.downcase != 'nsup'
  res
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"JPEG Decoder Extended parameters test, picture_res=#{params['picture_resolution']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_jpeg_decode_ext_params.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'                  => false,
    'script'    =>  'vatf-scripts/DVSDK/A-DVTB/A-DVTB_JPEG_DECODE/dvtb_jpeg_dec_ext_params.rb',

    # channel parameters
    'paramsChan'                 => get_params_chan(params),
    
    
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'picture_num_channels'				=> params['picture_num_channels'],
    },
    'configID'      => 'Config/dvtb_jpeg_dec.ini',
 #   'last'            => true, commented out to comply with new db schema
   }
  end
  # END_USR_CFG get_outputs
  
  def get_params_chan(params)
      result = {}
      result['test_type'] = 'decode'
      params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
      result['picture_width']	= get_picture_width(params) if params['picture_resolution'] && params['picture_resolution'].strip.downcase != 'nsup'
      result['picture_height'] = get_picture_height(params) if params['picture_resolution'] && params['picture_resolution'].strip.downcase != 'nsup'
      result['picture_source'] = get_picture_source(params)
      result['picture_num_mcu_row'] = get_num_mcu_row(params) if params['picture_num_mcu_row'] && params['picture_num_mcu_row'].strip.downcase != 'nsup'
      result = result.merge(get_subregion(params)) if params['picture_subregion'] && params['picture_subregion'].strip.downcase != 'nsup'
      result.delete('picture_num_channels')
      result.delete('picture_subregion')
      result
   end
  
  def get_picture_source(params)
	@picture_source_hash["\\w+"+params['picture_resolution']+"_"+params['picture_input_chroma_format']+"\\w{0,1}\.{0,1}"]
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
  
  def get_num_mcu_row(params)
    if params['picture_num_mcu_row'].to_i < 0
      (get_picture_height(params).to_i/2).to_s
    else
      params['picture_num_mcu_row']
    end
  end
  
  def get_subregion(params)
      result = Hash.new
      width = get_picture_width(params).to_i
      height = get_picture_height(params).to_i
      case params['picture_subregion'].downcase.strip
      	when 'less'
            result['picture_subregion_upper_leftx'] = rand((width/32).ceil)*32
            result['picture_subregion_upper_lefty'] = rand((height/32).ceil)*32
            result['picture_subregion_x_length'] = rand(((width - result['picture_subregion_upper_leftx'])/32).floor) * 32 + 32
            result['picture_subregion_y_length'] = rand(((height - result['picture_subregion_upper_lefty'])/32).floor) * 32 + 32
            result['picture_subregion_down_rightx'] = result['picture_subregion_upper_leftx'] + result['picture_subregion_x_length']  
            result['picture_subregion_down_righty'] = result['picture_subregion_upper_lefty'] + result['picture_subregion_y_length']
        else
            result['picture_subregion_upper_leftx'] = 0
            result['picture_subregion_upper_lefty'] = 0
            result['picture_subregion_down_rightx'] = 0
            result['picture_subregion_down_righty'] = 0
  	  end
  	  result
  end
  
end
