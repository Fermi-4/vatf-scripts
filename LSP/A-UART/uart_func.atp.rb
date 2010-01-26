require '../../TestPlans/LSP/A-UART/uart_common.rb'
class Uart_funcTestPlan < TestPlan
 
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
    common_paramsChan = {
      'target_sources'  => 'LSP\st_parser',
      'ensure'  => 'exit',
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
    fail_str = '(?i:fail)'
    #mknods = 'mknod /dev/ttyS0 c 4 64;mknod /dev/ttyS1 c 4 65;mknod /dev/ttyS2 c 4 66'
    
    tc = [
      {
        'description'  =>  "Verify write 1-1048576 bytes",
        'testcaseID'   => 'uart_basic_write_0001',
        'paramsChan'  => common_paramsChan.merge({
          #'cmd' => "#{mknods};psp_test_bench FnTest UART `++exit`; uart_basic_write_interrupt `++(?i:UART_BASIC_WRITE_PASS)--#{fail_str}`;exit" 
          'cmd' => "#{mknods};st_parser uart open 1 2 1 io write_sync 1`++Write Success--(?i:fail)`" +
                      ";st_parser uart open 1 2 1 io write_sync 10`++Write Success--(?i:fail)`" +
                      ";st_parser uart open 1 2 1 io write_sync 512000`++Write Success--(?i:fail)`" +
                      ";st_parser uart open 1 2 1 io write_sync 1048576`++Write Success--(?i:fail)`",
        }),
      },
      {
        'description'  =>  "Verify read 1-1048576 bytes",
        'testcaseID'   => 'uart_basic_read_0001',
        'auto'        => false,
        'paramsChan'  => common_paramsChan.merge({
          #'cmd' => "#{mknods};psp_test_bench FnTest UART`++exit`;uart_basic_read_interrupt `++(?i:UART_BASIC_READ_PASS)--#{fail_str}`;exit" 
        }),
      },
      {
        'description'  =>  "Verify uart0 write",
        'testcaseID'   => 'uart_basic',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "#{mknods};st_parser uart open 1 2 1 io write_sync 10`++Write Success--(?i:fail)`;stty sane 115200 raw -echo crtscts < /dev/ttyS0;stty -a < /dev/ttyS0;echo \"this is test\" > /dev/ttyS0;cat /proc/tty/driver/serial`++1: uart:16550A mmio:0x01C20400 irq:41 tx:[1-9]+\\s+rx`",
        }),
      },
      {
        'description'  =>  "Verify uart1 write",
        'testcaseID'   => 'uart_basic',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "#{mknods};st_parser uart update instance 1 open 1 2 1 io write_sync 10`++Write Success--(?i:fail)`;stty sane 115200 raw -echo crtscts < /dev/ttyS1;stty -a < /dev/ttyS1;echo \"this is test\" > /dev/ttyS1;cat /proc/tty/driver/serial`++1: uart:16550A mmio:0x01C20400 irq:41 tx:[1-9]+\\s+rx`",
        }),
      },
      {
        'description'  =>  "Verify uart2 write",
        'testcaseID'   => 'uart_basic',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "#{mknods};st_parser uart update instande 2 open 1 2 1 io write_sync 10`++Write Success--(?i:fail)`;stty sane 115200 raw -echo crtscts < /dev/ttyS2;stty -a < /dev/ttyS2;echo \"this is test\" > /dev/ttyS2;cat /proc/tty/driver/serial`++2: uart:16550A mmio:0x01E06000 irq:14 tx:[1-9]+\\s+rx`",
        }),
      },
    ]
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
