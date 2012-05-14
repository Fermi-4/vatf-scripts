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
   {'name' => 'Numeric Sort',
    'regex' => 'NUMERIC SORT\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'String Sort',
    'regex' => 'STRING SORT\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'FP Emulation',
    'regex' => 'FP EMULATION\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'Fourier',
    'regex' => 'FOURIER\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'Assignment',
    'regex' => 'ASSIGNMENT\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'Idea',
    'regex' => 'IDEA\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'Huffman',
    'regex' => 'HUFFMAN\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'Neural Net',
    'regex' => 'NEURAL NET\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   },
   {'name' => 'LU Decomposition',
    'regex' => 'LU DECOMPOSITION\s*:\s*(\d*.\d*)',
    'units' => 'IterationsPerSecond',
   }
  ]
  perf_metrics
end
