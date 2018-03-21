require File.dirname(__FILE__)+'/../../lib/utils'

# Get array of performance metrics
# Each array element is a hash with following key,values pairs:
#  name: Performance metric's name
#  regex: regular expression used to capture perf metric value
#  units: Performance metric's units
#  adj: Optional hash used to escale capture value to appropriate units.
#       The adj is a hash with following keys:
#        val_index: index of capture value in regex above
#        unit_index: index of capture units in regex above
#        val_adj: hash of regex:val. The capture unit value will be check agains regex key, if match value is adjusted by val.
def get_metrics
  if (get_iperf_version == 3)
     bandwidth_regex='sender.*?\s*(\d+\.\d+)\s*([KMG]Bytes\/sec).*\s*receiver'
     datagrams_regex='sender.*\d*\/(\d*).*receiver'
     jitter_regex='sender.*sec.*?([\d\.]+)\s*([mu]{0,1}s.*?)\s*.*?receiver'
     pktloss_regex='sender.*?\(([\d.]+)%\).*receiver'
  else
     bandwidth_regex= '^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+([\d\.]+)\s+([\w\/]+)'
     datagrams_regex='^\[[\s\d]+\]\s+Sent\s+(\d+)\s+datagrams'
     jitter_regex='^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+[\d\.]+\s+[\w\/]+\s+([\d\.]+)\s(\w+)'
     pktloss_regex='^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+[\d\.]+\s+[\w\/]+\s+[\d\.]+\s\w+[\s\d\/]+\(([\d\.]+)%\)'
  end
  perf_metrics = [
   {'name' => 'udp_datagrams',
    'regex' => datagrams_regex,
    'units' => 'datagrams',
   },
   {'name' => 'udp_bandwidth',
    'regex' => bandwidth_regex,
    'adj' => {'val_index' => 0, 'units_index' => 1, 'val_adj' => {/KBytes/ => 0.001*8, /MBytes/ => 1.0*8, /GBytes/ => 1000.0*8}},
    'units' => 'Mbits/sec',
   },
   {'name' => 'udp_jitter',
    'regex' => jitter_regex,
    'adj' => {'val_index' => 0, 'units_index' => 1, 'val_adj' => {/us/ => 0.001, /ms/ => 1.0, /sec/ => 1000.0}},
    'units' => 'ms',
   },
   {'name' => 'udp_packetloss',
    'regex' => pktloss_regex,
    'units' => '%',
   },
  ]
  perf_metrics
end
