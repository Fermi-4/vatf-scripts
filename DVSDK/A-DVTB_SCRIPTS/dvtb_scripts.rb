NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'
OPERA_WAIT_TIME           = 30000

def setup
  @equipment['dut1'].set_interface('dvtb')
  
  # Connect specified inputs
  @test_params.params_chan.video_in_ifaces.each do |current_iface|
  puts current_iface
    @connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => 0}, {@equipment["dut1"] => 0}, current_iface)
  @connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => 0}, {@equipment["tv0"] => 0}, current_iface)
  end
  @test_params.params_chan.audio_in_ifaces.each do |current_iface|
    @connection_handler.make_audio_connection({@equipment[@test_params.params_chan.media_source[0]] => 0}, {@equipment["dut1"] => 0}, current_iface)
  @connection_handler.make_audio_connection({@equipment[@test_params.params_chan.media_source[0]] => 0}, {@equipment["tv0"] => 0}, current_iface)
  end
  
  #Connect specified outputs
  @test_params.params_chan.video_out_ifaces.each do |current_iface|
    @connection_handler.make_video_connection({@equipment["dut1"] => 0},{@equipment['tv1'] => 0}, current_iface)
  end
  @test_params.params_chan.audio_out_ifaces.each do |current_iface|
    @connection_handler.make_audio_connection({@equipment["dut1"] => 0},{@equipment['tv1'] => 0}, current_iface)
  end
  
  #Making client go back to the linux command line
  @equipment['dut1'].send_cmd('exit', @equipment['dut1'].prompt)
end

def run
  scripts_exec_path = @equipment["dut1"].executable_path + "/#{@test_params.params_control.dvtb_scripts_dir[0]}/"
  win_based_exec_path = @equipment["dut1"].samba_root_path+scripts_exec_path
  #Check if the scripts have been copied from the DVSDK installation dir to the board's executable path
  raise "script folder has not been copied to the board's executable path" if !File.exists?(win_based_exec_path) 
  
  #Getting the script names
  scripts = get_board_scripts(win_based_exec_path)
  
  #Populating pop-up window with scripts names
  file_res_form = ScrollableResultForm.new("DVTB Scripts Test Form")
  file_res_form.add_link('Readme'){system("explorer #{win_based_exec_path.gsub("/","\\")}Readme.txt")} if File.exists?(win_based_exec_path+'Readme.txt')
  file_res_form.add_link('run_all') do
    scripts.each do |current_script|
      puts 'Running '+current_script+' ............'
      @equipment['dut1'].send_cmd('./dvtb-r -s '+scripts_exec_path+current_script, /func.*#{@equipment['dut1'].prompt}/im, 1000)
    end
  end  
  scripts.each do |current_script|
    file_res_form.add_link(current_script) do 
      @equipment['dut1'].send_cmd('./dvtb-r -s '+scripts_exec_path+current_script, /func.*#{@equipment['dut1'].prompt}/im, 1000)
    end
  end
  while file_res_form.test_result == FrameworkConstants::Result[:nry]
    file_res_form.show_result_form
  end
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  #Returning to DVTB command line
  @equipment['dut1'].send_cmd('./dvtb-r', />/)
end

private
def get_board_scripts(path)
   result = []
   script_dir = Dir.new(path)
   script_dir.each do |current_script|
    result << current_script if current_script.match(/.*\.dvs$/)
   end
   result
end








