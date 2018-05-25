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
   {'name' => 'radix2-big-64k',
    'regex' => 'radix2\-big\-64k:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'cjpeg-rose7-preset',
    'regex' => 'cjpeg\-rose7\-preset:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'sha-test',
    'regex' => 'sha\-test:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'nnet_test',
    'regex' => 'nnet_test:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'loops-all-mid-10k-sp',
    'regex' => 'loops\-all\-mid\-10k\-sp:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'core',
    'regex' => 'core:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'linear_alg-mid-100x100-sp',
    'regex' => 'linear_alg\-mid\-100x100\-sp:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'parser-125k',
    'regex' => 'parser\-125k:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'zip-test',
    'regex' => 'zip\-test:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   }
  ]
  perf_metrics
end
