require File.dirname(__FILE__)+'/../../../lib/utils'

#Function to run the modetest command on the dut, takes:
#  command, string containing the modetest command to run
#  timeout, time in sec to wait for the command to finish
# Returns the output of the command
def modetest(command, dut, timeout=5, interactive=false)
  response = ''
  t1 = Thread.new do
    dut.send_cmd("/home/root/modetest/modetest #{command}", dut.prompt, timeout) #Set /home/root/modetest/modetest for now should change to modetest once libdrm in included in fs
    response = dut.response
  end
  yield if interactive
  dut.send_cmd("")
  t1.join()
  response
end

#Function to change plane settings on a device, takes:
#  params, a Hash whose entries are:
#  format => <value>                       :the format of the data to display, needs to be one of the following
#                                            /* YUV packed */
#                                                 UYVY
#                                                 VYUY
#                                                 YUYV
#                                                 YVYU
#                                            /* YUV semi-planar */
#                                                 NV12
#                                                 NV21
#                                                 NV16
#                                                 NV61
#                                            /* YUV planar */
#                                                 YU12
#                                                 YV12
#                                            /* RGB16 */
#                                                 AR12
#                                                 XR12
#                                                 AB12
#                                                 XB12
#                                                 RA12
#                                                 RX12
#                                                 BA12
#                                                 BX12
#                                                 AR15
#                                                 XR15
#                                                 AB15
#                                                 XB15
#                                                 RA15
#                                                 RX15
#                                                 BA15
#                                                 BX15
#                                                 RG16
#                                                 BG16
#                                            /* RGB24 */
#                                                 BG24
#                                                 RG24
#                                            /* RGB32 */
#                                                 AR24
#                                                 XR24
#                                                 AB24
#                                                 XB24
#                                                 RA24
#                                                 RX24
#                                                 BA24
#                                                 BX24
#                                                 AR30
#                                                 XR30
#                                                 AB30
#                                                 XB30
#                                                 RA30
#                                                 RX30
#                                                 BA30
#                                                 BX30
#  width => <value>                        : width of the plane in pixels
#  height => <value>                       : height of the plane in pixels
#  crtc_id => <value>                      : id of the crtc to used
#  scale => <value>                        : (Optional) fraction to scale,
#  xyoffset => [<xoffset>,<yoffset>]       : (Optional) x,y offsets array in pixels, 
def set_plane(params, dut=@equipment['dut1'], timeout=600)
  #-P <crtc_id>:<w>x<h>[+<x>+<y>][*<scale>][@<format>]     set a plane
  p_string = get_plane_string(params)
  modeset(p_string, dut, timeout, true) do
    yield
  end
end

#Function to create the string for plane related tests, takes the
#same params value as required by set_plane
def get_plane_string(params)
  p_string = '-P '
  p_string += params['crtc_id']
  p_string += ':'+ params['width'].to_s + 'x' + params['height'].to_s
  p_string += '+'+ params['xyoffset'].join('+') if params['xyoffset']
  p_string += '*'+ params['scale'].to_s if params['scale']
  p_string += '@'+ params['format'] if params['format']
  p_string
end

#Function to set a drm mode, takes:
#  params, a Hash whose entries are:
#    format => <value>                     :the format of the data to display, needs to be one of the following
#                                            /* YUV packed */
#                                                 UYVY
#                                                 VYUY
#                                                 YUYV
#                                                 YVYU
#                                            /* YUV semi-planar */
#                                                 NV12
#                                                 NV21
#                                                 NV16
#                                                 NV61
#                                            /* YUV planar */
#                                                 YU12
#                                                 YV12
#                                            /* RGB16 */
#                                                 AR12
#                                                 XR12
#                                                 AB12
#                                                 XB12
#                                                 RA12
#                                                 RX12
#                                                 BA12
#                                                 BX12
#                                                 AR15
#                                                 XR15
#                                                 AB15
#                                                 XB15
#                                                 RA15
#                                                 RX15
#                                                 BA15
#                                                 BX15
#                                                 RG16
#                                                 BG16
#                                            /* RGB24 */
#                                                 BG24
#                                                 RG24
#                                            /* RGB32 */
#                                                 AR24
#                                                 XR24
#                                                 AB24
#                                                 XB24
#                                                 RA24
#                                                 RX24
#                                                 BA24
#                                                 BX24
#                                                 AR30
#                                                 XR30
#                                                 AB30
#                                                 XB30
#                                                 RA30
#                                                 RX30
#                                                 BA30
#                                                 BX30
#    crtc_id => <value>                    : (Optional) id of the crtc to used, for -P and optionally for -s 
#                                            and -v
#    connectors_ids => [id1,id2, ..., idx]  : array of connector ids,
#    mode => <value>                       : string containing the mode, i.e. 800x480
#  plane_params, (Optional) a Hash whose entries are:
#    width => <value>                      : width of the plane in pixels
#    height => <value>                     : height of the plane in pixels
#    scale => <value>                      : (Optional) fraction to scale, i.e. 0.5,
#    xyoffset => [<xoffset>,<yoffset>]     : (Optional) x,y offsets array in pixels,
def set_mode(params, plane_params=nil, dut=@equipment['dut1'], timeout=600)
  #-s <connector_id>[,<connector_id>][@<crtc_id>]:<mode>[@<format>]  set a mode
  m_str = get_mode_string(params)
  if plane_params
    plane_params['crtc_id'] = params['crtc_id']
    m_str += ' ' + get_plane_string(plane_params)
  end
  modetest(m_str, dut, timeout, true) do
    yield
  end
end

#Function to set a drm object property, takes a hash with entry:
#  id the id of the drm whose property will be set
#  name the name of the property whose value will be set
#  value the value of the property
def set_property(id, name, value, dut=@equipment['dut1'])
  #-w <obj_id>:<prop_name>:<value> set property
  modetest("-w #{id}:#{name}:#{value.strip()}", dut)
end

#Function to run a vsynced page flipping test, takes:
#  params, a Hash whose entries are:
#    format => <value>                     :the format of the data to display, needs to be one of the following
#                                            /* YUV packed */
#                                                 UYVY
#                                                 VYUY
#                                                 YUYV
#                                                 YVYU
#                                            /* YUV semi-planar */
#                                                 NV12
#                                                 NV21
#                                                 NV16
#                                                 NV61
#                                            /* YUV planar */
#                                                 YU12
#                                                 YV12
#                                            /* RGB16 */
#                                                 AR12
#                                                 XR12
#                                                 AB12
#                                                 XB12
#                                                 RA12
#                                                 RX12
#                                                 BA12
#                                                 BX12
#                                                 AR15
#                                                 XR15
#                                                 AB15
#                                                 XB15
#                                                 RA15
#                                                 RX15
#                                                 BA15
#                                                 BX15
#                                                 RG16
#                                                 BG16
#                                            /* RGB24 */
#                                                 BG24
#                                                 RG24
#                                            /* RGB32 */
#                                                 AR24
#                                                 XR24
#                                                 AB24
#                                                 XB24
#                                                 RA24
#                                                 RX24
#                                                 BA24
#                                                 BX24
#                                                 AR30
#                                                 XR30
#                                                 AB30
#                                                 XB30
#                                                 RA30
#                                                 RX30
#                                                 BA30
#                                                 BX30
#    crtc_id => <value>                    : id of the crtc to used, for -P and optionally for -s and -v.
#                                            Optional if not specifying plane_params, otherwise required
#    connectors_ids => [id1,id2, ..., idx] : array of connector ids,
#    mode => <value>                       : string containing the mode, i.e. 800x480
#    framerate => <value>                  : expected frame rate in Hz
#  plane_params, (Optional) a Hash whose entries are:
#    width => <value>                      : width of the plane in pixels
#    height => <value>                     : height of the plane in pixels
#    scale => <value>                      : (Optional) fraction to scale, i.e. 0.5,
#    xyoffset => [<xoffset>,<yoffset>]     : (Optional) x,y offsets array in pixels, 
#Return true if the captured frame rate matches the expected fram rate, specified by framerate 
def run_sync_flip_test(params, plane_params=nil, dut=@equipment['dut1'], timeout=600)
  #-v test vsynced page flipping
  s_f_test_str = '-v ' + get_mode_string(params)
  if plane_params
    plane_params['crtc_id'] = params['crtc_id']
    s_f_test_str += ' ' + get_plane_string(plane_params)
  end
  output = modetest(s_f_test_str, dut, timeout, true) do
    yield
  end
  fps_arr = output.scan(/^freq:\s*([\d.]+)Hz/).drop(2)
  fps_arr.each do |rate|
    return false if (rate[0].to_f - params['framerate'].to_f).abs > 2
  end
  !fps_arr.empty?
end

#Function to create the string for the mode related tests, takes the
#same params value as required by set_mode
def get_mode_string(params)
  result = '-s '
  result += params['connectors_ids'].join(',')
  result += '@' + params['crtc_id'] if params.has_key?('crtc_id')
  result += ':' + params['mode']
  result += '-' + params['framerate'] if params.has_key?('framerate')
  result += '@' + params['format'] if params.has_key?('format')
  result
end

#Function to obtain the parsed output of the modeset command
#Returns a hash containing the parsed output of modeset
def get_properties(dut=@equipment['dut1'])
  mode_string = modetest('', dut, 10).gsub(/#{dut.prompt}[^\n]+/,'')
  result = {}
  get_sections(mode_string, /^\w.*:/).each do |drm_mode_obj_type, info|
    result[drm_mode_obj_type] = get_entries(info)
  end
  result
end

#Function to parse the values of drm object entries, takes
#  string, string containing all the information related to a drm object
#Returns an array of hashes where each hash in the array contains 
#  <entry field name> => <field value> 
def get_entries(string)
  table_header = string.match(/(^id.*)/).captures[0].strip()
  table_content = string.sub(table_header,'')
  column_names = table_header.split(/\t+/)
  entry_regex = /^[\w,\- \(\)]+(?:\t+[\w\-, \(\)]+){#{column_names.length() - 1}}/
  entry_info = get_sections(table_content, entry_regex)
  result = []
  if entry_info
    entry_info.each do |state, caps|
      state_info = state.split(/\t+/)
      entry = {}
      state_info.each_index do |i|
          entry[column_names[i]] = state_info[i]
      end
      caps_info = get_sections(caps,/^ {2}\w+:/)
      if caps_info
        caps_info.each do |cap, cap_info|
          entry[cap] = {}
          next if cap_info.strip() == ''
          if cap == 'props:'
            props = get_sections(cap_info, /\d+ \w+:/)
            props.each do |p,vals|
              entry[cap][p] = get_sections(vals,/^\s+\w+:/)
              case entry[cap][p]['flags:'].to_s.strip()
                when 'enum'
                  entry[cap][p]['enums:'] = parse_sep_field(entry[cap][p]['enums:'])
                when 'bitmask'
                  entry[cap][p]['values:'] = parse_sep_field(entry[cap][p]['values:'])
                when 'range'
                  entry[cap][p]['values:'] = entry[cap][p]['values:'].strip().split(/\s+/)
              end
            end
          elsif cap == 'modes:'
            cap_arr = cap_info.strip().split(/\n/)
            cap_headers = cap_arr[0].split(/\s+(?!\()/)
            entry[cap] = []
            cap_arr[1..-1].each do |mode|
              mode_hash = {}
              m, ft = mode.split(/\s+(?=f)/)
              md = m.strip.split(/\s+/)
              md.each_index {|i| mode_hash[cap_headers[i]] = md[i]}
              mode_hash.merge!(get_sections(ft,/\w+:/))
              entry[cap] << mode_hash if !entry[cap].include?(mode_hash)
            end
          else
            entry[cap] = cap_info.strip().split(/\s+/)
          end
        end
      end
      result << entry
    end
  end
  result
end


