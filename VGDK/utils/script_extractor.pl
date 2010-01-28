# script_extractor.pl
# This Perl script parses through a log, and extracts the lines which have
# cc or dimt or dim msg and prints those lines. The main purpose of the script
# is to extract a run-able script from the logs provided by system test.
# 
# Input: Log file
# Output: script file
# -Vivek Chengalvala (Jun-09-2009)
# Revision 2.1

die "syntax: $0 input_log \n" if ($#ARGV != 0);
open input, $ARGV[0] or die "Can't open $ARGV[0]\n";

@lines = <input>;	# Read it into an array


foreach $i (@lines)
{
if ($i =~m/Host:/)
{
($junk, $script) = split(/ Host: /,$i);
$script =~ s/\r//g; # Remove carriage returns 
print $script;
}
}
