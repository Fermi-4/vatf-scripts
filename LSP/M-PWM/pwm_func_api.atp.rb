=begin
    printf("Usage:\n"
            "pwm_tests <options>\n\n"
            "-d       --devicenode     Device node on which test is to be run\n"
            "\t\t\t\tPossible value-/dev/davinci_pwm0 etc based on platform\n"
            "-T       --testname        Name of the special test\n"
            "\t\t\t\tPossible values-stability,api\n"
            "-m       --mode            Operating mode of PWM \n"
            "\t\t\t\tPossible values-0 for one shot mode, 1 for continous mode\n"
            "-I       --period          Period in milliseconds\n"
            "-i       --duration        Pulse width duration in milliseconds\n"
            "-n       --stabilitycount  Number of times to run stability test-any integer value\n"
            "-t       --testcaseid      Test case id string for testers reference/logging purpose\n"
            "\t\t\t\tPossible values- Any String without spaces\n"
            "-r       --rptval          Repeat value\n"
            "-s       --inactstate      Inact out state\n"
            "\t\t\t\tPossible values-0 or 1\n"
            "-p       --phasestate      Phase state\n"
            "\t\t\t\tPossible values-0 or 1\n"
            "-?       --help            Displays the help/usage\n"
            "-v       --version         Version of Display Test suite\n");

=end

class Pwm_func_apiTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'micro', 'dsp']
    @sort_by = ['microType', 'micro', 'dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
    {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
        'custom'    => ['usbslave'],
        # DEBUG-- Remove these after debugging & uncomment above line -- 'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        # 'platform' => ['dm365'],
        # 'os' => ['linux'],
        # 'target' => ['210_lsp'],
    },
      ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    @dev_nodes = ['/dev/davinci_pwm0', '/dev/davinci_pwm1', '/dev/davinci_pwm2', '/dev/davinci_pwm3']
    {
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    
    common_paramsChan = {
      'ensure' => "",
    }
    
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\M-PWM\pwm.rb',
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
    @dev_nodes.each {|dev_node|
      tc += 
      [
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for default mode, period and pulse width",
            'testcaseID'   => 'pwm_func_api_0002',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output by changing the mode, period and pulse width from the default parameters",
            'testcaseID'   => 'pwm_func_api_0003',
            'paramsChan'  => common_paramsChan.merge({
              #'cmd' => "#{pwm_open} st_parser pwm set_mode 1#{pwm_pass_fail} st_parser pwm set_period 2#{pwm_pass_fail}" \
              #  "st_parser pwm set_pw 2#{pwm_pass_fail} st_parser pwm set_rpt_cnt 2#{pwm_pass_fail} #{pwm_start}",
              #'cmd' => "pwm_tests -d {instance} -m {mode} -I {period} -i {pw} -r {rpt_cnt} -s {idle_state} -p {1st_phase} -n {count} -T {test_type}"
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api"
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM driver works fine after a software reset",
            'testcaseID'   => 'pwm_func_api_0004',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM driver works fine after a hardware reset",
            'testcaseID'   => 'pwm_func_api_0005',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM driver works fine after the power is shut ON/OFF for 10 times",
            'testcaseID'   => 'pwm_func_api_0006',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM module can be controlled for stopping (call the ioctl to stop the PWM module)",
            'testcaseID'   => 'pwm_func_api_0007',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -T api -m 0 -r 1",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM module can be controlled for free running (call the ioctl to run the PWM module)",
            'testcaseID'   => 'pwm_func_api_0008',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the interrupt can be enabled and disabled",
            'testcaseID'   => 'pwm_func_api_0009',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => ""
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the inactive output level can be configured to HIGH and LOW",
            'testcaseID'   => 'pwm_func_api_0010',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -s 1 -T api ; ./pwm_tests -d #{dev_node} -m 1 -s 0 -T api"
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the first phase output state can be configured to HIGH and LOW",
            'testcaseID'   => 'pwm_func_api_0011',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => ""
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the event level trigger can be Disabled",
            'testcaseID'   => 'pwm_func_api_0012',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 0 -n 1 -T api",
              }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the event level trigger can be set to Positive",
            'testcaseID'   => 'pwm_func_api_0013',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
              }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the event level trigger can be set to Negative",
            'testcaseID'   => 'pwm_func_api_0014',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the event level trigger can be RSV",
            'testcaseID'   => 'pwm_func_api_0015',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
              }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output mode can be set to Disable",
            'testcaseID'   => 'pwm_func_api_0016',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
              }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output mode can be set to One-Shot",
            'testcaseID'   => 'pwm_func_api_0017',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 0 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output mode can be set to Continuous",
            'testcaseID'   => 'pwm_func_api_0018',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output mode can be set to RSV",
            'testcaseID'   => 'pwm_func_api_0019',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse repeat count can be set to 1",
            'testcaseID'   => 'pwm_func_api_0020',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 1 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse repeat count can be set to 2",
            'testcaseID'   => 'pwm_func_api_0021',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 2 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse repeat count can be set to 15",
            'testcaseID'   => 'pwm_func_api_0022',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 15 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse repeat count can be set to 31",
            'testcaseID'   => 'pwm_func_api_0023',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 31 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse repeat count can be set to its maximum value",
            'testcaseID'   => 'pwm_func_api_0024',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 50 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output period register value can be set to 1 (output period = (period count + 1) * clock cycles)",
            'testcaseID'   => 'pwm_func_api_0025',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 1 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output period register value can be set to 2 (output period = (period count + 1) * clock cycles)",
            'testcaseID'   => 'pwm_func_api_0026',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 2 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output period register value can be set to 15 (output period = (period count + 1) * clock cycles)",
            'testcaseID'   => 'pwm_func_api_0027',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 15 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output period register value can be set to 31 (output period = (period count + 1) * clock cycles)",
            'testcaseID'   => 'pwm_func_api_0028',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 31 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the output period register value can be set to its maximum value (output period = (period count + 1) * clock cycles)",
            'testcaseID'   => 'pwm_func_api_0029',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 300 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse width count register can be set to 1",
            'testcaseID'   => 'pwm_func_api_0030',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 1 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse width count register can be set to 2",
            'testcaseID'   => 'pwm_func_api_0031',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 2 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse width count register can be set to 15",
            'testcaseID'   => 'pwm_func_api_0032',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 15 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse width count register can be set to 31",
            'testcaseID'   => 'pwm_func_api_0033',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 31 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify that the pulse width count register can be set to its maximum value",
            'testcaseID'   => 'pwm_func_api_0034',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the HIGH PWM output for first phase output state by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0035',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -s 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the LOW PWM output for first phase output state by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0036',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -s 0 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for Disabled event level triggers by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0037',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for Positive event level triggers by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0038',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for Negative event level triggers by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0039',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for RSV event level triggers by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0040',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for Disabled output mode by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0041',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for One-Shot output mode by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0042',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 0 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for Continuous output mode by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0043',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for RSV output mode by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0044',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the HIGH PWM output for first phase output state by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0045',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse repeat count of 1 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0046',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 1 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse repeat count of 2 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0047',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 2 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse repeat count of 15 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0048',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 15 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse repeat count of 31 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0049',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 31 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for the maximum pulse repeat count by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0050',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 50 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a output period of 1 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0051',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 1 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a output period of 2 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0052',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 2 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a output period of 15 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0053',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 15 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a output period of 31 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0054',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 31 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for the maximum output period by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0055',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse width count register value of 1 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0056',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 1 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse width count register value of 2 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0057',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 2 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse width count register value of 15 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0058',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 15 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for a pulse width count register value of 31 by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0059',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 31 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for the maximum pulse width count register value by observing waveforms on the CRO",
            'testcaseID'   => 'pwm_func_api_0060',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM status during idle mode",
            'testcaseID'   => 'pwm_func_api_0061',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -s 0 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM operation status while it is running",
            'testcaseID'   => 'pwm_func_api_0062',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM HIGH output status",
            'testcaseID'   => 'pwm_func_api_0063',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -s 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM LOW output status",
            'testcaseID'   => 'pwm_func_api_0064',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests -s 0 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the basic open() PWM API",
            'testcaseID'   => 'pwm_func_api_0065',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the basic close() PWM API",
            'testcaseID'   => 'pwm_func_api_0066',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the basic read() PWM API",
            'testcaseID'   => 'pwm_func_api_0067',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the basic write() PWM API",
            'testcaseID'   => 'pwm_func_api_0068',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the basic ioctl() PWM API",
            'testcaseID'   => 'pwm_func_api_0069',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
      ]
    }
    tc +=
    [
        {
            'description'  => "Verify the PWM Hardware version",
            'testcaseID'   => 'pwm_func_api_0072',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "",
            }),
        },
        {
            'description'  => "Verify the PWM Software version",
            'testcaseID'   => 'pwm_func_api_0073',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "pwm_tests --version",
            }),
        }
    ]
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
  end
  # END_USR_CFG get_outputs

end
