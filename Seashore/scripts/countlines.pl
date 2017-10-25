#! /usr/bin/perl -w

# countlines.pl
#
# Counts the number of lines of source code in a given directory.
#
# Mark Pazolli
#
# Public Domain 2002

use File::Find qw(finddepth);

# Find all appropriate files
finddepth (\&wanted, $ARGV[0]);
$count = 0;

# Go through each file and determine how many lines
foreach $file (@files) {
	open(THEFILE, $file) || die("The file ".$file." could not be opened.\n");
	@lines = <THEFILE>;
	$count += $#lines;
	close(THEFILE);
}

# Print the lines to screen
print "There are ".$count." lines\n";


sub wanted
{
	if ($_ =~ /\.h$/ || $_ =~ /\.m$/ || $_ =~ /\.c$/) {
		push(@files, $File::Find::name);
	}
}
