module PlatformSpecificVarNames
  @platform_specific_var_name = Hash.new()
  @platform_specific_var_name.merge!(
    'ramaddress' => {  
      'am43xx-epos' => '0x81000000',
      'omap5-evm' => '0x82000000',
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
      'am43xx-gpevm'=>'0x81000000',
      'dra7xx-evm'=>'0x80200000',
      'am57xx-evm'=>'0x80200000',
      'dra72x-evm'=>'0x80200000',
      'beaglebone'=>'0x81000000',
      'am18x-evm'=>'0xc0700000', 
      'am389x-evm'=>'0x81000000',
      'am17x-evm'=>'0xC0000000',  
      'beagle'=>'0x80200000',
      'da850-omapl138-evm'=>'0xc0700000',
      'tci6614-evm' => '0x80000100',
      'k2hk-evm' => '80000000',
      'k2l-evm' => '80000000',
      'k2e-evm' => '80000000'
      },
    'ramaddress_2' => {
      'am43xx-epos' => '0x82000000',
      'am335x-evm'=>'0x82000000',
      'am43xx-gpevm'=>'0x82000000',
      'dra7xx-evm'=>'0x81200000',
      'am57xx-evm'=>'0x81200000',
      'dra72x-evm'=>'0x81200000',
      'omap5-evm' => '0x83000000',
      'k2hk-evm' => 'f0000000',
      'k2l-evm' => 'f0000000',
      'k2e-evm' => 'f0000000'
      },
    'ramaddress_3' => {
      'am43xx-epos' => '0x84000000',
      'omap5-evm' => '0x84000000',
      'am335x-evm'=>'0x84000000',
      'am43xx-gpevm'=>'0x84000000',
      'dra7xx-evm'=>'0x84000000',
      'am57xx-evm'=>'0x84000000',
      'dra72x-evm'=>'0x84000000',
      },
    'nextramaddress' => {  
      'omap5-evm'=>'82000004',
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
      'am43xx-gpevm'=>'81000004',
      'dra7xx-evm'=>'80200004',
      'am57xx-evm'=>'80200004',
      'dra72x-evm'=>'80200004',
      'beaglebone'=>'81000004',
      'am18x-evm'=>'c0700004',
      'am389x-evm'=>'81000004',
      'am17x-evm' => 'C0000004',
      'beagle' =>'80200004',
      'da850-omapl138-evm'=>'C0700004',
      'tci6614-evm' => '0x80000200',
      'k2hk-evm' => '0x80000200',
      'k2l-evm' => '0x80000200',
      'k2e-evm' => '0x80000200'
      },
    )

    @platform_specific_var_name['magicpattern'] = Hash.new('0x0000A5A5')
    @platform_specific_var_name['magicpattern'].merge!(
      {
      'k2hk-evm' => '0000A5A5',
      'k2l-evm' => '0000A5A5',
      'k2e-evm' => '0000A5A5'
      },
    )

    @platform_specific_var_name['nand_test_addr'] = Hash.new('00900000')
    @platform_specific_var_name['nand_test_addr'].merge!(
      {
      'am335x-evm'=>'00900000',
      'dra7xx-evm'=>'00900000',
      'dra72x-evm'=>'00900000',
      'am43xx-gpevm'=>'00900000',
      },
    )

    @platform_specific_var_name['i2cchipadd'] = Hash.new('0x50')
    @platform_specific_var_name['i2cchipadd'].merge!(
      {
      'am3517-evm'=>'0x48',
      'am18x-evm'=>'',
      'beagle' =>'0x48',
      'da850-omapl138-evm'=>'',
      'k2hk-evm' => '0x50',
      'k2l-evm' => '0x50',
      'k2e-evm' => '0x50',
      'am57xx-evm' => '0x48',
      },
    )

    @platform_specific_var_name['i2coff1'] = Hash.new('0xa')
    @platform_specific_var_name['i2coff1'].merge!(
      {
      'da850-omapl138-evm'=>'',
      'k2hk-evm' => '0',
      'k2l-evm' => '0',
      'k2e-evm' => '0',  
      'am57xx-evm' => '0x2'
      },
    )

    @platform_specific_var_name['i2coff2'] = Hash.new('0xc')
    @platform_specific_var_name['i2coff2'].merge!(
      {
      'da850-omapl138-evm'=>'',
      'k2hk-evm' => '2',
      'k2l-evm' => '2',
      'k2e-evm' => '2'
      },
    )

    @platform_specific_var_name['i2cmagicval'] = Hash.new('55')
    @platform_specific_var_name['i2cmagicval'].merge!(
      {
      'da850-omapl138-evm'=>'',
      'k2hk-evm' => '55',
      'k2l-evm' => '55',
      'k2e-evm' => '55'
      },
    )

    @platform_specific_var_name['i2caddrprmpt'] = Hash.new('00000000')
    @platform_specific_var_name['i2caddrprmpt'].merge!(
      {
      'da850-omapl138-evm'=>''
      },
    )

    @platform_specific_var_name['i2cnextaddrprmpt'] = Hash.new('00000001')
    @platform_specific_var_name['i2cnextaddrprmpt'].merge!(
      {
      'da850-omapl138-evm'=>''
      },
    )

	  # Core PLL clock values
    @platform_specific_var_name.merge!(
    'clkspeed_0' => {  
      'k2hk-evm' => 1200000000,
      'k2l-evm' => 1000594188,
      'k2e-evm' => 1250000000
      },
    )


  def translate_var_name(platform, var_name)
    return var_name if !@platform_specific_var_name.include?(var_name)
    return @platform_specific_var_name[var_name][platform]
  end
end

