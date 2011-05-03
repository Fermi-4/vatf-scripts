require 'gnuplot'

module TestPlots
  # This function plots a each sample collected point by point.
  def stat_plot(values, plot_title, xlabel, ylabel, series_label = nil, file_name='test', plot_folder = 'misc')
    FileUtils.mkdir_p(File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s,plot_folder))
    plot_output = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s,plot_folder,"#{file_name}_plot_#{@test_id}\.pdf")
    max_range  =  (values.size).to_i - 1
    Gnuplot.open { |gp|
      Gnuplot::Plot.new( gp ) { |plot|
        plot.terminal "post eps colour size 13cm,10cm"
        plot.output plot_output
        plot.title  plot_title
        plot.ylabel ylabel
        plot.xlabel xlabel
        x = (0..max_range).collect { |v| v.to_f }
        plot.data << Gnuplot::DataSet.new( [x, values]) { |ds|
          ds.with = "lines"
          ds.linewidth = 4
          if series_label
            ds.title = series_label
          else
            ds.notitle
          end
        }
        
      }
    }
    plot_output
  end 
end  # End of module

