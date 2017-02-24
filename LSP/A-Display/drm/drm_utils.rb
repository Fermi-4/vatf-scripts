require File.dirname(__FILE__)+'/../../../lib/utils'

MODETEST_PIX_FMTS = ['UYVY', 'VYUY', 'YUYV', 'YVYU', 'NV12', 'NV21', 'NV16', 'NV61', 'YU12', 'YV12', 'AR12', 'XR12', 'AB12', 'XB12', 'RA12', 'RX12', 'BA12', 'BX12', 'AR15', 'XR15', 'AB15', 'XB15', 'RA15', 'RX15', 'BA15', 'BX15', 'RG16', 'BG16', 'BG24', 'RG24','AR24', 'XR24', 'AB24', 'XB24', 'RA24', 'RX24', 'BA24', 'BX24', 'AR30', 'XR30', 'AB30', 'XB30', 'RA30', 'RX30', 'BA30', 'BX30']

#Function to run the modetest command on the dut, takes:
#  command, string containing the modetest command to run
#  timeout, time in sec to wait for the command to finish
#  expected, regex defining the pattern to wait after sending the
#            modetest command
# Returns the output of the command
def modetest(command, dut, timeout=5, expected=nil)
  regex = expected ? expected : /trying\s*to\s*open\s*device.*?#{dut.prompt}/im
  response = ''
  dut.send_cmd("", dut.prompt)
  t1 = Thread.new do
    dut.send_cmd("modetest #{command}", /#{regex}|Killed\s*modetest|modetest:\s*no\s*process\s*killed/, timeout)
    response = dut.response
  end
  if block_given?
    yield
  else
    t1.join(2)
  end
  dut.send_cmd("\nkillall -9 modetest 2>&1; sleep 1", dut.prompt)
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
  p_string = ''
  params.each do |plane_inf|
    p_string += get_mode_string(plane_inf)
  end
  modetest(p_string, dut, timeout) do
    yield
  end
end

#Function to create the string for plane related tests, takes the
#same params value as required by set_plane
def get_plane_string(params)
  p_string = ' -P '
  p_string += params['crtc_id']
  p_string += ':'+ params['width'].to_s + 'x' + params['height'].to_s
  p_string += '+'+ params['xyoffset'].join('+') if params['xyoffset']
  p_string += '*'+ params['scale'].to_s if params['scale']
  p_string += '@'+ params['format'] if params['format']
  p_string
end

#Function to set a drm mode, takes:
#  params, an array of hashes where each hash defines a mode to set on
#          a display by specifying the following hash entries:
#
#     format => <value>                     :the format of the data to display, needs to be one of the following
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
#     crtc_id => <value>                    : id of the crtc to used, for -P and optionally for -s and -v.
#                                             Optional if not specifying plane_params, otherwise required
#     connectors_ids => [id1,id2, ..., idx] : array of connector ids,
#     mode => <value>                       : string containing the mode, i.e. 800x480
#     framerate => <value>                  : expected frame rate in Hz
#    'plane' => (Optional) a Hash whose entries are:
#       width => <value>                      : width of the plane in pixels
#       height => <value>                     : height of the plane in pixels
#       scale => <value>                      : (Optional) fraction to scale, i.e. 0.5,
#       xyoffset => [<xoffset>,<yoffset>]     : (Optional) x,y offsets array in pixels, 
def set_mode(params, expected_re=nil, dut=@equipment['dut1'], timeout=600)
  #-s <connector_id>[,<connector_id>][@<crtc_id>]:<mode>[@<format>]  set a mode
  m_str = ''
  params.each do |disp_inf|
    disp_inf['plane']['crtc_id'] = disp_inf['crtc_id']  if disp_inf['plane']
    m_str += get_mode_string(disp_inf, disp_inf['plane'])
  end
  modetest(m_str + ' &', dut, timeout, expected_re) do
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
#  params, an array of hashes where each hash defines a mode to set on
#          a display by specifying the following hash entries:
#
#     format => <value>                     :the format of the data to display, needs to be one of the following
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
#     crtc_id => <value>                    : id of the crtc to used, for -P and optionally for -s and -v.
#                                             Optional if not specifying plane_params, otherwise required
#     connectors_ids => [id1,id2, ..., idx] : array of connector ids,
#     mode => <value>                       : string containing the mode, i.e. 800x480
#     framerate => <value>                  : expected frame rate in Hz
#    'plane' => (Optional) a Hash whose entries are:
#       width => <value>                      : width of the plane in pixels
#       height => <value>                     : height of the plane in pixels
#       scale => <value>                      : (Optional) fraction to scale, i.e. 0.5,
#       xyoffset => [<xoffset>,<yoffset>]     : (Optional) x,y offsets array in pixels,
#Return true if the captured frame rate matches the expected frame rate, specified by framerate 
def run_sync_flip_test(params, dut=@equipment['dut1'], timeout=600)
  result = run_perf_sync_flip_test(params, dut, timeout) do
             yield
           end
  
  [result[0], result[2]]
end

#Function to run a vsynced page flipping test, takes the same parameters as function
#run_sync_flip_test
#Returns an array with two elements: 
#          [true/false if the captured frame rate matches the expected frame rate or not, 
#           an array [] containing the fps captured]
def run_perf_sync_flip_test(params, dut=@equipment['dut1'], timeout=600)
  #-v test vsynced page flipping
  s_f_test_str = '-t -v '
  f_rates = []
  params.each do |disp_inf|
    disp_inf['plane']['crtc_id'] = disp_inf['crtc_id'] if disp_inf['plane']
    s_f_test_str += get_mode_string(disp_inf, disp_inf['plane'])
    f_rates << disp_inf['framerate'].to_f
  end
  output = modetest(s_f_test_str + ' &', dut, timeout, /^freq:\s*([\d.]+)Hz.*?#{dut.prompt}/im) do
    yield
  end
  fps_arr = output.scan(/^freq:\s*([\d.]+)Hz/).drop(2).flatten
  failed_samples = 0.0
  (f_rates + fps_arr + f_rates).each_cons(2) do |rates|
    cons_errors = true 
    rates.each_with_object(true) do |rate, cons_f|
      err = f_rates.inject(f_rates[0]) do |error, fr|
        c_error = (rate.to_f - fr).abs
        error = c_error < error ? c_error : error
      end
      if err > 1.5
        failed_samples += 1
      else
        cons_errors = false
      end
    end
    return [false, fps_arr, output] if failed_samples/(fps_arr.length*2) > 0.1 || cons_errors
  end
  [!fps_arr.empty?, fps_arr, output]
end

#Function to create the string for the mode related tests, takes:
#  params, same params value as required by set_mode
#  plane_params, same params value as required by set_plane
def get_mode_string(params, plane_params=nil)
  result = ' -s '
  result += params['connectors_ids'].join(',')
  result += '@' + params['crtc_id'] if params.has_key?('crtc_id')
  result += ':' + params['mode']
  result += '-' + params['framerate'] if params.has_key?('framerate')
  result += '@' + params['format'] if params.has_key?('format')
  if plane_params
    result += get_plane_string(plane_params)
  end
  result
end

#Function to obtain the parsed output of the modeset command
#Returns a hash containing the parsed output of modeset
def get_properties(dut=@equipment['dut1'])
  mode_string = modetest('', dut, 10).gsub(/#{dut.prompt}[^\n]+/,'')
  result = {}
  get_sections(mode_string, /^\w.*:/).each do |drm_mode_obj_type, info|
    entries = get_entries(info)
    result[drm_mode_obj_type] = entries if entries
  end
  result
end

#Function to parse the values of drm object entries, takes
#  string, string containing all the information related to a drm object
#Returns an array of hashes where each hash in the array contains 
#  <entry field name> => <field value> 
def get_entries(string)
  raw_header = string.match(/(^id.*)/)
  return raw_header if !raw_header
  table_header = raw_header.captures[0].strip()
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

#Function to obtain the formats supported by the connector/graphics planes,
#takes:
#  - connectors, a Hash containing the information associated with all the CRTCs
#                enabled on the board, of the same syntax as the value referenced
#                by the Connectors: key of the hash returned by get_properties()
#Returns, a Hash of syntax {<connector id> => [ array of supported pix fmts]}
def get_supported_fmts(connectors)
  pix_fmts = Hash.new(){|h,k| h[k] = []}
  connectors.each do |c_info|
    next if !c_info['modes:']
    m_params = {}
    m_params['mode'] = c_info['modes:'][0]['name']
    m_params['connectors_ids'] = [c_info['id']]
    MODETEST_PIX_FMTS.each do |current_fmt|
      m_params['format'] = current_fmt
      mode_str = set_mode([m_params]){sleep 2}
      mode_str = mode_str.downcase()
      pix_fmts[c_info['id']] << current_fmt if ['unsupported pixel format', 'invalid pixel format',
                                                'invalid argument', 'segmentation fault', 'invalid pitch'].inject(true) do |t, str| 
                                                    t &&= !mode_str.include?(str)
                                               end
    end
  end
  pix_fmts
end

#Function to obtain the formats supported by the overlay planes, takes:
#  - crtc_info, a Hash containing the information associated with all the CRTCs
#               enabled on the board, of the same syntax as the value referenced
#               by the CRTCs: key of the hash returned by get_properties()
#Returns, a Hash of syntax {<crtc id> => [ array of supported pix fmts]}
def get_supported_plane_pix_fmts(crtcs_info)
  pix_fmts = Hash.new(){|h,k| h[k] = []}
  crtcs_info.each do |c_info|
    p_params = {}
    width, height = c_info['size'].gsub(/[\(\)]+/,'').split('x')
    p_params['width'] = width
    p_params['height'] = height
    p_params['crtc_id'] = c_info['id'] 
    MODETEST_PIX_FMTS.each do |current_fmt|
      p_params['format'] = current_fmt
      plane_str = set_plane([{'plane'=>p_params}]){sleep 2}
      plane_str = plane_str.downcase()
      pix_fmts[c_info['id']] << current_fmt if ['unsupported pixel format', 'invalid pixel format',
                                                'invalid argument', 'no unused plane available for'].inject(true) do |t, str| 
                                                    t &&= !plane_str.include?(str)
                                               end
    end
  end
  pix_fmts
end

#Function that returns the display modes supported by a device, takes a
#  drm_info, hash whose entries comply with the hash returned by get_entries
#  formats, hash with entries <connector id> => <array of fmts supported by connector>
#  conn, (Optional) string with connector type, i.e hdmi. If specified
#            the returned modes will only contain modes where the conn type is
#            used 
#  p_formats, (Optional) array of string containing formats to use for the planes
#Returns two arrays whose elements are arrays containing hashes that define a mode
#expected by the function set_mode and run_per_sync_flip_test. The first array
#contains modes for individual displays, the second array contains modes for
#multiple displays. If the device does not support multi-display then the
#arrays returned by this functions are the same
def get_test_modes(drm_info, formats, conn=nil, p_formats=nil)
  single_disp_modes = []
  multi_disp_modes = nil
  overlay_planes = []
  if drm_info['Planes:'].length > drm_info['CRTCs:'].length
    drm_info['Planes:'].each do |p|
      p['props:'].each do |k, v|
       if k.match(/\d+\s*type:/)
          val = v['value:'].strip
          overlay_planes << p['id'] if v['enums:'].match(/Overlay\s*=\s*#{val}[^\d]/)
        end
      end
    end
  end
  drm_info['Connectors:'].each do |connector|
    c_modes = []
    drm_info['Encoders:'].each do |encoder|
      next if encoder['id'] != connector['encoders']
      crtc = drm_info['CRTCs:'][encoder["possible crtcs"].to_i(16)-1]
      #If planes supported and only 1 mode, repeat mode to test with/wout planes
      if !overlay_planes.empty? && connector['modes:'].length == 1
        connector['modes:'] << connector['modes:'][0]
      end
      adj_idx = 0
      connector['modes:'].each_index do |i| 
        mode = connector['modes:'][i]
        if (@equipment['dut1'].name.match(/beagle|am335x|am43xx|k2g/) && (mode['name'].match(/(\d+)x(\d+)/).captures[0].to_i > 1280 || mode['name'].match(/(\d+)x(\d+)/).captures[1].to_i > 720)) 
          adj_idx += 1
          next
        end
        formats[connector['id']].each do |format|
          mode_params = {'connectors_ids' => [connector['id']],
                         'connectors_names' => [connector['name'].downcase().strip()], 
                         'crtc_id' => crtc['id'], 
                         'mode' => mode['name'],
                         'framerate' => mode['refresh (Hz)'],
                         'type' => connector['type'],
                         'encoder' => encoder['id']}
          mode_params['format'] = format if format != 'default'
          plane_params = nil
          if !overlay_planes.empty? && i % 2 == 1
            plane = drm_info['Planes:'][0]
            width, height = mode['name'].match(/(\d+)x(\d+)/).captures
            plane_params = {'id' => overlay_planes.rotate!()[0],
                            'width' => width, 
                            'height' => height,
                            'xyoffset' => [i-adj_idx+1,i-adj_idx+1],
                            'scale' => [0.125, 1.to_f/(2+i-adj_idx).to_f].max,
                            'format' => p_formats ? p_formats[rand(p_formats.length)] : plane['formats:'][rand(plane['formats:'].length)]}
          end
          mode_params['plane'] = plane_params
          c_modes << [mode_params]
          single_disp_modes << [mode_params] if !conn || connector['name'].match(/#{conn}/i)
        end
      end
    end
    if multi_disp_modes
      m_modes = multi_disp_modes
      multi_disp_modes = []
      m_modes.each do |m|
        c_modes.each do |cm|
          chk_conn = !conn
          if conn
            cm.each { |a_cm| chk_conn |= a_cm['connectors_names'].join(',').match(/#{conn}/i) }
            m.each { |a_m| chk_conn |= a_m['connectors_names'].join(',').match(/#{conn}/i) }
          end
          multi_disp_modes << m + cm if chk_conn
        end
      end
    else
      multi_disp_modes = c_modes.dup
    end
  end
  [single_disp_modes, multi_disp_modes]
end

#Function to obtain the bytes per pixel of a data format, takes
#  format, string with the format name
#Returns the length in bpp of the format
def get_format_length(format)
  return case(format)
           when 'NV12', 'NV21', 'YU12', 'YV12'
             1.5 
           when 'UYVY', 'VYUY', 'YUYV', 'YVYU', 'NV16', 'NV61', \
                'AR12', 'XR12', 'AB12', 'XB12', 'RA12', 'RX12', \
                'BA12', 'BX12', 'AR15', 'XR15', 'AB15', 'XB15', \
                'RA15', 'RX15', 'BA15', 'BX15', 'RG16', 'BG16'
             2
           when 'BG24', 'RG24'
             3
           when 'AR24', 'XR24', 'AB24', 'XB24', 'RA24', 'RX24', \
                'BA24', 'BX24', 'AR30', 'XR30', 'AB30', 'XB30', \
                'RA30', 'RX30', 'BA30', 'BX30'
             4
           end
end
