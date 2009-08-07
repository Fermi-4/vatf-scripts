# this is only for demo purpose. 
class I2c_func_dynTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true				# Bypass autogeneration and instead call get_manual
  end
  # END__CLASS_INIT	
  
  # BEG_USR_CFG setup
  def setup()
	@group_by = ['dsp']
	@sort_by = ['dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
      keys = [
		{
      'dsp'		=> ['dynamic'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
		},
	  ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
    }
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_manual
  def get_manual()
    tc = [
          {
             'description' =>  "Issue the insmod command",
             'paramsChan'  => {
                 'ltpTag'      => "I2C_0001",		# should match the tag in LTP script
	     }
          },
          {
             'description' =>  "Issue the rmmod command",
             'paramsChan'  => {
             	'ltpTag'      => "I2C_0002",		# should match the tag in LTP script
            }
          },
         ]
   return tc
   end
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
  
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {

    }
  end
  # END_USR_CFG get_outputs
  
end
