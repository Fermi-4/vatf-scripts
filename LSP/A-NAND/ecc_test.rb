# -*- coding: ISO-8859-1 -*-
#require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include LspTestScript
include Bootscript
def setup
  self.as(LspTestScript).setup
end

def run
  test_result = 0 # '0' is pass; else fail
  result_msg = 'this test pass'
  
  dev_node = '/dev/mtd2'
  bin_file_w_errbits = @test_params.params_chan.bin_file_w_errbits[0]
  page_size = @test_params.params_chan.page_size[0]
  hex_file_orig_nandpage = @test_params.params_chan.hex_file_orig_nandpage[0]
  
  bin_file_w_correction = 'nandpage_err_correct.bin'
  hex_file_w_correction = 'nandpage_err_correct.hex'
 
 
  # copy original nandpage hex and nandpage with errbits to the test location
  test_folder = "/#{@tester}/#{@test_params.target.downcase}/#{@test_params.platform.downcase}/#{page_size}_nand"
  test_dir_in_server = "#{@equipment['server1'].nfs_root_path}#{test_folder}"
  @equipment['server1'].send_cmd("mkdir -p #{test_dir_in_server}", @equipment['server1'].prompt, 10)

  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path}#{test_folder.gsub('/',"\\")}"
  puts "dst_folder is #{dst_folder}"
  src_file = @view_drive + hex_file_orig_nandpage.to_s
  BuildClient.copy(src_file, dst_folder+"\\"+File.basename(hex_file_orig_nandpage))
  src_file = @view_drive + bin_file_w_errbits.to_s
  BuildClient.copy(src_file, dst_folder+"\\"+File.basename(bin_file_w_errbits))
  
  #===== dut side ====
  bin_file_w_errbits = File.basename(bin_file_w_errbits)
  hex_file_orig_nandpage = File.basename(hex_file_orig_nandpage)
  @equipment['dut1'].send_cmd("cd #{test_folder}", @equipment['dut1'].prompt, 10)  
  @equipment['dut1'].send_cmd("flash_eraseall #{dev_node}", @equipment['dut1'].prompt, 60)

  @equipment['dut1'].send_cmd("nandwrite -n -o #{dev_node} #{bin_file_w_errbits}", @equipment['dut1'].prompt, 60)
  
  @equipment['dut1'].send_cmd("nanddump -p -l #{page_size} #{dev_node}", @equipment['dut1'].prompt, 60)
  
  @equipment['dut1'].send_cmd("nanddump -l #{page_size} -f #{bin_file_w_correction} #{dev_node}", @equipment['dut1'].prompt, 60)

  #===== linux pc side ====
  @equipment['server1'].send_cmd("cd #{test_dir_in_server}", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("xxd #{bin_file_w_correction} #{hex_file_w_correction}", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("diff #{hex_file_orig_nandpage} #{hex_file_w_correction}", @equipment['server1'].prompt, 60)
  
  # check if there is difference
  puts ">>>> response: "
  puts @equipment['server1'].response
  puts ""
  puts ">>>> end of response"
  if /\d+c\d+/.match(@equipment['server1'].response) && /[<>]/.match(@equipment['server1'].response)
    set_result(FrameworkConstants::Result[:fail], "corrected nandpage is not the same as the orignal nandpage.")
    return
  end

  set_result(FrameworkConstants::Result[:pass], result_msg)
end

def clean
  self.as(LspTestScript).clean
  puts 'child clean'
end  
