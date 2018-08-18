#!/usr/bin/perl -w
use lib "./perl";
use GDS2;
my $gds2File = new GDS2(-fileName=>$ARGV[0]);
while ($gds2File -> readGds2Record) {
    print $gds2File->returnRecordAsString(-compact=>0);
    print "\n";
}
