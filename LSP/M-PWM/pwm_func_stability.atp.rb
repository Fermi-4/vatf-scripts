=begin
    printf("Usage:\n"
            "./pwm_tests <options>\n\n"
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

class Pwm_func_stabilityTestPlan < TestPlan
 
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
        # 'platform' => ['dm355'],
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
            'description'  => "#{dev_node}: " +  "Verify the stability of the PWM driver in Continuous mode using different period, pulse and repeat counts by configuring -> starting -> stopping the PWM for each period, pulse and repeat count",
            'testcaseID'   => 'pwm_func_api_0070',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "./pwm_tests -d #{dev_node} -m 1 -I 100 -i 31 -r 10 -s 0 -p 1 -n 1 -T api ; ./pwm_tests -d #{dev_node} -m 1 -I 50 -i 50 -r 1 -s 0 -p 1 -n 1 -T api ; ./pwm_tests -d #{dev_node} -m 1 -I 25 -i 25 -r 1 -s 0 -p 1 -n 1 -T api ; ./pwm_tests -d #{dev_node} -m 1 -I 10 -i 10 -r 1 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the stability of the PWM driver in One-Shot mode using different period, pulse and repeat counts by configuring -> starting -> stopping the PWM for each period, pulse and repeat count",
            'testcaseID'   => 'pwm_func_api_0071',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "./pwm_tests -d #{dev_node} -m 0 -I 100 -i 31 -r 10 -s 0 -p 1 -n 1 -T api ; ./pwm_tests -d #{dev_node} -m 0 -I 50 -i 50 -r 1 -s 0 -p 1 -n 1 -T api ; ./pwm_tests -d #{dev_node} -m 0 -I 25 -i 25 -r 1 -s 0 -p 1 -n 1 -T api ; ./pwm_tests -d #{dev_node} -m 0 -I 10 -i 10 -r 1 -s 0 -p 1 -n 1 -T api",
            }),
        },
      ]
    }
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
