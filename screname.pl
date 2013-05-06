#a script to rename and number assesment screens according to 
#the numbering from flow chats
#USAGE: perl screname files  ex: perl screname *.png  or  perl screname ISF_*

#****SCRIPT CONFIG****
#working dir, relative to script location or absolute
$wdir = '';
#new file name prefix, for example 'SF-36' or 'Neuro-QOL EF'
$pref = 'SF-36';
#this array represents the number of screens on each page of the flow
#ex: @screens = (2,3,1);
#ISF36_1.png --> SF-36_1.1.png
#ISF36_2.png --> SF-36_1.2.png
#ISF36_3.png --> SF-36_2.1.png
#ISF36_4.png --> SF-36_2.2.png
#ISF36_5.png --> SF-36_2.3.png
#ISF36_6.png --> SF-36_3.1.png
@screens = (4,5,3,3,4);
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

chomp( @ARGV = <STDIN> ) unless @ARGV;

#set start page/screen
($pg, $sc) = ($spg, $ssc);
for ( @ARGV ) 
{
	$newName = $_;
	eval '$newName =~ ' . $op;
	#error message
	die $@ if $@;
	#$newName = $pref . '_' . $pg . '.' . $sc . '.' . $1;
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
print "\n" . 'Are these changes okay?  (y/n)';
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
		$_ = $_ . '_' . $pg . '.' . $sc . '.png';
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
