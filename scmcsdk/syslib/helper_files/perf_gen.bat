@if .%1 == . goto ERROR
@echo.
@echo.
@echo Generating TS1/TS2 performance data...
@ruby tresults.rb -tlperf_ipsec %1 -filt "_ts1;_ts2" -postpend "crypto_ts1_ts2"

@echo.
@echo.
@echo Generating Crypto 1G performance data...
@ruby tresults.rb -tlperf_ipsec %1 -filt "crypto_performance" -nfilt "_ts1;_ts2" -postpend "crypto_1G"

@REM @echo Generating All Crypto performance data
@REM @ruby tresults.rb -tlperf_ipsec %1 -filt "crypto" -postpend "all_crypto"

@REM @echo Generating Ethernet 1G performance data
@REM @ruby tresults.rb -tlperf_ipsec %1 -filt "_1G" -nfilt "eth1" -postpend "ethernet_eth0_1G"

@REM @echo Generating Ethernet 1G eth1 performance data
@REM @ruby tresults.rb -tlperf_ipsec %1 -filt "eth1_1G" -postpend "ethernet_eth1_1G"

@REM @echo Generating Ethernet 10G performance data
@REM @ruby tresults.rb -tlperf_ipsec %1 -filt "_10G" -postpend "ethernet_10G"

@echo.
@echo.
@echo Generating Ethernet 1G/10G performance data...
@ruby tresults.rb -tlperf_ipsec %1 -filt "eth0;eth1;eth2;eth4;eth8" -postpend "ethernet_1G_10G"

@goto ENDD

:ERROR
@echo.
@echo Command line parameter is missing
@echo.
@echo Command line prototype: perf_gen.bat {perf_data_from_testlink_filename}
@echo                Example: perf_gen.bat ipsec_mcsdk303_testlink_data.csv
@echo.

:ENDD
