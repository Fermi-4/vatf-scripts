# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require File.dirname(__FILE__)+'/../common/codec_params.rb'
require File.dirname(__FILE__)+'/../utils/eth_info.rb'
require File.dirname(__FILE__)+'/../utils/genPktHdrs'
require File.dirname(__FILE__)+'/../utils/genPktHdrsOverlay'
require File.dirname(__FILE__)+'/../utils/genSDP'
require File.dirname(__FILE__)+'/../utils/genCodecCfg'
include GenCodecCfg
include GenSDP
include GenPktHdrsOverlay
include GenPktHdrs
include CodecParams
include ETHInfo
require File.dirname(__FILE__)+'/../boot_scripts/boot.rb'
include BootScripts
VIDEO_TOOLS_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "..","utils")
INPUT_DIR = SiteInfo::VGDK_INPUT_CLIPS
OUTPUT_DIR = SiteInfo::VGDK_OUTPUT_CLIPS
MPLAYER_DIR = File.join(File.expand_path(File.dirname(__FILE__)),"..", "utils","MPlayer for Windows")
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
#attr :default_params
def setup
    dut = @equipment['dut1']
    dut.set_api("vgdk")
    server = defined?(@equipment['server1']) ? @equipment['server1'] : nil
    dut.connect({'type'=>'serial'})
    setup_boot(dut,server)
    dut.send_cmd("wait 10000", /OK/, 2)
    dut.send_cmd("cc ver", /OK/, 2)
    dut.send_cmd("dspi show", /OK/, 2)   
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

end

def run

    @show_debug_messages = false
    subjective = @test_params.params_chan.issubjectivereqd[0].to_i
    multislice = @test_params.params_chan.multislice[0].to_i
    test_case_id = @test_params.caseID
    num_frames = @test_params.params_chan.num_frames[0].to_i
    save_clips = @test_params.params_chan.saveclips[0].to_s
    move_and_freeze = @test_params.params_chan.move_and_freeze_g_ovly[0].to_i
    move = @test_params.params_chan.move_g_ovly[0].to_i
    relocate = @test_params.params_chan.relocate_g_ovly[0].to_i
    move_and_resume = @test_params.params_chan.move_and_resume_g_ovly[0].to_i
    timed_text = @test_params.params_chan.timed_text_t_ovly[0].to_i
    iteration = Time.now
    iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
    clip_iter = @test_params.params_chan.clip_iter[0].to_i
    dut = @equipment['dut1']
    @platform_info = Eth_info.new()
    @platform_info.init_eth_info(dut)
    template = 0
    clip_hash = Hash.new
    @test_params.params_chan.instance_variables.each do |curr_var|
        if /_clip/.match(curr_var)
            clip_hash[curr_var] = @test_params.params_chan.instance_variable_get(curr_var)[0]
        end
    end
    if @test_params.params_chan.instance_variable_defined?(:@wire_fps)
      wire_fps = @test_params.params_chan.wire_fps[0].to_i
    else
      wire_fps = 30
    end
    debug_puts "Close any channels that may be open"
    dut.send_cmd("dim tcids", /OK/, 2)
    tcids_state = dut.response
    tcids_state.each_line { |line|
    if(line.match(/[\d+\s+]{3}\d+\s\/\s+\d+\s+\w[Idle|Video|Exception]/i))
        tcid = line.match(/\d+/)[0]
        channel_reset(dut,tcid)
        close_channel(dut,tcid)
    end
    }
    test_done_result = nil
    test_comment = nil
    res_class_sent = false
    debug_puts clip_hash.keys


    codec_hash = Hash.new
    overlay_hash = Hash.new
    codec_template_hash = Hash.new

    g_ovly_conf_conn_template = 13
    codec_conf_conn_template = 15
    t_ovly_conf_conn_template = 17
    g_ovly_reloc_template = 19
    t_ovly_reloc_template = 21
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
        when "g_ovly"
            template = 28
            codec_template_hash.merge!(codec => template)
        when "t_ovly"
            template = 30
            codec_template_hash.merge!(codec => template)
        else
            raise " #### Error: Not a recognized codec #{codec.to_s}"
        end
    end
    end

    default_params = Hash.new
    codec_hash.each_key {|codec| default_params.merge!(initialize_codec_default_params(codec)) }
      
    #set ENC/DEC templates for this codec
    decoder_template = 0
    encoder_template = 0
    # Begin codec params configuration
       
    core = 0
    res = false
    tempc_info = CoreInfo::new()
    core_info_hash = Hash.new
    chan_params = @test_params.params_chan.chan_config

    (chan_params.length).times do |i| 
      params = chan_params[i].split
      chanCodec = params[0].to_s
      channels = params[1].to_i
      core_num = params[2].to_i
      resolution = params[3].to_s if params[3]
      if is_overlay?(chanCodec) #overlay channels
          dir = "dec"
          transcoded_to_codec = nil
          transcoded_from_codec = nil
          transized_from_res = nil
          resolution = nil 
          codec_type = "dec"
      else # regular codec channels
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
      end
      codec_hash[chanCodec].each{ |codec_info|
          if((codec_info.resolution == resolution && codec_info.codec_type == codec_type) || (is_overlay?(chanCodec) && codec_info.resolution == chanCodec))
              debug_puts "#{chanCodec} #{resolution} #{codec_type} exists in codec_hash"
              res = true
          end
          }
      if(res == false)
          if(resolution == nil) # For overlay resolution is overlay type
            debug_puts "Adding #{chanCodec}'s overlay type to codec_hash"
            codec_hash[chanCodec] << CodecInfo.new(codec_type,chanCodec,0,0)
          else            
            debug_puts "Adding #{chanCodec} #{resolution}  #{codec_type} to codec_hash"
            codec_hash[chanCodec] << CodecInfo.new(codec_type,resolution,0,0)
          end
      end
      if(core_info_hash.has_key?(core_num) == true)
          channels.times do 
              debug_puts "Adding #{chanCodec} #{resolution} #{codec_type} to core_info_hash"
              core_info_hash[core_num].append(ChannelInfo.new(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res))
          end
      else   
          tempc_info = CoreInfo::new() 
          channels.times do 
              tempc_info.append(ChannelInfo.new(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res))                    
          end
          core_info_hash.merge!(core_num => tempc_info)
      end
      res = false
    end

     (codec_hash).each_pair{|codec,res_arr| 
      res_arr.each { |res| 
       if ((res.resolution == "d1ntsc" || res.resolution == "d1pal") && res_class_sent == false)
         dut.send_cmd("dimt reset template 20",/OK/,2) 
         dut.send_cmd("dimt set template 20 dsp_glob_config video_sw_cfg res_class 2",/OK/,2) 
         dut.send_cmd("dimt dsp_glob_config 0 alloc 20",/ACK DONE/,2) 
         dut.send_cmd("wait 3000",/OK/,2) 
         res_class_sent = true
       end
     }
     }
     if (res_class_sent == false) 
      dut.send_cmd("dimt reset template 20",/OK/,2) 
      dut.send_cmd("dimt set template 20 dsp_glob_config video_sw_cfg res_class 1",/OK/,2) 
      dut.send_cmd("dimt dsp_glob_config 0 alloc 20",/ACK DONE/,2) 
      dut.send_cmd("wait 3000",/OK/,2) 
     end
    
    #CONF-CONNECT TEMPLATE

    reset_template(dut,codec_conf_conn_template)
    reset_template(dut,g_ovly_conf_conn_template)
    reset_template(dut,t_ovly_conf_conn_template)
    
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
        dut.send_cmd("dimt reset template #{decoder_template}",/OK/,2)
        if is_overlay?(codec) == false
          encoder_template = decoder_template + 2
          dut.send_cmd("dimt reset template #{encoder_template}",/OK/,2)
        end
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
        case(res.codec_type)
        when "dec"
          case(codec)   
          when /_ovly/
            # to send num_words = 0 for ovly
            set_codec_cfg(dut,codec,nil,multislice,"dec_st",decoder_template,"default",default_params)
            # to send img_height/width
            set_codec_cfg(dut,codec,res.resolution,multislice,"dec_st",decoder_template,"test",nil)
          else
            set_codec_cfg(dut,codec,nil,multislice,"dec_st",decoder_template,"default",default_params)
            set_codec_cfg(dut,codec,nil,multislice,"dec_dyn",decoder_template,"default",default_params)
            set_codec_cfg(dut,codec,res.resolution,multislice,"dec_st",decoder_template,"test",nil)
            set_codec_cfg(dut,codec,res.resolution,multislice,"dec_dyn",decoder_template,"test",nil)
          end
        when "enc"
          set_codec_cfg(dut,codec,nil,multislice,"enc_st",encoder_template,"default",default_params)
          set_codec_cfg(dut,codec,nil,multislice,"enc_dyn",encoder_template,"default",default_params)
          set_codec_cfg(dut,codec,res.resolution,multislice,"enc_st",encoder_template,"test",nil)
          set_codec_cfg(dut,codec,res.resolution,multislice,"enc_dyn",encoder_template,"test",nil)
        end
        
        tcid = 0
        core_info_hash.keys.sort.each { |key|
            core_info_hash[key].getLength().times { |i|
                if((core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type) || (core_info_hash[key][i].get_codec == codec && is_overlay?(core_info_hash[key][i].get_codec)))
                    dut.send_cmd("cc assoc #{tcid} #{key} #{i}", /OK/, 2) 
                    #cc assoc <tcid> <dsp> <chan>
                    dut.send_cmd("cc xdp_cli_reg #{tcid}", /OK/, 2) 
                    if(is_overlay?(core_info_hash[key][i].get_codec))
                      overlay_hash[tcid] = core_info_hash[key][i].get_codec
                    end
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
            if((core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type) || (core_info_hash[key][i].get_codec == codec && is_overlay?(core_info_hash[key][i].get_codec)))
                dut.send_cmd("dimt open #{tcid} alloc 11 chan encapcfg rtp txssrc #{ssrc} rxssrc #{ssrc}", /ACK DONE/, 2)
                dut.send_cmd("wait 40", /.*/, 2)
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
                    dut.send_cmd("dimt video_mode #{tcid} alloc #{decoder_template}", /ACK DONE/, 2)
                elsif(core_info_hash[key][i].get_dir == "enc")
                    dut.send_cmd("dimt video_mode #{tcid} alloc #{encoder_template}", /ACK DONE/, 2)
                end
                if(dut.timeout?)
                  cleanup_and_exit()
                  return
                end  
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
    while (chan_params[k]) != nil 
      if(is_overlay?((chan_params[k].split)[0]))
        while ((chan_params[k]) != nil  && is_overlay?((chan_params[k].split)[0]))
          debug_puts (chan_params[k].split)[0]
          i = (chan_params[k].split)[1].to_i
          m = k
          m -= 1
          enc_chan_num = chan-1
          while is_overlay?((chan_params[m].split)[0])
            enc_chan_num = chan-((chan_params[m].split)[1].to_i) - 1
            m -= 1
          end
          j = (chan_params[m].split)[1].to_i
          if(i != j && j != 1)
            raise " #### Error overlay channel config error ####"
          end
          (i).times do 
            if ((chan_params[k].split)[0] == "g_ovly")
              dut.send_cmd("dimt set template #{g_ovly_conf_conn_template} conn_req elem 0 req_type add ld_pkt_pkt src #{chan} dst #{enc_chan_num}", /OK/, 2)
              dut.send_cmd("dimt conn_req #{chan} alloc #{g_ovly_conf_conn_template}", /ACK DONE/, 2)
            else
              dut.send_cmd("dimt set template #{t_ovly_conf_conn_template} conn_req elem 0 req_type add ld_pkt_pkt src #{chan} dst #{enc_chan_num}", /OK/, 2)
              dut.send_cmd("dimt conn_req #{chan} alloc #{t_ovly_conf_conn_template}", /ACK DONE/, 2)      
            end
            if(dut.timeout?)
              cleanup_and_exit()
              return
            end  
            chan += 1
            enc_chan_num -= 1
          end
          k += 1
        end
      else
        i = (chan_params[k].split)[1].to_i 
        j = (chan_params[k+1].split)[1].to_i 
        if(i != j)
            raise " #### Error receive and send channel config error ####"
        end
        (i).times do 
          dut.send_cmd("dimt set template #{codec_conf_conn_template} conn_req elem 0 req_type add ld_pkt_pkt src #{chan} dst #{chan+i}", /OK/, 2)
          dut.send_cmd("dimt conn_req #{chan} alloc #{codec_conf_conn_template}", /ACK DONE/, 2)
          chan += 1
        end
        if(dut.timeout?)
          cleanup_and_exit()
          return
        end  
        k += 2
        chan += i 
      end        
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
                    if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && !is_overlay?(codec))
                        debug_puts "Generating pktHdrs.cfg"
                        case codec
                            when /h264/
                                file_ext_name = "264"
                            when "mpeg4"
                                file_ext_name = "m4v"
                            when "h263p"
                                file_ext_name = "263"
                            when "mpeg2"
                                file_ext_name = "m2v"
                        end
                        clip_hash.each_key { |clip|
                            puts "#{codec} #{clip} #{res.resolution} #{clip_hash[clip].to_s}"
                            if(/#{codec}_#{res.resolution}/.match(clip))
                                pkt_to_pkt_delay = -1
                                if ((multislice == 1 && !File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}.cap")) || (multislice == 0 && !File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}.cap")) )    
                                    raise "Error: ### Clip not found"
                                end
                                genCodecCfg(codec,res.resolution,test_case_id,clip_hash[clip].to_s,multislice) 
                                system("#{VIDEO_TOOLS_DIR}\\desktop_vppu.exe #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.cfg > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.txt")         
                                Dir.chdir("#{WIRESHARK_DIR}")
                                if(multislice == 1)
                                  system("capinfos.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}_rtpmarker.cap > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt")
                                else
                                  system("capinfos.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}_rtpmarker.cap > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt")
                                end
                                pkt_to_pkt_delay = get_pkt_to_pkt_delay("#{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.txt","#{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt",wire_fps)
                                genPktHdrs(codec,res.resolution,key,i,pc_udp_port,append,test_case_id,clip_hash[clip].to_s,multislice,pkt_to_pkt_delay,@platform_info) 
                                append = 1  
                            end
                            }
                        if(append == 0)
                            raise "Error: ### Clip not found in matrix"
                        end
                    elsif(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && is_overlay?(codec))
                        debug_puts "Generating pktHdrsOverlay.cfg"
                        clip_hash.each_key { |clip|
                                puts "#{codec} #{clip} #{res.resolution} #{clip_hash[clip].to_s}"
                                if(/#{codec}/.match(clip))
                                  if (!File.size("#{INPUT_DIR}\\in\\overlay\\#{codec}\\#{clip_hash[clip].to_s}.cap"))    
                                    raise "Error: ### Overlay clip not found"
                                  end
                                    genPktHdrsOverlay(codec,key,i,pc_udp_port,append,test_case_id,clip_hash[clip].to_s,multislice,@platform_info) 
                                    append = 1
                                 end
                        }   
                        if(append == 0)
                            raise "Error: ### Overlay Clip not found"
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
                    debug_puts "Generating SDP for #{core_info_hash[key][i].get_codec} #{core_info_hash[key][i].get_resolution} #{key} #{pc_udp_port}"
                    genSDP(core_info_hash[key][i].get_codec,core_info_hash[key][i].get_resolution,key,pc_udp_port,append,test_case_id,geom,multislice,iteration_id,c_iter,@platform_info)
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
        send_threads = []
        i = 0
        codec_hash.each_pair { |codec, res_arr|
            res_arr.each{|res|
                core_info_hash.keys.sort.each { |key|
                    core_info_hash[key].getLength().times { |i|
                        if(!is_overlay?(core_info_hash[key][i].get_codec) && core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && res.stream_sent == 0)
                            res.stream_sent = 1  
                            debug_puts "get_transcoded_to_codec :#{core_info_hash[key][i].get_transcoded_to_codec} codec: #{codec}"
                            transcoded_codec = core_info_hash[key][i].get_transcoded_to_codec
                            if(c_iter == 0)
                              system("#{VIDEO_TOOLS_DIR}/etherealUtil.exe #{INPUT_DIR}\\config\\change_headers_#{codec}_#{res.resolution}.cfg #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\pktHeaders_#{codec}_#{res.resolution}.cfg #{INPUT_DIR}\\config\\autogenerated\\auto_generated_ConfigFile_#{codec}_#{res.resolution}_Iter#{iteration_id}.cfg #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\delays_#{codec}_#{res.resolution}.cfg")
                            end
                        elsif(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && is_overlay?(codec))
                            if(c_iter == 0)
                              system("#{VIDEO_TOOLS_DIR}/etherealUtil.exe #{INPUT_DIR}\\config\\change_headers_#{codec}.cfg #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\pktHeaders_#{codec}.cfg #{INPUT_DIR}\\config\\autogenerated\\auto_generated_ConfigFile_#{codec}_Iter#{iteration_id}.cfg #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\delays_#{codec}.cfg")
                            end
                        end
                    }
                }
            }
        }
        if(c_iter == 0)
        system("ruby #{VIDEO_TOOLS_DIR}/genSendPkts.rb #{iteration_id}")
        end
        if(subjective == 1)
            codec_hash.each_pair { |codec, res_arr|
                res_arr.each{|res|
                    core_info_hash.keys.sort.each { |key|
                        core_info_hash[key].getLength().times { |i|
                        transcoded_codec = core_info_hash[key][i].get_transcoded_to_codec
                        if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && res.subjective_on == 0)
                            res.subjective_on = 1
			    system("start \"Mplayer\" cmd.exe \/c #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\#{transcoded_codec}_#{res.resolution}_subj_bat.bat")
                        end                        
                        }
                    }
                }
            }
        end
        send_threads << Thread.new() { system("#{VIDEO_TOOLS_DIR}/sendPackets.exe #{INPUT_DIR}\\config\\autogenerated\\auto_generated_ConfigFile_4sendPkts_Iter#{iteration_id}.cfg #{@platform_info.get_eth_dev} 1 s")    
        sleep(1)
        }
        send_threads << Thread.new() { overlay_hash.each_pair { |tcid, ovly_type| 
          if(ovly_type == "g_ovly")
            if (relocate == 1)
              debug_puts "Relocating graphic overlay"
              relocate_g_ovly(dut,tcid,g_ovly_reloc_template)
              sleep(2)
            end
            if (move_and_freeze == 1)
              debug_puts "Move and freeze graphic overlay"
              move_and_freeze_g_ovly(dut,tcid,g_ovly_reloc_template)  
              sleep(5) # longer sleep to notice the freeze
            end
            if(move_and_resume == 1)
              debug_puts "Move and resume graphic overlay"
              move_and_resume_g_ovly(dut,tcid,g_ovly_reloc_template) 
              sleep(2)
            end
            if(move == 1)
              debug_puts "Move graphic overlay"
              move_g_ovly(dut,tcid,g_ovly_reloc_template) 
              sleep(2)
            end
          else
            if(timed_text == 1)
              debug_puts "Timed text overlay"
              timed_text_t_ovly(dut,tcid,t_ovly_reloc_template)  
              sleep(2)      
            end
          end
        }
        }
        priority = 1 # main process has priority 0
        send_threads.each { |aThread|  
        aThread.priority = priority
        priority += 1
        }
        send_threads.each { |aThread|  aThread.join }  
        if(dut.timeout?)
          cleanup_and_exit()
          return
        end        
        codec_hash.each_pair { |codec, res_arr| res_arr.each{|res| res.stream_sent = 0} }     
        system("taskkill /F /IM tshark.exe")
        system("taskkill /FI \"IMAGENAME eq mplayer.exe\"")
	system("taskkill /FI \"WINDOWTITLE eq Mplayer\"")
    }

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
                        system("#{VIDEO_TOOLS_DIR}\\desktop_vppu.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\Iter#{iteration_id}\\#{codec}_#{res.resolution}\\clipIter#{c_iter}\\#{pc_udp_port}_codec_dump.cfg")         
                        if File.size?("#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name}")
                        else
                          test_done_result = FrameworkConstants::Result[:fail]
                          test_comment = "Test completed: No transcoding. Output clips directory #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}"
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
    tcids_state.each_line { |line|
    if(line.match(/Exception/i))
        test_done_result = FrameworkConstants::Result[:fail]
        test_comment = "Test completed: Channel Exception. Output clips directory #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}"
        set_result(test_done_result,test_comment)
   elsif(line.match(/[\d+\s+]{3}\d+\s\/\s+\d+\s+\w[Idle|Video]/i))
        tcid = line.match(/\d+/)[0]
        channel_reset(dut,tcid)
    end
    }
    tcid = 0
    core_info_hash.keys.sort.each { |key|
    core_info_hash[key].getLength().times {
        close_channel(dut,tcid)
        tcid += 1
        }
    }
    
    if (save_clips == "false")
        clip_iter.times { |c_iter| 
        if(c_iter > 0)
          FileUtils.remove_dir("#{OUTPUT_DIR}\\TC#{test_case_id}\\clipIter#{c_iter}") if File.directory?"#{OUTPUT_DIR}\\clipIter#{c_iter}"
        end
        }
    end
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
        puts " #### Error: set_xdp_vars: No match"
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


def set_codec_cfg(dut,codec,res,multislice,type,template,var_type,default_params = nil)
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
        param_msb = curr_var.to_s.gsub("@#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")
        param_lsb = curr_var.to_s.gsub("@#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")
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
          dut.send_cmd("dimt set template #{template} video video_ovly_cfg #{curr_var.to_s.gsub("@#{codec}v_enc_", "")} #{@test_params.params_chan.instance_variable_get(curr_var)[0]}",/OK/,2) 
        else
          dut.send_cmd("dimt set template #{template} video video_mode #{curr_var.to_s.gsub("@#{codec}v_enc_", "")} #{@test_params.params_chan.instance_variable_get(curr_var)[0]}",/OK/,2) 
        end
      end
    end
    if(@test_params.params_chan.instance_variable_defined?("@enc_framerate") && type == "enc_dyn")
        params_hash["#{codec.upcase}_ENC_tgtfrrate_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff
        params_hash["#{codec.upcase}_ENC_tgtfrrate_msb"] = (@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff0000) >> 16
    end
    if(@test_params.params_chan.instance_variable_defined?("@enc_bitrate") && type == "enc_dyn")
        params_hash["#{codec.upcase}_ENC_tgtbitrate_lsb"] = sprintf("0x%04x", @test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff)
        params_hash["#{codec.upcase}_ENC_tgtbitrate_msb"] = sprintf("0x%04x", (@test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff0000) >> 16)
    end
    if(@test_params.params_chan.instance_variable_defined?("@enc_bitrate") && type == "enc_st")
        params_hash["#{codec.upcase}_ENC_maxbitrate_lsb"] = sprintf("0x%04x", @test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff)
        params_hash["#{codec.upcase}_ENC_maxbitrate_msb"] = sprintf("0x%04x", (@test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff0000) >> 16)
    end
  else #default
    default_params.each_pair do |var,value|
    if /#{codec}v#{type}/.match(var)
    params_hash[var.to_s.gsub("#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")] = value
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
  if(res != nil) 
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
      when "g_ovly"
        height = 48
        width = 64
      when "t_ovly"
        height = 12
        width = 112
      else
        puts " #### Error :no recognized resolution"
    end
    debug_puts "type: #{type} res: #{res}"
    case(type)
    when "dec_st" 
      if(is_overlay?(res))
        dut.send_cmd("dimt set template #{template} video video_mode img_width #{width}",/OK/,2)
        dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,2)
      else
        dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxheight_lsb #{height} ",/OK/,2)
        dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxwidth_lsb #{width} ",/OK/,2)
        dut.send_cmd("dimt set template  #{template} video video_mode img_width #{width}",/OK/,2)
        dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,2)
        if(multislice == 1 && codec == "h264bp")
          dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{codec.upcase}_#{codectype}_ipstrformat_lsb 1",/OK/,2)       
        end
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
	dut.send_cmd("cc xdp_cli_set_state #{tcid} tx_disable rx_disable",/OK/,2)
    dut.send_cmd("dimt close #{tcid} alloc",/OK/,2)


end
def close_channel(dut,tcid) 
    debug_puts "#{tcid} : In close channel"
    dut.send_cmd("cc xdp_cli_unreg #{tcid}",/OK/,2)
    dut.send_cmd("cc disassoc #{tcid}",/OK/,2)
end

def print_stats(dut,tcid)
    dut.send_cmd("dimt req_stat #{tcid} alloc vppu vtk frc err yuv rtcp_to_pkt", /ACK DONE/, 2)
    puts dut.response
end

def debug_puts(message)
  if @show_debug_messages == true
    puts(message)
  end
end 

def is_overlay?(codec)
  if(codec == "g_ovly" || codec == "t_ovly")
    return true
  else
    return false
  end
end

def reset_template(dut,template)
    dut.send_cmd("dimt reset template #{template}", /OK/, 2)
    dut.send_cmd("dimt set template #{template} conn_req nelem 1", /OK/, 2)
end

def relocate_g_ovly(dut,tcid,template)
    dut.send_cmd("dimt reset template #{template}", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg x_offset 2048", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg y_offset 2048", /OK/, 2)
    dut.send_cmd("dimt video_config #{tcid} alloc #{template}", /ACK DONE/, 2)
end

def move_and_freeze_g_ovly(dut,tcid,template)
    dut.send_cmd("dimt reset template #{template}", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg x_offset 24576", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg y_offset 4096", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg ctrl_code_bitmap stop", /OK/, 2)
    dut.send_cmd("dimt video_config #{tcid} alloc #{template}", /ACK DONE/, 2)
end
def move_and_resume_g_ovly(dut,tcid,template)
    dut.send_cmd("dimt reset template #{template}", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg x_offset 24576", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg y_offset 4096", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg ctrl_code_bitmap resume", /OK/, 2)
    dut.send_cmd("dimt video_config #{tcid} alloc #{template}", /ACK DONE/, 2)
end

def move_g_ovly(dut,tcid,template)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg x_offset 24576", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg y_offset 24576", /OK/, 2)
    dut.send_cmd("dimt video_config #{tcid} alloc #{template}", /ACK DONE/, 2)
end

def timed_text_t_ovly(dut,tcid,template)
    dut.send_cmd("dimt reset template #{template}", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg x_offset 256", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg y_offset 30720", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg yuv_fg_msw 0x00d0", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg yuv_fg_lsw 0x6040", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg yuv_bg_msw 0x0080", /OK/, 2)
    dut.send_cmd("dimt set template #{template} video video_ovly_cfg yuv_bg_lsw 0x6040", /OK/, 2)
    dut.send_cmd("dimt video_config #{tcid} alloc #{template}", /ACK DONE/, 2)
end

def remove_dir(dir)
    puts "Cleaning directory #{dir}"
    Dir.foreach(dir) do |f|
      if f == '.' or f == '..' then next
      else FileUtils.remove_file("#{dir}#{f}")
      end
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
    system("taskkill /F /IM tshark.exe")
    system("taskkill /FI \"IMAGENAME eq mplayer.exe\"")
    remove_dir("#{INPUT_DIR}/out/")
    remove_dir("#{INPUT_DIR}/config/autogenerated/") 
    system("ccperl #{SCRIPT_EXTRACTOR}//script_extractor.pl #{@files_dir}//dut1_1_log.txt > #{@files_dir}//dut1_1_log_config_script.txt")
    system("taskkill /F /IM \"tshark.exe\"")
    system("taskkill /FI \"IMAGENAME eq mplayer.exe\"")
    system("taskkill /FI \"WINDOWTITLE eq Mplayer\"")
end

def cleanup_and_exit()
  test_done_result = FrameworkConstants::Result[:fail]
  test_comment = "No ACK DONE received from DSP, exiting"
  set_result(test_done_result,test_comment)
  system("taskkill /F /IM \"tshark.exe\"")
  system("taskkill /FI \"IMAGENAME eq mplayer.exe\"")
  system("taskkill /FI \"WINDOWTITLE eq Mplayer\"")
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
    puts "Tomahawk VGDK transcoding::setup_boot: skip booting process"
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
  params.each_line {|element|
  test_string += element.strip
  }
  test_string
end