import xml.etree.ElementTree as ET
from pprint import pprint
import sys

def usage():
    print '\n'
    print 'This script can be used to compare two TestLink-exported testsuites'
    print 'It can be used to tell the user what testcases will be added /' 
    print 'may need to be moved to TOBEDELETED from an existing testsuite when the' 
    print 'reference testsuite is imported in TestLink'
    print '\n'
    print 'Usage: '+sys.argv[0]+' <file1.xml> <file2.xml>'
    print 'where -'        
    print 'file1: reference testsuite xml'
    print 'file2: existing testsuite xml'
    print '\n'
    print 'The script will print the names of following testcases, after import'
    print ' * new testcases that will be added from reference to existing testsuites'
    print ' * testcases from existing testsuite that MAY need to be moved to TOBEDELETED'
    print ' * testcases that exist in both, reference and existing testsuite. TL will'
    print '   may create a new version, as necessary'
    print '\n'

if len(sys.argv) != 3:
  usage()
  sys.exit(0)

inFile1 = sys.argv[1]
inFile2 = sys.argv[2]

a1 = []
b1 = []
a2 = []
b2 = []

tree = ET.parse(inFile1)
root = tree.getroot()


for atype in root.findall('./testsuite'):
  if atype.attrib["name"] == "ltp":
    for btype in atype.findall('./testcase'):
      a1.append(btype.get('name'))

tree = ET.parse(inFile2)
root = tree.getroot()

for atype in root.findall('./testsuite'):
  if atype.attrib["name"] == "ltp":
    for btype in atype.findall('./testcase'):
      b1.append(btype.get('name'))

list11 = sorted(list(set(a1) - set(b1)))
list12 = sorted(list(set(b1) - set(a1)))
list13 = sorted(list(set(b1) & set(a1)))

print "ltp-ddt testcases"

print "NEW testcases"
print "++++++++++++++"
print "\n".join([str(x) for x in list11] )
print "++++++++++++++"

print "TO BE DELETED testcases"
print "++++++++++++++++++++++++"
print "\n".join([str(x) for x in list12] )
print "++++++++++++++++++++++++"

print "Existing testcases (TL will take care of creating new version, if needed) "
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "\n".join([str(x) for x in list13] )
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

tree = ET.parse(inFile1)
root = tree.getroot()

for atype in root.findall('./testsuite'):
  if atype.attrib["name"] == "host":
    for btype in atype.findall('./testcase'):
      a2.append(btype.get('name'))

tree = ET.parse(inFile2)
root = tree.getroot()

for atype in root.findall('./testsuite'):
  if atype.attrib["name"] == "host":
    for btype in atype.findall('./testcase'):
      b2.append(btype.get('name'))

list21 = sorted(list(set(a2) - set(b2)))
list22 = sorted(list(set(b2) - set(a2)))
list23 = sorted(list(set(b2) & set(a2))) 

print "host testcases"

print "NEW testcases"
print "++++++++++++++"
print "\n".join([str(x) for x in list21] )
print "++++++++++++++"

print "TO BE DELETED testcases"
print "+++++++++++++++++++++++"
print "\n".join([str(x) for x in list22] )
print "+++++++++++++++++++++++"

print "Existing host testcases (TL will take care of new version, if needed) "
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "\n".join([str(x) for x in list23] )
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

