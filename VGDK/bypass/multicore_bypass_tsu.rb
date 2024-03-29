# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require File.dirname(__FILE__)+'/../common/codec_params.rb'
require File.dirname(__FILE__)+'/../utils/eth_info.rb'
require File.dirname(__FILE__)+'/../boot_scripts/boot.rb'
require File.dirname(__FILE__)+'/../utils/genPktHdrs'
require File.dirname(__FILE__)+'/../utils/genSDP'
require File.dirname(__FILE__)+'/../utils/genCodecCfg'
require File.dirname(__FILE__)+'/../utils/profileMips'
include ProfileMips
include GenCodecCfg
include GenSDP
include GenPktHdrs
include BootScripts
include CodecParams
include ETHInfo
INPUT_DIR = SiteInfo::VGDK_INPUT_CLIPS
OUTPUT_DIR = SiteInfo::VGDK_OUTPUT_CLIPS
MPLAYER_DIR = File.join(File.expand_path(File.dirname(__FILE__)),"..","utils","MPlayer for Windows")
VIDEO_TOOLS_DIR = File.join(File.expand_path(File.dirname(__FILE__)),"..","utils")
WIRESHARK_DIR = ("C:/Program Files/Wireshark")
SCRIPT_EXTRACTOR = SiteInfo::VGDK_INPUT_CLIPS


class ChannelInfo
    def initialize(codec,dir,resolution,out_codec,in_codec,in_resolution,is_master,template)
        @in_codec = codec
        @dir = dir # 0 => stream from PC to THK; 1 => stream from THK to PC 
        @resolution = resolution
        @transcoded_to_codec = out_codec # This field is valid ONLY when dir = 0
        @transcoded_from_codec = in_codec # This field is valid ONLY when dir = 1
        @transized_from_resolution = in_resolution # This field is valid ONLY when dir = 1
        @is_master = is_master
        @template = template
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
    def is_master()
    @is_master
    end
    def get_template()
    @template
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
# chan since in HD case there is only one master Dec core and one master ENC core
CodecInfo = Struct.new(:codec_type, :resolution, :stream_sent, :subjective_on, :core) 
#attr :default_params
def setup
    @show_debug_messages = true
    dut = @equipment['dut1']
    dut.set_api("vgdk")
    server = defined?(@equipment['server1']) ? @equipment['server1'] : nil
    setup_boot(dut,server,@power_handler)
    dut.send_cmd("wait 10000", /OK/, 10)
    dut.send_cmd("cc ver", /OK/, 10)
    dut.send_cmd("dspi show", /OK/, 10)
    # dut.send_cmd("spy dim 2", /OK/, 10)   
    dut.send_cmd("dimt reset template 11",/OK/,10)
    dut.send_cmd("dimt set template 11 chan chan_state t2pmask app user alarm tone cas",/OK/,10)
    dut.send_cmd("dimt set template 11 chan chan_state t2pval app user alarm tone cas",/OK/,10)
    dut.send_cmd("dimt set template 11 chan chan_state p2tmask app user alarm tone cas",/OK/,10)
    dut.send_cmd("dimt set template 11 chan chan_state p2tval app user alarm tone cas",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg encapsulation rtp",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp txssrc 0xabababab",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp tx_start_timestamp 0xbcbcbcbc",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp rxssrc 0xabababab",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp rx_start_timestamp 0xbcbcbcbc",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp rxssrc_ctrl drop",/OK/,10)
    dut.send_cmd("dimt set template 11 chan encapcfg rtp txfo 0x00",/OK/,10)
    dut.send_cmd("wait 10", /OK/, 10)

end


def run
    @show_debug_messages = false
    @perfData = []
    dut = @equipment['dut1']
    @platform_info = Eth_info.new()
    @platform_info.init_eth_info(dut)
    subjective = 0
    if(@test_params.params_chan.instance_variable_defined?("@issubjectivereqd"))    
      subjective = @test_params.params_chan.issubjectivereqd[0].to_i
    end
    multislice = 0
    if(@test_params.params_chan.instance_variable_defined?("@multislice"))    
      multislice = @test_params.params_chan.multislice[0].to_i
    end
    profilemips = nil
    if(@test_params.params_chan.instance_variable_defined?("@profilemips"))    
      profilemips = @test_params.params_chan.profilemips[0].split(":")
    end
    video_clarity = 0
    if(@test_params.params_chan.instance_variable_defined?("@video_clarity"))
      video_clarity = @test_params.params_chan.video_clarity[0].to_i
      num_frames = @test_params.params_chan.num_frames[0].to_i
    end
    if @test_params.params_chan.instance_variable_defined?(:@wire_fps)
      wire_fps = @test_params.params_chan.wire_fps[0].to_i
    else
      wire_fps = 30
    end
    iteration = Time.now
    iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
    test_case_id = @test_params.caseID
    save_clips = @test_params.params_chan.saveclips[0].to_s
    template = 0
    clip_hash = Hash.new
    @test_params.params_chan.instance_variables.each do |curr_var|
      if /_clip/.match(curr_var)
          clip_hash[curr_var] = @test_params.params_chan.instance_variable_get(curr_var)[0]
      end
    end

    
    debug_puts "Close any channels that may be open"
    dut.send_cmd("dim tcids", /OK/, 10)
    tcids_state = dut.response
    tcids_state.each_line { |line|
    if(line.match(/[\d+\s+]{3}\d+\s\/\s+\d+\s+\w[Idle|Video|Exception]/i))
        tcid = line.match(/\d+/)[0]
        channel_reset(dut,tcid)
        close_channel(dut,tcid)
    end
    }

    test_done_result = nil
    test_comment = ''
    res_class_sent = false
    clip_iter = @test_params.params_chan.clip_iter[0].to_i
    codec_hash = Hash.new
    codec_template_hash = Hash.new
    chan_params = @test_params.params_chan.chan_config
    (chan_params.length).times do |i|
    codec = (chan_params[i].split)[0]
    if(codec.to_s == "yuv")
        if(i%2 == 0)
            codec = "yuv_#{(chan_params[i+1].split)[0]}"
        else
            codec = "yuv_#{(chan_params[i-1].split)[0]}"
        end
    end
    if((codec_hash).has_key?(codec.to_s) != true)
        codec_hash.merge!(codec.to_s => [])
        case(codec.to_s)
        when "h264bp"
            template = 16
            codec_template_hash.merge!(codec => template)
        when "mpeg4"
            template = 20
            codec_template_hash.merge!(codec => template)
        when "mpeg2"
            template = 24
            codec_template_hash.merge!(codec => template)
        when "h263p"
            template = 28
            codec_template_hash.merge!(codec => template)
        when "h264mp"
            template = 32
            codec_template_hash.merge!(codec => template)
        when "h264hp"
            template = 36
            codec_template_hash.merge!(codec => template)
        when "tsu"
            template = 40
            codec_template_hash.merge!(codec => template)
        when "yuv_h264bp"
            template = 44
            codec_template_hash.merge!(codec => template)
        when "yuv_mpeg4"
            template = 48
            codec_template_hash.merge!(codec => template)
        when "yuv_h263p"
            template = 52
            codec_template_hash.merge!(codec => template)
        when "yuv_h264mp"
            template = 56
            codec_template_hash.merge!(codec => template)
        when "yuv_mpeg2"
            template = 60
            codec_template_hash.merge!(codec => template)
        when "yuv_h264hp"
            template = 64
            codec_template_hash.merge!(codec => template)
        else
            raise " #### Error: #{codec.to_s} is not a recognized codec #### "
        end
    end
    end
    default_params = Hash.new
    codec_hash.each_key{|codec| default_params.merge!(initialize_codec_default_params(codec))}
      
      
    core = 0
    res = false
    core_info_hash = Hash.new
    chan_params = @test_params.params_chan.chan_config
    decoder_template = 0
    encoder_template = 0
    master_enc_template = []
    master_dec_template = []

    (chan_params.length).times do |i| 
      params = chan_params[i].split
      chanCodec = params[0].to_s
      channels = params[1].to_i
      core_num = params[2].to_i
      resolution = params[3].to_s
      if(chanCodec.to_s == "yuv")
          if(i%2 == 0)
              chanCodec = "yuv_#{(chan_params[i+1].split)[0]}"
          else
              chanCodec = "yuv_#{(chan_params[i-1].split)[0]}"
          end
      end
      # Once both have been set it means anymore channels are for the same enc/dec - restriction for multicore case only
      if (decoder_template == 0)
        decoder_template = codec_template_hash[chanCodec]      
        master_dec_template << decoder_template
      elsif (encoder_template == 0)
        encoder_template = decoder_template + 2
        master_enc_template << encoder_template
      end
      if is_tsu?(chanCodec) #overlay channels
          dir = "enc" # This could arguably be an enc or dec
          transcoded_to_codec = nil
          transcoded_from_codec = nil
          transized_from_res = (chan_params[i-2].split)[3]
          resolution = (chan_params[i-1].split)[3]
          codec_type = "enc"
          template = codec_template_hash[chanCodec] + 2
      else # regular codec channels
        if(i%2 == 0)
          dir = "dec" #incoming stream to THK
          transcoded_to_codec = (chan_params[i+1].split)[0]
          transcoded_to_codec.gsub!("yuv","yuv_#{chanCodec}")
          transcoded_from_codec = nil
          transized_from_res = nil
          codec_type = "dec"
          if(decoder_template != 0 and master_dec_template.include?(codec_template_hash[chanCodec])) 
            template = decoder_template 
          else
            template = codec_template_hash[chanCodec]
            master_dec_template << template
          end
        else
          dir = "enc"
          transcoded_to_codec = nil
          transcoded_from_codec = (chan_params[i-1].split)[0]
          transcoded_from_codec.gsub!("yuv","yuv_#{chanCodec}")
          transized_from_res = (chan_params[i-1].split)[3]
          transized_to_res = (chan_params[i].split)[3]
          if (transized_from_res == transized_to_res)
            tsu = true
          end
          codec_type = "enc"
          if((encoder_template != 0) and master_enc_template.include?(codec_template_hash[chanCodec]+2))
            template =  encoder_template 
          else
            template = codec_template_hash[chanCodec]+2
            master_enc_template << template
          end
        end
      end
      codec_hash[chanCodec].each{ |codec_info|
          if(codec_info.codec_type == codec_type && codec_info.resolution == resolution)
              res = true
          end
          }
      if(res == false)
          debug_puts "Adding #{chanCodec} #{codec_type} #{resolution} to codec_hash"
          codec_hash[chanCodec] << CodecInfo.new(codec_type,resolution,0,0,core_num)
      end
      if(core_info_hash.has_key?(core_num) == true)
        channels.times do 
          debug_puts "Adding #{chanCodec} #{resolution} to core_info_hash"
          core_info_hash[core_num].append(ChannelInfo.new(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,template))
          template += 1
        end
      else  # This will always be the case for HD 
          master_tempc_info = CoreInfo::new() 
          #For HD case 'channels' is always 1
          if (! is_tsu?(chanCodec))
            channels.times do 
                core_info_hash.merge!(core_num => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,1,template))
            end
          else
              core_info_hash.merge!(core_num => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template))   
          end
          if (! is_tsu?(chanCodec))
            # 1080p decoder needs two cores
            if (resolution == "1080p" and dir == "dec")
              core_info_hash.merge!(core_num+1 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              decoder_template = template + 1
              # 1080p encoder needs six cores
            elsif (resolution == "1080p" and dir == "enc")
              template += 1  
              core_info_hash.merge!(core_num+1 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template))
              template += 1              
              core_info_hash.merge!(core_num+2 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              template += 1 
              core_info_hash.merge!(core_num+3 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              template += 1 
              core_info_hash.merge!(core_num+4 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              template += 1 
              core_info_hash.merge!(core_num+5 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              encoder_template = template + 1
            elsif (resolution == "720p" and dir == "enc")
              template += 1  
              core_info_hash.merge!(core_num+1 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              template += 1 
              core_info_hash.merge!(core_num+2 => create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,0,template)) 
              encoder_template = template + 1
            end
          end
      end
      res = false
    end

     dut.send_cmd("dimt reset template 20",/OK/,10) 
     dut.send_cmd("dimt set template 20 dsp_glob_config video_sw_cfg res_class 3",/OK/,10) 
     dut.send_cmd("dimt dsp_glob_config 0 alloc 20",/ACK DONE/,10) 
     dut.send_cmd("wait 3000",/OK/,10) 
     
    (codec_hash).each_pair{|codec,res_arr|
      res_arr.each { |res|
        if((/yuv_/).match(codec)  != nil)
            codec_name = "yuv"
        else 
            codec_name = codec
        end
        if(codec_name != "yuv")
          if(res.codec_type == "dec")
            set_xdp_vars(dut,codec,"dec_dyn",default_params)
            set_xdp_vars(dut,codec,"dec_st",default_params)
          elsif (res.codec_type == "enc")
            set_xdp_vars(dut,codec,"enc_dyn",default_params)
            set_xdp_vars(dut,codec,"enc_st",default_params)
          end
        end
        decoder_template = codec_template_hash[codec]
        encoder_template = decoder_template + 2
        
        dut.send_cmd("dimt reset template #{decoder_template}",/OK/,10)
        dut.send_cmd("dimt reset template #{encoder_template}",/OK/,10)
        
        if (res.codec_type == "enc")
          default_params.each_pair do |var,value|
          if(/#{codec_name}v_enc/).match(var) 
              if(/#{codec_name}v_enc_ovly_type/).match(var) 
              debug_puts "setting default params for #{codec_name}"
              dut.send_cmd("dimt set template #{encoder_template} video video_ovly_cfg #{var.gsub("#{codec_name}v_enc_", "")} #{value}",/OK/,10) 
              else
              dut.send_cmd("dimt set template #{encoder_template} video video_mode #{var.gsub("#{codec_name}v_enc_", "")} #{value}",/OK/,10) 
              end
          end
          end
        
        elsif(res.codec_type == "dec")
          default_params.each_pair do |var,value|
          if(/#{codec_name}v_dec/).match(var)
              dut.send_cmd("dimt set template #{decoder_template} video video_mode #{var.gsub("#{codec_name}v_dec_", "")} #{value}",/OK/,10) 
          end
          end
        end
        case res.codec_type
        when "dec"
          case(codec_name)          
          when "yuv"
            # to send num_words = 0 for yuv
            set_codec_cfg(dut,codec_name,nil,multislice,"dec_st",decoder_template,"default",default_params,res.core)
            # to send img_height/width
            set_codec_cfg(dut,codec_name,res.resolution,multislice,"dec_st",decoder_template,"test",nil,res.core)
          else
            set_codec_cfg(dut,codec_name,nil,multislice,"dec_st",decoder_template,"default",default_params,res.core)
            set_codec_cfg(dut,codec_name,nil,multislice,"dec_dyn",decoder_template,"default",default_params,res.core)
            set_codec_cfg(dut,codec_name,res.resolution,multislice,"dec_st",decoder_template,"test",nil,res.core)
            set_codec_cfg(dut,codec_name,res.resolution,multislice,"dec_dyn",decoder_template,"test",nil,res.core)
          end
        when "enc"
          case(codec_name)
          when "yuv"
            set_codec_cfg(dut,codec_name,res.resolution,multislice,"enc_st",encoder_template,"test",nil,res.core)
            set_codec_cfg(dut,codec_name,nil,multislice,"enc_st",encoder_template,"default",default_params,res.core)
          else
            set_codec_cfg(dut,codec_name,nil,multislice,"enc_st",encoder_template,"default",default_params,res.core)
            set_codec_cfg(dut,codec_name,nil,multislice,"enc_dyn",encoder_template,"default",default_params,res.core)
            set_codec_cfg(dut,codec_name,res.resolution,multislice,"enc_st",encoder_template,"test",nil,res.core)
            set_codec_cfg(dut,codec_name,res.resolution,multislice,"enc_dyn",encoder_template,"test",nil,res.core)
          end
        end
        
             src_core = nil
        src_template = 0
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type)
               if(core_info_hash[key][i].is_master == 1 && core_info_hash[key][i].get_dir == "enc")
                  if (core_info_hash[key][i].get_resolution == "1080p" || core_info_hash[key][i].get_resolution == "720p")
                    if(src_core == nil)
                      src_template = core_info_hash[key][i].get_template
                      src_core = key
                      puts "##### Now saving template #{src_template} of core #{key}"
                    else
                      dst_template = core_info_hash[key][i].get_template
                      puts "##### Now setting template #{dst_template} to #{src_template} of core #{key}"
                      set_mc_template(dut,src_template,dst_template)
                    end
                  end
                end
            end
          }
        }
         core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type)
               if(core_info_hash[key][i].is_master == 1 && core_info_hash[key][i].get_dir == "enc")
                  encoder_template = core_info_hash[key][i].get_template
                  if core_info_hash[key][i].get_resolution == "1080p"
                    set_core_teams(dut,encoder_template,6,key)
                  elsif core_info_hash[key][i].get_resolution == "720p"
                    set_core_teams(dut,encoder_template,3,key)
                  end
            elsif (core_info_hash[key][i].is_master == 1 && core_info_hash[key][i].get_dir == "dec")
                  decoder_template = core_info_hash[key][i].get_template
                  if core_info_hash[key][i].get_resolution == "1080p"
                    set_core_teams(dut,decoder_template,2,key)
                  end
                end
            end
          }
        }
        
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type)
               if(core_info_hash[key][i].is_master == 1 && core_info_hash[key][i].get_dir == "enc")
                  encoder_template = core_info_hash[key][i].get_template
                  if (core_info_hash[key][i].get_resolution == "1080p" || core_info_hash[key][i].get_resolution == "720p")
                    set_mc_enc(dut,encoder_template,res.resolution,codec)
                  end
                end
            end
          }
        }
        
        tcid = 0
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|
            if(core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && core_info_hash[key][i].get_dir == res.codec_type)
              dut.send_cmd("cc assoc #{tcid} #{key} #{i}", /OK/, 10) 
              #cc assoc <tcid> <dsp> <chan>
              dut.send_cmd("cc xdp_cli_reg #{tcid}", /OK/, 10) 
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
            dut.send_cmd("wait 40", //, 10)
            dut.send_cmd("cc xdp_cli_set_prot #{tcid} ether ipv4 udp", /OK/, 10)
            dut.send_cmd("cc xdp_set #{tcid} phy phy_id 24", /OK/, 10) 
            dut.send_cmd("cc xdp_set #{tcid} phy dsp_dev_iface 2", /OK/, 10) 
            dut.send_cmd("cc xdp_set #{tcid} phy dsp_port_id 0", /OK/, 10)
            dut.send_cmd("cc xdp_set #{tcid} ether loc_addr dspMacVoiceSrc#{key}_0", /OK/, 10) 
            dut.send_cmd("cc xdp_set #{tcid} ether rem_addr dspMacVoiceTgt#{key}_0", /OK/, 10)
            dut.send_cmd("cc xdp_set #{tcid} ipv4 loc_addr dspIpVoiceSrc#{key}_0", /OK/, 10) 
            dut.send_cmd("cc xdp_set #{tcid} ipv4 rem_addr dspIpVoiceTgt#{key}_0", /OK/, 10)  
            dut.send_cmd("cc xdp_set #{tcid} udp loc_port #{loc_port}", /OK/, 10) 
            dut.send_cmd("cc xdp_set #{tcid} udp rem_port #{rem_port}", /OK/, 10) 
            dut.send_cmd("cc xdp_cli_set_state #{tcid} tx_enable rx_enable", /OK/, 10)
            dut.send_cmd("wait 40", //, 10)
            dut.send_cmd("cc rtcp_ctrl #{tcid} 1000 0x1F 0x1234567 0x89abcdef 5 0 1 2", /OK/, 10) 
            dut.send_cmd("cc rtcp_chan_sdes #{tcid} 1 0x1 gw1tcid0", /OK/, 10) 
         
          end
          ssrc += 1
          loc_port += 2
          rem_port += 2
          tcid += 1
          }
          loc_port = 32768
        }
        dut.send_cmd("wait 10", /OK/, 10)   
      }
    }
    
      tcid = 0
    core_info_hash.keys.sort.each { |key|
    core_info_hash[key].getLength().times { |i|
        puts "core id: #{key} i:#{i}"
        if(core_info_hash[key][i].get_dir == "dec") 
            dut.send_cmd("dimt video_mode #{tcid} alloc #{core_info_hash[key][i].get_template}", /OK/, 10)
        end
     tcid += 1
    }
    }
  #  dut.wait_for(/(?:ACK\sDONE)/,60)
    if(dut.timeout?)
      cleanup_and_exit()
      return
    end  
    
    tcid = 0
    enc_cores = 0
    core_info_hash.keys.sort.each { |key|
    core_info_hash[key].getLength().times { |i|
        puts "core id: #{key} i:#{i}"
        if(core_info_hash[key][i].get_dir == "enc")
          if (core_info_hash[key][i].is_master == 1)
            puts "$$$$$$$$$$$$$ Wait here $$$$$$$$$$$$$$$$"
            sleep 10
            dut.send_cmd("dimt video_mode #{tcid} alloc  #{core_info_hash[key][i].get_template}", /OK/, 10)
          elsif (is_tsu?(core_info_hash[key][i].get_codec))
            dut.send_cmd("dimt video_mode #{tcid} alloc  #{core_info_hash[key][i].get_template}", /OK/, 10)
            puts "$$$$$$$$$$$$$ Wait here $$$$$$$$$$$$$$$$"
            sleep 10
          else
            dut.send_cmd("dimt video_mode #{tcid} alloc  #{core_info_hash[key][i].get_template}", /OK/, 10)
          end
        end
        tcid += 1
        }
    }
    sleep 120
    # dut.wait_for(/(?:ACK\sDONE)/,60)
    if(dut.timeout?)
      cleanup_and_exit()
      return
    end 
    
    #CONF-CONNECT TEMPLATE
    dut.send_cmd("dimt reset template 15", /OK/, 10)
    dut.send_cmd("dimt set template 15 conn_req nelem 1", /OK/, 10)

    k = 0
    i = 1
    chan = 0

    dec_res = (chan_params[k].split)[3]
    enc_res = (chan_params[k+1].split)[3]

    
    if (dec_res == "1080p")
      i = 2
    end
    dut.send_cmd("dimt set template 15 conn_req elem 0 req_type add ld_pkt_pkt src #{chan} dst #{chan+i}", /OK/, 10)
    dut.send_cmd("dimt conn_req #{chan} alloc 15", /ACK DONE/, 10)
    chan += 1
    dut.send_cmd("dimt set template 15 conn_req elem 0 req_type add ld_pkt_pkt src #{chan} dst #{chan+1}", /OK/, 10)
    dut.send_cmd("dimt conn_req #{chan} alloc 15", /ACK DONE/, 10)

    if(dut.timeout?)
      cleanup_and_exit()
      return
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
    num_chans = tcid
    append = 0
    i = 0
    pc_udp_port = 32768
    # Generate packet headers

    
    FileUtils.remove_dir("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}")  if (File.exists?"#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}")
    FileUtils.mkdir("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}")     
    FileUtils.mkdir("#{OUTPUT_DIR}/outputCap/TC#{test_case_id}") if !File.exists?("#{OUTPUT_DIR}/outputCap/TC#{test_case_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}") if !File.exists?("#{OUTPUT_DIR}/TC#{test_case_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/VideoClarityRefs") 
    
    file_ext_name = nil
    dim = []
    codec_hash.each_pair { |codec, res_arr|
        res_arr.each {|res|
            core_info_hash.keys.sort.each { |key|
                core_info_hash[key].getLength().times { |i|
                    if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)
                    if(core_info_hash[key][i].is_master == 1)
                        debug_puts "Generating pktHdrs.cfg"
                        case codec
                            when /yuv_/
                                file_ext_name = "yuv"
                            when /h264/
                                file_ext_name = "264"
                            when "mpeg4"
                                file_ext_name = "m4v"
                            when "mpeg2"
                                file_ext_name = "m2v"
                            when "h263p"
                                file_ext_name = "263"

                        end
                        case res.resolution
                            when "qcif"
                                dim << [176,144]
                            when "cif"
                                dim << [352,288]
                            when "d1pal"
                                dim << [720,480]
                            when "d1ntsc"
                                dim << [720,576]
                            when "1080p"
                                dim << [1920,1088]
                            when "720p"
                                dim << [1280,720]
                        end
                        clip_hash.each_key { |clip|
                          puts "#{codec} #{clip} #{res.resolution} #{clip_hash[clip].to_s}"
                          pkt_to_pkt_delay = -1
                          if(/#{codec}_#{res.resolution}/.match(clip) || (/yuv/.match(codec) && /yuv_#{res.resolution}/.match(clip)))
                            if(/yuv/.match(codec) && /yuv_#{res.resolution}/.match(clip))
                              if (multislice == 1)
                                  if(!File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\multislice\\#{clip_hash[clip].to_s}.yuv"))
                                    raise "Error: ### Clip not found"
                                  end
                              else  
                                  if (!File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{clip_hash[clip].to_s}.yuv")) 
                                    raise "Error: ### Clip not found"
                                  end
                              end
                            else
                              if (multislice == 1)
                                  if(!File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}.cap"))
                                    raise "Error: ### Clip not found"
                                  end
                              else
                                  if (!File.size("#{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}.cap")) 
                                    raise "Error: ### Clip not found"
                                  end
                              end
                            end
                           if(!/yuv/.match(codec))
                            genCodecCfg(codec,res.resolution,test_case_id,clip_hash[clip].to_s,multislice) 
                            system("#{VIDEO_TOOLS_DIR}\\desktop_vppu.exe #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.cfg > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.txt")         
                            Dir.chdir("#{WIRESHARK_DIR}")
                            if(multislice == 1)
                              system("capinfos.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}_rtpmarker.cap > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt")
                            else
                              system("capinfos.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}_rtpmarker.cap > #{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt")
                            end
                            pkt_to_pkt_delay = get_pkt_to_pkt_delay("#{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\codec_dump_#{codec}_#{res.resolution}.txt","#{INPUT_DIR}\\config\\pktHdrs\\TC#{test_case_id}\\capinfos_#{codec}_#{res.resolution}.txt",wire_fps)
                           end
                            genPktHdrs(codec,res.resolution,key,i,pc_udp_port,append,test_case_id,clip_hash[clip].to_s,multislice,pkt_to_pkt_delay,@platform_info) 
                            if(video_clarity == 1)
                              begin
                                if (/yuv/.match(codec) && /yuv_#{res.resolution}/.match(clip))
                                  if(multislice == 1)
                                    FileUtils.copy_file("#{INPUT_DIR}\\in\\#{res.resolution}\\multislice\\#{clip_hash[clip].to_s}.#{file_ext_name} #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv") if !File.exists?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv"
                                  else
                                    FileUtils.copy_file("#{INPUT_DIR}\\in\\#{res.resolution}\\#{clip_hash[clip].to_s}.#{file_ext_name}","#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv") if !File.exists?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv"
                                  end
                                else
                                  if(multislice == 1)
                                    system("#{VIDEO_TOOLS_DIR}\\ffmpeg.exe -i #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\multislice\\#{clip_hash[clip].to_s}.#{file_ext_name} -f rawvideo #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv") if !File.exists?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv"
                                  else
                                    system("#{VIDEO_TOOLS_DIR}\\ffmpeg.exe -i #{INPUT_DIR}\\in\\#{res.resolution}\\#{codec}\\#{clip_hash[clip].to_s}.#{file_ext_name} -f rawvideo #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv") if !File.exists?"#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\VideoClarityRefs\\#{codec}_#{res.resolution}.yuv"
                                  end
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
                    end
                    pc_udp_port += 2
                }
            }
            pc_udp_port = 32768
            append = 0
        }
    }
    if(profilemips)
      FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling")
      pc_udp_port = 0x7802
      sprintf("%d", pc_udp_port)
      core_info_hash.keys.sort.each { |key|
        start_profiling(dut,key)
        puts("start #{VIDEO_TOOLS_DIR}/rcvUdpPackets.exe #{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling/profileinfo#{pc_udp_port}.dat #{pc_udp_port}")
        system("start #{VIDEO_TOOLS_DIR}/rcvUdpPackets.exe #{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling/profileinfo#{pc_udp_port}.dat #{pc_udp_port}")
        pc_udp_port += 2
        }
    end
    clip_iter.times { |c_iter|
        pc_udp_port = 32768
        append = 0
        geom = 0       
        if(!profilemips)
        codec_hash.each_pair { |codec, res_arr|
        res_arr.each {|res|
        core_info_hash.keys.sort.each { |key|
            core_info_hash[key].getLength().times { |i|  
                if(core_info_hash[key][i].get_dir == "enc" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)
                    if(core_info_hash[key][i].get_codec != "yuv" and core_info_hash[key][i].is_master == 1)
                        debug_puts "Generating SDP for #{core_info_hash[key][i].get_codec} #{core_info_hash[key][i].get_resolution} #{key} #{pc_udp_port}"
                        genSDP(core_info_hash[key][i].get_codec,core_info_hash[key][i].get_resolution,key,pc_udp_port,append,test_case_id,geom,multislice,iteration_id,c_iter,@platform_info)
                Dir.chdir("#{WIRESHARK_DIR}")
                        system("start tshark -f \"dst #{@platform_info.get_pc_ip} and udp dst port #{pc_udp_port}\"  -i #{@platform_info.get_eth_dev} -w #{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}/Iter#{iteration_id}_clipIter#{c_iter}.cap")
                geom += 180
            append = 1
            end
                end
                pc_udp_port += 2  
            }
        }
        pc_udp_port = 32768
        append = 0
        geom = 0
        }
        }
    end

        if(subjective == 1 && !profilemips)
        codec_hash.each_pair { |codec, res_arr|
            res_arr.each{|res|
                core_info_hash.keys.sort.each { |key|
                    core_info_hash[key].getLength().times { |i|
                    transcoded_codec = core_info_hash[key][i].get_transcoded_to_codec
                    if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && res.subjective_on == 0)
                        if (core_info_hash[key][i].is_master == 1)
                        system("start \"Mplayer\" cmd.exe \/c #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\#{transcoded_codec}_#{res.resolution}_subj_bat.bat")
                        sleep(1)
                        res.subjective_on = 1
                        end
                    end                        
                    }
                }
            }
        }
        end
           
    
        codec_hash.each_pair { |codec, res_arr|
          res_arr.each{|res|
            core_info_hash.keys.sort.each { |key|
              core_info_hash[key].getLength().times { |i|
                if(core_info_hash[key][i].get_dir == "dec" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution && res.stream_sent == 0)
                    if(core_info_hash[key][i].is_master == 1)
                    res.stream_sent = 1 
                    dim.each { |elem|
                     clip_hash.each_key { |clip|
                      system("#{VIDEO_TOOLS_DIR}/yuvStreamer.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{clip_hash[clip].to_s}.yuv #{elem[0]} #{elem[1]} #{@platform_info.get_platform_ip["CORE_0"]}:32768 #{wire_fps}")
                      puts("#{VIDEO_TOOLS_DIR}/yuvStreamer.exe #{INPUT_DIR}\\in\\#{res.resolution}\\#{clip_hash[clip].to_s}.yuv #{elem[0]} #{elem[1]} #{@platform_info.get_platform_ip["CORE_0"]}:32768 #{wire_fps}")
                      }
                    }	
                    end
                 end
                }
            }
          }
        }		  
        sleep(num_chans*0.1)
        codec_hash.each_pair { |codec, res_arr| res_arr.each{|res| res.stream_sent = 0} }        
        system("taskkill /F /IM \"tshark.exe\"")
        system("taskkill /FI \"IMAGENAME eq mplayer.exe\"")
        system("taskkill /FI \"WINDOWTITLE eq Mplayer\"")
        pc_udp_port = 32768
        codec_hash.each_pair { |codec, res_arr|
        res_arr.each {|res|
        core_info_hash.keys.sort.each { |key|
          core_info_hash[key].getLength().times { |i|  
            if(core_info_hash[key][i].get_dir == "enc" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)               
              if (core_info_hash[key][i].is_master == 1)
              system("tshark -r #{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}/Iter#{iteration_id}_clipIter#{c_iter}.cap -R \"udp.port == #{pc_udp_port}\" -w #{OUTPUT_DIR}/outputCap/TC#{test_case_id}/Iter#{iteration_id}/#{pc_udp_port}_out_clipIter#{c_iter}.cap")
              end
            end
            pc_udp_port += 2  
          }
        }
        pc_udp_port = 32768
        }
        }
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
        if(profilemips)
          system("taskkill /F /IM rcvUdpPackets.exe")
          begin
            pc_udp_port = 0x7802
            sprintf("%d", pc_udp_port)
            core_info_hash.keys.sort.each { |key|
            system("ccperl #{VIDEO_TOOLS_DIR}/parsemips.pl -b64xle #{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling/profileinfo#{pc_udp_port}.dat #{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling/profileinfo#{pc_udp_port} ")
            pc_udp_port += 2
            }
          rescue
            raise "ccperl error"
          end
          pc_udp_port = 0x7802
          profileData = []
          sprintf("%d", pc_udp_port)
          core_info_hash.keys.sort.each { |key| 
          stop_profiling(dut,key)
          profileMips("#{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling/profileinfo#{pc_udp_port}.csv",profilemips,key,@perfData,profileData)
          pc_udp_port += 2
          }
          profileHash = Hash.new{0}
          profileData.each { |elem|
          profileHash[elem] += 1
       }
       profileHash.each { |param,count|
      if(count == core_info_hash.length)
        test_comment += "#{param} MIPS not found"
        test_done_result = FrameworkConstants::Result[:fail]
      end
      }
      test_comment += "MIPS Profiling data at #{OUTPUT_DIR}/TC#{test_case_id}/Iter#{iteration_id}/MIPSProfiling/ \n"
    else
    
    clip_iter.times { |c_iter|
        codec_hash.each_pair { |codec, res_arr|
            res_arr.each{|res|
                core_info_hash.keys.sort.each { |key|
                    core_info_hash[key].getLength().times { |i|
                    if(core_info_hash[key][i].get_dir == "enc" && core_info_hash[key][i].get_dir == res.codec_type && core_info_hash[key][i].get_codec == codec && core_info_hash[key][i].get_resolution == res.resolution)
                        if (core_info_hash[key][i].is_master == 1)
                        debug_puts "codec: #{codec} res: #{res.resolution} port:#{pc_udp_port}"
                            #system("etherealUtil.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\#{pc_udp_port}.cfg #{OUTPUT_DIR}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\auto_generated_ConfigFile4sendPkts_#{pc_udp_port}.cfg")
                            case codec
                                when /h264/
                                    file_ext_name = "264"
                                when "mpeg4"
                                    file_ext_name = "m4v"
                                when "h263p"
                                    file_ext_name = "263"
                                when /yuv_/
                                    file_ext_name = "yuv"
                            end
                            # system("start /D \"#{MPLAYER_DIR}\" mplayer sdp://#{OUTPUT_DIR}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\t_rtp_#{pc_udp_port}.sdp -fps 15 -dumpvideo -dumpfile #{OUTPUT_DIR}\\TC#{test_case_id}\\trans_#{codec}_#{res.resolution}_cap\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name}")
                            # sleep(5)
                            # system("sendPackets.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\#{codec}_#{res.resolution}\\auto_generated_ConfigFile4sendPkts_#{pc_udp_port}.cfg #{ETH_DEV} 1 s")                              
                            begin
                              system("#{VIDEO_TOOLS_DIR}\\desktop_vppu.exe #{Pathname.new("#{OUTPUT_DIR}").realpath}\\TC#{test_case_id}\\Iter#{iteration_id}\\#{codec}_#{res.resolution}\\clipIter#{c_iter}\\#{pc_udp_port}_codec_dump.cfg")   
                              if File.size?("#{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name}")
                                if(!/yuv_/.match(codec)) 
                                  system("#{VIDEO_TOOLS_DIR}\\ffmpeg.exe -i #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.#{file_ext_name} -f rawvideo #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.yuv") 
                                end
                                if(subjective == 1)
                                  system("#{VIDEO_TOOLS_DIR}\\YUVSequenceViewer.exe #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}\\trans_#{codec}_#{res.resolution}_cap\\clipIter#{c_iter}\\trans_#{codec}_#{res.resolution}_#{pc_udp_port}_cap.yuv")
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
                              test_comment = "File IO failed - no Video Clarity scores will be generated. Output clips directory #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}" 
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
                                  format = [720,576,25]
                                  when "720p"
                                  format = [1280,720,25]
                                  when "1080p"
                                  format = [1920,1080,25]
                                  else
                                  format = [176,144,30]
                                  end
                                  test_comment = ""
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
                                      # test_comment += video_done_comment+"\n" if video_done_comment.strip.to_s == ''
                                      test_done_result = video_done_result if test_done_result !=	 FrameworkConstants::Result[:fail]
                                  end
                                  set_result(test_done_result, test_comment)
                              end
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
    end
    debug_puts "#### sending channel close #### "
    dut.send_cmd("dim tcids", /OK/, 10)
    tcids_state = dut.response
    tcids_state.each_line { |line|
    if(line.match(/Exception/i))
        test_done_result = FrameworkConstants::Result[:fail]
        test_comment = "Test completed: Channel Exception"
        set_result(test_done_result,test_comment)
    elsif(line.match(/[\d+\s+]{3}\d+\s\/\s+\d+\s+\w[Idle|Video]/i))
        tcid = line.match(/\d+/)[0]
        channel_reset(dut,tcid)
        if(dut.timeout?)
        cleanup_and_exit()
        return
        end  
    end
    }
    tcid = 0
    core_info_hash.keys.sort.each { |key|
    core_info_hash[key].getLength().times {
        close_channel(dut,tcid)
        tcid += 1
        }
    }
    if (test_done_result != FrameworkConstants::Result[:fail])
        test_done_result = FrameworkConstants::Result[:pass] 
        test_comment += "\nTest completed"
        if(!profilemips)
          test_comment += "Output clips at #{OUTPUT_DIR}\\TC#{test_case_id}\\Iter#{iteration_id}"
        end
    end
    set_result(test_done_result,test_comment,@perfData)
end

def channel_reset(dut,tcid)
    puts "#{tcid} : In channel_reset"
    dut.send_cmd("cc xdp_cli_set_state #{tcid} tx_disable rx_disable",/OK/,10)
    dut.send_cmd("dimt close #{tcid} alloc",/ACK DONE/,2)


end
def close_channel(dut,tcid)
    debug_puts "#{tcid} : In close channel"
    dut.send_cmd("cc xdp_cli_unreg #{tcid}",/OK/,10)
    dut.send_cmd("cc disassoc #{tcid}",/OK/,10)
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
        puts " #### Error: set_xdp_vars: No match ####"
    end    
    debug_puts "#### In set_xdp_vars ####"
    params.each_pair do |var,value|
        if /#{codec}v#{type}/.match(var.to_s)
        params_array.push(var.gsub("#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}"))
        end
    end
     params_array.sort!

    params_array.each do |elem|
        dut.send_cmd("cc xdp_var set #{elem.gsub(/_[0-9]+/, "")} #{i}",/OK/,10)
        i += 1
    end
end

def set_mc_enc(dut,src_template,resolution,codec)
  dst_template = src_template + 1
  case resolution
    when "1080p"
      top = 128
      bottom = 320
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)
      dst_template += 1
      top = 320
      bottom = 512
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)
      dst_template += 1
      top = 512
      bottom = 704
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)
      dst_template += 1
      top = 704
      bottom = 896
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)
      dst_template += 1
      top = 896
      bottom = 1088
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)
    when "720p"

      top = 240
      bottom = 480
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)
      dst_template += 1
      top = 480
      bottom = 720
      set_mc_template(dut,src_template,dst_template)
      set_top_bottom_slices(dut,dst_template,codec,top,bottom)

  end
end

def set_mc_template(dut,src_template,dst_template)
  dut.send_cmd("dimt reset template #{dst_template}",/OK/,10) 
  dut.send_cmd("dimt copy #{src_template} #{dst_template}",/OK/,10) 
end

def set_top_bottom_slices(dut,dst_template,codec,top,bottom)
  dut.send_cmd("dimt set template #{dst_template} video dynamic_video_codec_cfg cfg_param_str #{codec.upcase}_ENC_topslline_msb 0",/OK/,10) 
  dut.send_cmd("dimt set template #{dst_template} video dynamic_video_codec_cfg cfg_param_str #{codec.upcase}_ENC_topslline_lsb #{top}",/OK/,10) 
  dut.send_cmd("dimt set template #{dst_template} video dynamic_video_codec_cfg cfg_param_str #{codec.upcase}_ENC_bottomslline_msb 0",/OK/,10) 
  dut.send_cmd("dimt set template #{dst_template} video dynamic_video_codec_cfg cfg_param_str #{codec.upcase}_ENC_bottomslline_lsb #{bottom}",/OK/,10) 
end

def set_core_teams(dut,template,n_cores,core)
    dut.send_cmd("dimt set template #{template} video video_mode n_cores #{n_cores}",/OK/,10)
    core_team_mapping = []
    chan_id_on_cores = []
    n_cores.times {
      core_team_mapping << "#{core}" 
      chan_id_on_cores <<  1
      core = core+1
    }
    dut.send_cmd("dimt set template #{template} video video_mode core_team_mapping #{core_team_mapping.join(" ")}",/OK/,10)
    dut.send_cmd("dimt set template #{template} video video_mode chan_id_on_cores #{chan_id_on_cores.join(" ")}",/OK/,10)                 
end


def set_codec_cfg(dut,codec,res,multislice,type,template,var_type,default_params = nil,core)
  i = 0
  debug_puts "#{var_type} parameters for #{codec} #{res}"
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
  if (!is_tsu?(codec))  
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
          dut.send_cmd("dimt set template #{template} video video_ovly_cfg #{curr_var.to_s.gsub("@#{codec}v_enc_", "")} #{@test_params.params_chan.instance_variable_get(curr_var)[0]}",/OK/,10) 
        else
          dut.send_cmd("dimt set template #{template} video video_mode #{curr_var.to_s.gsub("@#{codec}v_enc_", "")} #{@test_params.params_chan.instance_variable_get(curr_var)[0]}",/OK/,10) 
        end
      end
    end
    if(@test_params.params_chan.instance_variable_defined?("@enc_framerate") && type == "enc_dyn")
      params_hash["#{codec.upcase}_ENC_tgtfrrate_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff
      params_hash["#{codec.upcase}_ENC_tgtfrrate_msb"] = (@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff0000) >> 16
      params_hash["#{codec.upcase}_ENC_intrafrint_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i/1000 & 0xffff
      params_hash["#{codec.upcase}_ENC_intrafrint_msb"] = ((@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i/1000) & 0xffff0000) >> 16
      params_hash["#{codec.upcase}_ENC_reffrrate_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff
      params_hash["#{codec.upcase}_ENC_reffrrate_msb"] = (@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i & 0xffff0000) >> 16
      if(codec == "h264bp")
          params_hash["#{codec.upcase}_ENC_maxdelay_lsb"] = @test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i/1000 & 0xffff
          params_hash["#{codec.upcase}_ENC_maxdelay_msb"] = ((@test_params.params_chan.instance_variable_get("@enc_framerate")[0].to_i/1000) & 0xffff0000) >> 16
      end
    end
    if(@test_params.params_chan.instance_variable_defined?("@enc_bitrate") && type == "enc_dyn")
      params_hash["#{codec.upcase}_ENC_tgtbitrate_lsb"] = sprintf("0x%04x", @test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff)
      params_hash["#{codec.upcase}_ENC_tgtbitrate_msb"] = sprintf("0x%04x", (@test_params.params_chan.instance_variable_get("@enc_bitrate")[0].to_i & 0xffff0000) >> 16)
    end
  else #default
    default_params.each_pair do |var,value|
    if /#{codec}v#{type}/.match(var)
    params_hash[var.to_s.gsub("#{codec}v#{codectype.swapcase}_#{paramtype}", "#{codec.upcase}_#{codectype}")] = value
    end
    end
  end
  end
  arr = Array.new
  arr = params_hash.sort
  arr.each do |elem|
    dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{elem[0].gsub(/_[0-9]+/, "")} #{elem[1]} ",/OK/,10)
  end
  if(var_type == "default")
    dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg num_words #{arr.length} ",/OK/,10)
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
      when "720p"
        height = 720
        width = 1280
      when "1080p"
        height = 1088
        width = 1920
      else
        raise " #### Error :no recognized resolution"
    end
    if !is_tsu?(codec)
        case(type)
        when "dec_st" 
            if(codec != "yuv")
            dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{codec.upcase}_#{codectype}_maxheight_lsb #{height} ",/OK/,10)
            dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{codec.upcase}_#{codectype}_maxwidth_lsb #{width} ",/OK/,10)
            end
            if(multislice == 1 && codec == "h264bp")
                dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str #{codec.upcase}_#{codectype}_ipstrformat_lsb 1",/OK/,10)       
            end
            dut.send_cmd("dimt set template  #{template} video video_mode img_width #{width}",/OK/,10)
            dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,10)
        when "enc_st"
            if(codec != "yuv")
            dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxheight_lsb #{height} ",/OK/,10)
            dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_maxwidth_lsb #{width} ",/OK/,10)
            end
            dut.send_cmd("dimt set template  #{template} video video_mode img_width #{width}",/OK/,10)
            dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,10)
        when "enc_dyn"
            dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_inputht_lsb #{height} ",/OK/,10)
            dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_inputwdth_lsb #{width} ",/OK/,10)
            if (res == "1080p")
                dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_bottomslline_lsb 128 ",/OK/,10)       
                # 1080p decoder needs six cores
            elsif (res == "720p")
                dut.send_cmd("dimt set template #{template} video #{config}_video_codec_cfg cfg_param_str  #{codec.upcase}_#{codectype}_bottomslline_lsb 240 ",/OK/,10) 
            end
        end
    else
        dut.send_cmd("dimt set template  #{template} video video_mode img_width #{width}",/OK/,10)
        dut.send_cmd("dimt set template #{template} video video_mode img_height #{height}",/OK/,10)
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

def print_stats(dut,tcid)
    dut.send_cmd("dimt req_stat #{tcid} alloc vppu vtk frc yuv rtcp_to_pkt", /ACK DONE/, 10)
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

def setup_boot(dut,ftp_server,power_handler)
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
    boot(dut,ftp_server,boot_params,power_handler)
  else
    dut.connect({'type'=>'serial'})
    puts "Tomahawk VGDK transcoding::setup_boot: dsp and app image NOT specified. Will skip booting process"
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

def start_profiling(dut,core)
    dut.send_cmd("cc write_mem2 #{core} 0 0x420002 0",/OK/,10)
end

def stop_profiling(dut,core)
    dut.send_cmd("cc write_mem2 #{core} 0 0x420002 0xFFFF",/OK/,10)
end

def is_tsu?(codec)
  return ((codec == "tsu") ? true : false)
end

def create_chan(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,is_master,template)
  slave_tempc_info = CoreInfo::new()
  slavenewChan = ChannelInfo.new(chanCodec,dir,resolution,transcoded_to_codec,transcoded_from_codec,transized_from_res,is_master,template)
  slave_tempc_info.append(slavenewChan)  
end
