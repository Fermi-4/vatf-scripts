# Array to regular expressions.
# If a testcase tag matches any of the regular expressions in the array
# then the testcase is skipped, in other words, it is not imported
# to Testlink.
$FILTER_TAGS = [
/ETH_[SML]_PERF_IPERF/,
/ETH_IPERF/,
/WDT_/,
]
