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
{'name' => 'tflite mobilenet_v1_1.0_224_quant with 1 thread',
'regex' => 'mobilenet_v1[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite mobilenet_v1_1.0_224_quant with 2 thread',
'regex' => 'mobilenet_v1[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite mobilenet_v2_1.0_224_quant with 1 thread',
'regex' => 'mobilenet_v2[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite mobilenet_v2_1.0_224_quant with 2 thread',
'regex' => 'mobilenet_v2[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v1_224_quant with 1 thread',
'regex' => 'inception_v1[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v1_224_quant with 2 thread',
'regex' => 'inception_v1[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v2_224_quant with 1 thread',
'regex' => 'inception_v2[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v2_224_quant with 2 thread',
'regex' => 'inception_v2[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v3_quant with 1 thread',
'regex' => 'inception_v3[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v3_quant with 2 thread',
'regex' => 'inception_v3[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v4_299_quant with 1 thread',
'regex' => 'inception_v4[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite inception_v4_299_quant with 2 thread',
'regex' => 'inception_v4[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite coco_ssd_mobilenet_v1_1.0_quant with 1 thread',
'regex' => 'detect\.tflite[^\n]+with 1.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
},
{'name' => 'tflite coco_ssd_mobilenet_v1_1.0_quant with 2 thread',
'regex' => 'detect\.tflite[^\n]+with 2.*?\n[^\n]+avg=([\d\.eE\+\_]+)',
'units' => 'ms',
}
]
perf_metrics
end
