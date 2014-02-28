#!/bin/sh

XSPATH=/home/a0273433/ti/xdctools_3_25_04_88

while getopts o:g:r: x
do
    case "$x" in
        o) OUTPUTFILE="$OPTARG";;
        g) GOLDENFILE="$OPTARG";;
        r) RESULTSFILE="$OPTARG";;
      [?]) print >&2 "Usage: $0 -o output_C_I/O_file -g golden_javascript_test_lookup_file -r output_results_file"; exit 1;;
    esac
done

${XSPATH}/xs -c mainCompare.xs ${OUTPUTFILE} ${GOLDENFILE} ${RESULTSFILE}
