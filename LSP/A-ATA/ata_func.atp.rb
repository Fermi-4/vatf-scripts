require '../../TestPlans/LSP/A-ATA/ata_common'

#---
#:section: General
# Test Area:: ATA
# Test Type:: Functionality
# Test Owners:: Asha (TII), Yan Liu (TIGT)
#---

#---
#:section: Overview
# These area test plan is part of the ATA area test plans. This ATP just covers the functionality test cases related
# to ATA. There are other ATPs that cover performance and stress test cases.
# ATA/ATAPI is an interface between a host processor and data storage or audio devices.
# Devices like hard disk drives are ATA devices. Devices like CDs, compact flash and DVDs are ATAPI devices.
# The test cases defined in this test plan check proper functionality of the ATA/ATAPI driver with different devices.
#---

#---
#:section: References
# * TMS320DM644x DMSoc ATA Controller User's Guide 
# * ATA/ATAPI-6 specification (d1410r3b-ATA-ATAPI-6.pdf)
#---

#---
#:section: Required Hardware
# * Proper CD-ROM or DVD-ROM
# * One hard disk with size > 256GB
# * One hard disk with size < 256GB (Built-in hard disk in EVM)
#---

#---
#:section: Setup
# There is no external test equipment. The typical automation setup of VATF PC, PortMaster and APC
# can be used.
#
# link:../ATP_LSP_Ata.jpg
#---

#---
#:section: Test Focus
# The focus is to check ATA driver's functionality with combination of:
# * different device type such as ATA device type like hard disk or ATAPI device type like CD-ROM.
# * different mode of operations such as pio0~4, mdma0~2 or udma0~5.
# * different power modes such as active, standby or sleep.
# * different LBA modes such as 28-bits or 48-bits addressing mode.
# * different filesystem types like Ext2, Ext3.
# * different file sizes
# * different buffer sizes
# The tests also verify that the appropriate proc entry are created by the Linux driver like ioports and interrupts. 
# In addition, this test plan also verifies the basic functionality when two devices (either HD or CD) are connected into one channel.
#---

#---
#:section: Tests not included/ Future Enhancements 
# * CF -- Compact Flash 
# * SATA -- Serial ATA
#---

#---
#:section: Test Parameters.
# See get_params() method at Ata_funcTestPlan class 
#---

class Ata_funcTestPlan < TestPlan
  include Ata_common
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['device_type', 'lba_mode', 'fs_type', 'test_type', 'op_mode']
    @sort_by = ['device_type', 'lba_mode', 'fs_type', 'test_type', 'op_mode']
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
    # from PRD-LSP-210: SR-4.3.4.6.3	Mode of operation: The IDE ATA driver shall support up to UDMA4 (UDMA0 – UDMA4).
    @op_mode =  ['pio0', 'pio1', 'pio2', 'pio3', 'pio4'] +
                ['mdma0', 'mdma1', 'mdma2'] +
                ['udma0', 'udma1', 'udma2', 'udma3','udma4', 'udma5',]
    @power_mode = ['active', 'idle', 'standby', 'sleep']
    @lba_mode = ['28bits', '48bits']
    @device_type = ['ata_device', 'atapi_device']
    # from PRD-LSP-210: SR-4.3.4.6.4 Filesystem: EXT3 shall be the default file system supported on the Hard Drive. EXT2 shall also be supported on the Hard Drive.
    @fs_type = ['ext3', 'ext2'] 
    {
      # operational mode
      'op_mode'     => @op_mode,
      'power_mode'  => @power_mode,
      'device_type' => @device_type,  # for testing ATA or ATAPI
      'lba_mode'    => @lba_mode,
      'file_size'   => [500, 100*1024, 500*1024, 1024*1024, 55*1024*1024, 10*1024*1024, 100*1024*1024],
      'buffer_size' => [100*1024, 500*1024, 1*1024*1024, 5*1024*1024],
      'append_size' => [500, 500*1024, 1*1024*1024, 5*1024*1024],
      'test_type'   => ['write-read', 'write-append', 'read'],
      'fs_type'     => @fs_type,
      'mnt_point'   => ['/mnt/ata'],
      'device_node' => ['/dev/hda1'],
      'test_file'   => ['/mnt/ata/test_file'], 
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      'IF [file_size] <= 1048576 THEN [buffer_size] in {102400, 512000};',
      'IF [device_type] = "atapi_device" THEN [test_type] = "read" ELSE [test_type] <> "read";',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_sources'  => 'LSP\A-EDMA\edma_test',
      #'ensure'  => "rmmod {module_name}`--(?i:fail|error)`",
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
    tc = [
      {
        'description'  => "Verify that the driver is not initialized when no media is present.  ", 
        'testcaseID'   => 'ata_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
        }),
        'auto'  => false,
      },
      {
        'description'  => "Verify proc/ioports for an ATA device", 
        'testcaseID'   => 'ata_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'cat /proc/ioports`++(?i:ide)`'
        }),
      },
      {
        'description'  => "Verify proc/interrupts for an ATA device", 
        'testcaseID'   => 'ata_func_man_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'cat /proc/interrupts`++(?i:ide)`'
        }),
      },
      {
        'description'  => "Verify proc/ide for an ATA device", 
        'testcaseID'   => 'ata_func_man_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'ls /proc/ide`++(?i:ide)`'
        }),
      },
      {
        'description'  => "Verify that the module cannot be inserted when already statically built.", 
        'testcaseID'   => 'ata_func_man_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'insmod xx``', #TODO:
        }),
        'auto'  => false,
      },
      {
        'description' => "Multiple mount points with different File systems.", 
        'testcaseID'  => "ata_func_man_0006",
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "mkfs -t #{@fs_type[0]} /dev/hda1;mkfs -t #{@fs_type[1]} /dev/hda2" +
                        ";mkdir /mnt/ata1;mkdir /mnt/ata2" +
                        ";mount -t #{@fs_type[0]} /mnt/ata1;mount`++/mnt/ata1`" +
                        ";mount -t #{@fs_type[1]} /mnt/ata2;mount`++/mnt/ata2`",      
        }),
      },
    ]
    
    tc_append = []
    @lba_mode.each {|mode|
      tc_append += [
        {
          'description'  => "Verify that one ATA device that is connected is detected and initialized during initialization when lba mode is #{@lba_mode}.", 
          'testcaseID'   => 'ata_func_man_0001',
          'paramsChan'  => common_paramsChan.merge({
          }),
          'auto'  => false,
        },
        {
          'description'  => "Verify that two ATA devices that are connected are detected and initialized during initialization when lba mode is #{@lba_mode}.", 
          'testcaseID'   => 'ata_func_man_0002',
          'paramsChan'  => common_paramsChan.merge({
          }),
          'auto'  => false,
        },
        {
          'description'  => "Verify that one ATAPI device that is connected is detected and initialized during initialization when lba mode is #{@lba_mode}.", 
          'testcaseID'   => 'ata_func_man_0003',
          'paramsChan'  => common_paramsChan.merge({
          }),
          'auto'  => false,
        },
        {
          'description'  => "Verify that two ATAPI device that are connected are detected and initialized during initialization when lba mode is #{@lba_mode}.", 
          'testcaseID'   => 'ata_func_man_0004',
          'paramsChan'  => common_paramsChan.merge({
          }),
          'auto'  => false,
        },
        {
          'description'  => "Verify that one ATA device and one ATAPI device that are connected are detected and initialized during initialization when lba mode is #{@lba_mode}.", 
          'testcaseID'   => 'ata_func_man_0005',
          'paramsChan'  => common_paramsChan.merge({
          }),
          'auto'  => false,
        },
      ]
    }
    tc = tc + tc_append
        
    tc_config = []
    @op_mode.each { |mode|
      tc_config << {
        'description'  => "Verify the driver can be configured into I/O modes: #{mode} mode", 
        'testcaseID'   => "ata_func_#{mode}",
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "hdparm -X#{get_xfer_mode(mode)} /dev/hda;hdparm -i /dev/hda`++\\*#{mode}`"
        }),
      }
    }
    tc = tc + tc_config

    tc_config = []
    @power_mode.each { |mode|
      tc_config << {
        'description'  => "Verify the driver can be configured into power modes: #{mode} mode;" +
                          " and read/write operation work fine in this power mode", 
        'testcaseID'   => "ata_func_#{mode}",
        'script'       => 'LSP\A-ATA\ata.rb',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => get_power_mode_cmd(mode) + 
                        ";\./st_parser fsapi fwrite /mnt/ata/test_file 1024 fread /mnt/ata/test_file`--(?i:fail)`"
        }),
      }
    }
    tc = tc + tc_config

    tc_config = []
    @fs_type.each { |fs|
      tc_config << {
        'description'  => "Create multiple mount points for #{fs.upcase} filesystem.", 
        'testcaseID'   => "ata_func_#{fs}",
        'paramsChan'  => common_paramsChan.merge({
          # make sure the fstype on device is what I want. need mkfs????
          'cmd'       => "umount /dev/hda1;mkdir /mnt/ata1;mount -t #{fs} /dev/hda1 /mnt/ata1;mount`++/mnt/ata1`" +
                        ";echo abc > /mnt/ata1/test1;ls /mnt/ata1/test*`++test1`" +
                        ";mkdir /mnt/ata2;mount -t #{fs} /dev/hda1 /mnt/ata2;mount`++/mnt/ata2`" +
                        ";echo abc > /mnt/ata2/test2;ls /mnt/ata2/test*`++test2`",
          'ensure'    => "rm /mnt/ata1/test1;rm /mnt/ata2/test2;umount /mnt/ata;umount /mnt/ata2",
        }),
      }
    }
    tc = tc + tc_config
    
    # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      #val.merge!(common_vars)
      tc_new << common_vars.merge(val)
    }
    
    return tc_new
  end
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'target_sources'  => 'LSP\st_parser',
        'op_mode'         => params['op_mode'],
        'power_mode'      => params['power_mode'],
        'lba_mode'        => params['lba_mode'],
        'file_size'       => params['file_size'],
        'append_size'     => params['append_size'],
        'buffer_size'     => params['buffer_size'],
        'test_type'       => params['test_type'],
        'test_file'       => params['test_file'],
        'fs_type'         => params['fs_type'],
        'mnt_point'       => params['mnt_point'],
        'device_node'     => params['device_node'],
        'cmd'             => "#{get_power_mode_cmd(params['power_mode'])}" +
                          ";#{set_opmode(params['op_mode'])};[dut_timeout\\=30]" +
                          ";#{get_cmd(params['test_type'], params['file_size'], params['buffer_size'], params['append_size'], params['test_file'])}",
        'ensure'          => "[dut_timeout\\=30];rm #{params['test_file']}"
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      # 'description'    => get_desc("Verify for #{params['chan_type'].upcase} channel with #{params['transfer_type'].upcase}" +
                          # " + #{params['addr_mode'].upcase} + #{params['features'].upcase}, data with size #{params['file_size']} bytes transfer sucessfully", params['test_switch']),
      'description'     => "Verify the #{params['test_type']} operation on a file of size #{params['file_size']}" +
                          " with buffer size #{params['buffer_size']} on operation mode #{params['op_mode']} on hard disk.",
      'testcaseID'      => "ata_func_" + "%04d" % "#{@current_id}",
      'script'          => 'LSP\A-ATA\ata.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private
  
  def get_cmd(test_type, file_size, buffer_size, append_size, test_file)
    rtn = case test_type
      when 'write-read':  "\./st_parser fsapi buffsize #{buffer_size} fwrite #{test_file} #{file_size}`--(?i:fail|fatal)`" +
                          ";\./st_parser fsapi fread {test_file}`--(?i:fail)`"
      when 'write-append':"\./st_parser fsapi buffsize #{buffer_size} fwrite #{test_file} #{file_size}--(?i:fail|fatal)`" +
                          ";\./st_parser fsapi fappend #{test_file} #{append_size}--(?i:fail)`"
      when 'read':  "\./st_parser fsapi buffsize #{buffer_size} fread #{test_file}`--(?i:fail)`"
      else  "echo no cmd for #{test_type}`--no\\s+cmd`"
    end
  end
  
end #END_CLASS
