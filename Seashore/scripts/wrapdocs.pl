#! /usr/bin/perl -w

# wrapdocs.pl
#
# Wraps certain HeaderDoc comments in a given file to fixed number
# of characters. This script will only work if you follow my
# commenting style and even then may still corrupt your headers, so
# please only use this script on code that is backed-up!
#
# Mark Pazolli
#
# Public Domain 2002

use File::Find qw(finddepth);

$WRAP_LENGTH = 80;

# Check that our arguments make sense, otherwise print usage
if ($#ARGV != 0 ||
	!($ARGV[0] && -e $ARGV[0])) {
	print "\nUsage:\twrapdocs.pl target\n\n";
	print "\ttarget - the folder or header containing the HeaderDoc comments you wish to wrap\n";
	die("\n");
}

# Create a list of all the files we have to check
if (-d $ARGV[0]) {
	finddepth (\&wanted, $ARGV[0]);
}
else {
	push(@files, $ARGV[0]);
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
	
	# Start outside of a comment
	$comment = 0;
	
	# Go through all lines in the file
	for ($i = 0; $i <= $#input; $i++) {
		
		# Determine the current line
		$curline = $input[$i];
		
		# Check if we've entered a comment
		if ($curline =~ /\/\*/) {
			$comment = 1; 
		}
		
		# We're only worried about stuff inside a comment
		if ($comment) {
		
			# We are only concerned with lines that include @discussion, @abstract, @result, @field and @param
			if ($curline =~ /\@discussion/ || $curline =~ /\@abstract/ || $curline =~ /\@result/ || $curline =~ /\@param/ || $curline =~ /\@field/) {
				
				# If the line includes @param or @field we actually want to play with the line below
				if ($curline =~ /\@param/ || $curline =~ /\@field/) {
					print FILE $curline;
					$i++;
					$curline = $input[$i];
				}
				
				# Now delete all the line breaks
				delete_breaks();
				
				# And reinsert them properly
				reinsert_breaks();
				
				# And print everything
				print FILE $newcurline;
				
			}
			else {
				print FILE $curline;
			}
			
		}
		else {
			print FILE $curline;
		}
		
		# Check if we've left a comment
		if ($curline =~ /\*\//) {
			$comment = 0;
		}
	}
	
	# Close the file output
	close(FILE);
	
	# Delete the temporary backup file
	unlink($saved_name);

}

sub delete_breaks
{
	$leave = 0;
	do {
		$i++;
		$nextline = $input[$i];
		if (!($nextline =~ /\W*\@/ || $nextline =~ /\*\// || $nextline =~ /\<br\>/)) {
			chomp($curline);
			$nextline =~ s/\W*//;
			$curline .= " ".$nextline;
		}
		else {
			$leave = 1;
		}
	} while (!$leave);
	$i--;
}

sub reinsert_breaks
{
	if ($curline =~ /(\W+\@\w*\W+)/) {
		$lastentry = length($1);
		$count = 16;
	}
	else {
		$lastentry = 4;
		$count = 16;
	}
	
	$newcurline = substr($curline, 0, $lastentry);
	for ($j = $lastentry; $j < length($curline); $j++) {
	
		if ($j - $lastentry + $count > $WRAP_LENGTH) {
			$lastentry++;
			$j = $lastentry;
			$newcurline .= "\n\t\t\t\t";
			$count = 16;
		}
		elsif (substr($curline, $j, 1) eq " " || substr($curline, $j, 1) eq "\n") {
			$newcurline .= substr($curline, $lastentry, $j - $lastentry);
			$count += $j - $lastentry;
			$lastentry = $j;
		}
	
	}
	$newcurline .= "\n";
}

sub wanted
{
	if ($_ =~ /\.h$/) {
		push(@files, $File::Find::name);
	}
}
