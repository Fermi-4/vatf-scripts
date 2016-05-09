# Use this script to run ltp perf tests
$PERF_SCRIPT = 'LSP/TARGET/dev_test_perf_gov.rb'

# Append extra parameters to params_control
$EXTRA_PARAMS_TESTS = {
  /^SPI_/      => {'extra_params' => ['bootargs_append=spi']},
  /REALTIME_[XSLM]{1,3}_PERF/ => {'extra_params' => ['perf_metrics_file=LSP/A-Realtime/cyclic_parser.rb'] },
}

def get_extra_params(testcase)
  $EXTRA_PARAMS_TESTS.each {|k,v|
    return v['extra_params'].join(",") if testcase.match(k)
  }
  return nil
end