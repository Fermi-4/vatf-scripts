module Ata_common
  def get_power_mode_cmd(mode)
    rtn = case mode
      when 'active': "hdparm -C /dev/hda`++active`"
      when 'idle': "hdparm -C /dev/hda`++idle`"
      when 'standby': "hdparm -y /dev/hda;hdparm -C /dev/hda`++standby`"
      when 'sleep': "hdparm -Y /dev/hda;hdparm -C /dev/hda`++sleep`"
      else            
    end
  end
    
  # @op_mode =  ['pio0', 'pio1', 'pio2', 'pio3', 'pio4'] +
            # ['mdma0', 'mdma1', 'mdma2'] +
            # ['udma0', 'udma1', 'udma2', 'udma3','udma4', 'udma5',]
  def get_xfer_mode(mode)
    rtn = case mode
      when /pio(\d+)/: 8 + $1.to_i
      when /mdma(\d+)/: 32 + $1.to_i
      when /udma(\d+)/: 64 + $1.to_i
      else              'fail'  
    end
    rtn.to_s
  end
  
  def set_opmode(mode)
    rtn = "hdparm -X#{get_xfer_mode(mode)} /dev/hda;hdparm -i /dev/hda`++\\*#{mode}`"
  end
end