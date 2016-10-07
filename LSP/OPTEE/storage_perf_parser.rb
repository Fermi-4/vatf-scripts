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
  puts "get_metrics called"
  perf_metrics = [
   {'name' => 'write_256B',
    'regex' => get_regex('WRITE', '256'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'write_512B',
    'regex' => get_regex('WRITE', '512'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'write_1024B',
    'regex' => get_regex('WRITE', '1024'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'write_2048B',
    'regex' => get_regex('WRITE', '2048'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'write_4096B',
    'regex' => get_regex('WRITE', '4096'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'write_1MB',
    'regex' => get_regex('WRITE', '1048576'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'read_256B',
    'regex' => get_regex('READ', '256'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'read_512B',
    'regex' => get_regex('READ', '512'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'read_1024B',
    'regex' => get_regex('READ', '1024'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'read_2048B',
    'regex' => get_regex('READ', '2048'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'read_4096B',
    'regex' => get_regex('READ', '4096'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'read_1MB',
    'regex' => get_regex('READ', '1048576'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'rewrite_256B',
    'regex' => get_regex('REWRITE', '256'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'rewrite_512B',
    'regex' => get_regex('REWRITE', '512'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'rewrite_1024B',
    'regex' => get_regex('REWRITE', '1024'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'rewrite_2048B',
    'regex' => get_regex('REWRITE', '2048'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'rewrite_4096B',
    'regex' => get_regex('REWRITE', '4096'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'rewrite_1MB',
    'regex' => get_regex('REWRITE', '1048576'),
    'units' => 'KBytes/sec',
   },

  ]
  perf_metrics
end

def get_regex(type, size)
  puts "get_regex called"
  regex = /TEE Trusted Storage Performance Test \(#{type}\).+?^\s*#{size}\s+\|.+?\|\s+([\d\.]+)/m
  return regex
end