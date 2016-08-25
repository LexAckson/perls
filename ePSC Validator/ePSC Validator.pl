#!/usr/bin/perl
#ePSC Validator
#Alex Jackson July 2014
#Checks an eProStudyConfig.xml for the following:
#Note! these numbers are not related to FRS req
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
#		17	The file is for the BM170 or HD2 devices and there is a Langauge
#			entry with the translation code 'ar' or 'he' that does not have the 
#			tag '<NativeRTL>True</NativeRTL>' under the Language

#packaging notes
#
#To install PP with strawberry perl, use the cpan manager to install PAR
#then use these commands:
#cpan> look PAR::Packer
##prompt should change to something like,
##H:\straw5.16\cpan\build\PAR-Packer-1.014-lqy0Qe>
#perl Makefile.PL
#dmake -f Makefile install
#******************************
#User the perl command line to compile.
#The command for pp is:
#C:\Users\alex.jackson\Documents\perls\ePSC Validator>pp.bat -o ePSCValidator.exe -M File::ReadBackwards "ePSC Validator.pl"


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
my $outfile = "ePSCVaildationSummary_" . $version . ".csv";
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
my $workSuffix = ".epsctmp";

#		1	Output ePSC version
print $fh $version ? "Version,$version\n" : "Version Not Found\n";

#		2	Output ISP login and password
# print $fh "Account Login,";
# (my $login) = $epro =~ /Account.*name="(.*)"\spas/i,"\n";
# print $fh $login ? "$login\n" : "Account Name Not Found\n";

# print $fh "Account Password,";
# (my $pass) = $epro =~ /"\spassword="(.*)"/;
# print $fh $pass ? "$pass\n" : "Account Password Not Found\n";

		# 3	Verify ISP password is login backwards
# remove domain from login and compare
# chomp($pass);
# $login =~ s/@.*$//;
# chomp($login);
# unless ($login eq scalar reverse $pass){print $fh ",Password Mismatch!!!";}
#print $fh "\n\n";

#		4	For each study list the name and display if applicable
# to grab all the things @ary = $str =~ m/(stuff)/g;

#
#		--	For each language:
#

#grabbing stuff into arrays, a </study> resets the counter
$order = 0;
my @lid;
my @sname;
my $snameExists;
my @sver;
my @dname;
my @bmap;
my @imap;
my @nRTL;
my $error;
while ($epro =~ /<Study\sname="(.*?)"						#1	study
				|displayname="(.*?)"						#2	display
				|<Language\sid="(.{5})						#3	@lid
				|<ScriptName>(.*)<\/ScriptName>				#4	@sname
				|<DisplayName>(.*)<\/DisplayName>			#5	@dname
				|<ScriptImageName>(.*)<\/ScriptImageName>	#6	@bmap
				|<ScriptImageMap>(.*)<\/ScriptImageMap>		#7	@imap
				|<NativeRTL>(.*)<\/NativeRTL>				#8	@nRTL
				|(<\/language>)								#9	end of lang
				|(<\/study>)								#10	end study
				|(<SupportedLanguages>)						#11	start langs list
				/xgi)
{
	if ($1){print $fh "Study Name,$1\n";}
	if ($2){print $fh "Display Name,$2";}
	if ($11){print $fh "\n[[Study Languages]]\nDisplay Name,Language ID,Script Name,Script Version,Warning(s)\n";}
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
		#see if our file exists
		$snameExists = (-e "@sname[$order].xml" or -e "@sname[$order].xml" . $workSuffix);

		#try the decrypted version
		my $sfh = File::ReadBackwards->new(@sname[$order] . ".xml" . $workSuffix);
		#try the never encrypted version
		unless($sfh){$sfh = File::ReadBackwards->new(@sname[$order] . ".xml")}
		
		if($sfh)
		{
			until (@sver[$order] =~ /^#V\s/ ){@sver[$order] = $sfh->readline;}
			chomp (@sver[$order]);
			@sver[$order] =~ s/#V\s//;
			$sfh->close;
		} else { print "Error Reading Version from file. " . @sname[$order] . "\n";}
	}
	if ($5)
	{
		@dname[$order] = $5;
#		6	Verify format and spelling for display name (country - lang)
		my ($country, $lang) = @dname[$order] =~ /(.*)\s-\s(.*)/;
		if ($iso !~ /\,$country\n/ or $iso !~ /,$lang\n/)
		{$error = $error . "DisplayName Spelling - ";}
#		7	Verify order of display name (alpha)
		if ($order >= 1 && @dname[$order] le @dname[$order - 1])
		{$error = $error . "DisplayName Out of Order - ";}
#		8	Verify language ID matches the display name
		my ($lg, $ct) = @lid[$order] =~ /(\w\w)-(\w\w)/;
		if ($iso !~ /\b$ct,$country\n/ or $iso !~ /\b$lg,$lang\n/)
		{$error = $error . "Language ID Invalid - ";}
	}
	if ($6) #bitmap
	{
		@bmap[$order] = $6;
#		14	make sure the bitmap file is present
#			ths sname should be populated from an earlier iteration
		unless(-e "@bmap[$order].sdf" or not $snameExists)
		{$error = $error . "Script Image File Missing - ";}
#		make sure the language name matches the sdf name
		if(-e "@bmap[$order].sdf" and $snameExists 
		and ("@bmap[$order]" ne "@sname[$order]"))
		{$error = $error . "Script Image Mismatch - ";}
	}
	if ($7)
	{
		@imap[$order] = $7;
#		15	make sure every image map file listed is present
		unless (-e "@imap[$order].xml" or not $snameExists)
		{$error = $error . "Missing Image Map - ";}
	}
#		17	Verify that ar and he langs on PIDION or HD2 will also have the NativeRTL set to true
	if ($8)
	{
		@nRTL[$order] = $8;
	}
	if ($9)#end of language, print all lang nodes
	{
#		15	no bitmaps files are in the package without listing in epsc
		unless(length @bmap[$order])
		{
			foreach (glob("*.sdf"))
			{
				if(/@sname[$order]/ and $snameExists)
				{$error = $error . "Script Image Tag Missing - ";}
			};
		}
#		17	Verify that ar and he langs on PIDION or HD2 will also have the NativeRTL set to true
		if (@lid[$order] =~ /^ar|he/ and $epro =~ /<Device\sname="PIDION"|<Device\sname="HD2"/)
		{
			unless (@nRTL[$order] =~ /true/)
			{
				$error = $error . "RtoL Tag Missing - ";
			}
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
#		print $fh @bmap[$order] ? ",@bmap[$order]" : ",None";
#		13	Output image map if applicable
#		print $fh @imap[$order] ? ",@imap[$order]" : ",None";
#			Output warning messages
		print $fh $error ? ",$error" : ",None";
		print $fh "\n";
		$error = "";
		$order++;
	}
	if ($10) #end of study
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