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
     bandwidth_regex='sec\s+[\d\.]+\s+.Bytes\s+([\d\.]+)\s+([\w\/]+).*receiver'
  else
     bandwidth_regex='sec\s+[\d\.]+\s+.Bytes\s+([\d\.]+)\s+([\w\/]+)'
  end
  perf_metrics = [
   {'name' => 'tcp_bidir_throughput',
    'regex' => bandwidth_regex,
    'adj' => {'val_index' => 0, 'units_index' => 1, 'val_adj' => {/KBytes/ => 0.001*8, /MBytes/ => 1.0*8, /GBytes/ => 1000.0*8}},
    'units' => 'Mbits/sec',
   },
  ]
  perf_metrics
end
