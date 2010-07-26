module C6xKernelModuleNames
  # if the module name is different from default one, add the different name in the following hash. here is the example:
  # @module_name = {'davinci_nand' => {'dm365'=>'davinci_nand1', 'dm355'=>'davinci_nand2'}, 'jffs2'=>{'dm365'=>'jffs2_test'} }
  @module_name = {}
  def translate_mod_name(platform, mod_name)
    return mod_name if !@module_name.include?(mod_name)
    return mod_name if !@module_name[mod_name].include?(platform)
    return @module_name[mod_name][platform]
  end
end