import xml.etree.ElementTree as ET
from pprint import pprint
import sys

def usage():
    print '\n'
    print 'This script can be used to compare two TestLink-exported testplans'
    print 'It can be used to tell the user what testcases need to be added / '
    print 'deleted from an existing testplan inorder to make it match with a '
    print 'reference testplan'
    print '\n'
    print 'Usage: '+sys.argv[0]+' <file1.xml> <file2.xml>'
    print 'where -'        
    print 'file1: reference testplan xml'
    print 'file2: existing testplan xml'
    print '\n'
    print 'The script will print the names of testcases that:'
    print ' * need to be added from reference to existing testplans'
    print ' * need to be deleted from existing testplan'
#    print ' * are in reference testplan'
    print '\n'

if len(sys.argv) != 3:
  usage()
  sys.exit(0)

inFile1 = sys.argv[1]
inFile2 = sys.argv[2]

a1 = []
b1 = []

tree = ET.parse(inFile1)
root = tree.getroot()


for elem in tree.iter():
  if elem.tag == "testcase":
    #pprint(elem.attrib["name"])
    a1.append(elem.attrib["name"])


tree = ET.parse(inFile2)
root = tree.getroot()

for elem in tree.iter():
  if elem.tag == "testcase":
    #pprint(elem.attrib["name"])
    b1.append(elem.attrib["name"])


list1 = sorted(list(set(a1) - set(b1)))
list2 = sorted(list(set(b1) - set(a1)))
list3 = sorted(list(set(b1) & set(a1)))
print "Number of testcases in reference testplan: %d" %(len((list(set(a1)))))
print "Number of testcases in existing testplan: %d" %(len((list(set(b1)))))

print "List of NEW testcases to be added to existing testplan: %d" %(len((list(set(a1) - set(b1)))))
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "\n".join([str(x) for x in list1] )
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

print "List of TO BE DELETED testcases from existing testplan: : %d" %(len((list(set(b1) - set(a1)))))
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "\n".join([str(x) for x in list2] )
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#print "List of existing testcases: %d" %(len((list(set(a1) & set(b1)))))
#print "+++++++++++++++++++++"
#print "\n".join([str(x) for x in list3] )
#print "+++++++++++++++++++++"

