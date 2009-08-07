  # concatenate 'cmd' for 'rtp_times'.
  def get_repeat_cmd(rpt_times, cmd)
    rtn = ''
    rpt_times.to_i.times {|x|
      rtn = rtn + ";#{cmd}"
    }
    rtn = rtn.sub(/^;/, '')
  end
