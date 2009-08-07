module Gpio_common  
  def get_gpio_num(platform)
    rtn = case platform
      when 'dm355': [6, 7, 25, 26, 32, 54, 67, 81]
      when 'dm644x': [5, 6, 32, 38, 54]
    end
    rtn
  end
  
  # get description of dir
  def get_dir(dir)
    rtn = case dir
      when '0': 'Output'
      when '1': 'Input'
    end
    rtn
  end

  # get description of dir
  def get_trig_edge(trig_edge)
    rtn = case trig_edge
      when '0': 'Rising Edge'
      when '1': 'Falling Edge'
    end
    rtn
  end
  
  # choose one or two gpio from each bank to test.
  def get_gpio_bank(gpio_num)
    gpio_bank = case gpio_num.to_i
      when 0..15: 0
      when 16..31: 1
      when 32..47: 2
      when 48..63: 3
      when 64..79: 4
      when 80..95: 5
      else         6
    end
    gpio_bank
  end  
  
  def get_irq_num(gpio_num, platform)
    case platform
    when 'dm355', 'dm365'
      rtn = case gpio_num.to_i
        when 0..9: gpio_num.to_i+44
        when 10..15: 54
        when 16..31: 55
        when 32..47: 56
        when 48..63: 57
        when 64..79: 58
        when 80..95: 59
        else         60
      end
    when 'dm644x'
      rtn = case gpio_num.to_i
        when 0..7: gpio_num.to_i+48
        when 8..15: 56
        when 16..31: 57
        when 32..47: 58
        when 48..63: 59
        else         60
      end
    end
    rtn
  end
end