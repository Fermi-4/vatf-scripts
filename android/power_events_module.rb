module PowerEventsModule

def get_events_sequence(key)

power_events =  Hash.new()
 
power_events['go_home'] = ["__back__","__back__","__back__","__back__"]
power_events['alarm_set_minute']= ["__directional_pad_up__","__enter__"]
power_events['disable_stay_awake']= ["__directional_pad_down__","__enter__"]
power_events['step_down']=["__directional_pad_down__"]
power_events['alarm_dismiss']= ["__enter__"]
power_events['force_to_suspend']= ["__power__"]
power_events[key]
end
end 



