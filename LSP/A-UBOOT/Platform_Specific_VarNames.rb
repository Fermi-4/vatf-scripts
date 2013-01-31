module PlatformSpecificVarNames
  @platform_specific_var_name =  {
    'ramaddress' => {  
      'dm644x-evm'=>'0x80700000',
      'dm365-evm'=>'0x80700000',
      'am37x-evm'=>'0x80200000', 
      'omap3evm'=>'0x80200000', 
      'dm646x-evm'=>'0x80700000',
      'am3517-evm'=>'0x80200000', 
      'dm368-evm'=>'0x80700000', 
      'dm355-evm'=>'0x80700000', 
      'am387x-evm'=>'0x81000000',
      'dm385-evm'=>'0x81000000',
      'ti813x-evm'=>'0x81000000',
      'am335x-evm'=>'0x81000000',
      'beaglebone'=>'0x81000000',
      'am18x-evm'=>'0xc0700000', 
      'am389x-evm'=>'0x81000000',
      'am17x-evm'=>'0xC0000000',  
      'beagle'=>'0x80200000',
      'da850-omapl138-evm'=>'0xc0700000',
      'tci6614-evm' => '0x80000100'
      },
    'ramaddress_2' => {
      'am335x-evm'=>'0x82000000'
      },
    'ramaddress_3' => {
      'am335x-evm'=>'0x84000000'
      },
    'nanderaseforramdisk' => {
      'dm644x-evm'=>'nand erase 0x460000 0x300000', 
      'dm365-evm'=>'nand erase 0xC00000  0x300000',
      'am37x-evm'=>'nand erase 0x780000 0x2000000', 
      'omap3evm'=>'nand erase 0x780000 0x2000000',
      'dm646x-evm'=>'nand erase 0x560000 0x500000', 
      'am3517-evm'=>'nand erase 0x780000 0x2000000', 
      'dm368-evm'=>'nand erase 0xC00000  0x300000', 
      'dm355-evm'=>'nand erase 0xC00000  0x300000', 
      'am387x-evm'=>'nand erase 0x006C0000  0x400000', 
      'am18x-evm'=>'nand erase 0x600000 0x400000', 
      'am389x-evm'=>'nand erase 0x006C0000  0x400000',
      'am17x-evm' => 'nand erase 0x400000 0x400000', 
      'da850-omapl138-evm' => 'nand erase 0x400000 0x400000',
      'beagle' => '',
      },
    'mtestendaddr'  => {
      'dm644x-evm'=>'0x80800000',
      'dm365-evm'=>'0x80800000',
      'am37x-evm'=>'0x80300000',
      'omap3evm'=>'0x80300000',
      'dm646x-evm'=>'0x80800000',
      'am3517-evm'=>'0x80300000',
      'dm368-evm'=>'0x80800000',
      'dm355-evm'=>'0x80800000',
      'am387x-evm'=>'0x81100000',
      'dm385-evm'=>'0x81100000',
      'ti813x-evm'=>'0x81100000',
      'am335x-evm'=>'0x81100000',
      'beaglebone'=>'0x81100000',
      'am18x-evm'=>'0xC0800000',
      'am389x-evm'=>'0x81100000',
      'am17x-evm' => '0xC0100000',
      'beagle' =>'0x80300000',
      'da850-omapl138-evm'  =>  '0xC0800000', 
      },
    'nextramaddress' => {  
      'dm644x-evm'=>'80700004',
      'dm365-evm'=>'80700004',
      'am37x-evm'=>'0x80200004',
      'omap3evm'=>'0x80200004',
      'dm646x-evm'=>'80700004',
      'am3517-evm'=>'80200004',
      'dm368-evm'=>'80700004',
      'dm355-evm'=>'80700004',
      'am387x-evm'=>'81000004',
      'dm385-evm'=>'81000004',
      'ti813x-evm'=>'81000004',
      'am335x-evm'=>'81000004',
      'beaglebone'=>'81000004',
      'am18x-evm'=>'c0700004',
      'am389x-evm'=>'81000004',
      'am17x-evm' => 'C0000004',
      'beagle' =>'80200004',
      'da850-omapl138-evm'=>'C0700004',
      'tci6614-evm' => '0x80000200'
      },
    'ramaddressfornm'  => {
      'dm644x-evm'=>'',
      'dm365-evm'=>'',
      'am37x-evm'=>'80200000',
      'omap3evm'=>'80200000',
      'dm646x-evm'=>'',
      'am3517-evm'=>'80200000',
      'dm368-evm'=>'',
      'dm355-evm'=>'',
      'am387x-evm'=>'',
      'am335x-evm'=>'0x81000000',
      'beaglebone'=>'0x81000000',
      'am18x-evm'=>'',
      'am389x-evm'=>'',
      'am17x-evm' => 'c0000000',
      'beagle' =>'80200000',
      'da850-omapl138-evm'=>'0xc0700000'
      },
    'magicpattern' => {  
      'dm644x-evm'=>'0x0000A5A5',
      'dm365-evm'=>'0x0000A5A5',
      'am37x-evm'=>'0x0000A5A5',
      'omap3evm'=>'0x0000A5A5',
      'dm646x-evm'=>'0x0000A5A5',
      'am3517-evm'=>'0x0000A5A5',
      'dm368-evm'=>'0x0000A5A5',
      'dm355-evm'=>'0x0000A5A5',
      'am387x-evm'=>'0x0000A5A5',
      'dm385-evm'=>'0x0000A5A5',
      'ti813x-evm'=>'0x0000A5A5',
      'am335x-evm'=>'0x0000A5A5',
      'beaglebone'=>'0x0000A5A5',
      'am18x-evm'=>'0x0000A5A5',
      'am389x-evm'=>'0x0000A5A5',
      'am17x-evm' => '0x0000A5A5',
      'beagle' =>'0x0000A5A5',
      'da850-omapl138-evm'=>'0x0000A5A5',
      'tci6614-evm' => '0x0000A5A5'
      },
    'bootcmd' => {  
      'dm644x-evm'=>'dhcp;tftp;bootm',
      'dm365-evm'=>'dhcp;tftp;bootm',
      'am37x-evm'=>'dhcp;tftp;bootm',
      'omap3evm'=>'dhcp;tftp;bootm',
      'dm646x-evm'=>'dhcp;tftp;bootm',
      'am3517-evm'=>'dhcp;tftp;bootm',
      'dm368-evm'=>'dhcp;tftp;bootm',
      'dm355-evm'=>'dhcp;tftp;bootm',
      'am387x-evm'=>'dhcp;tftp;bootm',
      'dm385-evm'=>'dhcp;tftp;bootm',
      'ti813x-evm'=>'dhcp;tftp;bootm',
      'am18x-evm'=>'dhcp;tftp;bootm',
      'am389x-evm'=>'dhcp;tftp;bootm',
      'am17x-evm' => 'dhcp;tftp;bootm',
      'beagle' =>'',
      'da850-omapl138-evm' => 'dhcp;tftp;bootm'
      },
    'nandoffset' => {  
      'dm644x-evm'=>'"0x460000"',
      'dm365-evm'=>'"0x1400000"',
      'am37x-evm'=>'0x780000',
      'omap3evm'=>'0x780000',
      'dm646x-evm'=>'0x560000',
      'am3517-evm'=>'0x780000',
      'dm368-evm'=>'0x1400000',
      'dm355-evm'=>'0x460000',
      'am387x-evm'=>'0x6C0000',
      'am18x-evm'=>'0x200000',
      'am389x-evm'=>'0x6C0000',
      'am17x-evm' => '0x2c0000',
      'beagle' =>'0x780000',
      'da850-omapl138-evm' => '0x200000'
      },
    'nandreadwritesize' => {  
      'dm644x-evm'=>'0x100000',
      'dm365-evm'=>'0x100000',
      'am37x-evm'=>'0x100000',
      'omap3evm'=>'0x100000',
      'dm646x-evm'=>'0x100000',
      'am3517-evm'=>'0x100000',
      'dm368-evm'=>'0x100000',
      'dm355-evm'=>'0x100000',
      'am387x-evm'=>'0x100000',
      'am18x-evm'=>'0x100000',
      'am389x-evm'=>'0x100000',
      'am17x-evm' => '0x100000',
      'beagle' =>'0x100000',
      'da850-omapl138-evm' => '0x100000'
      },
    'ramlocfornanddata' => {  
      'dm644x-evm'=>'0x80800000',
      'dm365-evm'=>'0x80800000',
      'am37x-evm'=>'0x80300000',
      'omap3evm'=>'0x80300000',
      'dm646x-evm'=>'0x80800000',
      'am3517-evm'=>'0x80300000',
      'dm368-evm'=>'0x80800000',
      'dm355-evm'=>'0x80800000',
      'am387x-evm'=>'0x81100000',
      'am18x-evm'=>'0xC0800000',
      'am389x-evm'=>'0x81100000',
      'am17x-evm' => '0xC0400000',
      'beagle' =>'0x80300000',
      'da850-omapl138-evm' => '0xC0800000'
      },
    'rambootargs' => {  
      'dm644x-evm'=>'mem=120M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'dm365-evm'=>'mem=116M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'am37x-evm'=>'mem=120M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x81600000,40M ip=dhcp',
      'omap3evm'=>'mem=120M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x81600000,40M ip=dhcp',
      'dm646x-evm'=>'mem=120M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x81100000,16M ip=dhcp',
      'am3517-evm'=>'mem=256M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0x81600000,40M ip=dhcp',
      'dm368-evm'=>'mem=116M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'dm355-evm'=>'mem=120M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'am387x-evm'=>'console=ttyS0,115200n8 mem=256M earlyprintk root=/dev/ram rw initrd=0x82000000,32MB',
      'am18x-evm'=>'mem=64M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0xc1180000,24M ip=dhcp eth=$\{ethaddr}',
      'am389x-evm'=>'console=ttyS0,115200n8 mem=256M earlyprintk root=/dev/ram rw initrd=0x82000000,32MB',
      'am17x-evm' => 'mem=32M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0xc1180000,4M ip=dhcp eth=$\{ethaddr}',
      'da850-omapl138-evm' => 'mem=32M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0xc1180000,4M ip=dhcp',
      'beagle' =>''
      },
    'rambootcmd' => {  
      'dm644x-evm'=>'dhcp;tftp 0x80700000 $bootfile; tftp 0x82000000 $ramdiskimage; bootm 0x80700000',
      'dm365-evm'=>'dhcp;tftp 0x80700000 $bootfile; tftp 0x82000000 $ramdiskimage; bootm 0x80700000',
      'am37x-evm'=>'dhcp;tftp 0x80200000 $bootfile; tftp 0x81600000 $ramdiskimage; bootm 0x80200000',
      'omap3evm'=>'dhcp;tftp 0x80200000 $bootfile; tftp 0x81600000 $ramdiskimage; bootm 0x80200000',
      'dm646x-evm'=>'dhcp;tftp 0x80700000 $bootfile; tftp 0x81100000 $ramdiskimage; bootm 0x80700000',
      'am3517-evm'=>'dhcp;tftp 0x80000000 $bootfile; tftp 0x81600000 $ramdiskimage; bootm 0x80000000',
      'dm368-evm'=>'dhcp;tftp 0x80700000 $bootfile; tftp 0x82000000 $ramdiskimage; bootm 0x80700000',
      'dm355-evm'=>'dhcp;tftp 0x80700000 $bootfile; tftp 0x82000000 $ramdiskimage; bootm 0x80700000',
      'am387x-evm'=>'dhcp;tftp 0x81000000 $bootfile; tftp 0x82000000 $ramdiskimage; bootm 0x81000000',
      'am18x-evm'=>'dhcp;tftp 0xc0700000 $bootfile; tftp 0xc1180000 $ramdiskimage; bootm 0xc0700000',
      'am389x-evm'=>'dhcp;tftp 0x81000000 $bootfile; tftp 0x82000000 $ramdiskimage; bootm 0x81000000',
      'am17x-evm' => 'dhcp;tftp 0xc0700000 $bootfile; tftp 0xc1180000 $ramdiskimage; bootm 0xc0700000',
      'da850-omapl138-evm' => 'tftp 0xc0700000 $bootfile; tftp 0xc1180000 $ramdiskimage; bootm 0xc0700000',
      'beagle' =>''
      },
    'downloaduimage' => {  
      'dm644x-evm'=>'tftp 0x80700000 $bootfile',
      'dm365-evm'=>'tftp 0x80700000 $bootfile',
      'am37x-evm'=>'tftp 0x80200000 $bootfile',
      'omap3evm'=>'tftp 0x80200000 $bootfile',
      'dm646x-evm'=>'tftp 0x80700000 $bootfile',
      'am3517-evm'=>'tftp 0x80000000 $bootfile',
      'dm368-evm'=>'tftp 0x80700000 $bootfile',
      'dm355-evm'=>'tftp 0x80700000 $bootfile',
      'am387x-evm'=>'tftp 0x81000000 $bootfile',
      'am18x-evm'=>'tftp 0xc0700000 $bootfile',
      'am389x-evm'=>'tftp 0x81000000 $bootfile',
      'am17x-evm' => 'tftp 0xc0700000 $bootfile',
      'da850-omapl138-evm' => 'tftp 0xc0700000 $bootfile',
      'beagle' =>''
      },
    'nanderaseforuimage' => {  
      'dm644x-evm'=>'nand erase 0x60000  0x200000',
      'dm365-evm'=>'nand erase 0x400000 0x300000',
      'am37x-evm'=>'nand erase 0x280000 0x300000',
      'omap3evm'=>'nand erase 0x280000 0x300000',
      'dm646x-evm'=>'nand erase 0x160000  0x300000',
      'am3517-evm'=>'nand erase 0x280000 0x300000',
      'dm368-evm'=>'nand erase 0x400000 0x300000',
      'dm355-evm'=>'nand erase 0x440000 0x300000',
      'am387x-evm'=>'nand erase 0x00280000  0x400000',
      'am18x-evm'=>'nand erase 0x200000 0x300000',
      'am389x-evm'=>'nand erase 0x00280000  0x400000',
      'am17x-evm' => 'nand erase 0x200000 0x200000',
      'da850-omapl138-evm' => 'nand erase 0x200000 0x200000',
      'beagle' =>''
      },
    'nandwriteforuimage' => {  
      'dm644x-evm'=>'nand write.e 0x80700000 0x60000 0x200000',
      'dm365-evm'=>'nand write.e 0x80700000 0x400000 0x300000',
      'am37x-evm'=>'nand write.e 0x80200000 0x280000 0x300000',
      'omap3evm'=>'nand write.e 0x80200000 0x280000 0x300000',
      'dm646x-evm'=>'nand write.e 0x80700000 0x160000 0x300000',
      'am3517-evm'=>'nand write.e 0x80000000 0x280000 0x300000',
      'dm368-evm'=>'nand write.e 0x80700000 0x400000 0x300000',
      'dm355-evm'=>'nand write.e 0x80700000 0x440000 0x300000',
      'am387x-evm'=>'nand write.e 0x81000000 0x00280000 0x400000',
      'am18x-evm'=>'nand write.e 0xc0700000 0x200000 0x300000',
      'am389x-evm'=>'nand write.e 0x81000000 0x00280000 0x400000',
      'am17x-evm' => 'nand write.e 0xc0700000 0x200000 0x200000',
      'beagle' =>'',
      'da850-omapl138-evm' => 'nand write.e 0xc0700000 0x200000 0x200000'
      },
    'downloadramdisk' => {  
      'dm644x-evm'=>'tftp 0x82000000 $ramdiskimage',
      'dm365-evm'=>'tftp 0x82000000 $ramdiskimage',
      'am37x-evm'=>'tftp 0x81600000 $ramdiskimage',
      'omap3evm'=>'tftp 0x81600000 $ramdiskimage',
      'dm646x-evm'=>'tftp 0x81100000 $ramdiskimage',
      'am3517-evm'=>'tftp 0x81600000 $ramdiskimage',
      'dm368-evm'=>'tftp 0x82000000 $ramdiskimage',
      'dm355-evm'=>'tftp 0x82000000 $ramdiskimage',
      'am387x-evm'=>'tftp 0x82000000 $ramdiskimage',
      'am18x-evm'=>'tftp 0xc1180000 $ramdiskimage',
      'am389x-evm'=>'tftp 0x82000000 $ramdiskimage',
      'am17x-evm' => 'tftp 0xc1180000 $ramdiskimage',
      'beagle' =>'',
      'da850-omapl138-evm' => 'tftp 0xc1180000 $ramdiskimage'
      },
    'nanderaseforramdisk' => {  
      'dm644x-evm'=>'nand erase 0x460000 0x300000',
      'dm365-evm'=>'nand erase 0xC00000  0x300000',
      'am37x-evm'=>'nand erase 0x780000 0x2000000',
      'omap3evm'=>'nand erase 0x780000 0x2000000',
      'dm646x-evm'=>'nand erase 0x560000 0x500000',
      'am3517-evm'=>'nand erase 0x780000 0x2000000',
      'dm368-evm'=>'nand erase 0xC00000  0x300000',
      'dm355-evm'=>'nand erase 0xC00000  0x300000',
      'am387x-evm'=>'nand erase 0x006C0000  0x400000',
      'am18x-evm'=>'nand erase 0x600000 0x400000',
      'am389x-evm'=>'nand erase 0x006C0000  0x400000',
      'am17x-evm' => 'nand erase 0x400000 0x400000',
      'beagle' =>'',
      'da850-omapl138-evm' => 'nand erase 0x400000 0x400000'
      },
    'nandwriteforramdisk' => {  
      'dm644x-evm'=>'nand write.e 0x82000000 0x460000 0x300000',
      'dm365-evm'=>'nand write 0x82000000 0xC00000 0x300000',
      'am37x-evm'=>'nand write.e 0x81600000 0x780000 0x2000000',
      'omap3evm'=>'nand write.e 0x81600000 0x780000 0x2000000',
      'dm646x-evm'=>'nand write.e 0x81100000  0x560000 0x500000',
      'am3517-evm'=>'nand write.e 0x81600000 0x780000 0x2000000',
      'dm368-evm'=>'nand write 0x82000000 0xC00000 0x300000',
      'dm355-evm'=>'nand write 0x82000000 0xC00000 0x300000',
      'am387x-evm'=>'nand write.e 0x82000000 0x006C0000  0x400000',
      'am18x-evm'=>'nand write.e 0xc1180000 0x600000 0x400000',
      'am389x-evm'=>'nand write.e 0x82000000 0x006C0000  0x400000',
      'am17x-evm' => 'nand write.e 0xc1180000 0x400000 0x400000',
      'beagle' =>'',
      'da850-omapl138-evm' => 'nand write.e 0xc1180000 0x400000 0x400000'      
      },
    'nandbootcmd' => {  
      'dm644x-evm'=>'nand read.e 0x82000000 0x460000 0x300000; nboot 0x80700000  0 0x60000; bootm',
      'dm365-evm'=>'nand read.e 0x82000000 0xC00000 0x300000; nboot 0x80700000  0 0x400000; bootm',
      'am37x-evm'=>'nand read.e 0x81600000 0x780000 0x2000000; nboot 0x80200000  0 0x280000; bootm',
      'omap3evm'=>'nand read.e 0x81600000 0x780000 0x2000000; nboot 0x80200000  0 0x280000; bootm',
      'dm646x-evm'=>'nand read.e 0x81100000 0x560000 0x500000; nboot 0x80700000  0 0x160000; bootm',
      'am3517-evm'=>'nand read.e 0x81600000 0x780000 0x2000000; nboot 0x80000000  0 0x280000; bootm 0x80000000',
      'dm368-evm'=>'nand read.e 0x82000000 0xC00000 0x300000; nboot 0x80700000  0 0x400000; bootm',
      'dm355-evm'=>'nand read.e 0x82000000 0xC00000 0x300000; nboot 0x80700000  0 0x440000; bootm',
      'am387x-evm'=>'nand read.e 0x82000000 0x006C0000 0x400000; nboot.e 0x81000000 0 0x00280000; bootm',
      'am18x-evm'=>'nand read.e 0xc1180000 0x600000 0x400000; nboot.e 0xc0700000 0 0x200000; bootm',
      'am389x-evm'=>'nand read.e 0x82000000 0x006C0000 0x400000; nboot.e 0x81000000 0 0x00280000; bootm',
      'am17x-evm' => 'nand read.e 0xc1180000 0x400000 0x400000; nboot.e 0xc0700000 0 0x200000; bootm',
      'beagle' =>'',
      'da850-omapl138-evm' => 'nand read.e 0xc1180000 0x400000 0x400000; nboot.e 0xc0700000 0 0x200000; bootm'
      },
    'nandbootargs' => {  
      'dm644x-evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0xc1180000,4M ip=dhcp',
      'dm365-evm'=>'mem=116M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'am37x-evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x81600000,40M ip=dhcp',
      'omap3evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x81600000,40M ip=dhcp',
      'dm646x-evm'=>'mem=120M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x81100000,16M ip=dhcp',
      'am3517-evm'=>'"mem=256M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0x81600000,40M ip=dhcp',
      'dm368-evm'=>'mem=116M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'dm355-evm'=>'mem=116M console=ttyS0,115200n8 root=/dev/ram0 rw initrd=0x82000000,4M ip=dhcp',
      'am387x-evm'=>'console=ttyS0,115200n8 mem=256M earlyprintk root=/dev/ram rw initrd=0x82000000,32MB',
      'am18x-evm'=>'mem=32M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0xc1180000,4M ip=dhcp eth=${ethaddr}',
      'am389x-evm'=>'console=ttyS0,115200n8 mem=256M earlyprintk root=/dev/ram rw initrd=0x82000000,32MB',
      'am17x-evm' => 'mem=32M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0xc1180000,4M ip=dhcp eth=${ethaddr}',
      'beagle' =>'',
      'da850-omapl138-evm' => 'mem=32M console=ttyS2,115200n8 root=/dev/ram0 rw initrd=0xc1180000,4M ip=dhcp'
      },
    'mmcbootargs' => {  
      'dm644x-evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'dm365-evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'am37x-evm'=>'mem=128M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'omap3evm'=>'mem=128M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'dm646x-evm'=>'',
      'am3517-evm'=>'mem=256M console=ttyS2,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'dm368-evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'dm355-evm'=>'mem=32M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'am387x-evm'=>'mem=32M console=ttyS2,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'dm385-evm'=>'mem=128M console=ttyO0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'ti813x-evm'=>'mem=128M console=ttyO0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'am18x-evm'=>'mem=32M console=ttyS2,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'am389x-evm'=>'mem=32M console=ttyS2,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'am17x-evm' => 'mem=32M console=ttyS0,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'beagle' =>'vram=12M console=ttyS2,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off',
      'da850-omapl138-evm'=>'mem=32M console=ttyS2,115200n8 root=/dev/mmcblk0p2 rw rootwait ip=off'
      },
    'mmcbootcmd' => {  
      'dm644x-evm'=>'fatload mmc 0 0x80700000 $bootfile;bootm',
      'dm365-evm'=>'fatload mmc 0 0x80700000 $bootfile;bootm',
      'am37x-evm'=>'fatload mmc 0 0x82000000 $bootfile;bootm',
      'omap3evm'=>'fatload mmc 0 0x82000000 $bootfile;bootm',
      'dm646x-evm'=>'',
      'am3517-evm'=>'fatload mmc 0 0x80000000 $bootfile;bootm 0x80000000',
      'dm368-evm'=>'fatload mmc 0 0x80700000 $bootfile;bootm',
      'dm355-evm'=>'fatload mmc 0 0x80700000 $bootfile;bootm',
      'am387x-evm'=>'fatload mmc 0 0x81000000 $bootfile;bootm',
      'dm385-evm'=>'fatload mmc 0 0x81000000 $bootfile;bootm',
      'ti813x-evm'=>'fatload mmc 0 0x81000000 $bootfile;bootm',
      'am18x-evm'=>'fatload mmc 0 0xc0700000 $bootfile;bootm',
      'am389x-evm'=>'fatload mmc 0 0x81000000 $bootfile;bootm',
      'am17x-evm' => 'fatload mmc 0 0xC0000000 $bootfile;bootm',
      'beagle' =>'fatload mmc 0 0x82000000 $bootfile;bootm 0x82000000',
      'da850-omapl138-evm'=>'fatload mmc 0 0xc0700000 $bootfile;bootm'
      },
    'i2cchipadd' => {  
      'dm644x-evm'=>'0x50',
      'dm365-evm'=>'0x50',
      'am37x-evm'=>'0x48',
      'omap3evm'=>'0x48',
      'dm646x-evm'=>'0x50',
      'am3517-evm'=>'0x48',
      'dm368-evm'=>'0x50',
      'dm355-evm'=>'0x50',
      'am387x-evm'=>'0x50',
      'dm385-evm'=>'0x50',
      'ti813x-evm'=>'0x50',
      'am18x-evm'=>'',
      'am389x-evm'=>'0x50',
      'am17x-evm' => '',
      'beagle' =>'0x48',
      'da850-omapl138-evm'=>''
      },
    'i2coff1' => {  
      'dm644x-evm'=>'0',
      'dm365-evm'=>'0',
      'am37x-evm'=>'0',
      'omap3evm'=>'0',
      'dm646x-evm'=>'0',
      'am3517-evm'=>'0',
      'dm368-evm'=>'0',
      'dm355-evm'=>'0',
      'am387x-evm'=>'0',
      'dm385-evm'=>'0',
      'ti813x-evm'=>'0',
      'am18x-evm'=>'',
      'am389x-evm'=>'0',
      'am17x-evm' => '',
      'beagle' =>'0',
      'da850-omapl138-evm'=>'',
      'tci6614-evm' => '0'
      },
    'i2coff2' => {  
      'dm644x-evm'=>'2',
      'dm365-evm'=>'2',
      'am37x-evm'=>'2',
      'omap3evm'=>'2',
      'dm646x-evm'=>'2',
      'am3517-evm'=>'2',
      'dm368-evm'=>'2',
      'dm355-evm'=>'2',
      'am387x-evm'=>'2',
      'am18x-evm'=>'',
      'am389x-evm'=>'2',
      'am17x-evm' => '',
      'beagle' =>'2',
      'da850-omapl138-evm'=>'',
      'tci6614-evm' => '2'
      },
    'i2cmagicval' => {  
      'dm644x-evm'=>'55',
      'dm365-evm'=>'55',
      'am37x-evm'=>'55',
      'omap3evm'=>'55',
      'dm646x-evm'=>'55',
      'am3517-evm'=>'55',
      'dm368-evm'=>'55',
      'dm355-evm'=>'55',
      'am387x-evm'=>'55',
      'am18x-evm'=>'',
      'am389x-evm'=>'55',
      'am17x-evm' => '',
      'beagle' =>'55',
      'da850-omapl138-evm'=>'',
      'tci6614-evm' => '55'
      },
    'i2caddrprmpt' => {  
      'dm644x-evm'=>'00000000',
      'dm365-evm'=>'00000000',
      'am37x-evm'=>'00000000',
      'omap3evm'=>'00000000',
      'dm646x-evm'=>'00000000',
      'am3517-evm'=>'00000000',
      'dm368-evm'=>'00000000',
      'dm355-evm'=>'00000000',
      'am387x-evm'=>'00000000',
      'am18x-evm'=>'',
      'am389x-evm'=>'00000000',
      'am17x-evm' => '',
      'beagle' =>'00000000',
      'da850-omapl138-evm'=>''
      },
    'i2cnextaddrprmpt' => {  
      'dm644x-evm'=>'00000001',
      'dm365-evm'=>'00000001',
      'am37x-evm'=>'00000001',
      'omap3evm'=>'00000001',
      'dm646x-evm'=>'00000001',
      'am3517-evm'=>'00000001',
      'dm368-evm'=>'00000001',
      'dm355-evm'=>'00000001',
      'am387x-evm'=>'00000001',
      'am18x-evm'=>'',
      'am389x-evm'=>'00000001',
      'am17x-evm' => '',
      'beagle' =>'00000001',
      'da850-omapl138-evm'=>''
      },
    'bootargs' => {  
      'dm644x-evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'dm365-evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=116M ip=dhcp',
      'am37x-evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=128M ip=dhcp',
      'omap3evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=128M ip=dhcp',
      'dm646x-evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'am3517-evm'=>'console=ttyS2,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=256M ip=dhcp',
      'dm368-evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=116M ip=dhcp',
      'dm355-evm'=>'console=ttyS0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'am387x-evm'=>'console=ttyO0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'dm385-evm'=>'console=ttyO0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'ti813x-evm'=>'console=ttyO0,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'am18x-evm'=>'console=ttyS2,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'am389x-evm'=>'console=ttyO2,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'am17x-evm' => 'console=ttyS2,115200n8 noinitrd rw root=/dev/nfs nfsroot=$serverip:$nfspath,nolock mem=120M ip=dhcp',
      'beagle' =>'',
      'da850-omapl138-evm' => 'console=ttyS2,115200n8 noinitrd rw ip=dhcp root=/dev/nfs nfsroot=192.168.247.76:$nfspath ,nolock mem=32M@0xc0000000 mem=64M@0xc4000000 vpif_capture.ch0_bufsize=831488 vpif_display.ch2_bufsize=831488',
      'tci6614-evm' => 'console=ttyS0,115200n8 ip=dhcp root=/dev/nfs nfsroot=$nfspath,v3,tcp rw'
            }
    }
  def translate_var_name(platform, var_name)
    return var_name if !@platform_specific_var_name.include?(var_name)
    return var_name if !@platform_specific_var_name[var_name].include?(platform)
    return @platform_specific_var_name[var_name][platform]
  end
end


