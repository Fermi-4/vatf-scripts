#!/usr/bin/python
import xml.etree.ElementTree as ET
import re
import sys
import subprocess
import os
import difflib
import traceback

params_control = re.compile('params_control')
ltp_test = re.compile('.*script=cd\s+\/opt\/ltp;\s*\./runltp')
test_suite = re.compile('.*\s+-f\s+(.+?)\s+')
test_case = re.compile('.*\s+-s[\s"]+(.+?)["\s,]+')
errors = []
warnings = []
TOBEDELETED_TS = '3769061'  # Node ID of TOBEDELETED test suite in Testlink

def extract_test_suite(text):
    m = test_suite.match(text)
    if m == None:
        errors.append("{0} does not contain an ltp test suite".format(text))
        return None
    return m.group(1)

def extract_test_case(text):
    m = test_case.match(text)
    if m == None:
        errors.append("{0} does not contain an ltp test case tag".format(text))
        return None
    return m.group(1)

def test_case_exists(ts,tc):
    return 0 == subprocess.call('cat ' + os.path.join(ltp_root,'runtest',ts) + ' | egrep ' + tc + '[[:blank:]\,[:punct:]]+ > /dev/null', shell=True)

def read_words(words_file):
    return [word for line in open(words_file, 'r') for word in line.split()]

def check_custom_field(e, tl_ts1_name, tl_ts2_name, tl_tc, sql_file):
    text = e.text
    ts = extract_test_suite(text)
    tc = extract_test_case(text)
    if ts == None or tc == None: return
    if not test_case_exists(ts,tc):
        tl_tc_name = tl_tc.get('name')
        warnings.append("On {0}:{1} {2} reference to nonexistent ltp-ddt test: scenario {3} test tag {4}"
            .format(tl_ts1_name, tl_ts2_name, tl_tc_name, ts, tc))
        sql_file.write("# Moving {0}:{1} {2} to TOBEDELETED suite\n"
            .format(tl_ts1_name, tl_ts2_name, tl_tc_name))
        sql_file.write('update nodes_hierarchy set parent_id=' +
            TOBEDELETED_TS + ' where id=' + tl_tc.get('internalid') + ';\n')

def usage():
    print "Find old ltp-ddt tests references in testlink tests and create updates.sql file."
    print "This file can be run in mysql (e.g. mysql -u root -p testlink < updates.sql)"
    print "to move old tests to TOBEDELETED test suite"
    print '  USAGE: ' + sys.argv[0] + ' <ltp sources root> <testsuite.xml file>'
    exit(1)

######################
##### Main Logic #####
######################
if len(sys.argv) < 3: usage()
try:
    sql_file = open(os.path.join('.','updates.sql'),'w')

    tests_processed = 0
    ltp_root = sys.argv[1]
    test_suite_file = sys.argv[2]

    tree = ET.parse(test_suite_file)
    root = tree.getroot()

    for tl_ts1_e in root.findall("./testsuite"):
        print tl_ts1_e.get('name')
        for tl_ts2_e in tl_ts1_e.findall("./testsuite"):
            print "\t" + tl_ts2_e.get('name')
            for tl_tc_e in tl_ts2_e.findall(".//testcase"):
                print "\t\t" + tl_tc_e.get('name')
                tests_processed += 1
                for cf in tl_tc_e.findall(".//*/custom_field"):
                    name = cf.findtext('name')
                    value = cf.findtext('value')
                    if params_control.match(name) and ltp_test.match(value):
                        elem = cf.find('value')
                        check_custom_field(elem, tl_ts1_e.get('name'), tl_ts2_e.get('name'), tl_tc_e, sql_file)
except Exception, e:
    print "Exception running script. DO NOT UPDATE database with generated sql file"
    test_trace = traceback.format_exc()
    print test_trace
finally:
    sql_file.close()

print "There were {0} errors".format(len(errors))
for e in errors:
    print "ERROR: " + e

print "{0} old ltp-ddt tests references found".format(len(warnings))
for m in warnings:
    print "WARNING: " + m

print str(tests_processed) + " tests processed"
print "Done\n"
