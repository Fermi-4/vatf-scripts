# Array to regular expressions.
# If a testcase tag matches any of the regular expressions in the array
# then the testcase is skipped, in other words, it is not imported
# to Testlink.
$FILTER_TAGS = [
/ETH_[SML]_PERF_IPERF/,
/ETH_IPERF/,
/WIFI_IPERF/,
/WDT_/,
/MMC_[XSML]_MODULAR/,
/USBHOST_[XSML]_[FUNC|STRESS]_ETH/,
/PCI_[XSML]_[FUNC|STRESS]_ETH/,
]
