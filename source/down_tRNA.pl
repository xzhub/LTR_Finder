#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  down_tRNA.pl
#
#        USAGE:  ./down_tRNA.pl
#
#  DESCRIPTION:  download tRNA seq from
#                http://lowelab.ucsc.edu/GtRNAdb/
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  2006年11月18日 22时17分41秒 CST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
if ( @ARGV < 1 )
{
    print "Usage:$0 download_dir > log.txt\n\n";
    print "   this program download tRNA fasta sequence\n";
    print "   from http://lowelab.ucsc.edu/GtRNAdb/\n";
    exit;
}
my $outdir = $ARGV[0];
my $URL    = "http://lowelab.ucsc.edu/GtRNAdb/";
system("wget -O tmp_all.html \"$URL\"");
open( F, "tmp_all.html" ) || die $!;
while (<F>)
{
    if ( $_ =~ /h2>(.*?)</ )
    {
        print ">$1\n";
    }
    if ( $_ =~ /lowelab\.ucsc\.edu\/GtRNAdb\/(.*?)\">(.*?)</ )
    {
        my $file = GetFile($1);
        print "$2\t$file\n";
    }
}
close F;
unlink "tmp_all.html";
unlink "tmp.html";

sub GetFile
{
    my ($u) = @_;
    my $url = $URL . $u;
    system("wget -O tmp.html $url");
    open( FILE, "tmp.html" ) || die $!;

    # href="Athal-tRNAs.fa">[FASTA Seqs]
    while (<FILE>)
    {
        if ( $_ =~ /.*href=\"(.*)\">\[FASTA Seqs\]/ )
        {
            system("cd $outdir; wget -N \"$url$1\"");
            close FILE;
            return $1;
        }
    }
    close FILE;
    return "";
}
