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
   {'name' => 'write_102400_throughput',
    'regex' => get_regex('write', '102400', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'write_262144_throughput',
    'regex' => get_regex('write', '262144', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'write_524288_throughput',
    'regex' => get_regex('write', '524288', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'write_1048576_throughput',
    'regex' => get_regex('write', '1048576', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'write_5242880_throughput',
    'regex' => get_regex('write', '5242880', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'read_102400_throughput',
    'regex' => get_regex('read', '102400', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'read_262144_throughput',
    'regex' => get_regex('read', '262144', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'read_524288_throughput',
    'regex' => get_regex('read', '524288', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'read_1048576_throughput',
    'regex' => get_regex('read', '1048576', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'read_5242880_throughput',
    'regex' => get_regex('read', '5242880', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'copy_102400_throughput',
    'regex' => get_regex('copy', '102400', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'copy_262144_throughput',
    'regex' => get_regex('copy', '262144', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'copy_524288_throughput',
    'regex' => get_regex('copy', '524288', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'copy_1048576_throughput',
    'regex' => get_regex('copy', '1048576', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'copy_5242880_throughput',
    'regex' => get_regex('copy', '5242880', 'throughput'),
    'units' => 'MBytes/sec',
   },
   {'name' => 'write_102400_cpuload',
    'regex' => get_regex('write', '102400', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_262144_cpuload',
    'regex' => get_regex('write', '262144', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_524288_cpuload',
    'regex' => get_regex('write', '524288', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_1048576_cpuload',
    'regex' => get_regex('write', '1048576', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'write_5242880_cpuload',
    'regex' => get_regex('write', '5242880', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_102400_cpuload',
    'regex' => get_regex('read', '102400', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_262144_cpuload',
    'regex' => get_regex('read', '262144', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_524288_cpuload',
    'regex' => get_regex('read', '524288', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_1048576_cpuload',
    'regex' => get_regex('read', '1048576', 'cpuload'),
    'units' => '%',
   },
   {'name' => 'read_5242880_cpuload',
    'regex' => get_regex('read', '5242880', 'cpuload'),
    'units' => '%',
   },
  ]
  perf_metrics
end

def get_regex(iomode, bsize, key)
  if key == 'throughput'
    regex = /\|PERFDATA\|bsize:\s*#{bsize}\|iomode:\s*#{iomode}\|throughput:\s*([\d\.]+)\s*MB\/S\|/ 
  elsif key == 'cpuload'
    regex = /\|PERFDATA\|bsize:\s*#{bsize}\|iomode:\s*#{iomode}\|throughput:\s*[\d\.]+\s*MB\/S\|cpuload:\s*([\d\.]+)%/ 
  end
  return regex
end





