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
#		14	make sure the bitmap file is present
#		15	no bitmaps files are in the package without listing in epsc
#		16	make sure every image map file listed is present

#bonus TODO
# questions for ben
# 1. always a study, always a display name, always lang-id, script name?
# r1. study is not always there, disp not, lang and script name always there
# 2. should a missing script file be called out? No

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
(my $version) = $epro =~ /Version>(.*)<\/Version>/i;
chomp ($version);
my $outfile = $version . "_VaildationSummary.csv";
open (my $fh, '>', $outfile);

#extract scripts
my $work = $ARGV[0];
$work =~ s/ePROStudyConfig.xml//i;
$work =~ s/\\/\\\\/g;
my $path = $Bin . "\\cryptonite\\myDecryptDecompAll.bat";
$path =~ s/\//\\/g;
#call the cryptonite batch decomp decrypt
system( $path, $work );
#the decrypted files should have this extension
my $workSuffix = ".xml.epsctmp";

#		1	Output ePSC version
print $fh $version ? "Version,$version\n" : "Version Not Found\n";

#		2	Output ISP login and password
print $fh "Account Login,";
(my $login) = $epro =~ /Account.*name="(.*)"\spas/i,"\n";
print $fh $login ? "$login\n" : "Account Name Not Found\n";

print $fh "Account Password,";
(my $pass) = $epro =~ /"\spassword="(.*)"/;
print $fh $pass ? "$pass\n" : "Account Password Not Found\n";

#		3	Verify ISP password is login backwards
#remove domain from login and compare
chomp($pass);
$login =~ s/@.*$//;
chomp($login);
unless ($login eq scalar reverse $pass){print $fh ",Password Mismatch!!!";}
print $fh "\n\n";

#		4	For each study list the name and display if applicable
# to grab all the things @ary = $str =~ m/(stuff)/g;

#
#		--	For each language:
#

#grabbing stuff into arrays, a </study> resets the counter
$order = 0;
my @lid;
my @sname;
my @sver;
my @dname;
my @bmap;
my @imap;
my $error;
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
	if ($1){print $fh "Study Name,$1\n";}
	if ($2){print $fh "Display Name,$2";}
	if ($10){print $fh "\n[[Study Languages]]\nDisplay Name,Language ID,Script Name,Script Version,Script Image,Image Map,Warning(s)\n";}
	if ($3)
	{
		@lid[$order] = $3;
#		9	Verify no language ID is repeated per study
		my $n = 0;
		while ($n < $order)
		{
			if (@lid[$order] eq @lid[$n]) {$error = $error . "Language ID Repeated - ";}
			$n++;
		}
	}
	if ($4)# script name and version
	{
		@sname[$order] = $4;
		if (my $sfh = File::ReadBackwards->new(@sname[$order] . $workSuffix))
		{
			$sfh->readline; #blow out the last line
			@sver[$order] = $sfh->readline;
			$sfh->close;
			chomp (@sver[$order]);
			@sver[$order] =~ s/#V\s//;
		} else { print "Error Reading Version from file."; system( 'pause' );}
	}
	if ($5)
	{
		@dname[$order] = $5;
#		6	Verify format and spelling for display name (country - lang)
		my ($country, $lang) = @dname[$order] =~ /(.*)\s-\s(.*)/;
		if ($iso !~ /$country/ or $iso !~ /$lang/)
		{$error = $error . "DisplayName Spelling - ";}
#		7	Verify order of display name (alpha)
		if ($order >= 1 && @dname[$order] le @dname[$order - 1])
		{$error = $error . "DisplayName Out of Order - ";}
#		8	Verify language ID matches the display name
		my ($lg, $ct) = @lid[$order] =~ /(\w\w)-(\w\w)/;
		if ($iso !~ /$ct,$country/ or $iso !~ /$lg,$lang/)
		{$error = $error . "Language ID Invalid - ";}
	}
	if ($6) #bitmap
	{
		@bmap[$order] = $6;
#		14	make sure the bitmap file is present
		unless(-e "@bmap[$order].sdf")
		{$error = $error . "Script Image Error - ";}
	}
	if ($7)
	{
		@imap[$order] = $7;
#		15	make sure every image map file listed is present
		unless (-e "@imap[$order].xml")
		{$error = $error . "Missing Image Map - ";}
	}
	if ($8)#end of language, print all lang nodes
	{
#		15	no bitmaps files are in the package without listing in epsc
		unless(length @bmap[$order])
		{
			foreach (glob("*.sdf"))
			{
				if(/@sname[$order]/){$error = $error . "Script Image Error - ";}
			};
		}
#			Printing!
#		5	Output display name
		print $fh @dname[$order] ? "@dname[$order]" : ",None";
#			output language id
		print $fh @lid[$order] ? ",@lid[$order]" : ",None";
#		10	Output script name
		print $fh @sname[$order] ? ",@sname[$order]" : ",None";
#		11	Output version of the script
		print $fh @sver[$order] ? ",@sver[$order]" : ",None";
#		12	Output bitmap if applicable
		print $fh @bmap[$order] ? ",@bmap[$order]" : ",None";
#		13	Output image map if applicable
		print $fh @imap[$order] ? ",@imap[$order]" : ",None";
#			Output warning messages
		print $fh $error ? ",$error" : ",None";
		print $fh "\n";
		$error = "";
		$order++;
	}
	if ($9) #end of study
	{
		$order = 0;
		(@lid,@sname,@sver,@dname,@bmap,@imap) = ();
		print $fh "\n";
	}
}
#cleanup
close $fh;
#commented out to test if cryptonite is working
unlink glob "\*$workSuffix";
exec($outfile);

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