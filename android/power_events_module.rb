module PowerEventsModule

def get_events(key)

power_events =  Hash.new()
 
power_events['go_home'] = ["__back__","__back__","__back__","__back__"]
#bluetooth config 
power_events['alarm_select__munite'] =["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_up__","__directional_pad_right__","__directional_pad_up__"]
power_events['alarm_set_munite']= ["__directional_pad_up__","__enter__"]
power_events['alarm_save_munite']=["__directional_pad_down__","__directional_pad_down__","__directional_pad_left__","__enter__",
"__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__",
"__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__",
"__directional_pad_down__","__directional_pad_left__","__enter__"]

power_events['no_stay_awake']= ["__directional_pad_down__","__directional_pad_down__","__enter__"]
power_events['step_down']=["__directional_pad_down__"]

power_events['alarm_delete']=["__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_right__","__enter__","__enter__"]

power_events['alarm_dismis']= ["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_right__","__enter__"]
power_events[key]
end
end 
