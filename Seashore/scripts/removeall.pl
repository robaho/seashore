#! /usr/bin/perl

# removeall.pl
#
# Takes all files matching various pre-specified endings and places them
# in the user's trash can. Be warned this script is dangerous and should
# only be used if properly understood.
#
# Mark Pazolli
#
# Public Domain 2003

use File::Find qw(finddepth);

# Check that we have an argument specifying the directory to search and destroy files in
if ($#ARGV + 1 < 2 || !($ARGV[0] && -e $ARGV[0] && -d $ARGV[0])) {
	print "\nUsage:\tremoveall.pl directory name1 ...\n\n";
	print "\t\tdirectory - the directory to recurse in search of files\n";
	print "\t\tname1 ... - the list of file name endings to be deleted\n";
	die "\n";
}

# Go through the specified directory
finddepth (\&fordeletion, $ARGV[0]);

# Move the correct files to the trash
foreach $filename (@trash) {
	print "$filename\n";
	$trashfilename = $filename;
	$trashfilename =~ s/.*\///;
	$trashfilename = "$ENV{'HOME'}/.Trash/$trashfilename";
	if (-e $trashfilename) {
		for ($i = 1; -e $trashfilename.$i; $i++) {}
		$trashfilename = $trashfilename.$i; 
	}
	rename($filename, $trashfilename);
	# unlink($filename);
}

sub fordeletion
{
	$delete = 0;
	for ($i = 1; $i < $#ARGV + 1; $i++) {
		$delete = $delete || $_ =~ /$ARGV[$i]$/;
	}
	if ($delete) {
		push(@trash, $File::Find::name);
	}
}

