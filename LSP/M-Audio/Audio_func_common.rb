# -*- coding: ISO-8859-1 -*-
module Audio_func_common
  def get_input(input)
      if input == '0'
          result = "Line In"
      elsif input == '1'
          result = "Mic In"
      end
      result
  end
  def get_output(output)
      if output == '0'
          result = "Line In"
      elsif output == '1'
          result = "Mic In"
      end
      result
  end
end

