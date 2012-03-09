require 'gnuplot'

module TestPlots
  # This function plots a each sample collected point by point.
  def stat_plot(values, plot_title, xlabel, ylabel, series_label = nil, file_name='test', plot_folder = 'misc')
    FileUtils.mkdir_p(File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s,plot_folder))
    plot_output = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s,plot_folder,"#{file_name}_plot_#{@test_id}\.pdf")
    plot_values = values
    plot_values = { '' => values } if !values.kind_of?(Hash)
    Gnuplot.open { |gp|
      Gnuplot::Plot.new( gp ) { |plot|
        plot.terminal "post eps colour size 13cm,10cm"
        plot.output plot_output
        plot.title  plot_title
        plot.ylabel ylabel
        plot.xlabel xlabel
        plot_values.each do |s_label, s_vals|
          max_range  =  (s_vals.size).to_i - 1
          x = (0..max_range).collect { |v| v.to_f }
          plot.data << Gnuplot::DataSet.new( [x, s_vals]) { |ds|
            ds.with = "lines"
            ds.linewidth = 4
            if series_label != ''
              ds.title = s_label
            else
              ds.notitle
            end
          }
        end
      }
    }
    plot_output
  end 
end  # End of module

