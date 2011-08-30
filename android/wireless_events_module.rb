module EventsModule

def get_events(key)

wireless_events =  Hash.new()
 
wireless_events['go_home'] = ["__back__","__back__","__back__","__back__"]
#bluetooth config 
wireless_events['select_bluetooth'] =["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__"]
wireless_events['select_bluetooth_setting']= ["__directional_pad_down__","__enter__"]
wireless_events['configure_bluetooth']=["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__enter__"]
#wireless config 
wireless_events['select_wireless'] =["__directional_pad_down__","__enter__"]
wireless_events['select_wireless_setting']= ["__directional_pad_down__","__enter__"]
wireless_events['two_step_down']=["__directional_pad_down__","__directional_pad_down__"]
wireless_events['clear_access']=["__enter__","__directional_pad_down__","__enter__"]
wireless_events['top']=["__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__"]

wireless_events['configure_wireless_open']=["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__
","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__","gtaccess-open","__directional_pad_down__","__directional_pad_down__","__enter__"]
wireless_events['find_access_open']=["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__"]
wireless_events['connect_access_open']=["__enter__","__directional_pad_down__","__directional_pad_left__","__enter__"]

wireless_events['configure_wireless_wpa-psk']=["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__
","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__","gtaccess-wpa-psk","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","q1w2e3r4","__directional_pad_down__","__directional_pad_down__","__enter__"]
wireless_events['find_access_wpa-psk']=["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__"]
wireless_events['connect_access__wpa-psk']=["__enter__","q1w2e3r4","__directional_pad_down__","__directional_pad_left__","__enter__"]

wireless_events[key]
end
end 
