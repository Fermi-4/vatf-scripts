# Get array of performance metrics for mtd speedtest.
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
   {'name' => 'eraseblock_write_throughput',
    'regex' => get_regex('write', 'eraseblock'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'eraseblock_read_throughput',
    'regex' => get_regex('read', 'eraseblock'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'page_write_throughput',
    'regex' => get_regex('write', 'page'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'page_read_throughput',
    'regex' => get_regex('read', 'page'),
    'units' => 'KBytes/sec',
   },
   {'name' => '2page_write_throughput',
    'regex' => get_regex('write', '2 page'),
    'units' => 'KBytes/sec',
   },
   {'name' => '2page_read_throughput',
    'regex' => get_regex('read', '2 page'),
    'units' => 'KBytes/sec',
   },
   {'name' => 'erase_throughput',
    'regex' => get_regex('erase', ''),
    'units' => 'KBytes/sec',
   },
  ]
  perf_metrics
end

def get_regex(iomode, type)
  regex = /mtd_speedtest:\s*#{type}\s*#{iomode}\s*speed\s*is\s*([\d\.]+)\s*KiB\/s/
  return regex
end





