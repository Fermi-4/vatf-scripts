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
   {'name' => 'write_4_throughput',
    'regex' => get_regex('write', '4', 'throughput'),
    'units' => 'KBits/sec',
   },
   {'name' => 'write_8_throughput',
    'regex' => get_regex('write', '8', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'write_16_throughput',
    'regex' => get_regex('write', '16', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'write_32_throughput',
    'regex' => get_regex('write', '32', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'write_64_throughput',
    'regex' => get_regex('write', '64', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'read_4_throughput',
    'regex' => get_regex('read', '4', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'read_8_throughput',
    'regex' => get_regex('read', '8', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'read_16_throughput',
    'regex' => get_regex('read', '16', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'read_32_throughput',
    'regex' => get_regex('read', '32', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'read_64_throughput',
    'regex' => get_regex('read', '64', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'copy_4_throughput',
    'regex' => get_regex('copy', '4', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'copy_8_throughput',
    'regex' => get_regex('copy', '8', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'copy_16_throughput',
    'regex' => get_regex('copy', '16', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'copy_32_throughput',
    'regex' => get_regex('copy', '32', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'copy_64_throughput',
    'regex' => get_regex('copy', '64', 'throughput'),
    'units' => 'Kbits/sec',
   },
   {'name' => 'write_4_cpuload',
    'regex' => get_regex('write', '4', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_8_cpuload',
    'regex' => get_regex('write', '8', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_16_cpuload',
    'regex' => get_regex('write', '16', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_32_cpuload',
    'regex' => get_regex('write', '32', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_64_cpuload',
    'regex' => get_regex('write', '64', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_4_cpuload',
    'regex' => get_regex('read', '4', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_8_cpuload',
    'regex' => get_regex('read', '8', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_16_cpuload',
    'regex' => get_regex('read', '16', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_32_cpuload',
    'regex' => get_regex('read', '32', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_64_cpuload',
    'regex' => get_regex('read', '64', 'cpuload'),
    'units' => '%',
   },
  ]
  perf_metrics
end

def get_regex(iomode, bsize, key)
  if key == 'throughput'
    regex = /\|PERFDATA\|bsize:\s*#{bsize}\|iomode:\s*#{iomode}\|throughput:\s*([\d\.]+)\s*Kbits\/S\|/ 
  elsif key == 'cpuload'
    regex = /\|PERFDATA\|bsize:\s*#{bsize}\|iomode:\s*#{iomode}\|throughput:\s*[\d\.]+\s*Kbits\/S\|cpuload:\s*([\d\.]+)%/ 
  end
  return regex
end





