require '../../TestPlans/LSP/A-NAND/nand_func_basic.atp.rb'
class Nand_func_basic_yaffsTestPlan < Nand_func_basicTestPlan
  
   # BEG_USR_CFG get_params
   def get_params()  
     @fs_type = ['yaffs2']   
     {
     }
   end
   # END_USR_CFG get_params
 
end