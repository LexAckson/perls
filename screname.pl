#a script to rename and number assesment screens according to 
#the numbering from flow chats
#USAGE: perl screname files  ex: perl screname *.png  or  perl screname ISF_*

#****SCRIPT CONFIG****
#working dir, relative to script location or absolute
$wdir = 'C:\deSyncInvivio\ey2491s\QIDS';
if ($wdir)
{
	chdir($wdir) or die("Can't change to dir $wdir: $!\n");
}
#new file name prefix, for example 'SF-36' or 'Neuro-QOL EF'
$pref = 'QIDS';
#this array represents the number of screens on each page of the flow
#ex: @screens = (2,3,1);
#ISF36_1.png --> SF-36_1.1.png
#ISF36_2.png --> SF-36_1.2.png
#ISF36_3.png --> SF-36_2.1.png
#ISF36_4.png --> SF-36_2.2.png
#ISF36_5.png --> SF-36_2.3.png
#ISF36_6.png --> SF-36_3.1.png
@screens = (5,3,4,5);
#operation on filename
$op = 's/^.*\.(.*)/${pref}_$pg\.$sc\.$1/';
#****SCRIPT CONFIG****

#has the user accepted the changes?
$verified = 0;
#starting page
$spg = 1;
#starting screen
$ssc = 1;

#windows cmd workaround
use File::DosGlob;
@ARGV = map {
  my @g = File::DosGlob::glob($_) if /[*?]/;
  @g ? @g : $_;
} @ARGV;

#uncomment next line to allow passing your own regex operation as the first command line arg
# $op = shift or die "Usage: screname expr [files]\n";

#get rid of \n terminator
chomp( @ARGV = <STDIN> ) unless @ARGV;

#windows bullshit sorting inconsistency workaround
for ( @ARGV ) 
{
	$old = $_;
	s/(_\d\.)/a$1/;
	#error message
	die $@ if $@;
	#rename unless no change
	rename ( $old, $_ );
}

#set start page/screen
($pg, $sc) = ($spg, $ssc);
for ( @ARGV ) 
{
	$newName = $_;
	eval '$newName =~ ' . $op;
	#error message
	die $@ if $@;
	
	print $_ . ' --> ' . $newName . "\n";
	#incrementing numeric postfix
	if ($sc == @screens[$pg-1] )
	{
		$sc = 0;
		$pg = $pg + 1;
	}
	$sc = $sc + 1;
}
#changes ok?
print "\n" . 'Are these changes okay? (y/n) ';
chomp(my $input = <STDIN>);

if ($input =~ m/y/i) 
{
	($pg, $sc) = ($spg, $ssc);
	for ( @ARGV ) 
	{
		$was = $_;
		eval $op;
		#error message
		die $@ if $@;
		#rename unless no change
		rename ( $was, $_ ) unless $was eq $_;
		#incrementing numeric postfix
		if ($sc == @screens[$pg-1] )
		{
			$sc = 0;
			$pg = $pg + 1;
		}
		$sc = $sc + 1;
	}
}