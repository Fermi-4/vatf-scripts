class Rtc_func_ioctlTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType']
    @sort_by = ['microType']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
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
    ioctls =['RTC_ALM_READ', 'RTC_ALM_SET', 'RTC_RD_TIME', 'RTC_SET_TIME'] +
            ['RTC_EPOCH_SET', 'RTC_EPOCH_READ', 'RTC_WKALM_SET', 'RTC_WKALM_RD', 'RTC_UIE_OFF', 'RTC_UIE_ON']
    fail_string = "Cannot|fault|error|Invalid"
    common_paramsChan = {
      'target_sources'  => 'LSP\A-RTC\rtc_tests',
      'ensure'  => "hwclock --set --date \"09/18/2008 12:30:00\"`--(#{fail_string})`",
    }
    common_vars = {
      'configID'        => '..\Config\lsp_generic.ini', 
      'script'          => 'LSP\default_test_script.rb',
      'ext'             => false,
      'bestFinal'       => false,
      'basic'           => false,
      'bft'             => false,
      'reg'             => false,
      'auto'            => true,
      'paramsControl'   => {
      },
      'paramsEquip'     => {
      },

    }
    tc = []
    ioctls.each { |ioctl|
      tc += [
        'description'  => "Verify the rtc IOCTL #{ioctl} works.", 
        'testcaseID'   => "rtc_func_ioctl_#{ioctl.downcase}",
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "rtc_test`++(?i:complete)--(?i:fail)`"
        }),
      ]
    }
    
    # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      tc_new << common_vars.merge(val)
    }
    return tc_new
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
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

end
