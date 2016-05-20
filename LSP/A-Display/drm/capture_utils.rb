module CaptureUtils
  CAP_UTILS_FOLDER = File.join(SiteInfo::UTILS_FOLDER, 'capture-utils')
  HOST_UTILS_URL = 'http://gtopentest-server.gt.design.ti.com/anonymous/common/Multimedia/host-utils'
  
  def get_ref_files_name(mode, fmt, plane)
    fields = ['p']
    fields = ['f1', 'f2'] if mode[-1] == 'i'
    ref_name = "ref_#{mode}"
    p_info = ''
    p_info = ["_P",
              plane['xyoffset'][0],
              plane['xyoffset'][1],
              plane['scale'],
              plane['format']].join('_') if plane
    fields.collect{ |f| ref_name + f + "-#{fmt}" + p_info + ".rgb"}
  end
  
  def install_utils(cap_sys=@equipment['server1'])
      capture_bin = File.join(CAP_UTILS_FOLDER, 'Capture')
      psnr_bin = File.join(CAP_UTILS_FOLDER, 'argb-psnr-ssim')
      if !File.exists?(capture_bin) || !File.exists?(psnr_bin)
        cap_sys.send_cmd("wget --no-proxy #{HOST_UTILS_URL}/capture-utils.tar.gz -P #{SiteInfo::UTILS_FOLDER} || " \
                         "wget #{HOST_UTILS_URL}/capture-utils.tar.gz -P #{SiteInfo::UTILS_FOLDER}",
                         cap_sys.prompt,
                         180)
        cap_sys.send_cmd("tar -C #{SiteInfo::UTILS_FOLDER} -zxvf #{File.join(SiteInfo::UTILS_FOLDER, 'capture-utils.tar.gz')}",
                      cap_sys.prompt,
                      180)
        raise "Unable to fetch capture utility" if !File.exists?(capture_bin) || !File.exists?(psnr_bin)
      end
  end
  
  def change_uyvy_to_rgb(src_file, width, height, cap_sys=@equipment['server1'])
    res_file = src_file+'.rgb24'
    cap_sys.send_cmd("avconv -pix_fmt uyvy422 -s #{width}x#{height} -f rawvideo -i #{src_file} " \
                     "-pix_fmt rgb24 -s #{width}x#{height} -f rawvideo #{res_file}" ,
                      cap_sys.prompt,
                      180)
    res_file
  end
  
  def get_ref_file(mode, format, plane, cap_sys=@equipment['server1'])
    fmt = format ? format : 'XR24'
    cap_sys.send_cmd("mkdir #{@linux_temp_folder}", cap_sys.prompt) if !File.exists?(@linux_temp_folder)
    cap_sys.send_cmd("rm #{@linux_temp_folder}/ref_*.rgb*", cap_sys.prompt)
    result = []
    get_ref_files_name(mode, fmt, plane).each do |f_name|
      f_base_name = f_name + '.tar.xz'
      remote_url = "#{HOST_UTILS_URL}/ref-media/#{f_base_name}"
      local_file = File.join(@linux_temp_folder, f_base_name)
      cap_sys.send_cmd("wget --no-proxy #{remote_url} -O #{local_file} || " \
                      "wget #{remote_url} -O #{local_file} || rm #{local_file}",
                      cap_sys.prompt,
                      600)

      cap_sys.send_cmd("tar -C #{@linux_temp_folder} -Jxvf #{local_file} || rm #{local_file}",
                      cap_sys.prompt,
                      600)
      result << File.join(@linux_temp_folder, f_name) if !cap_sys.response.match(/Error/i)
    end
    result
  end

  def get_psnr_ssim_argb(ref, test, width, height, num_comp, sys=@equipment['server1'])
    result = []
    install_utils(sys)
    ssim = File.join(CAP_UTILS_FOLDER, 'argb-psnr-ssim')
    sys.send_cmd("LD_LIBRARY_PATH=#{CAP_UTILS_FOLDER} #{ssim} #{ref} #{test} #{width} #{height} #{num_comp} 0", sys.prompt, 1000)
    a_psnr=/\s*A=([-\d\.]+)dB,/
    a_ssim=/\s*A=([-\d\.]+)%,/
    if num_comp != 4
      sys.response.scan(/^Frame\s*#\d+:\s+PSNR:\s*R=([-\d\.]+)dB,\s*G=([-\d\.]+)dB,\s*B=([-\d\.]+)dB\s*\|\|\s*SSIM:\s*R=([-\d\.]+)%,\s*G=([-\d\.]+)%,\s*B=([-\d\.]+)%/i) do |v1, v2, v3, v4, v5, v6| 
        result << {'psnr' => {'r' => v1.to_f, 'g' => v2.to_f, 'b' => v3.to_f},
                   'ssim' => {'r' => v4.to_f, 'g' => v5.to_f, 'b' => v6.to_f}}
      end
    else
      sys.response.scan(/^Frame\s*#\d+:\s+PSNR:\s*A=([-\d\.]+)dB,\s*R=([-\d\.]+)dB,\s*G=([-\d\.]+)dB,\s*B=([-\d\.]+)dB\s*\|\|\s*SSIM:\s*A=([-\d\.]+)%,\s*R=([-\d\.]+)%,\s*G=([-\d\.]+)%,\s*B=([-\d\.]+)%/i) do |v1, v2, v3, v4, v5, v6, v7, v8| 
        result << {'psnr' => {'a' => v1.to_f, 'r' => v2.to_f, 'g' => v3.to_f, 'b' => v4.to_f},
                   'ssim' => {'a' => v5.to_f, 'r' => v6.to_f, 'g' => v7.to_f, 'b' => v8.to_f}}
      end
    end
    result
  end

  #Class to control a blackmagicdesign card based on the Capture example 
  #provided with their SDK 
  class MediaCapture

    EDIDS = {
      'Intensity Pro 4K' => '00ffffffffffff0009a4000001000000' \
                            '341601038047289612daffa3584aa229' \
                            '17494b20000001010101010101010101' \
                            '010101010101011d8018711c1620582c' \
                            '2500c48e2100009e011d007251d01e20' \
                            '6e285500c48e2100001e000000fc0042' \
                            '4d442048444d490a20202020000000fd' \
                            '00323c0f2d08000a20202020202001fc' \
                            '02032a764e858486949395a0a1a29f90' \
                            '021101230f0704831f00006e030c0000' \
                            '00383c200080010203048c0aa01451f0' \
                            '1600267c4300138e21000098011d80d0' \
                            '721c1620102c2580c48e2100009e011d' \
                            '00bc52d01e20b8285540c48e2100001e' \
                            '8c0aa02051201810187e2300138e2100' \
                            '009800000000000000000000000000dc'
    }

    def initialize(cap_sys)
      @capture_modes = {}
      @capture_bin = File.join(CAP_UTILS_FOLDER, 'Capture')
      @sys = cap_sys
      install_utils(@sys)
      @sys.send_cmd("#{@capture_bin} -d 0")
      @pixel_fmts = {}
      @model = @sys.response.match(/(?<=device id.:).*?\d+:([^\(]+)\(selected\)/im)[1].strip()
      @sys.response.scan(/(\d+):\s*(.*?)(\d+\s*x\s*\d+)\s*([\d\.]+)\s*FPS/i) do |val, name, resolution, fr|
        res = resolution.gsub(/\s+/,'')
        next if name.match(/ntsc|pal/i) #disabling ntsc and pal since card has problems with this modes
        @capture_modes[res] = {} if !@capture_modes.has_key?(res)
        @capture_modes[res][fr] = {} if !@capture_modes[res].has_key?(fr)
        @capture_modes[res][fr][name.include?('p') ? 'p' : 'i'] = 
                            {'name' => name.strip(),
                            'val' => val}
      end
      @sys.response.scan(/(\d+):\s*(\d+\s*bit\s*[^\d\s]+)/i) do |val, name|
        @pixel_fmts[name.gsub(/\s+/,'-').downcase()] = val
      end
    end
    
    def capture_media(v_name, a_name, width, height, framerate, interlace, cap_secs=10, a_chans=2, a_bits=16)
      fr = framerate.to_i
      n_h = height == 480 ? 486 : height.to_i
      n_w = width.to_i
      pixel = @pixel_fmts['8-bit-argb']
      n_c = 4
      inter = interlace.downcase()
      if [720, 480].include?(n_w) && [486, 576].include?(n_h) && [50, 60].include?(fr)
        pixel = @pixel_fmts['8-bit-yuv']
        n_c = 3
      end
      num_frames = (cap_secs*fr).to_i
      if inter == 'p' && @capture_modes[n_w.to_s+'x'+n_h.to_s][fr.to_s] &&
         @capture_modes[n_w.to_s+'x'+n_h.to_s][fr.to_s][inter]
        mode =  @capture_modes[n_w.to_s+'x'+n_h.to_s][fr.to_s][inter]['val']
      elsif inter == 'i' && @capture_modes[n_w.to_s+'x'+n_h.to_s][(fr/2).to_s] &&
            @capture_modes[n_w.to_s+'x'+n_h.to_s][(fr/2).to_s][inter]
        mode =  @capture_modes[n_w.to_s+'x'+n_h.to_s][(fr/2).to_s][inter]['val']
        num_frames = (cap_secs*fr/2).to_i
      else
        return -1
      end
      @sample_size = a_bits.to_i/8
      @audio_channels = a_chans.to_i
      @sys.send_cmd("#{@capture_bin} -v #{v_name} -d 0 -m #{mode} -p #{pixel} -a #{a_name} -c #{a_chans} -n #{num_frames} -s #{a_bits} -x 1", @sys.prompt, 10 + (num_frames*n_w*n_h).to_f/15552000) 
      raise "Frame drop detected" if @sys.response.match(/Frame\s*received\s*\(#\d+\)\s*-\s*No input signal detected/)
      n_c
    end

    def is_capture_mode_supported(width, height, framerate, interlace)
      
      fr = framerate.to_i
      n_h = height.to_i == 480 ? 486 : height.to_i
      n_w = width.to_i
      inter = interlace.downcase()
      
      @capture_modes[n_w.to_s+'x'+n_h.to_s] &&
      ((inter == 'p' && @capture_modes[n_w.to_s+'x'+n_h.to_s][fr.to_s] &&
         @capture_modes[n_w.to_s+'x'+n_h.to_s][fr.to_s][inter]) ||
      (inter == 'i' && @capture_modes[n_w.to_s+'x'+n_h.to_s][(fr/2).to_s] &&
            @capture_modes[n_w.to_s+'x'+n_h.to_s][(fr/2).to_s][inter]))
    end

    def get_recorded_sample_size()
      @sample_size
    end
    
    def get_audio_sampling_rate()
      48000
    end
    
    def get_recorded_audio_channels()
      @audio_channels
    end
    
    def get_edid()
      EDIDS[@model]
    end
    
  end
end
