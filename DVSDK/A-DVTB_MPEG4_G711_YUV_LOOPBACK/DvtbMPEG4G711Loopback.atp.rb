class DvtbMpeg4G711LoopbackTestPlan < DvtbH264G711LoopbackTestPlan
    # BEG_USR_CFG get_params
    def get_params()
    super().merge!({'codec_class'	=> ['MPEG4']})
    end
    # END_USR_CFG get_params
end