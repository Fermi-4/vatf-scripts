module EventsModule

def get_events(key)

wireless_events =  Hash.new()
wireless_events['go_home'] = ["__back__","__back__","__back__","__back__"]
wireless_events['select_bluetooth_setting']= ["__directional_pad_down__","__enter__"]
wireless_events['two_step_down']=["__directional_pad_down__"]
wireless_events['top_gb']=["__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__"]
wireless_events['top']=["__directional_pad_up__","__directional_pad_up__","__back__"]
wireless_events['adjust']=["__directional_pad_up__","__enter__"] 
wireless_events[key]
end
end 
