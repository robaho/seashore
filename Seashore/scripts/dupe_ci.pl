#! /usr/bin/perl

#
# dupe_ci.pl
#
# Creates a new Core Image plug-in in the style of the base plug-in.
#
# Mark Pazolli
# Public Domain 2007
#

use File::Find qw(finddepth);

# Check that we have an argument specifying the directory to search and destroy files in
if ($#ARGV + 1 != 2 || !(-e $ARGV[0] && -d $ARGV[0]) || (-e $ARGV[1])) {
	print "\nUsage:\dupe_ci.pl src dest\n\n";
	print "\t\tsrc - the directory containing the base plug-in\n";
	print "\t\tdest - the directory to contain the new plug-in\n";
	die "\n";
}

# Move into more friendly variables
if ($ARGV[0] =~ /\/$/) { $src = $ARGV[0]; } else { $src = $ARGV[0]."/"; }
if ($ARGV[1] =~ /\/$/) { $dest = $ARGV[1]; } else { $dest = $ARGV[1]."/"; }
$src_ciname = $ARGV[0];
$src_ciname =~ s/\/$//;
$src_ciname =~ s/.*\///;
$dest_ciname = $ARGV[1];
$dest_ciname =~ s/\/$//;
$dest_ciname =~ s/.*\///;
$src_name = $src_ciname;
$src_name =~ s/^CI//;
$dest_name = $dest_ciname;
$dest_name =~ s/^CI//;

# Copy file
`cp -r "$src" "$dest"`;

# Go through the specified directory
finddepth (\&fordeletion, $dest);

# Move the correct files to the trash
foreach $filename (@trash) {
	$trashfilename = $filename;
	$trashfilename =~ s/.*\///;
	$trashfilename = "$ENV{'HOME'}/.Trash/$trashfilename";
	if (-e $trashfilename) {
		for ($i = 1; -e $trashfilename.$i; $i++) {}
		$trashfilename = $trashfilename.$i; 
	}
	rename($filename, $trashfilename);
}

# Do renames
rename($dest.$src_ciname.".xcodeproj", $dest.$dest_ciname.".xcodeproj");
rename($dest.$src_ciname."Class.h", $dest.$dest_ciname."Class.h");
rename($dest.$src_ciname."Class.m", $dest.$dest_ciname."Class.m");
if (-e $dest."English.lproj/".$src_ciname.".nib") {
	rename($dest."English.lproj/".$src_ciname.".nib", $dest."English.lproj/".$dest_ciname.".nib");
}

# Go through the specified directory
finddepth (\&fortext, $dest);

# Do substitutions
foreach $filename (@txtfiles) {
	
	# Memorize the file
	open(FILE, $filename);
	@input = <FILE>;
	close(FILE);

	# Now write out with changes
	open(FILE, ">".$filename);
	for ($i = 0; $i <= $#input; $i++) {
		$curline = $input[$i];
		$curline =~ s/$src_name/$dest_name/g;
		print FILE $curline;
	}
	close(FILE);
	
}

sub fordeletion
{
	$delete = 0;
	$delete = $delete || $_ =~ /\.svn$/;
	$delete = $delete || $_ =~ /\.DS_Store$/;
	$delete = $delete || $_ =~ /\.pbxuser$/;
	$delete = $delete || $_ =~ /\.mode1$/;
	if ($delete) {
		push(@trash, $File::Find::name);
	}
}

sub fortext
{
	$all = 0;
	$all = $all || $_ =~ /\.h$/;
	$all = $all || $_ =~ /\.m$/;
	$all = $all || $_ =~ /\.pbxproj$/;
	$all = $all || $_ =~ /\.plist$/;
	$all = $all || $_ =~ /\.strings$/;
	if ($all) {
		push(@txtfiles, $File::Find::name);
	}
}
