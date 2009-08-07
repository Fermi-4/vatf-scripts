# thest tests must be run using telnet instead serial connection.
# read test must be run from serial connection.
class Uart_func_configTestPlan < TestPlan
 
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
    @baud_rate = [2400,4800,9600,19200,38400,57600,115200]  # need human intervention
    @stopbit = [1, 2]
    @parity = ['none', 'even', 'odd']
    @data = [5, 6, 7, 8]  # need human intervention
    @flowctl = ['none', 'software', 'hardware']
    {
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_manual
  def get_manual()
    fail_str = '(?i:fail|Not support)'
    open_str = 'open 2'
    stty_str = 'stty -a < /dev/ttyS0'
    write_str = "./st_parser uart #{open_str} io write_sync 6"
    
    common_paramsChan = {
      'target_sources'  => 'LSP\st_parser',
      'ensure'  => './st_parser uart ioctl set_baud 115200 set_stopbit 1 set_parity 0 set_data 8 set_flowctl 0 exit exit'
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
    @baud_rate.each {|baud_rate|
      tc += [{
        'description'  =>  "Verify that the DUT works for baud rates #{baud_rate}.",
        'testcaseID'   => 'uart_config',
        #'script'    => 'LSP\A-UART\uart_semiauto.rb',
        'paramsChan'  => common_paramsChan.merge({
          'baud_rate' => baud_rate,
          'cmd' => "\./st_parser uart #{open_str} ioctl set_baud #{baud_rate}`++#{baud_rate}--#{fail_str}`;#{stty_str}`++speed\\s+#{baud_rate}\\s+baud;`;#{write_str}" 
        }),
      }]
    }
    @stopbit.each {|stop_bit|
      tc += [{
        'description'  =>  "Verify that the DUT works for stop bit #{stop_bit}.",
        'testcaseID'   => 'uart_config',
        'paramsChan'  => common_paramsChan.merge({
          'stop_bit' => stop_bit,
          'cmd' => "\./st_parser uart #{open_str} ioctl set_stopbit #{stop_bit}`++to\\s+#{stop_bit}--#{fail_str}`;#{stty_str}`++#{get_stty_stopbit(stop_bit)}`;#{write_str}" 
        }),
      }]
    }
    @parity.each {|parity|
      tc += [{
        'description'  =>  "Verify that the DUT works for parity #{parity}.",
        'testcaseID'   => 'uart_config',
        #'script'    => 'LSP\A-UART\uart_semiauto.rb',
        'paramsChan'  => common_paramsChan.merge({
          'parity' => parity,
          'cmd' => "\./st_parser uart #{open_str} ioctl set_parity #{translate_parity(parity)}`++#{translate_parity(parity)}--#{fail_str}`;#{write_str}" 
        }),
      }]
    }
    @data.each {|data|
      tc += [{
        'description'  =>  "Verify that the DUT works for data #{data}.",
        'testcaseID'   => 'uart_config',
        #'script'    => 'LSP\A-UART\uart_semiauto.rb',
        'paramsChan'  => common_paramsChan.merge({
          'data' => data,
          'cmd' => "\./st_parser uart #{open_str} ioctl set_data #{data}`++#{data}--#{fail_str}`;#{stty_str}`++cs#{data}`;#{write_str}" 
        }),
      }]
    }
    @flowctl.each {|flowctl|
      tc += [{
        'description'  =>  "Verify that the DUT works for #{flowctl} flow control.",
        'testcaseID'   => 'uart_config',
        'paramsChan'  => common_paramsChan.merge({
          'flowctl' => flowctl,
          'cmd' => "\./st_parser uart #{open_str} ioctl set_flowctl #{translate_flowctl(flowctl)}`++to\\s+#{translate_flowctl(flowctl)}--#{fail_str}`;#{write_str}" 
        }),
      }]
    }
    tc +=  [{
        'description'  =>  "Get current config",
        'testcaseID'   => 'uart_config',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "\./st_parser uart #{open_str} ioctl get_config`++over`--#{fail_str}" 
        }),
    }]

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
  end
  # END_USR_CFG get_outputs
end

private
    # @parity = ['none', 'even', 'odd']
    # @flowctl = ['none', 'software', 'hardware']

def translate_parity(parity)
  rtn = case parity.to_s
    when 'none': '0'
    when 'even': '1'
    when 'odd':  '2'
    else  'error -- invalid parity input'
  end
end

def translate_flowctl(flowctl)
  rtn = case flowctl.to_s
    when 'none': '0'
    when 'software': '1'
    when 'hardware':  '2'
    else  'error -- invalid flowctl input'
  end
end

def get_stty_stopbit(stop_bit)
  rtn = case stop_bit.to_s
    when '1': '-cstopb'
    when '2': 'cstopb'
  end
end