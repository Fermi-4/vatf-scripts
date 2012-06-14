def get_host_android_root_bin_path
  arch=send_adb_cmd("shell getprop ro.product.cpu.abi").strip
  File.join(SiteInfo::FILE_SERVER,"android/common/#{arch}")
end
