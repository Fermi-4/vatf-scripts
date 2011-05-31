require File.dirname(__FILE__)+'/cetk_perf'
require 'rexml/document'
include REXML
require 'iconv'
#include WinceTestScript

def parse_xml_data(log_file)
    result = ""
	perfdata = []
	
     xmldoc = REXML::Document.new(File.open(log_file,'r'))
     res_table = @results_html_file.add_table([["Performance Numbers",{:bgcolor => "green", :colspan => "6"},{:color => "red"}]],{:border => "1",:width=>"20%"})
     scenario_instance = XPath.match(xmldoc, "//ScenarioInstance")
     scenario_instance.each do |instance|
	 session_namespace = XPath.first(instance,"SessionNamespace")
	 statistic = XPath.match(session_namespace,"Statistic") 
	 if (statistic)	   
		statistic.each {	
		|stat| puts "Stat is #{stat}\n"
		units = "us"
		if (stat.attributes.get_attribute("Name").to_s.match("Count")) 
		 units = "none"
		end
		perfdata<<{'name'=>stat.attributes.get_attribute("Name").to_s,'value'=>Float(stat.attributes.get_attribute("Value").to_s),'units'=>units}
		@results_html_file.add_row_to_table( res_table,[stat.attributes.get_attribute("Name").to_s,Float(stat.attributes.get_attribute("Value").to_s)])
		
		}
		
	    #@results_html_file.add_row_to_table( res_table,["Statistics_Data",result])	
        #perfdata<<{'name'=>result[attr[0]].to_s,'value'=>result[attr[1]],'units'=>'us'}		
	    end	
end
return perfdata
end 
