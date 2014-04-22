# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def run
  drm_rand = Random.new()
  perf_data = []
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  connector_test_time = @test_params.params_chan.instance_variable_defined?(:@connector_test_time) ? 
                        @test_params.params_chan.connector_test_time[0].to_i : 8 
  
  iterations = @test_params.params_chan.instance_variable_defined?(:@iterations) ? 
               @test_params.params_chan.iterations[0].to_i : 1 
  test_result = true     
  drm_info = get_properties()
  @results_html_file.add_paragraph("Random seed = #{drm_rand.seed}")
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Connector",{:bgcolor => "4863A0"}], 
                                            ["Encoder", {:bgcolor => "4863A0"}],
                                            ["CRTC", {:bgcolor => "4863A0"}],
                                            ["Mode", {:bgcolor => "4863A0"}],
                                            ["Plane", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}]])
  connectors = drm_info['Connectors:']
  if iterations > 1
    connectors = Array.new(iterations) {drm_info['Connectors:'][drm_rand.rand(drm_info['Connectors:'].length)]}
  end
  
  formats = @test_params.params_chan.instance_variable_defined?(:@formats) ?
            Hash.new(@test_params.params_chan.formats) :
            get_supported_fmts(drm_info['Connectors:'])
  @results_html_file.add_paragraph("Supported Formats: #{formats}")
  if !drm_info['Planes:'].empty?
    plane_formats = @test_params.params_chan.instance_variable_defined?(:@plane_formats) ?
              Hash.new(@test_params.params_chan.plane_formats) :
              get_supported_plane_pix_fmts(drm_info['CRTCs:'])
  end

  i = 0
  connectors.each do |connector|
    drm_info['Encoders:'].each do |encoder|
      next if encoder['id'] != connector['encoder']
      drm_info['CRTCs:'].each do |crtc|
        next if crtc['id'] != encoder['crtc']
        mode = connector['modes:'][drm_rand.rand(connector['modes:'].length)]
        mode_params = {'connectors_ids' => [connector['id']], 
                       'crtc_id' => crtc['id'], 
                       'mode' => mode['name'],
					             'framerate' => mode['refresh (Hz)'],
					             'format' => formats[connector['id']][drm_rand.rand(formats[connector['id']].length)]}
        plane_params = nil
        if !drm_info['Planes:'].empty? && i % 2 == 0
          plane = drm_info['Planes:'][0]
          width, height = mode['name'].match(/(\d+)x(\d+)/).captures
          plane_params = { 'width' => width, 
                           'height' => height,
                           'xyoffset' => [i,i],
                           'scale' => [0.125, 1.to_f/(1+i).to_f].max,
                           'format' => plane_formats[crtc['id']][drm_rand.rand(plane_formats[crtc['id']].length)]}
          plane_info_str = "Scale: #{plane_params['scale']}, pix_fmt: #{plane_params['format']}"
        end
        res, fps_data = run_perf_sync_flip_test(mode_params, plane_params, @equipment['dut1'], connector_test_time + 300) do
                            sleep connector_test_time
                        end
        perf_data << {'name' => "#{mode['name']}@#{mode['refresh (Hz)']}-#{mode_params['format']}",
                     'units' => 'fps',
                     'values' => fps_data}
        test_result &= res
        @results_html_file.add_row_to_table(res_table,[connector['id'], 
					                                             encoder['id'],
					                                             crtc['id'],
					                                             "#{mode['name']}@#{mode['refresh (Hz)']}-" +
					                                             "#{mode_params['format']}",
					                                             plane_params ? plane_info_str : 'No plane',
					                                             res ? ["Passed",{:bgcolor => "green"}] : 
					                                             ["Failed",{:bgcolor => "red"}]])
      end
    end
    i += 1
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "DRM Stress Test Passed", perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Stress Test failed", perf_data)
  end
end

