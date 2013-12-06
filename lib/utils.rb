#Function to parse string containing <name>sep<value> pairs, takes
#  field_string the string to be parsed
#  sep, string or regex used as the <name>, <value> separator, 
#  i.e for <name>=<value> sep is '=', defaults to '=' 
#Returns a hase whose entries are <name>=><value> for each pair found in
#field_string
def parse_sep_field(field_string, sep='=')
  vals = field_string.strip().scan(/([\w ]+)#{sep}(\d+)/)
  vals_hash = {}
  vals.each { |c_val| vals_hash[c_val[0].strip()] = c_val[1] }
  vals_hash
end
