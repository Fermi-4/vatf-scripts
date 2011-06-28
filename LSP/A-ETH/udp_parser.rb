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
  perf_metrics = [
   {'name' => 'udp_datagrams',
    'regex' => '^\[[\s\d]+\]\s+Sent\s+(\d+)\s+datagrams',
    'units' => 'num_datagrams',
   },
   {'name' => 'udp_bandwidth',
    'regex' => '^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+([\d\.]+)\s+([\w\/]+)',
    'adj' => {'val_index' => 0, 'units_index' => 1, 'val_adj' => {/KBytes/ => 0.001*8, /MBytes/ => 1.0*8, /GBytes/ => 1000.0*8}},
    'units' => 'Mbits/sec',
   },
   {'name' => 'udp_jitter',
    'regex' => '^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+[\d\.]+\s+[\w\/]+\s+([\d\.]+)\s(\w+)',
    'adj' => {'val_index' => 0, 'units_index' => 1, 'val_adj' => {/us/ => 0.001, /ms/ => 1.0, /sec/ => 1000.0}},
    'units' => 'ms',
   },
   {'name' => 'udp_packetloss',
    'regex' => '^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+[\d\.]+\s+[\w\/]+\s+[\d\.]+\s\w+[\s\d\/]+\(([\d\.]+)%\)',
    'units' => '%',
   },
  ]
  perf_metrics
end





