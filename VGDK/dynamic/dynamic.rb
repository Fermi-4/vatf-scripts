# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require File.dirname(__FILE__)+'/../common/codec_params.rb'
require File.dirname(__FILE__)+'/../utils/eth_info.rb'
include CodecParams
include ETHInfo
require File.dirname(__FILE__)+'/../boot_scripts/boot.rb'
include BootScripts
require File.dirname(__FILE__)+'/../utils/genPktHdrs'
require File.dirname(__FILE__)+'/../utils/genSDP'
require File.dirname(__FILE__)+'/../utils/genCodecCfg'
include GenCodecCfg
include GenSDP
include GenPktHdrs
INPUT_DIR = SiteInfo::VGDK_INPUT_CLIPS
OUTPUT_DIR = SiteInfo::VGDK_OUTPUT_CLIPS
MPLAYER_DIR = File.join(File.expand_path(File.dirname(__FILE__)),"..","utils","MPlayer for Windows")
VIDEO_TOOLS_DIR = File.join(File.expand_path(File.dirname(__FILE__)),"..","utils")
WIRESHARK_DIR = ("C:/Program Files/Wireshark")
SCRIPT_EXTRACTOR = SiteInfo::VGDK_INPUT_CLIPS

class ChannelInfo
    def initialize(codec,dir,resolution,out_codec,in_codec,in_resolution)
        @in_codec = codec
        @dir = dir # 0 => stream from PC to THK; 1 => stream from THK to PC 
        @resolution = resolution
        @transcoded_to_codec = out_codec # This field is valid ONLY when dir = 0
        @transcoded_from_codec = in_codec # This field is valid ONLY when dir = 1
        @transized_from_resolution = in_resolution # This field is valid ONLY when dir = 1
    end
    def get_dir()
    @dir
    end
    def get_codec()
    @in_codec
    end
    def get_resolution()
    @resolution
    end
    def get_transized_from_resolution()
    @transized_from_resolution
    end
    def get_transcoded_to_codec()
    @transcoded_to_codec
    end
    def get_transcoded_from_codec()
    @transcoded_from_codec
    end
end
#data structure that will contain an array of ChannelInfo objects
class CoreInfo
    def initialize()
        @channels = Array.new
    end
    def append(aChannel)
        @channels.push(aChannel)
    self
    end

    def [](key)
    if key.kind_of?(Integer)
      @channels[key]
    else
      # ...
    end
    end

    def getLength()
        @channels.length
    end
end

CodecInfo = Struct.new(:codec_type, :resolution, :stream_sent, :subjective_on) 

def setup
    dut = @equipment['dut1']
    dut.set_api("vgdk")
    server = defined?(@equipment['server1']) ? @equipment['server1'] : nil
    dut.connect({'type'=>'telnet'})
    setup_boot(dut,server)
    dut.send_cmd("wait 10000", /OK/, 2)
    dut.send_cmd("cc ver", /OK/, 2)
    dut.send_cmd("dspi show", /OK/, 2) 
    #dut.send_cmd("spy dim 2", /OK/, 2) 
    dut.send_cmd("dimt reset template 11",/OK/,2)
    dut.send_cmd("dimt set template 11 chan chan_state t2pmask app user alarm tone cas",/OK/,2)
    dut.send_cmd("dimt set template 11 chan chan_state t2pval app user alarm tone cas",/OK/,2)
    dut.send_cmd("dimt set template 11 chan chan_state p2tmask app user alarm tone cas",/OK/,2)
    dut.send_cmd("dimt set template 11 chan chan_state p2tval app user alarm tone cas",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg encapsulation rtp",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp txssrc 0xabababab",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp tx_start_timestamp 0xbcbcbcbc",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp rxssrc 0xabababab",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp rx_start_timestamp 0xbcbcbcbc",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp rxssrc_ctrl drop",/OK/,2)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp txfo 0x00",/OK/,2)
    dut.send_cmd("wait 10", /OK/, 2)
    enc_framerate =  @test_params.params_chan.instance_variable_get("@enc_framerate")

end

def run

    @show_debug_messages = false
    subjective = @test_params.params_chan.issubjectivereqd[0].to_i
    @multislice = @test_params.params_chan.multislice[0].to_i
    test_case_id = @test_params.caseID
    num_frames = @test_params.params_chan.num_frames[0].to_i
    save_clips = @test_params.params_chan.saveclips[0].to_s
    video_clarity = 0
    if(@test_params.params_chan.instance_variable_defined?("@video_clarity"))
      video_clarity = @test_params.params_chan.video_clarity[0].to_i
    end
    iteration = Time.now
    iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
    clip_iter = @test_params.params_chan.clip_iter[0].to_i
    dut = @equipment['dut1']
    @platform_info = Eth_info.new()
    @platform_info.init_eth_info(dut)
    template = 0
    dyn_iter = 0
    clip_hash = Hash.new
    @test_params.params_chan.instance_variables.each do |curr_var|
        if /_clip/.match(curr_var)
            clip_hash[curr_var] = @test_params.params_chan.instance_variable_get(curr_var)
        end
    end
    test_done_result = nil
    test_comment = nil
    res_class_sent = false
    codec_hash = Hash.new
    codec_template_hash = Hash.new
    
    debug_puts "Close any channels that may be open"
    dut.send_cmd("dim tcids", /OK/, 2)
    tcids_state = dut.response
    tcids_state.each { |line|
    if(line.match(/[\d+\s+]{3}\d+\s\/\s+\d+\s+\w[Idle|Video|Exception]/i))
        tcid = line.match(/\d+/)[0]
        channel_reset(dut,tcid)
        close_channel(dut,tcid)
    end
    }
    if @test_params.params_chan.instance_variable_defined?(:@wire_fps)
      wire_fps = @test_params.params_chan.wire_fps[0].to_i
    else
      wire_fps = 30
    end
    chan_params = @test_params.params_chan.chan_config
    (chan_params.length).times do |i|
    codec = (chan_params[i].split)[0]
    if((codec_hash).has_key?(codec.to_s) != true)
        codec_hash.merge!(codec.to_s => [])
        case(codec.to_s)
        when "h264bp"
          template = 10
          codec_template_hash.merge!(codec => template)
        when "mpeg4"
          template = 14
          codec_template_hash.merge!(codec => template)
        when "mpeg2"
          template = 18
          codec_template_hash.merge!(codec => template)
        when "h263p"
          template = 22
          codec_template_hash.merge!(codec => template)
        when "h264mp"
          template = 26
          codec_template_hash.merge!(codec => template)
        else
          raise " #### Error: Not a recognized codec #{codec.to_s}"
        end
    end
    end

    default_params = Hash.new
    codec_hash.each_key{|codec| default_params.merge!(initialize_codec_default_params(codec))}
      
    #set ENC/DEC templates for this codec
    decoder_template = 0
    encoder_template = 0
    encoder_dyn_template = 0
    # Begin codec params configuration
       
    core = 0
    res = false
    tempc_info = CoreInfo::new()
    core_info_hash = Hash.new
    chan_params = @test_params.params_chan.chan_config
    if(((chan_params.length) % 2) == 1)
      raise " #### Error: Config strings should be pairwise, input stream-output stream"
    end
    (chan_params.length).times do |i| 
      params = chan_params[i].split
      chanCodec = params[0].to_s
      channels = params[1].to_i
      core_num = params[2].to_i
      resolution = params[3].to_s
      if(i%2 == 0)
          dir = "dec" #incoming stream to THK
          transcoded_to_codec = (chan_params[i+1].split)[0]
          transcoded_from_codec = nil
          transized_from_res = nil
          codec_type = "dec"
      else
          dir = "enc"
          transcoded_to_codec = nil
          transcoded_from_codec = (chan_params[i-1].split)[0]
          transized_from_res = (chan_params[i-1].split)[3]
          codec_type = "enc"
      end
      codec_hash[chanCodec].each{ |codec_info|
        if(codec_info.codec_type == codec_type && codec_info.resolution == resolution)
            debug_puts "#{chanCodec} #{codec_type} #{resolution} exists in codec_hash"
            res = true
        end
      }
      if(res == false)
          debug_puts "Adding #{chanCodec} #{codec_type} #{resolution} to codec_hash"
          codec_hash[chanCodec] << CodecInfo.new(codec_type,resolution,0,0)
      end
      if(core_info_hash.has_key?(core_num) == true)
          channels.times do 
              debug_puts "Adding #{chanCodec} #{resolution} #{dir} to core_info_hash"
              core_info_hash[core_num].append(ChannelInfo.new(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res))
          end
      else   
          tempc_info = CoreInfo::new() 
          channels.times do 
              tempc_info.append(ChannelInfo.new(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res))                    
          end
          core_info_hash.merge!(core_num => tempc_info)
          debug_puts "Adding #{chanCodec} #{resolution} #{dir} to core_info_hash"
      end
      res = false
    end
     
     (codec_hash).each_pair{|codec,res_arr| 
      res_arr.each { |res| 
       if ((res.resolution == "d1ntsc" || res.resolution == "d1pal") && res_class_sent == false)
         dut.send_cmd("dimt reset template 20",/OK/,2) 
         dut.send_cmd("dimt set template 20 dsp_glob_config video_sw_cfg res_class 2",/OK/,2) 
         dut.send_cmd("dimt dsp_glob_config 0 alloc 20",/ACK DONE/,10) 
         dut.send_cmd("wait 3000",/OK/,2) 
         res_class_sent = true
       end
     }
     }
     if (res_class_sent == false) 
      dut.send_cmd("dimt reset template 20",/OK/,2) 
      dut.send_cmd("dimt set template 20 dsp_glob_config video_sw_cfg res_class 1",/OK/,2) 
      dut.send_cmd("dimt dsp_glob_config 0 alloc 20",/ACK DONE/,10) 
      dut.send_cmd("wait 3000",/OK/,2) 
     end
     
    (codec_hash).each_pair{|codec,res_arr| 
      res_arr.each { |res|
        if(res.codec_type == "dec")
          set_xdp_vars(dut,codec,"dec_dyn",default_params)
          set_xdp_vars(dut,codec,"dec_st",default_params)
        elsif (res.codec_type == "enc")
          set_xdp_vars(dut,codec,"enc_dyn",default_params)
          set_xdp_vars(dut,codec,"enc_st",default_params)
        end
        decoder_template = codec_template_hash[codec]
        encoder_template = decoder_template + 2
        encoder_dyn_template = encoder_template + 1
        
        reset_template(dut,decoder_template)
        reset_template(dut,encoder_template)
        reset_template(dut,encoder_dyn_template)
        
        if (res.codec_type == "enc")
          default_params.each_pair do |var,value|
            if(/#{codec}v_enc/).match(var) 
              if(/#{codec}v_enc_ovly_type/).match(var) 
              debug_puts "setting default params for #{codec}"
              dut.send_cmd("dimt set template #{encoder_template} video video_ovly_cfg #{var.gsub("#{codec}v_enc_", "")} #{value}",/OK/,2) 
              else
              dut.send_cmd("dimt set template #{encoder_template} video video_mode #{var.gsub("#{codec}v_enc_", "")} #{value}",/OK/,2) 
              end
            end
          end
        elsif(res.codec_type == "dec")
          default_params.each_pair do |var,value|
            if(/#{codec}v_dec/).match(var)
              dut.send_cmd("dimt set template #{decoder_template} video video_mode #{var.gsub("#{codec}v_dec_", "")} #{value}",/OK/,2) 
            end
          end
        end
      #CONF-CONNECT TEMPLATE
        dut.send_cmd("dimt reset template 15", /OK/, 2)
        dut.send_cmd("dimt set template 15 conn_req nelem 1", /OK/, 2)
        case res.codec_type
        when "dec"
          set_codec_cfg(dut,codec,nil,"dec_dyn",decoder_template,"default",dyn_iter,default_params)
          set_codec_cfg(dut,codec,nil,"dec_st",decoder_template,"default",dyn_iter,default_params)
          set_codec_cfg(dut,codec,res.resolution,"dec_st",decoder_template,"test",dyn_iter,nil)
          set_codec_cfg(dut,codec,res.resolution,"dec_dyn",decoder_template,"test",dyn_iter,nil)
        when "enc"
          set_codec_cfg(dut,codec,nil,"enc_dyn",encoder_template,"default",dyn_iter,default_params)
          template_copy(dut,encoder_template,encoder_dyn_template)
          set_codec_cfg(dut,codec,nil,"enc_st",encoder_template,"default",dyn_iter,default_params)
          set_codec_cfg(dut,codec,res.resolution,"enc_st",encoder_template,"test",dyn_iter,nil)
          set_codec_cfg(dut,codec,res.resolution,"enc_dyn",encoder_template,"test",dyn_iter,nil)
          set_frc_mode(dut,encoder_template)
        else
          # do nothing
        end
        tcid = 0
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type)
              dut.send_cmd("cc assoc #{tcid} #{key} #{i}", /OK/, 2) 
              #cc assoc <tcid> <dsp> <chan>
              dut.send_cmd("cc xdp_cli_reg #{tcid}", /OK/, 2) 
            end
            tcid += 1
          }
        }
        ssrc = 100
        loc_port = 32768
        rem_port = 32768
        tcid = 0
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type)
              dut.send_cmd("dimt open #{tcid} alloc 11 chan encapcfg rtp txssrc #{ssrc} rxssrc #{ssrc}", /ACK DONE/, 10)
              dut.send_cmd("wait 10", /.*/, 2)
              dut.send_cmd("cc xdp_cli_set_prot #{tcid} ether ipv4 udp", /OK/, 2)
              dut.send_cmd("cc xdp_set #{tcid} phy phy_id 24", /OK/, 2) 
              dut.send_cmd("cc xdp_set #{tcid} phy dsp_dev_iface 2", /OK/, 2) 
              dut.send_cmd("cc xdp_set #{tcid} phy dsp_port_id 0", /OK/, 2)
              dut.send_cmd("cc xdp_set #{tcid} ether loc_addr dspMacVoiceSrc#{key}_0", /OK/, 2) 
              dut.send_cmd("cc xdp_set #{tcid} ether rem_addr dspMacVoiceTgt#{key}_0", /OK/, 2)
              dut.send_cmd("cc xdp_set #{tcid} ipv4 loc_addr dspIpVoiceSrc#{key}_0", /OK/, 2) 
              dut.send_cmd("cc xdp_set #{tcid} ipv4 rem_addr dspIpVoiceTgt#{key}_0", /OK/, 2)  
              dut.send_cmd("cc xdp_set #{tcid} udp loc_port #{loc_port}", /OK/, 2) 
              dut.send_cmd("cc xdp_set #{tcid} udp rem_port #{rem_port}", /OK/, 2) 
              dut.send_cmd("cc xdp_cli_set_state #{tcid} tx_enable rx_enable", /OK/, 2)
              if(core_info_hash[key][i].get_dir == "dec")
                  dut.send_cmd("dimt video_mode #{tcid} alloc #{decoder_template}", /ACK DONE/, 10)
              elsif(core_info_hash[key][i].get_dir == "enc")
                  dut.send_cmd("dimt video_mode #{tcid} alloc #{encoder_template}", /ACK DONE/, 10)
              end
            end
            if(dut.timeout?)
              cleanup_and_exit()
              return
            end  
            ssrc += 1
            loc_port += 2
            rem_port += 2
            tcid += 1
          }
        loc_port = 32768
        }
        dut.send_cmd("wait 10", /OK/, 2)   
      }
    }
 
    k = 0
    chan = 0
    (((chan_params.length))/2).times do 
      i = (chan_params[k].split)[1].to_i
      j = (chan_params[k+1].split)[1].to_i
      if(i != j)
        raise " #### Error receive and send channel config error ####"
      end
      (i).times do 
        dut.send_cmd("dimt set template 15 conn_req elem 0 req_type add ld_pkt_pkt src #{chan} dst #{chan+i}", /OK/, 2)
        dut.send_cmd("dimt conn_req #{chan} alloc 15", /ACK DONE/,10)
        chan += 1
      end
      if(dut.timeout?)
        cleanup_and_exit()
        return
      end  
      k += 2
      chan += i 
    end

    tcid = 0
    core_info_hash.keys.sort.each { |key|
    core_info_hash[key].getLength().times {
        print_stats(dut,tcid)
        tcid += 1
        }
    }
    if(dut.timeout?)
      cleanup_and_exit()
      return
    end  
    append = 0
    i = 0
    pc_udp_port = 32768
    # Generate packet headers
    if (File.exists?"#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}")
        FileUtils.remove_dir("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}") 
    end
    FileUtils.mkdir("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}")   
    FileUtils.mkdir("#{OUTPUT_DIR}/outputCap/TC#{test_case_id}") if !File.exists?("#{OUTPUT_DIR}/outputCap/TC#{test_case_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}") if !File.exists?("#{OUTPUT_DIR}/TC#{test_case_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/VideoClarityRefs") 
    
    file_ext_name = nil
    codec_hash.each_pair { |codec, res_arr|
      res_arr.each {|res|
        debug_puts "codec_hash res_arr: #{res}"
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)
              debug_puts "Generating pktHdrs.cfg"
              case codec
                  when /h264/
                    file_ext_name = "264"
                  when "mpeg4"
                    file_ext_name = "m4v"
                  when "mpeg2"
                    file_ext_name = "m2v"
                  when "h263p"
                    file_ext_name = "263"
              end
              clip_hash.each_key { |clip|
                debug_puts "#{codec} #{clip} #{res.resolution} #{clip_hash[clip].to_s}"
                if(/#{codec}_#{res.resolution}/.match(clip))
                    if ((@multislice == 1 && !File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}.cap")) || (@multislice == 0 && !File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}.cap")) )    
                        raise "Error: ### Clip not found"
                    end
                    genCodecCfg(codec,res.resolution,test_case_id,clip_hash[clip].to_s,@multislice) 
                    system("#{VIDEO_TOOLS_DIR}\\desktop_vppu.exe #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.cfg > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.txt")         
                    Dir.chdir("#{WIRESHARK_DIR}")
                    if(@multislice == 1)
                      system("capinfos.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}_rtpmarker.cap > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt")
                    else
                      system("capinfos.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}_rtpmarker.cap > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt")
                    end
                    pkt_to_pkt_delay = get_pkt_to_pkt_delay("#{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.txt","#{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt",wire_fps)
                    genPktHdrs(codec,res.resolution,key,i,pc_udp_port,append,test_case_id,clip_hash[clip].to_s,@multislice,pkt_to_pkt_delay,@platform_info) 
                    if(video_clarity == 1)
                      begin
                        if(@multislice == 1)
                          system("#{VIDEO_TOOLS_DIR}\\ffmpeg.exe -i #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}.#{file_ext_name} -f rawvideo #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv") if !File.exists?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv"
                        else
                          system("#{VIDEO_TOOLS_DIR}\\ffmpeg.exe -i #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}.#{file_ext_name} -f rawvideo #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv") if !File.exists?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv"
                        end
                      rescue
                        test_done_result = FrameworkConstants::Result[:fail]
                        test_comment += "File.open failed" + $!
                        $stderr.print "File.open failed" + $!
                        raise
                      end
                    end
                    append = 1                                
                end
              }
              if(append == 0)
                  raise "Error: ### Clip not found"
              end
            end
            pc_udp_port += 2
          }
        }
        pc_udp_port = 32768
        append = 0
      }
    }

    clip_iter.times { |c_iter|
      pc_udp_port = 32768
      append = 0
      geom = 0
      codec_hash.each_pair { |codec, res_arr|
        res_arr.each {|res|
          core_info_hash.keys.sort.each { |key|
            core_info_hash[key].getLength().times { |i|  
                if(core_info_hash[key][i].get_dir == "enc" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)
                  debug_puts "Generating SDP for #{core_info_hash[key][i].get_codec} #{core_info_hash[key][i].get_resolution} #{key} #{pc_udp_port} #{core_info_hash[key][i].get_dir}"
                  genSDP(core_info_hash[key][i].get_codec,core_info_hash[key][i].get_resolution,key,pc_udp_port,append,test_case_id,geom,@multislice,iteration_id,c_iter,@platform_info)
                  Dir.chdir("#{WIRESHARK_DIR}")
                  system("start tshark -f \"dst #{@platform_info.get_pc_ip} and udp dst port #{pc_udp_port}\" -i #{@platform_info.get_eth_dev} -w #{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}/#{pc_udp_port}_out_clipIter#{c_iter}.cap")
                  geom += 180
                  append = 1
                end
                pc_udp_port += 2  
            }
          }
        pc_udp_port = 32768
        append = 0
        geom = 0
        }
      }
      #Dir.chdir("#{WIRESHARK_DIR}")
      #system("start tshark -f \"dst #{@platform_info.get_pc_ip} \" -i #{@platform_info.get_eth_dev} -w #{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}/Iter#{iteration_id}_clipIter#{c_iter}.cap")
      i = 0
      send_threads = []
      codec_hash.each_pair { |codec, res_arr|
        res_arr.each{|res|
          core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
              if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && res.stream_sent == 0)
                res.stream_sent = 1  
                debug_puts "get_transcoded_to_codec :#{core_info_hash[key][i].get_transcoded_to_codec}"
                transcoded_codec = core_info_hash[key][i].get_transcoded_to_codec
                if(c_iter == 0)
                    system("#{VIDEO_TOOLS_DIR}/etherealUtil.exe #{INPUT_DIR}\\config\\change_headers_#{codec}_#{res.resolution}.cfg #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\pktHeaders_#{codec}_#{res.resolution}.cfg #{INPUT_DIR}\\config\\autogenerated\\auto_generated_ConfigFile_#{codec}_#{res.resolution}_Iter#{iteration_id}.cfg #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\delays_#{codec}_#{res.resolution}.cfg")
                end
              end
            }
          }
        }
      }
      system("ruby #{VIDEO_TOOLS_DIR}/genSendPkts.rb #{iteration_id}")
      if(subjective == 1)
      codec_hash.each_pair { |codec, res_arr|
          res_arr.each{|res|
              core_info_hash.keys.sort.each { |key|
                core_info_hash[key].getLength().times { |i|
                transcoded_codec = core_info_hash[key][i].get_transcoded_to_codec
                if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && res.subjective_on == 0)
                  system("start cmd.exe \/c #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\#{transcoded_codec}_#{res.resolution}_subj_bat.bat")
                  sleep(1)
                  res.subjective_on = 1
                end
                }
              }
          }
      }
      end
      
      dyn_params = []
      if(@test_params.params_chan.instance_variable_defined?(:@enc_bitrate))
        dyn_params << @test_params.params_chan.enc_bitrate.length
      end
      if(@test_params.params_chan.instance_variable_defined?(:@enc_framerate))
        dyn_params << @test_params.params_chan.enc_framerate.length
      end
      if(@test_params.params_chan.instance_variable_defined?(:@enc_resolution))
        dyn_params << @test_params.params_chan.enc_resolution.length
        resolution = @test_params.params_chan.instance_variable_get("@enc_resolution")[dyn_iter].to_s 
      end
      max_iters = dyn_params.max
      send_threads << Thread.new() { system("#{VIDEO_TOOLS_DIR}/sendPackets.exe #{INPUT_DIR}\\config\\autogenerated\\auto_generated_ConfigFile_4sendPkts_Iter#{iteration_id}.cfg #{@platform_info.get_eth_dev} 1 s")    
      sleep(1)
      }
      send_threads << Thread.new() {
        tcid = 0
        sleep(1)
        max_iters.times { |i| 
          if (@test_params.params_chan.instance_variable_defined?(:@enc_resolution) && dyn_iter < @test_params.params_chan.enc_resolution.length)
            resolution = @test_params.params_chan.instance_variable_get("@enc_resolution")[dyn_iter].to_s 
          else
            resolution = nil
          end
          (codec_hash).each_pair{|codec,res_arr| 
            res_arr.each { |res| 
              if res.codec_type == "enc"
                encoder_dyn_template = codec_template_hash[codec] + 3
                debug_puts "Resolution :#{resolution}"
                set_codec_cfg(dut,codec,resolution,"enc_dyn",encoder_dyn_template,"test",dyn_iter,nil)
                core_info_hash.keys.sort.each { |key|
                  core_info_hash[key].getLength().times { |i|
                  if(core_info_hash[key][i].get_dir == "enc" && core_info_hash[key][i].get_codec == codec)
                    dut.send_cmd("dimt video_config #{tcid} alloc #{encoder_dyn_template}",/ACK DONE/,10)
                  end
                  tcid += 1
                  }
                }
              end
              tcid = 0
            }
          }
          dyn_iter += 1
        }
      }
      priority = 2 # main process has priority 0
      send_threads.each { |aThread|  
      aThread.priority = priority
      priority -= 1
      }
      send_threads.each { |aThread|  aThread.join }   
      codec_hash.each_pair { |codec, res_arr| res_arr.each{|res| res.stream_sent = 0} }        
      system("taskkill /F /IM tshark.exe")
      system("taskkill /FI \"IMAGENAME eq mplayer.exe\"")
      
    }
    if(dut.timeout?)
      cleanup_and_exit()
      return
    end  
    pc_udp_port = 32768
    local_ref_file = nil
    test_file = nil
    format = []
    tcid = 0
    core_info_hash.keys.sort.each { |key|
    core_info_hash[key].getLength().times {
        print_stats(dut,tcid)
        tcid += 1
        }
    }
    if(dut.timeout?)
      cleanup_and_exit()
      return
    end  
 clip_iter.times { |c_iter|
    codec_hash.each_pair { |codec, res_arr|
        res_arr.each{|res|
            core_info_hash.keys.sort.each { |key|
                core_info_hash[key].getLength().times { |i|
                    if(core_info_hash[key][i].get_dir == "enc" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)
                      debug_puts "codec: #{codec} res: #{res.resolution} port:#{pc_udp_port}"
                      #system("etherealUtil.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\#{pc_udp_port}.cfg #{OUTPUT_DIR}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\auto_generated_ConfigFile4sendPkts_#{pc_udp_port}.cfg")
                      case(codec)
                      when /h264/
                          file_ext_name = "264"
                      when "mpeg4"
                          file_ext_name = "m4v"
                      when "h263p"
                          file_ext_name = "263"
                      end
                      # system("start /D \"#{MPLAYER_DIR}\" mplayer sdp://#{OUTPUT_DIR}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\t_rtp_#{pc_udp_port}.sdp -fps 15 -dumpvideo -dumpfile #{OUTPUT_DIR}\\TC#{test_case_id}\\trans_#{codec}_#{res.resolution}_cap\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name}")
                      # sleep(5)
                      # system("sendPackets.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\auto_generated_ConfigFile4sendPkts_#{pc_udp_port}.cfg #{ETH_DEV} 1 s")  
                      begin
                        system("#{VIDEO_TOOLS_DIR}\\desktop_vppu.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\Iter#{iteration_id}\\#{codec}_#{res.resolution}\\clipIter#{c_iter}\\#{pc_udp_port}_codec_dump.cfg")         
                        if File.size?("#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name}")
                          if(video_clarity == 1)
                            system("#{VIDEO_TOOLS_DIR}\\ffmpeg.exe -i #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name} -f rawvideo #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.yuv") if File.size?("#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name}")
                          end
                        else
                          test_done_result = FrameworkConstants::Result[:fail]
                          test_comment = "Test completed: No transcoding. Output clips directory #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}"
                        end
                        if(video_clarity == 1)
                          test_file = "#{Pathname.new("#{OUTPUT_DIR}").realpath}/TC#{test_case_id}/Iter#{iteration_id}/trans_#{codec}_#{res.resolution}_cap/clipIter#{c_iter}/trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.yuv"
                          local_ref_file = "#{Pathname.new("#{OUTPUT_DIR}").realpath}/TC#{test_case_id}/Iter#{iteration_id}/VideoClarityRefs/#{core_info_hash[key][i].get_transcoded_from_codec}_#{core_info_hash[key][i].get_transized_from_resolution}.yuv" 
                          FileUtils.chmod(0755,local_ref_file)
                          FileUtils.chmod(0755,test_file)
                        end
                      rescue SystemCallError
                        test_done_result = FrameworkConstants::Result[:fail]
                        test_comment = "File IO failed - no Video Clarity scores will be generated" 
                        $stderr.print "File IO failed" + $!
                      end
                      if(video_clarity == 1)
                        if (File.size?(test_file) != nil && File.size?(local_ref_file) != nil)
                          case(res.resolution)
                          when "qcif"
                            format = [176,144,30]
                          when "cif"
                            format = [352,288,30]
                          when "d1ntsc"
                            format = [720,480,30]
                          when "d1pal"
                            format = [720,576,30]
                          else
                            format = [176,144,30]
                          end
                          video_tester_result = @equipment['video_tester'].file_to_file_test({'ref_file' => local_ref_file, 
                                                                                              'test_file' => test_file,
                                                                                              #'data_format' => @test_params.params_chan.video_input_chroma_format[0],
                                                                                              'format' => format,
                                                                                              'video_height' => format[1],
                                                                                              'video_width' =>format[0],
                                                                                              'num_frames' => num_frames,
                                                                                              'frame_rate' => 30,
                                                                                              #'metric_window' => metric_window
                                                                                             })
                          if  !video_tester_result
                              @results_html_file.add_paragraph("")
                              test_done_result = FrameworkConstants::Result[:fail]
                              test_comment += "Objective Video Quality could not be calculated. Video_Tester returned #{video_tester_result} for #{local_ref_file}\n"   
                          else  
                              video_done_result, video_done_comment = get_results(test_file)
                              #test_comment += video_done_comment+"\n" if video_done_comment.strip.to_s == ''
                              test_done_result = video_done_result if test_done_result !=	 FrameworkConstants::Result[:fail]
                          end
                          set_result(test_done_result, test_comment)                            
                      end
                    end
                  end
                  pc_udp_port += 2 
                }
            }
            pc_udp_port = 32768
            if(c_iter > 0 && save_clips == "false")
              FileUtils.remove_dir("#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}") if File.directory?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}"
            end 
        }
    }
    }
    debug_puts "%%%%%%%%%% sending channel close %%%%%%%%%%%%%%%%"
    dut.send_cmd("dim tcids", /OK/, 2)
    tcids_state = dut.response
    tcids_state.each { |line|
    if(line.match(/Exception/i))
        test_done_result = FrameworkConstants::Result[:fail]
        test_comment = "Test completed: Channel Exception"
        set_result(test_done_result,test_comment)
    elsif(line.match(/[\d+\s+]{3}\d+\s\/\s+\d+\s+\w[Idle|Video]/i))
        tcid = line.match(/\d+/)[0]
        channel_reset(dut,tcid)
        close_channel(dut,tcid)
    end
    }
    if (test_done_result != FrameworkConstants::Result[:fail])
        test_done_result = FrameworkConstants::Result[:pass] 
        test_comment = "Test completed: Output clips at #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}"
    end
    set_result(test_done_result,test_comment)
    
end

def set_xdp_vars(dut,codec,type,params)
    i = 0
    params_array = Array.new
    if(type == "dec_dyn")
        paramtype = "dyn" 
        codectype = "DEC"
    elsif (type == "dec_st")
        paramtype = "st" 
        codectype = "DEC"
    elsif (type == "enc_st")
        paramtype = "st" 
        codectype = "ENC"
    elsif (type == "enc_dyn")
        paramtype = "dyn" 
        codectype = "ENC"
    else
        raise " #### Error: set_xdp_vars: No match"
    end    
    debug_puts "%%%%%%%%%%%%%%%%%%%% In set_xdp_vars %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    params.each_pair do |var,value|
        if /#{codec}v#{type}/.match(var.to_s)
        params_array.push(var.gsub("#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}"))
        end
    end
     params_array.sort!

    params_array.each do |elem|
        dut.send_cmd("cc xdp_var set #{elem.gsub(/_[0-9]+/, "")} #{i}",/OK/,2)
        i += 1
    end
end

def set_codec_cfg(dut,codec,res,type,template,var_type,dyn_iter,default_params = nil)
  i = 0
  puts "#{var_type} parameters for #{codec} #{res}"
  params_hash = Hash.new
  if(type == "dec_dyn")
    paramtype = "dyn" 
    codectype = "DEC"
    config = "dynamic"
  elsif (type == "dec_st")
    paramtype = "st" 
    codectype = "DEC"
    config = "static"
  elsif (type == "enc_st")
    paramtype = "st" 
    codectype = "ENC"
    config = "static"
  elsif (type == "enc_dyn")
    paramtype = "dyn" 
    codectype = "ENC"
    config = "dynamic"
  end    
  
  if(var_type == "test")
    @test_params.params_chan.instance_variables.each do |curr_var|
      if /#{codec}v#{type}/.match(curr_var)
        param_msb = curr_var.gsub("@#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")
        param_lsb = curr_var.gsub("@#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")
        param_msb << "_msb"
        param_lsb << "_lsb" 
        params_hash[param_lsb] = @test_params.params_chan.instance_variable_get(curr_var)[0].to_i & 0xffff
        params_hash[param_msb] = (@test_params.params_chan.instance_variable_get(curr_var)[0].to_i & 0xffff0000) >> 16
        # bit rate is the only test_param sent in HEX - EL: 06/15/09
        if(/bitrate/.match(curr_var))
          params_hash[param_lsb] = sprintf("0x%04x", params_hash[param_lsb])
          params_hash[param_msb] = sprintf("0x%04x", params_hash[param_msb])
        end
      end
      if((/#{codec}v_#{codectype.downcase}/).match(curr_var) && type == "enc_st")
        if(/#{codec}v_#{codectype.downcase}_ovly_type/).match(curr_var) 
          dut.send_cmd("dimt set template #{template} video video_ovly_cfg #{curr_var.gsub("@#{codec}v_enc_", "")} #{@test_params.params_chan.instance_variable_get(curr_var)}",/OK/,2) 
        else
          dut.send_cmd("dimt set template #{template} video video_mode #{curr_var.gsub("@#{codec}v_enc_", "")} #{@test_params.params_chan.instance_variable_get(curr_var)}",/OK/,2) 
        end
      end
    end
    if(@test_params.params_chan.instance_variable_defined?(:@enc_framerate) && dyn_iter < @test_params.params_chan.enc_framerate.length  && type == "enc_dyn")
      params_hash["#{codec.upcase}_ENC_tgtfrrate_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff
      params_hash["#{codec.upcase}_ENC_tgtfrrate_msb"] = (@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff0000) >> 16
      params_hash["#{codec.upcase}_ENC_intrafrint_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i/1000 & 0xffff
      params_hash["#{codec.upcase}_ENC_intrafrint_msb"] = ((@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i/1000) & 0xffff0000) >> 16
      params_hash["#{codec.upcase}_ENC_reffrrate_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff
      params_hash["#{codec.upcase}_ENC_reffrrate_msb"] = (@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff0000) >> 16
    end
    if(@test_params.params_chan.instance_variable_defined?(:@enc_bitrate) && dyn_iter < @test_params.params_chan.enc_bitrate.length && type == "enc_dyn")
      params_hash["#{codec.upcase}_ENC_tgtbitrate_lsb"] = sprintf("0x%04x", @test_params.params_chan.instance_variable_get("@enc_bitrate")[dyn_iter].to_i & 0xffff)
      params_hash["#{codec.upcase}_ENC_tgtbitrate_msb"] = sprintf("0x%04x", (@test_params.params_chan.instance_variable_get("@enc_bitrate")[dyn_iter].to_i & 0xffff0000) >> 16)
    end
    if(@test_params.params_chan.instance_variable_defined?(:@enc_bitrate) && type == "enc_st")
      params_hash["#{codec.upcase}_ENC_maxbitrate_lsb"] = sprintf("0x%04x", @test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff)
      params_hash["#{codec.upcase}_ENC_maxbitrate_msb"] = sprintf("0x%04x", (@test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff0000) >> 16)
    end

  else #default
    default_params.each_pair do |var,value|
      if /#{codec}v#{type}/.match(var)
        params_hash[var.gsub("#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")] = value
      end
    end
  end
  arr = Array.new
  arr = params_hash.sort
  arr.each do |elem|
  dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{elem[0].gsub(/_[0-9]+/, "")} #{elem[1]} ",/OK/,2)
  end
  if(var_type == "default")
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg num_words #{arr.length} ",/OK/,2)
  end

  if(res != nil ) 
    case res
      when "qcif"
        height = 144
        width = 176
      when "cif"
        height = 288
        width = 352
      when "d1ntsc"
        height = 480
        width = 720
      when "d1pal"
        height = 576
        width = 720
      else
        raise " #### Error :no recognized resolution"
    end
    case(type)
    when "dec_st" 
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxheight_lsb #{height} ",/OK/,2)
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxwidth_lsb #{width} ",/OK/,2)
      dut.send_cmd("dimt set template  #{template} video video_mode img_width #{width}",/OK/,2)
      dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,2)
      if(@multislice == 1 && codec == "h264bp")
          dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{codec.upcase}_#{codectype}_ipstrformat_lsb 1",/OK/,2)       
      end
    when "enc_st"
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxheight_lsb #{height} ",/OK/,2)
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxwidth_lsb #{width} ",/OK/,2)
      dut.send_cmd("dimt set template  #{template} video video_mode img_width #{width}",/OK/,2)
      dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,2)
    when "enc_dyn"
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_inputht_lsb #{height} ",/OK/,2)
      dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_inputwdth_lsb #{width} ",/OK/,2)
    end
  end    
end

def get_results(video_file)
	test_done_result = FrameworkConstants::Result[:pass]
	@results_html_file.add_paragraph("")
    test_comment = " "	
	res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
	
	@results_html_file.add_row_to_table(res_table, [["Scores #{File.basename(video_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
		# if @equipment['video_tester'].get_jnd_scores({'component' => 'y'}).max > pass_fail_criteria[1].to_f || @equipment['video_tester'].get_jnd_scores({'component' => 'chroma'}).max > pass_fail_criteria[1].to_f
			# test_done_result = FrameworkConstants::Result[:fail]
		# end
		@results_html_file.add_row_to_table(res_table,["AVG_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y'})])
		@results_html_file.add_row_to_table(res_table,["MIN_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma'})])
		@results_html_file.add_row_to_table(res_table,["MIN_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y'})])
		@results_html_file.add_row_to_table(res_table,["MIN_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb'})])
		@results_html_file.add_row_to_table(res_table,["MIN_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr'})])
		@results_html_file.add_row_to_table(res_table,["MIN_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr', 'type' => 'max'})])
	
	if test_done_result == FrameworkConstants::Result[:fail]
		test_comment = "Test failed for file "+File.basename(video_file)+"."
		file_ext = File.extname(video_file)
		failed_file_name = video_file.sub(/\..*$/,'_failed_'+Time.now.to_s.gsub(/[\s\-:]+/,'_')+file_ext)
		File.copy(video_file, failed_file_name)
		@results_html_file.add_paragraph(File.basename(failed_file_name),nil,nil,"//"+failed_file_name.gsub("\\","/"))
	end
	[test_done_result, test_comment]
end
def channel_reset(dut,tcid)
    debug_puts "#{tcid} : In channel_reset"
    dut.send_cmd("dimt close #{tcid} alloc",/OK/,2)
    dut.send_cmd("cc xdp_cli_set_state #{tcid} tx_disable rx_disable",/OK/,2)

end
def close_channel(dut,tcid) 
    debug_puts "#{tcid} : In close channel"
    dut.send_cmd("cc xdp_cli_unreg #{tcid}",/OK/,2)
    dut.send_cmd("cc disassoc #{tcid}",/OK/,2)
end

def print_stats(dut,tcid)
    dut.send_cmd("dimt req_stat #{tcid} alloc vppu vtk frc err yuv rtcp_to_pkt", /ACK DONE/, 10)
    puts dut.response
end

def debug_puts(message)
  if @show_debug_messages == true
    puts(message)
  end
end 

def remove_dir(dir)
  puts "Cleaning directory #{dir}"
  Dir.foreach(dir) do |f|
    if f == '.' or f == '..' then next
    else 
    FileUtils.remove_file("#{dir}#{f}")
    end
  end
end

def reset_template(dut,template)
  dut.send_cmd("dimt reset template #{template}", /OK/, 2)
end

def template_copy(dut,src_template,dest_template)
  dut.send_cmd("dimt reset template #{dest_template} ", /OK/, 2)
  dut.send_cmd("dimt copy #{src_template} #{dest_template} ", /OK/, 2)
end

def set_frc_mode(dut,encoder_template)
  if(@test_params.params_chan.instance_variable_defined?(:@frc_mode_track_ip) && @test_params.params_chan.instance_variable_get("@frc_mode_track_ip")[0].to_i == 1)
    dut.send_cmd("dimt set template #{encoder_template} video video_frc_cfg mode track_input ", /OK/, 2)
  elsif(@test_params.params_chan.instance_variable_defined?(:@frc_mode_rtp_ts) && @test_params.params_chan.instance_variable_get("@frc_mode_rtp_ts")[0].to_i == 1)
    dut.send_cmd("dimt set template #{encoder_template} video video_frc_cfg mode rtp_ts ", /OK/, 2)
  else
    dut.send_cmd("dimt set template #{encoder_template} video video_frc_cfg mode disable ", /OK/, 2)
  end

end

def get_pkt_to_pkt_delay(vppu_stats_file,capinfos_file,wFps)
 numFrames = 0
 numPkts = 0
 pkt_to_pkt_delay = -1
  begin
    cfg_file = File.open(vppu_stats_file,'r')
    cfg_file.each { |line|
    if(/rxNetFramesRecvd/.match(line))
      numFrames = line.match(/\d+/)[0].to_i
    elsif(/rxNetPkts/.match(line))
      numPkts = line.match(/\d+/)[0].to_i
    end
    }
    if (numFrames == 0)
      cfg_file = File.open(capinfos_file,'r')
      cfg_file.each { |line|
        if(/Number of packets/.match(line))
          numFrames = line.match(/\d+/)[0].to_i
        end
        }
    end
    pkt_to_pkt_delay = (numFrames*1000000)/wFps
    pkt_to_pkt_delay = pkt_to_pkt_delay/numPkts
    debug_puts "Frames: #{numFrames} Packets:#{numPkts} wire_fps: #{wFps}"
    debug_puts pkt_to_pkt_delay
    pkt_to_pkt_delay
  rescue
    puts "File IO failed"
    raise
  end
  
end
def clean
    remove_dir("#{INPUT_DIR}/out/")
    remove_dir("#{INPUT_DIR}/config/autogenerated/") 
    system("ccperl #{SCRIPT_EXTRACTOR}//script_extractor.pl #{@files_dir}//dut1_1_log.txt > #{@files_dir}//dut1_1_log_config_script.txt")
end

def cleanup_and_exit()
  test_done_result = FrameworkConstants::Result[:fail]
  test_comment = "No ACK DONE received from DSP, exiting"
  set_result(test_done_result,test_comment)
  clean()
end

def setup_boot(dut,ftp_server)
  # Boot DUT if app and dsp image was specified in the test parameters

  if (@test_params.instance_variable_defined?(:@dsp) and @test_params.instance_variable_defined?(:@app))
    puts "Tomahawk VGDK transcoding::setup_boot: dsp and app image specified. Proceeding to boot DUT"
    boot_params = {'dsp'=> @test_params.dsp, 'app' => @test_params.app}
    @new_keys = get_keys()
  else
    boot_params = nil
    @new_keys = nil
  end
  
  if boot_required?(@old_keys, @new_keys) # call bootscript if required
    boot(dut,ftp_server,boot_params)
  else
    puts "Tomahawk VGDK transcoding::setup_boot: Boot not required"
  end
end

private
def get_keys
  keys = @test_params.dsp.to_s + @test_params.app.to_s
  keys
end

def boot_required?(old_params, new_params)
  old_test_string = get_test_string(old_params)
  new_test_string = get_test_string(new_params)
  old_test_string != new_test_string
end

def get_test_string(params)
  test_string = ''
  if(params == nil)
    return nil
  end
  params.each {|element|
  test_string += element.strip
  }
  test_string
end
