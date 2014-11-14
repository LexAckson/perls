#!/usr/bin/perl

use strict;
use warnings;

#windows cmd workaround
use File::DosGlob;
@ARGV = map {
  my @g = File::DosGlob::glob($_) if /[*?]/;
  @g ? @g : $_;
} @ARGV;


foreach $_ (@ARGV) {
   my $oldfile = $_;
   s/.*_(....)_.*/IA0088_DiaryPRO_10123_Patient_$1.xml"/g;
   print $_ + "\n";
   rename($oldfile, $_);
}