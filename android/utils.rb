def get_host_android_root_bin_path
  arch=send_adb_cmd("shell getprop ro.product.cpu.abi").strip
  File.join(SiteInfo::FILE_SERVER,"android/common/#{arch}")
end

#Function to obtain the android settings from the dut.
#Takes:
#    - type: (optional) a string or array of strings specifying the type of settings to look for (global, system, secure, etc)
#    - setting: (optional) a string specifying the name of the setting to look for (bluetooth_on, lockscreen_sounds_enabled, etc)
#Returns: If setting is specified returns the value for that setting, if the setting does not exist it will return a Hash 
#         of all the settings. If type is specified it will restrict the search to the those types of settings only. If neither type not setting are specified, then it will return a Hash containing all the settings. The hash will be have the following structure {<setting type global, system, etc> => {<setting name> => <setting value>,..., <setting name> => <setting value>}  
def get_android_settings(type=nil, setting=nil)
  settings_db = '/data/data/com.android.providers.settings/databases/settings.db'
  result = {}
  if type
    setting_tables = type
    if !type.kind_of?(Array)
      settings_tables = [type]
    end
  else
    settings_tables = send_adb_cmd("shell sqlite3 #{settings_db} .tables").split(/\s+/)
  end
  for table in settings_tables
    result[table] = {}
    schema = send_adb_cmd("shell sqlite3 #{settings_db} \".schema #{table}\"")
    parsed_schema = schema.split(/[\r\n]+/)[0].scan(/([^,\);\(]+)/i)[1..-1]
    num_colums=parsed_schema.length
    column_names = []
    for column_info in parsed_schema
        column_names << column_info[0].split(/\s+/)[0]
    end
    data = send_adb_cmd("shell sqlite3 #{settings_db} \"select * from #{table};\"").split(/[\s]+/)
    for table_line in data
      parsed_data = table_line.split('|')
      if column_names.length == 3 && column_names[0].downcase().include?('id') && \
         column_names[1].downcase() == 'name' && column_names[2].downcase() == 'value'
         result[table][parsed_data[1]] = parsed_data[2]
         return parsed_data[2] if setting && parsed_data[1] == setting
      else
        column_names.each_with_index do |column, idx|
          next if column.downcase() == "_id"
          result[table][column] = parsed_data[idx]
        end
      end
    end
  end
  result
end
