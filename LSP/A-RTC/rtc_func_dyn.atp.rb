class Rtc_func_dynTestPlan < TestPlan
#class Rtc_funcTestPlan < Rtc_func_premTestPlan 
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
        'dsp'       => ['dynamic'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
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
    fail_string = "Cannot|fault|error|Invalid"
    module_name = 'rtc-davinci-dm365.ko'
    insmod = "insmod #{module_name};lsmod`++rtc`"
    rmmod = "rmmod #{module_name};lsmod`--rtc`"
    common_paramsChan = {
      'ensure'  => "hwclock --set --date \"09/18/2008 12:30:00\"`--(#{fail_string})`;#{rmmod}",
    }
    common_vars = {
      'configID'        => '..\Config\lsp_generic.ini', 
      'script'          => 'LSP\A-RTC\rtc.rb',
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
    tc = [
      {
        'description'  => "Verify the device node is created.", 
        'testcaseID'   => 'rtc_func_0001',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};ls /dev/rtc0`++/dev/rtc0`",
        }),
      },
      {
        'description'  => "Verify that clock can be set and read correctly.", 
        'testcaseID'   => 'rtc_func_0002',
        'paramsChan'  => common_paramsChan.merge({  
          #'is_set_time' => 1,
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"7/31/2008 05:40:00\"`--(#{fail_string})`;hwclock`++Jul 31 05:40:\\d+ 2008`",
        }),
      },
      {
        'description'  => "Verify that rtc is accurate.", 
        'testcaseID'   => 'rtc_func_0002',
        'script' => 'LSP\A-RTC\rtc_accuracy.rb',
        'paramsChan'  => common_paramsChan.merge({  
          #'is_set_time' => 1,
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock`--(#{fail_string})`", # repeat sending this cmd
          'interval'  => 10,  # sleep 10s
          'boundary'  => 1,   # accuracy in second
          'test_loop'  => 5,   # do 5 times.
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transitioning between years. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"12/31/2007 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Jan\\s+1\\s+[\\d:]+\\s+2008`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transitioning between months. ",
        'testcaseID'   => 'rtc_func_0004',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"1/31/2007 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Feb\\s+1\\s+[\\d:]+\\s+2007`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transitioning between days. ",
        'testcaseID'   => 'rtc_func_0005',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"1/30/2008 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Jan\\s+31\\s+[\\d:]+\\s+2008`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transitioning between hours. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"12/31/2007 22:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++23:\\d+:\\d+`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transitioning between minutes. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"12/31/2007 20:50:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++20:51:\\d+`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transitioning between seconds. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"12/31/2007 23:59:00\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++23:59:\\d+`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when Feb-March transition in a leap year. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"02/29/2008 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Mar\\s+1\\s+[\\d:]+\\s+2008`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when Feb-March transition in a non-leap year. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"02/28/2007 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Mar\\s+1\\s+[\\d:]+\\s+2007`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when Feb-March transistion in a year multiple of 100 not multiple of 400 (this is a non-leap year)." +
                          "Can not be tested since no such year between 1970 to 2037",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"02/28/xxxx 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Mar\\s+1\\s+[\\d:]+\\s+xxxx`",
        }),
        'auto'  => false, 
      },
      {
        'description'  => "Verify the rtc rollover correctly when transistion between all months in a leap year. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"03/31/2008 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Apr\\s+1\\s+[\\d:]+\\s+2008`",
        }),
      },
      {
        'description'  => "Verify the rtc rollover correctly when transistion between all months in a non-leap year. ",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"12/31/2007 23:59:50\"`--(#{fail_string})`" +
                  ";sleep 10;hwclock`++Jan\\s+1\\s+[\\d:]+\\s+2008`",
        }),
      },
      {
        'description'  => "Verify the rtc clock range.",
        'testcaseID'   => 'rtc_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"12/31/1969 23:59:00\"`++(Invalid|fail)`" +
                  ";hwclock --set --date \"01/01/2038 23:59:00\"`++(Invalid|fail)`" +
                  ";hwclock --set --date \"1/1/1970 1:1:00\"`--(#{fail_string})`" +
                  ";hwclock --set --date \"12/31/2037 23:59:00\"`--(#{fail_string})`" +
                  ";hwclock --set --date \"08/01/2008 11:16:00\"`--(#{fail_string})`",
        }),
      },
      {
        'description'  => "Verify the system Time and RTC Tests are in sync . ",
        'testcaseID'   => 'rtc_func_0006',
        'paramsChan'  => common_paramsChan.merge({ 
        }),
        'auto'        => false,
      },
      {
        'description'  => "Verify mulitiple insmod and rmmod. ",
        'testcaseID'   => 'rtc_func_0006',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};[dut_timeout\\=30];hwclock --set --date \"7/31/2008 05:40:00\"`--(#{fail_string})`;hwclock`++Jul 31 05:40:\\d+ 2008`" +
                  "#{rmmod}" +
                  "#{insmod};[dut_timeout\\=30];hwclock --set --date \"7/31/2008 05:40:00\"`--(#{fail_string})`;hwclock`++Jul 31 05:40:\\d+ 2008`" +
                  "#{rmmod}" +
                  "#{insmod};[dut_timeout\\=30];hwclock --set --date \"7/31/2008 05:40:00\"`--(#{fail_string})`;hwclock`++Jul 31 05:40:\\d+ 2008`" +
                  "#{rmmod}",
        }),
      },
    ]
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
