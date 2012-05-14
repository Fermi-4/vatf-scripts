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
  {'name' => 'Dhrystone Per MHz',
  'regex' => 'Dhrystone DMIPS/MHz\s*=\s*(\d*.\d*)',
  'units' => 'DMIPS/MHz',
  },
  {'name' => 'Dhrystone Per Second',
  'regex' => 'Dhrystones per Second:\s*(\d*.\d*)',
  'units' => 'DhrystonePerSec',
  },
  {'name' => 'CPU Clock',
  'regex' => 'CPU clock\s*=\s*(\d*)',
  'units' => 'MHz',
  }
  ]
  perf_metrics
end
