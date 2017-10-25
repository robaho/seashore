#! /usr/bin/perl -w

# addtop.pl
#
# Adds the "Top" link to top of every "toc.html" in the specified directory.
#
# Mark Pazolli
#
# Public Domain 2002

use File::Find qw(finddepth);

# Check that our arguments make sense, otherwise print usage
if ($#ARGV != 0 ||
	!($ARGV[0] && -e $ARGV[0])) {
	print "\nUsage:\taddtop.pl target\n\n";
	print "\ttarget - the directory containing the \"toc.html\" files to add the \"Top\" link to\n";
	die("\n");
}

# Create a list of all the files we have to check
if (-d $ARGV[0]) {
	finddepth (\&wanted, $ARGV[0]);
}

# Go through each of the files doing our duty
foreach $path (@files) {
	
	# Memorize the file
	open(FILE, $path);
	@input = <FILE>;
	close(FILE);
	
	# Create a temporary backup file in case things go wrong
	$saved_name = $path."~";
	rename($path, $saved_name);
	
	# Now create a new file at the original location for output
	open(FILE, ">".$path);
	
	# Define what we are testing for
	# $linecheck = "<table width=\"100%\"><tr bgcolor=\"#999999\"><td>&nbsp;</td></tr></table>";
	$linecheck = "<table width=\"100%\" cellpadding=0 cellspacing=0 border=0><tr height=51 bgcolor=\"#466C9B\"><td>&nbsp;</td></tr></table><br><table border=\"0\" cellpadding=\"0\" cellspacing=\"2\" width=\"148\">";
	
	# Go through all lines in the file
	for ($i = 0; $i <= $#input; $i++) {
		
		# Determine the current line
		$curline = $input[$i];
		
		# Check if it needs adjusting
		if ($curline =~ /$linecheck/) {
			$contents = substr($path, length($ARGV[0]));
			if (substr($contents, 0, 1) eq "/") {
				$contents = substr($contents, 1, length($contents) - 1);
			}
			$contents =~ s/[^\/]*\//..\//g;
			$contents =~ s/toc/MasterTOC/;
			$oldtext = "&nbsp;";
			$newtext = "<a href=\"".$contents."\" target=\"_top\">Top</a>";
			$curline =~ s/$oldtext/$newtext/;
		}
		
		# Put it in the new file
		print FILE $curline;
		
	}
	
	# Close the file output
	close(FILE);
	
	# Delete the temporary backup file
	unlink($saved_name);

}

sub wanted
{
	if ($_ eq "toc\.html") {
		push(@files, $File::Find::name);
	}
}
