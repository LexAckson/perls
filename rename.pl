use File::DosGlob;
@ARGV = map {
  my @g = File::DosGlob::glob($_) if /[*?]/;
  @g ? @g : $_;
} @ARGV;

@screens = (4,5,5,4,4,4,5,4,4);
$pg = 1;
$sc = 1;

$op = shift or die "Usage: rename expr [files]\n";
chomp( @ARGV = <STDIN> ) unless @ARGV;
for ( @ARGV ) 
{
  $was = $_;
  eval $op;
  $_ = $_ . '_' . $pg . '.' . $sc . '.png';
  die $@ if $@;
  rename ( $was, $_ ) unless $was eq $_;
  if ($sc == @screens[$pg-1] )
  {
	$sc = 0;
	$pg = $pg + 1;
  }
  $sc = $sc + 1;
}