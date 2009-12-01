require '../media_filer_utils'
include MediaFilerUtils

class DvtbJpegDecodeTestPlan < TestPlan
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
    'picture_resolution'		  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '176x144', '352x288', '720x576', '320x240', '640x480','704x576', '1280x720', '2048x3172'],
    'picture_input_chroma_format'  => ['411p','420p','422i','422p','444p','gray', '420sp'],
	'picture_output_chroma_format' => ['default', '422i'], #Only these output formats have been confirmed to be supported
	'picture_num_scans' => [0,1,3,10],
	'picture_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
	'picture_num_ticks' => [3500],
	'picture_display' => ['on','off'],
    'picture_num_channels'	=> [1],
	'picture_output_scale_factor' => [1,2,3,4,5,6,7,8], # valid values are 1 to 8, decoded image is scaled by a factor of picture_output_scale_factor/8, i.e if picture_output_scale_factor = 1 then decoded image is scaled by 1/8 
	'picture_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
	'picture_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
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
         format_constraints << 'IF [picture_signal_format] = "'+ format + '" THEN [picture_resolution] NOT IN {'+ current_group +'};'
     end
	format_constraints | [
		'IF [picture_output_chroma_format] = "422i" OR [picture_input_chroma_format] IN {"444p","411p","420p","422i"} THEN [picture_display] = "off";',
		'IF [picture_input_chroma_format] = "444p" THEN [picture_resolution] NOT IN {"192x144","640x480","704x480"};',
		'IF [picture_input_chroma_format] = "gray" THEN [picture_resolution] NOT IN {"640x480","704x480","192x144"};',
		'IF [picture_input_chroma_format] = "411p" THEN [picture_resolution] NOT IN {"1280x720","320x240","640x480","704x480","704x576","352x240","720x576","352x288"};',
		'IF [picture_input_chroma_format] = "420p" THEN [picture_resolution] NOT IN {"320x240","640x480","704x480","192x144"};',
		'IF [picture_input_chroma_format] = "422p" THEN [picture_resolution] NOT IN {"192x144","704x480"};',
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
	'description'		=>"JPEG Decoder test, picture_res=#{params['picture_resolution']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_jpeg_decode.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'                  => false,
    'script'    =>  'DVSDK/A-DVTB_JPEG_DECODE/dvtb_jpeg_dec.rb',

    # channel parameters
    'paramsChan'                 => {
		'picture_width'		  => get_picture_width(params['picture_resolution']),
		'picture_height'	  => get_picture_height(params['picture_resolution']),
		'picture_input_chroma_format' => params['picture_input_chroma_format'],
		'picture_output_chroma_format' => params['picture_output_chroma_format'],
		'picture_source'		      => get_picture_source(params),
		'picture_data_endianness' => params['picture_data_endianness'],
		'picture_num_scans' => params['picture_num_scans'],
		'picture_num_ticks' => params['picture_num_ticks'],
		'picture_signal_format' => params['picture_signal_format'],
		'picture_display' => params['picture_display'],
		'picture_output_scale_factor' => params['picture_output_scale_factor'],
		'picture_iface_type' => params['picture_iface_type']
    },
    
    
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'picture_num_channels'				=> params['picture_num_channels'],
    },
    'configID'      => '../Config/dvtb_jpeg_dec.ini',
 #   'last'            => true, commented out to comply with new db schema
   }
  end
  # END_USR_CFG get_outputs

  def get_picture_source(params)
	@picture_source_hash["\\w+"+params['picture_resolution']+"_"+params['picture_input_chroma_format']+"\\w{0,1}\.{0,1}"]
  end
  private
  def get_picture_height(resolution)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
		res[2]
  end
  
  def get_picture_width(resolution)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
		res[1]
  end
  
end
