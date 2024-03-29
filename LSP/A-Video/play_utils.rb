
def vyuy_to_yuyv(in_file, out_file)
  out_f = File.open(out_file, 'wb') do |ofd|
    in_f = File.open(in_file, 'rb') do |ifd|
      while(!ifd.eof?)
        pixels = ifd.read(4)
        ofd.write(pixels[1..3])
        ofd.write(pixels[0])
      end
    end
  end
end

def yvyu_to_yuyv(in_file, out_file)
  out_f = File.open(out_file, 'wb') do |ofd|
    in_f = File.open(in_file, 'rb') do |ifd|
      while(!ifd.eof?)
        pixels = ifd.read(4)
        ofd.write(pixels[0])
        ofd.write(pixels[1..3].reverse)
      end
    end
  end
end

def nv24_to_yuv444(in_file, out_file, width, height)
  nvxx_to_yuvxx(in_file, out_file, width, height, 2)
end

def nv16_to_yuv422(in_file, out_file, width, height)
  nvxx_to_yuvxx(in_file, out_file, width, height, 1)
end

def nvxx_to_yuvxx(in_file, out_file, width, height, multiplier, chroma_uv=true)
  frame_size = width.to_i * height.to_i
  out_f = File.open(out_file, 'wb') do |ofd|
    in_f = File.open(in_file, 'rb') do |ifd|
      while(!ifd.eof?)
        luma = ifd.read(frame_size)
        chroma = ifd.read(frame_size*multiplier).unpack('C*').partition.with_index { |_, index| index % 2 ==0 }
        ofd.write(luma)
        if chroma_uv #UV
          ofd.write(chroma[0].pack('C*'))
          ofd.write(chroma[1].pack('C*'))
        else #VU
          ofd.write(chroma[1].pack('C*'))
          ofd.write(chroma[0].pack('C*'))
        end
      end
    end
  end
end

def process_video(params)
  pixel_fmts = {"RGB565" => 'rgb565le',
                "RGB565X" => 'rgb565be',
                "RGB32" => 'rgba',
                "RGB24" => 'rgb24',
                "BGR32" => 'bgra',
                "XR24" => 'bgra',
                "AR24" => 'bgra',
                "YUYV2X8" => 'yuyv422',
                "YUYV" => 'yuyv422',
                "UYVY2X8" => 'uyvy422',
                "UYVY" => 'uyvy422',
                "NV12" => 'nv12',
                "NM12" => 'nv12',
                "YUV420" => 'yuv420p',
                "422P" => 'yuv422p',
                "RGBP" => 'rgb565le',
                #You need to download and compile raw2rgbpnm from git@gitorious.org:raw2rgbpnm/raw2rgbpnm.git
                #for these formats
                "SBGGR8" => "SBGGR8",
                "SGBRG8" => "SGBRG8",
                "SGRBG8" => "SGRBG8",
                "SRGGB8" => "SRGGB8",
                "BA81"   => "SBGGR8",
                #Setting these formats to an avplay supported pix_fmt, requires using a tx function
                "VYUY" => 'yuyv422',
                "YVYU" => 'yuyv422',
                "NV24" => 'yuv444p',
                "NV16" => 'yuv422p',
                "RGB3" => 'rgb24',
                "RGB4" => 'rgba',
                "BGR3" => 'bgr24',
                "BGR4" => 'bgra',
                "RGBR" => 'rgb565be'
                }
  pixel_fmts.default = params['pix_fmt'].downcase()
  
  if raw_sensor_fmts_list.include?(params['pix_fmt'])
    return [pixel_fmts, params['file_path']]
  else
    conv_file = params['file_path']
    case params['pix_fmt']
      when "VYUY"
        conv_file += '.conv'
        vyuy_to_yuyv(params['file_path'], conv_file)
      when "YVYU"
        conv_file += '.conv'
        yvyu_to_yuyv(params['file_path'], conv_file)
      when "NV24"
        conv_file += '.conv'
        nv24_to_yuv444(params['file_path'], conv_file, params['width'], params['height'])
      when "NV16"
        conv_file += '.conv'
        nv16_to_yuv422(params['file_path'], conv_file, params['width'], params['height'])
    end
    return [pixel_fmts, conv_file]
  end
end

def play_video(params)

  pixel_fmts, conv_file = process_video(params)
  if raw_sensor_fmts_list.include?(params['pix_fmt'])
    converted_file = params['file_path'].gsub(/[^\.]+$/, 'pnm')
    src_file = params['file_path'].gsub(/[^\.]+$/, '1fr')
    [converted_file, src_file].each {|f| File.delete(f) if File.exist?(f)} 
    frame_size = params['width'].to_i * params['height'].to_i
    num_frames = File.size(params['file_path'])/frame_size
    if num_frames > 0
      File.open(params['file_path'],'rb') do |ifd|
        File.open(src_file,'wb') do |ofd|
          ifd.read((num_frames*frame_size/2).to_i)
          ofd.write(ifd.read(frame_size))
        end
      end
      params['sys'].send_cmd("raw2rgbpnm -f #{pixel_fmts[params['pix_fmt']]} -s #{params['width']}x#{params['height']} #{src_file} #{converted_file}", params['sys'].prompt, 600)
      params['sys'].send_cmd("avplay #{converted_file}", params['sys'].prompt, 600)
    end
  else
    params['sys'].send_cmd("avplay -pixel_format #{pixel_fmts[params['pix_fmt']]} -video_size #{params['width']}x#{params['height']} -f rawvideo #{conv_file}", params['sys'].prompt, 600)
  end
end

def yuvxx_to_nvxx(in_file, out_file, width, height, multiplier, chroma_uv=true)
  frame_size = width.to_i * height.to_i
  out_f = File.open(out_file, 'wb') do |ofd|
    in_f = File.open(in_file, 'rb') do |ifd|
      while(!ifd.eof?)
        luma = ifd.read(frame_size)
        chroma1 = ifd.read(frame_size*multiplier)
        chroma2 = ifd.read(frame_size*multiplier)
        ofd.write(luma)
        chroma1.length().times() do |i|
          if chroma_uv #UV
            ofd.write(chroma1[i])
            ofd.write(chroma2[i])
          else #VU
            ofd.write(chroma2[i])
            ofd.write(chroma1[i])
          end
        end
      end
    end
  end
end

def yuv444_to_nv24(in_file, out_file, width, height)
  yuvxx_to_nvxx(in_file, out_file, width, height, 1)
end

def yuv422_to_nv16(in_file, out_file, width, height)
  yuvxx_to_nvxx(in_file, out_file, width, height, 0.5)
end

def convert_to_argb(src_file, width, height, p_fmt, filter=nil, cap_sys=@equipment['server1'])
  if raw_sensor_fmts_list.include?(p_fmt)
    puts "8-bit format no conversion performed"
    return src_file
  else
    res_file = src_file+'.argb'
    cap_sys.send_cmd("rm #{res_file}", cap_sys.prompt,
                      300)
    pixel_fmts, conv_file = process_video({'file_path'=> src_file, 'width'=>width, 'height' => height, 'pix_fmt' => p_fmt})
    f_opt = ''
    f_opt = " -filter #{filter}" if filter
    cap_sys.send_cmd("avconv -pix_fmt #{pixel_fmts[p_fmt]} -s #{width}x#{height} -f rawvideo -i #{conv_file} " \
                     "#{f_opt} -pix_fmt argb -s #{width}x#{height} -f rawvideo #{res_file}" ,
                      cap_sys.prompt,
                      600)
    res_file
  end
end

def raw_sensor_fmts_list()
  ["SBGGR8", "SGBRG8", "SGRBG8", "SRGGB8", "BA81"]
end

def sub8bit_ch_fmts_list()
  ["RGBR", "RGBP", "XR15", "AR15"]
end
