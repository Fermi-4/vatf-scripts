require 'rexml/document'

if (ARGV.length < 1)
  puts "Syntax: ruby extract-msgs.rb <PATH-TO-TRACE-LOG-FILE>"
  exit
end
infile = File.new(ARGV[0])
outfile = File.new("#{ARGV[0]}-out.txt",'w')
doc = REXML::Document.new infile
arr = doc.elements.to_a("//record")
outArr = []

arr2 = arr[0].elements.to_a("//message")
arr3 = arr2[0].elements.to_a("//message")


arr3.each { |elem|
 outfile.puts elem.to_s.match(/<message>(.*)<\/message>/m).captures[0].to_s
  }
infile.close
outfile.close
