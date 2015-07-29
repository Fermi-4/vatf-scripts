require 'net/ssh'
require 'net/scp'

#Function to parse string containing <name>sep<value> pairs, takes
#  field_string the string to be parsed
#  sep, string or regex used as the <name>, <value> separator, 
#  i.e for <name>=<value> sep is '=', defaults to '=' 
#Returns a hase whose entries are <name>=><value> for each pair found in
#field_string
def parse_sep_field(field_string, sep='=')
  vals = field_string.strip().scan(/([\w \-_]+)#{sep}((?:0x){0,1}\d+)/)
  vals_hash = {}
  vals.each { |c_val| vals_hash[c_val[0].strip()] = c_val[1] }
  vals_hash
end

#Fucntion to obtain the mean (avg), of an array of values, takes
#  arr, an array of values
def mean(arr)
  arr.inject(:+).to_f / arr.length
end

#Function to compute the variance of the values in an array, takes
#  arr, an array of values
def variance(arr)
  mean = mean(arr)
  sum = arr.inject(0){|sum,ele| sum+=(ele-mean)**2}
  sum/(arr.length-1) 
end

#Function to compute the standard deviation of the values in an array, takes
#  arr, an array of value
def std_dev(arr)
  variance(arr)**0.5    
end

#Function to compute the cross correlation between two arrays, takes
#  arr1, an array of samples
#  arr2, an array of samples
def cross_correlation(arr1, arr2)
  raise "Arrays must have same length" if arr1.length != arr2.length
  dev1 = std_dev(arr1)
  dev2 = std_dev(arr2)
  m1 = mean(arr1)
  m2 = mean(arr2)
  sum = (0...arr2.length).inject(0) {|r, i| r + (arr1[i]-m1)*(arr2[i]-m2)}
  sum/((arr1.length-1)*dev1*dev2)
end

#Function to perform a scp from a ssh server (require gems net-ssh and net-scp)
#to the host, takes
#  ip_addr, string containing the ip address of the ssh server
#  rem_path, string containing the path of the file, that will be copied, from ip_addr
#  local_path, string containing destination path of the file
#  username, (Optiona) string containing the ssh username, defaults to root
#  password, (Optional) string containing the password associated with user 
#            username, defaults to ''
def scp_pull_file(ip_addr, rem_path, local_path, username='root', password='', paranoid=false) 
  Net::SSH.start(ip_addr, username, :password => password, :paranoid => paranoid) do |ssh|
    ssh.scp.download!(rem_path, local_path)
  end
end

#Function to perform a scp to a ssh server (require gems net-ssh and net-scp)
#to the host, takes
#  ip_addr, string containing the ip address of the ssh server
#  local_path, string containing the path of the file to be copied
#  rem_path, string containing destination path of the file in ip_addr
#  username, (Optiona) string containing the ssh username, defaults to root
#  password, (Optional) string containing the password associated with user 
#            username, defaults to ''
def scp_push_file(ip_addr, local_path, rem_path, username='root', password='') 
  Net::SSH.start(ip_addr, username, :password => password) do |ssh|
    ssh.scp.upload!(local_path, rem_path)
  end
end

#Function to parse sections of a string, takes:
#  string, the string to be parsed
#  sep_regex, a regex containing the pattern used to determine the sections
#Return a hash whose key-value pair entries are 
#  <string that matches sep_regex> => <string found after sep_regex>
def get_sections(string, sep_regex)
  scan_res = string.scan(/(#{sep_regex})((.(?!#{sep_regex}))*)/im)
  return nil if scan_res.empty?
  result = {}
  scan_res.each do |cur_section|
    result[cur_section[0].strip()] = cur_section[1]
  end
  result
end
