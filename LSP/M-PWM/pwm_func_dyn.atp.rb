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

class Pwm_func_dynTestPlan < TestPlan
 
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
        'dsp'       => ['dynamic'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
        'custom'    => ['default'],
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
    insmod_pwm = "insmod davinci_pwm.ko`--(?i:fail)`"
    rmmod_pwm = "rmmod davinci_pwm"
    
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
    tc = [
      {
        'description'  => "Verify insmod of module works fine.", 
        'testcaseID'   => 'keypad_func_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "#{rmmod_pwm};#{insmod_pwm};lsmod`++pwm`",
        }),
      },
      {
        'description'  => "Verify rmmod of module works fine.", 
        'testcaseID'   => 'keypad_func_0002',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{rmmod_pwm};#{insmod_pwm};lsmod`++pwm`" + ";#{rmmod_pwm};lsmod`--pwm`",
        }),
      },
      {
        'description'  => "Verify multiple insmod and rmmod of module works fine.", 
        'testcaseID'   => 'keypad_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod_pwm};#{rmmod_pwm};#{insmod_pwm};#{rmmod_pwm};#{insmod_pwm};#{rmmod_pwm}"
        }),
      },
    ]

    @dev_nodes.each {|dev_node|
      tc += 
      [
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output for default mode, period and pulse width",
            'testcaseID'   => 'pwm_func_api_0002',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{rmmod_pwm};#{insmod_pwm};pwm_tests -d #{dev_node} -m 1 -I 100 -i 50 -r 10 -s 0 -p 1 -n 1 -T api",
            }),
        },
        {
            'description'  => "#{dev_node}: " +  "Verify the PWM output by changing the mode, period and pulse width from the default parameters",
            'testcaseID'   => 'pwm_func_api_0003',
            'paramsChan'  => common_paramsChan.merge({
              #'cmd' => "#{pwm_open} st_parser pwm set_mode 1#{pwm_pass_fail} st_parser pwm set_period 2#{pwm_pass_fail}" \
              #  "st_parser pwm set_pw 2#{pwm_pass_fail} st_parser pwm set_rpt_cnt 2#{pwm_pass_fail} #{pwm_start}",
              #'cmd' => "pwm_tests -d {instance} -m {mode} -I {period} -i {pw} -r {rpt_cnt} -s {idle_state} -p {1st_phase} -n {count} -T {test_type}"
              'cmd' => "#{rmmod_pwm};#{insmod_pwm};pwm_tests -d #{dev_node} -m 1 -I 200 -i 150 -r 20 -s 1 -p 0 -n 1 -T api"
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
