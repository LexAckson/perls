#does f/r on content control xml datas in config docs
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

#todo get doc path as argument
$docpath = 'C:\working\Software\_SitePRO Tablet Product\Configurations\AA3074\Configuration Documentation\TMPL 3402_03 - DesignReview.docx';

#init zip object
my $zip = Archive::Zip->new();
#read doc
$zip->read($docpath) == AZ_OK or die "read error\n";
#get xml file handle and contents TODO figure out why item number changes every time...
my $xmlhandle = $zip->memberNamed('customXml/item4.xml');
my $xmlcontents = $xmlhandle->contents();
#make replacements
$xmlcontents =~ s/<pjtcode\>.*<\/pjtcode>/<pjtcode\>butts<\/pjtcode>/g;
#write contents
$xmlhandle->contents($xmlcontents) or die "write error\n";
#save archive
$zip->overwriteAs($docpath);