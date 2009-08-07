class HRTimer_func_premTestPlan < TestPlan
 
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
        'microType' => ['lld', 'rtt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
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
    common_paramsChan = {
      'ensure'  => ''
    }
    common_vars = {
      'configID'        => '..\Config\lsp_generic.ini', 
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
    ]
    iperiod = [10]
    tc_append = []
    iperiod.each { |i|
      tc_append << 
      {
        'description'  => "Verify that the accuracy of the HRT." +
                        "\r\n Test Procedure >>>" +
                        "\r\n 1.Start timing for a periods of #{i} seconds." +
                        "\r\n 2.Compare the time period against the Wall clock." +
                        "\r\n The deviation from the Wall clock time interval should be not more than 1 sec.",        
        'testcaseID'   => "timer_func_it#{i}",
        'script'  => 'LSP\A-Timer\hr_clock_test.rb',
        'paramsChan'  => common_paramsChan.merge({ 
          'target_sources' => 'LSP\A-Timer\timer_tests',
          'cmd' => "\./clock_test`++Gettimeofday`",
          'interval'  => i,   # in seconds. can be float number. the time between sending two cmds.
          'boundary'  => 1,   # in seconds. can be float number. the dif between timer and ruby sleep.(need high resolution sleep).
        }),
      }
    }
    tc = tc + tc_append
    tc_append = []  
    tc_append = [
      {
        'description'  => "Check for the accuracy of the itimer with different resolutions." +
                        "\r\n Test Procedure >>>" +
                        "\r\n 1.Set to different resolution and different interval." +
                        "\r\n 2.Check if got expected interval." +
                        "\r\n The test case fails if there is big difference between expected interval and got interval.",        
        'testcaseID'   => "hrtimer_func_8",
        'script'  => 'LSP\default_test_script.rb',
        'paramsChan'  => common_paramsChan.merge({ 
          'target_sources' => 'LSP\A-Timer\timer_tests',
          'cmd' => "[dut_timeout\=60];\./itimer_test",
        }),
      },
      {
        'description'  => "Verify that the resolution of the HRT." +
                        "\r\n Test Procedure >>>" +
                        "\r\n 1.The test case records the resolution of the timer for 1000 iterations using the least possible sleep value, and then averages the recorded values to report a result.." +
                        "\r\n 2.This test case runs at highest scheduler priority." +
                        "\r\n 3.This test case prints out the calculated resolution; the user must verify that it is as expected." +
                        "\r\n Note >>> This test case evaluates resolution, not precision. The precision of a clock is the smallest unit of measurement that the clock displays. The resolution is the smallest interval/tick that the clock accurately measures." +
                        "\r\n The test case fails if the average of the recorded values is greater than the maximum specified resolution.",        
        'testcaseID'   => "hrtimer_func_8",
        'script'  => 'LSP\A-Timer\hr_cyclic_test.rb',      
        'paramsChan'  => common_paramsChan.merge({ 
          'target_sources' => 'LSP\A-Timer\hrt_tests',
          # static int clocksources[] = {
            # CLOCK_MONOTONIC, 
            # CLOCK_REALTIME,
            # CLOCK_MONOTONIC_HR,
            # CLOCK_REALTIME_HR -> 3
          # };
          'cmd' => "\./cyclictest -n -p 80 -i 500 -l 5000 -c 1",  # pass clock_id to clock_nanosleep() and clock_getres() functions.
          'expected_resolution' => "1000",  # in ns
          'time_to_finish'  => "5",   # the program should get over in this time. otherwise, it is not hr.
        }),
      },
    ]
    tc = tc + tc_append
    
    # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      #val.merge!(common_vars)
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
