require 'csv'

module ProfileMips
  def profileMips(csvFile,profileParams)
    test_comment = " "
	test_done_result = nil
    begin
	  @lines = CSV.readlines(csvFile)
	rescue

	end
	@perfData = []
	@results_html_file.add_paragraph("")
	@res_table = @results_html_file.add_table([["MIPS count",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
	if(profileParams.include?("decoder"))
	    param_name = "Decoder Cycles"
		param = "vtkDecode_ch"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name} Channel #{value}",key) }
	end
	if(profileParams.include?("encoder"))
	    param_name = "Encoder Cycles"
		param = "vtkEncode_ch"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name} Channel #{value}",key) }
	end
	if(profileParams.include?("txrx"))
		param_name = "TxRx Cycles"
		param = "txrx_ch"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name} Channel #{value}",key) }
	end
	if(profileParams.include?("rcurx"))
		param_name = "RCU Rx Cycles"
		param = "rcurx_ch"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name} Channel #{value}",key) }
	end
	if(profileParams.include?("neurx"))
		param_name = "NEU Rx Cycles"
		param = "neurx_ch"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name} Channel #{value}",key) }
	end
	if(profileParams.include?("vppurx"))
		param_name = "VPPU Rx Cycles"
		param = "vppurx_ch"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name} Channel #{value}",key) }
	end
	if(profileParams.include?("totalcount"))
		param_name = "Total Cycles"
		param = "totalcount"
		get_col(param,test_comment,test_done_result).each_pair{ |key,value| add_result("#{param_name}",key) }
	end
    return test_comment,test_done_result,@perfData
	#set_result(FrameworkConstants::Result[:pass], "Test Pass", @perfData)
  end
  def add_result(label,col)
	@results_html_file.add_row_to_table(@res_table, [[label,{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
	@results_html_file.add_row_to_table(@res_table,["Min","#{@lines[-3][col]}"])
	@results_html_file.add_row_to_table(@res_table,["Average","#{@lines[-2][col]}"])
	@results_html_file.add_row_to_table(@res_table,["Max","#{@lines[-1][col]}"])
	@perfData << {'name' => label, 'value' => @lines[-2][col] , 'units' => 'cycles'}
  end
  def get_col(param,test_comment,test_done_result)
    col = {}
	@lines[0].each { |elem| 
	if elem != nil
	if elem.match(param) 
	  channel = elem.scan(/\d/)
	  if channel
	    col[@lines[0].index("#{param}#{channel}")] = channel 
	  else
	    col[@lines[0].index("#{param}")] = nil
	  end
	end
	end
	}
	if col.empty?
	test_comment += "#{param} MIPS not found \n"
	test_done_result = FrameworkConstants::Result[:fail]
    end	
	col
  end
end