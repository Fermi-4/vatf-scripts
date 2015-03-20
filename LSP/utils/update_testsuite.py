#!/usr/bin/python
import xml.etree.ElementTree as ET
import re
import sys
import subprocess 
import os
import difflib

###########################
# Modify ET to handle CDATA
ET._original_serialize_xml = ET._serialize_xml
def _serialize_xml(write, elem, encoding, qnames, namespaces):
    if elem.tag == 'name' or elem.tag == 'value' or elem.tag == 'node_order' or \
       elem.tag == 'details' or elem.tag == 'externalid' or elem.tag == 'summary' or \
       elem.tag == 'execution_type' or elem.tag == 'importance' or elem.tag == 'steps' or \
       elem.tag == 'expectedresults' or elem.tag == 'notes':
        if elem.text == None: elem.text = ''
        write("<%s><![CDATA[%s]]></%s>" % (elem.tag, elem.text, elem.tag))
        return
    return ET._original_serialize_xml(
         write, elem, encoding, qnames, namespaces)
ET._serialize_xml = ET._serialize['xml'] = _serialize_xml
###########################

params_control = re.compile('params_control') 
ltp_test = re.compile('.*script=cd\s+\/opt\/ltp;\s*\./runltp')
test_suite = re.compile('.*\s+-f\s+(.+?)\s+')
test_case = re.compile('.*\s+-s[\s"]+(.+?)["\s,]+')
errors = []
warnings = []

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
    return 0 == subprocess.call('cat ' + os.path.join(ltp_root,'runtest',ts) + ' | grep ' + tc , shell=True)

def read_words(words_file):
    return [word for line in open(words_file, 'r') for word in line.split()]

def find_closest_match(ts,tc):
    all_words = read_words(os.path.join(ltp_root,'runtest',ts))
    cm = difflib.get_close_matches(tc, all_words, 1)[0]
    return cm

def update_custom_field(e):
    text = e.text
    ts = extract_test_suite(text)
    tc = extract_test_case(text)
    tc_exists = test_case_exists(ts,tc)
    if tc_exists:
        print ts + ": " + tc + ": exists"
    else:
        print ts + ": " + tc + ": does NOT exist"
    if ts == None or tc == None or tc_exists: return
    new_testcase = find_closest_match(ts,tc)
    warnings.append("Replacing {0} with {1}".format(tc, new_testcase))
    e.text = text.replace(tc, new_testcase, 1)

def usage():
    print "Update ltp test case tags in test cases under host test suites that calls ltp tests."
    print '  USAGE: ' + sys.argv[0] + ' <ltp sources root> <testsuite.xml file>'
    exit(1)

######################
##### Main Logic #####
######################
if len(sys.argv) < 3: usage()

ltp_root = sys.argv[1]
test_suite_file = sys.argv[2]

tree = ET.parse(test_suite_file)
root = tree.getroot()

for cf in root.findall(".//custom_field"):
    name = cf.findtext('name')
    value = cf.findtext('value')
    if params_control.match(name) and ltp_test.match(value):
        elem = cf.find('value')
        update_custom_field(elem)
        
for m in warnings:
    print "WARNING: " + m
for e in errors:
    print "ERROR: " + e
if len(errors) == 0:
    print("Creating output.xml")
    tree.write('output.xml')
    print "{0} tests cases updated".format(len(warnings))
else:
    print "There were {0} errors".format(len(errors))

print "Done\n" 