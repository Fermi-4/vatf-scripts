class Nand_func_eccTestPlan < TestPlan
  
   # BEG_CLASS_INIT
   def initialize()
     super
     #@import_only = true
   end
   # END__CLASS_INIT    
   
   # BEG_USR_CFG setup
   def setup()
     @group_by = ['nand_page']
     @sort_by = ['nand_page']
   end
   # END_USR_CFG setup
   
   # BEG_USR_CFG get_keys
   def get_keys()
     keys = [
     {
         'dsp'       => ['static'],   # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
         'micro'     => ['default'],      # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
         'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
         'custom'    => ['default'],
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
     @fs_type = ['']   
     {
     }
   end
   # END_USR_CFG get_params
 
   # BEG_USR_CFG get_manual
   def get_manual()
     nand_page =['2k', '4k']
     common_paramsChan = {
     }
     
     common_vars = {
       'configID'    => '..\Config\lsp_generic.ini', 
       'script'      => 'LSP\A-NAND\ecc_test.rb',
       'auto'	=> true,      
     }
     
     tc = []

     nand_page.each{|chip|
      tc += [
         {
             'description'  =>  "#{chip}: Verify mtdutils: flash_eraseall, nandwrite, nanddump",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0019',
             'auto'         => false,
             'paramsChan'  => common_paramsChan.merge({
             }),
         },
         # {
             # 'description'  =>  "#{chip}: Verify 1 bit ECC can be corrected for 1st 512 chunk",
             # 'configID'     => '..\Config\lsp_generic.ini', 
             # 'testcaseID'   => 'nand_func_basic_0020',
             # 'auto'         => false,
             # 'paramsChan'  => common_paramsChan.merge({
                # 'bin_file_w_errbits' => get_bin_file_w_err_1b_1sttrunk(chip),
                # 'page_size' => get_page_size(chip),
                # 'hex_file_orig_nandpage' => get_orig_nandpage(chip),
             # }),
         # },
         {
             'description'  =>  "#{chip}: Verify 1 bit ECC can be corrected for all 512byte-trunks.",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0020',
             'auto'         => true,
             'paramsChan'  => common_paramsChan.merge({
                'bin_file_w_errbits' => get_bin_file_w_err_1b_alltrunk(chip),
                'page_size' => get_page_size(chip),
                'hex_file_orig_nandpage' => get_orig_nandpage(chip),
             }),
         },
         # {
             # 'description'  =>  "#{chip}: Verify 4 bit ECC can be corrected for 1st 512 chunk",
             # 'configID'     => '..\Config\lsp_generic.ini', 
             # 'testcaseID'   => 'nand_func_basic_0020',
             # 'auto'         => false,
             # 'paramsChan'  => common_paramsChan.merge({
                # 'bin_file_w_errbits' => get_bin_file_w_err_4b_1sttrunk(chip),
                # 'page_size' => get_page_size(chip),
                # 'hex_file_orig_nandpage' => get_orig_nandpage(chip),
             # }),
         # },
         {
             'description'  =>  "#{chip}: Verify 4 bit ECC can be corrected for all 512byte-trunks.",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0020',
             'auto'         => true,
             'script'       => 'LSP\A-NAND\ecc_test.rb',
             'paramsChan'  => common_paramsChan.merge({
                'bin_file_w_errbits' => get_bin_file_w_err_4b_alltrunk(chip),
                'page_size' => get_page_size(chip),
                'hex_file_orig_nandpage' => get_orig_nandpage(chip),
             }),
         },                                  
         # {
             # 'description'  =>  "#{chip}: Verify 1 bit ECC can be corrected for 1st 512 chunk in Uboot level",
             # 'configID'     => '..\Config\lsp_generic.ini', 
             # 'testcaseID'   => 'nand_func_basic_0020',
             # 'auto'         => false,
             # 'paramsChan'  => common_paramsChan.merge({
             # }),
         # },
         {
             'description'  =>  "#{chip}: Verify 1 bit ECC can be corrected for all 512byte-trunks in Uboot level",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0020',
             'auto'         => false,
             'paramsChan'  => common_paramsChan.merge({
             }),
         },
         # {
             # 'description'  =>  "#{chip}: Verify 4 bit ECC can be corrected for 1st 512 chunk in Uboot level",
             # 'configID'     => '..\Config\lsp_generic.ini', 
             # 'testcaseID'   => 'nand_func_basic_0020',
             # 'auto'         => false,
             # 'paramsChan'  => common_paramsChan.merge({
             # }),
         # },
         {
             'description'  =>  "#{chip}: Verify 4 bit ECC can be corrected for all 512byte-trunks in Uboot level",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0020',
             'auto'         => false,
             'paramsChan'  => common_paramsChan.merge({
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

  private
  def get_page_size(page)
    rtn = case page
      when '2k': 2048
      when '4k': 4096
      else 0
    end
    return rtn
  end
  
  def get_bin_file_w_err_4b_alltrunk(page)
    rtn = ''
    if page == '2k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_2k_err_4b_alltrunk.bin'
    elsif page == '4k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_4k_err_4b_alltrunk.bin'
    end
    return rtn
  end

  def get_bin_file_w_err_1b_1sttrunk(page)
    rtn = ''
    if page == '2k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_2k_err_1b_1sttrunk.bin'
    elsif page == '4k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_4k_err_1b_1sttrunk.bin'
    end
    return rtn
  end

  def get_bin_file_w_err_1b_alltrunk(page)
    rtn = ''
    if page == '2k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_2k_err_1b_alltrunk.bin'
    elsif page == '4k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_4k_err_1b_alltrunk.bin'
    end
    return rtn
  end

  def get_bin_file_w_err_4b_1sttrunk(page)
    rtn = ''
    if page == '2k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_2k_err_4b_1sttrunk.bin'
    elsif page == '4k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_4k_err_4b_1sttrunk.bin'
    end
    return rtn
  end
  
  def get_orig_nandpage(page)
    rtn = ''
    if page == '2k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_2k.hex'
    elsif page == '4k'
      rtn = 'LSP\A-NAND\ecc_test_files\nandpage_4k.hex'
    end
    return rtn
  end
 end