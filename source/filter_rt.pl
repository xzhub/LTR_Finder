#!/usr/bin/perl
use strict;
if ( @ARGV == 1 && ( $ARGV[0] eq '-h' || $ARGV[0] eq '--help' ) )
{
    print "Usage: ltr_finder | filter_rt.pl > LTR_RT.txt\n";
    exit 1;
}
my $sequence;
my $location;
while (<>)
{
    if ( $_ =~ /^>Sequence: (.*) Len:/ )
    {
        $sequence = $1;
    }
    if ( $_ =~ /^Location : (.*) Len:/ )
    {
        $location = $1;
    }
    if ( $_ =~ /^Domain: .* \(RT\(.*/ )
    {
        print "$sequence Loc:$location $_";
    }
}

