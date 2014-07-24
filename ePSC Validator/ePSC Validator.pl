#ePSC Validator
#Alex Jackson July 2014
#Checks an eProStudyConfig.xml for the following:
#		1	Output ePSC version
#		2	Output ISP login and password
#		3	Verify ISP password is login backwards
#		4	For each study list the name and display if applicable
#		--	For each language:
#		5	Output display name
#		6	Verify format and spelling for display name (country - lang)
#		7	Verify order of display name (alpha)
#		8	Verify language ID matches the display name
#		9	Verify no language ID is repeated per study
#		10	Output script name
#		11	Output version of the script
#		12	Output bitmap if applicable
#		13	Output image map if applicable

#bonus TODO
# questions for ben
# 1. always a study, always a display name, always lang-id, script name?
# r1. study is not always there, disp not, lang and script name always there
# 2. example of bitmap
# 3. example of image map

use File::ReadBackwards;

#path to this
use FindBin qw($Bin);
use lib "$Bin/../lib";

if ($ARGV[0] !~ /ePROStudyConfig/i)
{
	print "Oops, not an ePROStudyConfig.xml!\n";
	system( 'pause' );
	exit;
}

#move the ePRO into mem for much scanning
$epro = &_slurp (@ARGV);

#move iso codes into memory for scans
$iso = &_slurp ("$Bin/ISO Country and Language Codes.csv");
#prepare the output file
my $version = &scan (qr/Version>(.*)<\/Version>/i);
chomp ($version);
my $outfile = $version . "_VaildationSummary.csv";
open (my $fh, '>', $outfile);

#extract scripts
my $work = $ARGV[0];
$work =~ s/ePROStudyConfig.xml//i;
$work =~ s/\\/\\\\/g;
my $path = $Bin . "\\\\cryptonite\\\\myDecryptDecompAll.bat";
$path =~ s/\//\\\\/g;
#call the cryptonite batch decomp decrypt
system($path, $work);
#the decrypted files should have this extension
my $workSuffix = ".xml.epsctmp";

#		1	Output ePSC version
print $fh "ePSC version,$version\n";
#		2	Output ISP login and password
print $fh "ISP Login,";
print $fh my $login = &scan (qr/Account.*name="(.*)"\spas/i);

print $fh "ISP Password,";
print $fh my $pass = &scan (qr/"\spassword="(.*)"/i);

#		3	Verify ISP password is login backwards
#$string = reverse $string;
print $fh "ISP pass is login backwards,";
#remove domain from login and compare
chomp($pass);
scalar reverse $pass;
if ($login =~ /^$pass$/) {print $fh "True\n";}
else {print $fh "False\n";}

#		4	For each study list the name and display if applicable
# to grab all the things @ary = $str =~ m/(stuff)/g;
print $fh "\nStudies:\n\n";

#
#		--	For each language:
#

#grabbing stuff into arrays, a </study> resets the counter
#consider moving the prints outside because the order of nodes can change
$order = 0;
my @lid;
my @sname;
my @dname;
my @bmap;
my @imap;
while ($epro =~ /<Study\sname="(.*?)"						#1	study
				|displayname="(.*?)"						#2	display
				|<Language\sid="(.{5})						#3	@lid
				|<ScriptName>(.*)<\/ScriptName>				#4	@sname
				|<DisplayName>(.*)<\/DisplayName>			#5	@dname
				|<ScriptImageName>(.*)<\/ScriptImageName>	#6	@bmap
				|<ScriptImageMap>(.*)<\/ScriptImageMap>		#7	@imap
				|(<\/language>)								#8	end of lang
				|(<\/study>)								#9	end study
				|(<SupportedLanguages>)						#10	start langs list
				/xgi)
{
	if (length $1){print $fh "Study,Display Name\n$1";}
	if (length $2){print $fh ",$2";}
	if (length $10){print $fh "\nLanguages:\nLang ID,Script Name,Script Version,Display Name,Bitmap,Image Map\n";}
	if (length $3)
	{
		@lid[$order] = $3;
		print $fh "$3";
#		9	Verify no language ID is repeated per study
		my $n = 0;
		while ($n < $order)
		{
			if (@lid[$order] eq @lid[$n]) {print $fh "REPEAT!!!";}
			$n++;
		}
	}
#		10	Output script name
	if (length $4)
	{
		@sname[$order] = $4;
		print $fh ",$4";
#		11	Output version of the script
		my $sfh = File::ReadBackwards->new(@sname[$order] . $workSuffix);
		$sfh->readline; #blow out the last line
		my $sver = $sfh->readline;
		$sfh->close;
		chomp ($sver);
		$sver =~ s/#V\s//;
		print $fh "," . $sver;
	}
#		5	Output display name
	if (length $5)
	{
		@dname[$order] = $5;
		print $fh ",$5";
#		6	Verify format and spelling for display name (country - lang)
		my ($country, $lang) = @dname[$order] =~ /(.*)\s-\s(.*)/;
		if ($iso !~ /$country/ or $iso !~ /$lang/) {print $fh "BAD SP/FMT!!!";}
#		7	Verify order of display name (alpha)
		if ($order >= 1 && @dname[$order] le @dname[$order - 1]){print $fh "OUT OF ORDER!!!";}
#		8	Verify language ID matches the display name
		my ($lg, $ct) = @lid[$order] =~ /(\w\w)-(\w\w)/;
		if ($iso !~ /$ct,$country/ or $iso !~ /$lg,$lang/) {print $fh "LID MISMATCH!!!";}
	}
#		12	Output bitmap if applicable
	if (length $6){@bmap[$order] = $6; print $fh ",$6";}
#		13	Output image map if applicable
	if (length $7){@imap[$order] = $7; print $fh ",$7";}
	if (length $8){print $fh "\n"; $order++;}#end of language
	if (length $9) #end of study
	{
		$order = 0;
		(@lid,@sname,@dname,@bmap,@imap) = ();
		print $fh "\n";
	}
}

#cleanup
close $fh;
unlink glob "\*$workSuffix";
exec($outfile);

#sub to scan the command arg file and return 1st matched substr
sub scan 
{
	my $reg = shift;
	if ($epro =~ $reg) { return $1 . "\n"; last;}
}

#reads file into memory
sub _slurp
{
    my $filename = shift;
    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";
    local $/;
    my $contents = <$in>;
    close($in);
    return $contents;
}