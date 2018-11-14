# Core list for each platform
def get_supported_cores(platform)
  data_list = {}
  data_list['k2hk-evm']   = %w[dsp0 dsp1 dsp2 dsp3 dsp4 dsp5 dsp6 dsp7]
  data_list['k2l-evm']    = %w[dsp0 dsp1 dsp2 dsp3]
  data_list['k2e-evm']    = %w[dsp0]
  data_list['k2g-evm']    = %w[dsp0]
  data_list['am572x-evm'] = %w[dsp0 dsp1 ipu1 ipu2]
  data_list['am572x-idk'] = %w[dsp0 dsp1 ipu1 ipu2]
  data_list['am571x-idk'] = %w[dsp0 ipu1 ipu2]

  return data_list[platform]
end
