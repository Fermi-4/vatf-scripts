module  KnownLinuxProblems
  MSG_PREFIX = 'START_KLP: '
  MSG_SUFFIX = ' :END_KLP'
  # Define know problems set. Syntax:
  # /platform regex/ => {/problem regex/ => 'problem message'}
  # where:
  #   platform regex: regular expression to identify platforms affected
  #   problem regex: regular expression to find issue in platform log
  #   problem message: string to describe problem in result's notes
  PROBLEMS = {
    /.*/ => {
      /BOOTP broadcast \d+.+Retry (count|time) exceeded/m => 'Error executing dhcp',
    },

  }

  # Return string that should be appended to test result's notes
  def check_for_known_problem(e)
    begin
      e_problems = PROBLEMS.select{|k| k.match(e.name)}.map{|k,v| v}
      e_problems = Hash[*e_problems.flatten]
      e_problems.each {|regex, msg|
        return MSG_PREFIX+msg+MSG_SUFFIX if e.response.match(regex)
      }
    rescue Exception => e
      puts e.to_s
    end
    return ''
  end

  # Define known setup problems to help identify false failures
  # Syntax: {/DEVICE TYPE/ => [/REGEX_KEY/,'ERROR DESCRIPTION']}
  KNOWN_SETUP_PROBLEMS = {
    /dut/    => [
      [/nfs: server [\d\.]+ not responding/,'NFS Server failure'],
      [/input overrun\(s\)/, 'Serial port overruns'],
      [/BOOTP broadcast \d+.+Retry (count|time) exceeded/m, 'Error executing dhcp']
    ],

    /server/ => [
      [/incorrect password attempts/, 'Wrong password']
    ]
  }


end
