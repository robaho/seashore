#! /usr/bin/perl

# Check that we have an argument specifying the directory to search and destroy files in
if ($#ARGV + 1 < 2 || !($ARGV[0] && -e $ARGV[0]) || !($ARGV[1] && -e $ARGV[1])) {
	print "\nUsage:\ttranslate.pl enfile xxfile\n\n";
	print "\t\tenfile - the english strings from nibtool\n";
	print "\t\txxfile - the translated string from nibtool\n";
	die "\n";
}

# Load english strings
open(FILE, "<:encoding(UTF-16)", $ARGV[0]);
@enfile = <FILE>;
close(FILE);

# Load translated strings
open(FILE, "<:encoding(UTF-16)", $ARGV[1]);
@xxfile = <FILE>;
close(FILE);

# Go through the english strings
$off = 0;
for ($i = 0; $i < $#enfile / 3; $i++) {

	# Get three lines at a time
	$line1 = $enfile[$i * 3 + $off];
	chomp($line1);
	if ($line1 !~ /\*\//) {
		$off = $off + 1;
		$line1 = $line1.$enfile[$i * 3 + $off];
		chomp($line1);
	}
	$line2 = $enfile[$i * 3 + 1 + $off];
	chomp($line2);

	# Extract information for record
	$finalrec[$i]{"comment"} = $line1;
	$line1 =~ /oid:([0-9]*)/;
	$finalrec[$i]{"oid"} = $1;
	$line2 =~ s/\\"/&quot;/g;
	$line2 =~ /\"([^\"]*)\"/;
	$out = $1;
	$out =~ s/&quot;/\\"/g;
	$finalrec[$i]{"first"} = $out;
	$finalrec[$i]{"second"} = $out;

}

# Remember the length
$finalrec_len = $#enfile / 3;

# Go through the translated strings
$off = 0;
for ($i = 0; $i < $#xxfile / 3; $i++) {

	# Get three lines at a time
	$line1 = $xxfile[$i * 3 + $off];
	chomp($line1);
	if ($line1 !~ /\*\//) {
		$off = $off + 1;
		$line1 = $line1.$enfile[$i * 3 + $off];
		chomp($line1);
	}
	$line2 = $xxfile[$i * 3 + 1 + $off];
	chomp($line3);
	
	# Extract information for record
	$line1 =~ /oid:([0-9]*)/;
	$oid = $1;
	$fin = 0;
	for ($j = 0; $j < $finalrec_len && !$fin; $j++) {
		if ($finalrec[$j]{"oid"} == $oid) {
			$line2 =~ /\"([^\"]*)\"/;
			$finalrec[$j]{"second"} = $1;
			$fin = 1;
		}
	}
	if ($fin == 0) {
		$finalrec[$j]{"comment"} = $line1;
		$line1 =~ /oid:([0-9]*)/;
		$finalrec[$j]{"oid"} = $1;
		$line2 =~ s/\\"/&quot;/g;
		$line2 =~ /\"([^\"]*)\"/;
		$out = $1;
		$out =~ s/&quot;/\\"/g;
		$finalrec[$j]{"first"} = $out;
		$finalrec[$j]{"second"} = $out;
		$finalrec_len = $finalrec_len + 1;
	}
	
}

# Print output
open(FILE, ">:encoding(UTF-16)", "new.strings");
for ($i = 0; $i < $finalrec_len; $i++) {
	print FILE $finalrec[$i]{"comment"}."\n";
	print FILE "\"".$finalrec[$i]{"first"}."\" = \"".$finalrec[$i]{"second"}."\";\n";
	print FILE "\n";
}
close(FILE);
