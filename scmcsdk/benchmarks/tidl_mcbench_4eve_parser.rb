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
{'name' => 'MobileNetv1_DSP1_EVE4_mcbench',
'regex' => '-d\s+1.*?mobileNet1_lg2\.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'MobileNetv1_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*mobileNet1_lg2\.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'MobileNetv2_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*?mobileNet2_lg2\.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'InceptionNetv1_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*?inceptionNetv1_lg2.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'JacintoNet11v2Sparse_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*?j11_v2.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'JacintoNet11v2Dense_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*?j11_v2_dense.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'JacintoNet11v2Sparse_lg2_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*?j11_v2_lg2.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
},
{'name' => 'JacintoNet11v2Dense_lg2_DSP2_EVE4_mcbench',
'regex' => '-d\s+2.*?j11_v2_dense_lg2.txt.*?FPS:([\d\.]+)',
'units' => 'FPS',
}
]
perf_metrics
end
