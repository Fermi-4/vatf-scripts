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
   {'name' => '4M-cmykw2',
    'regex' => '4M\-cmykw2:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-check-reassembly-tcp',
    'regex' => '4M\-check\-reassembly\-tcp:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'ippktcheck-4Mw1',
    'regex' => 'ippktcheck\-4Mw1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'rotate\-4Ms64w1',
    'regex' => 'rotate\-4Ms64w1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-check-reassembly-tcp-cmykw2-rotatew2',
    'regex' => '4M\-check\-reassembly\-tcp\-cmykw2\-rotatew2:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'ipres-4Mw1',
    'regex' => 'ipres\-4Mw1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'rotate-4Ms1',
    'regex' => 'rotate\-4Ms1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-tcp-mixed',
    'regex' => '4M\-tcp\-mixed:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'rotate-4Ms64',
    'regex' => 'rotate\-4Ms64:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'md5-4M',
    'regex' => 'md5\-4M:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-cmykw2-rotatew2',
    'regex' => '4M\-cmykw2\-rotatew2:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'rotate-4Ms1w1',
    'regex' => 'rotate\-4Ms1w1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'rgbcmyk-4Mw1',
    'regex' => 'rgbcmyk\-4Mw1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-reassembly',
    'regex' => '4M\-reassembly:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-rotatew2',
    'regex' => '4M\-rotatew2:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-x264w2',
    'regex' => '4M\-x264w2:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-check-reassembly-tcp-x264w2',
    'regex' => '4M\-check\-reassembly\-tcp\-x264w2:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'ippktcheck-4M',
    'regex' => 'ippktcheck\-4M:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'x264-4Mq',
    'regex' => 'x264\-4Mq:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'iDCT-4Mw1',
    'regex' => 'iDCT\-4Mw1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-check',
    'regex' => '4M\-check:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'x264-4Mqw1',
    'regex' => 'x264\-4Mqw1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'rgbcmyk-4M',
    'regex' => 'rgbcmyk\-4M:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'ipres-4M',
    'regex' => 'ipres\-4M:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'md5-4Mw1',
    'regex' => 'md5\-4Mw1:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'empty-wld',
    'regex' => 'empty\-wld:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => 'iDCT-4M',
    'regex' => 'iDCT\-4M:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   },
   {'name' => '4M-check-reassembly',
    'regex' => '4M\-check\-reassembly:workloads\/sec=\s*([\d\.]+)',
    'units' => 'workloads/sec',
   }
  ]
  perf_metrics
end
