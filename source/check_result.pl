#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  check_result.pl
#
#        USAGE:  ./check_result.pl
#
#  DESCRIPTION:  test ltr_finder
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  2006年11月09日 11时19分50秒 CST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

if ( @ARGV < 2 )
{
    print "$0 anno_file predict_file [tex=0] [DelOneSignal?]> result\n";
    exit;
}

my $anno = $ARGV[0];
my $pred = $ARGV[1];
my $tab  = "\t";
$tab = "&" if ( $ARGV[2] );
my $delOneSignal = 0;
if ( defined $ARGV[3] )
{
    $delOneSignal = $ARGV[3];
}
my %ANNO;
open( FILE, "$anno" ) || die $!;
while (<FILE>)
{
    $_ =~ s/"//g;

    $_ =~ /(\S+)\s+(\d+)\s*-\s*(\d+)\s+(\S+)\s+(\S+)/;
    my $n      = $1;
    my $strand = "+";
    $strand = "-" if ( $2 > $3 );
    my $b = $2 < $3 ? $2 : $3;
    my $e = $3 > $2 ? $3 : $2;
    my $tsr = $4;
    if ( $tsr ne $5 )
    {
        $tsr = 'N';
    }
    push @{ $ANNO{$n} }, [ $b, $e, $tsr, 0, $strand ];

    #warn "$n => $b,$e,$tsr\n";
}
close FILE;
if ( $tab eq "&" )
{
    print '\begin{tabular}[t]{cccccccccc}' . "\n";
    print '\hline' . "\n";
    print "NO.&Result&CHR&Location&\\minitab[c]{LTR\\\\length}&";
    print
"\\minitab[c]{Inserted\\\\element\\\\length}&TSR&+/-&Score&Similarity\\\\\n\\hline\n";

}
my $row_count      = 0;
my $total_pred     = 0;
my $total_correct  = 0;
my $total_partial  = 0;
my $total_nd       = 0;
my $direct_correct = 0;
open( FILE, "$pred" ) || die $!;
while (<FILE>)
{
    chomp $_;
    if ( $_ =~ /^\[\s*(\d+)\](.*)/ )
    {
        my $rest = $2;
        my @tmp  = split( " ", $rest );
        my $n    = $tmp[0];
        $tmp[1] =~ /(\d+)\-(\d+)/;
        my $b      = $1;
        my $e      = $2;
        my $tsr    = $tmp[4];
        my $offset = 99999999;
        my $index  = -1;

        for ( my $i = 0 ; exists $ANNO{$n} && $i < @{ $ANNO{$n} } ; ++$i )
        {
            if ( $ANNO{$n}[$i][0] > $e || $ANNO{$n}[$i][1] < $b )
            {
                next;
            }
            my $tmp =
              abs( $ANNO{$n}[$i][0] - $b ) + abs( $ANNO{$n}[$i][1] - $e );
            if ( $tmp < $offset )
            {
                $offset = $tmp;
                $index  = $i;
            }
        }
        my $domain_score = 0;
        foreach ( @tmp[ 7 .. 10 ] )
        {
            if ( $_ ne "N-N" )
            {
                $domain_score++;
            }
        }

        #if($domain_score<=0)
        #{
        #    next;
        #}

        my $signal_score = 0;
        foreach ( @tmp[ 5 .. 6 ] )
        {
            if ( $_ ne "N-N" )
            {
                $signal_score++;
            }
        }
        if ( $tsr ne 'N' )
        {
            $signal_score++;
        }
        if ( $signal_score < 2 && $delOneSignal )
        {

            #warn "Del one, signal score:$signal_score\n";
            next;
        }

        $total_pred++;
        if ( !exists $ANNO{$n} )
        {
            $total_nd++;
        }
        else
        {
            if ( $offset == 0
                || ( ( $ANNO{$n}[$index][2] eq $tsr ) && ( $tsr ne "N" ) )
              )    #match
            {
                $total_correct++;
                if ( $ANNO{$n}[$index][4] eq $tmp[11] )
                {
                    $direct_correct++;
                }
                else
                {
                    warn
"Strand Wrong: $n $ANNO{$n}[$index][0]-$ANNO{$n}[$index][1],$ANNO{$n}[$index][2]\n";
                }
            }
            elsif ( $index >= 0 )
            {
                $total_partial++;
            }
            else
            {
                $total_nd++;
            }
        }

        if ( $tab eq "\t" )
        {
            if ( !exists $ANNO{$n} )
            {
                print "*\t";
            }
            else
            {
                if ( $offset == 0
                    || ( ( $ANNO{$n}[$index][2] eq $tsr ) && ( $tsr ne "N" ) )
                  )    #match
                {
                    $ANNO{$n}[$index][3] = 3 if ( $ANNO{$n}[$index][3] < 3 );
                    print "C($offset)\t";
                }
                elsif ( $index >= 0 )
                {
                    $ANNO{$n}[$index][3] = 2 if ( $ANNO{$n}[$index][3] < 2 );
                    print "P($offset)\t";
                }
                else
                {
                    print "*\t";
                }
            }
            print "$tmp[0]\t";
            print "\[$ANNO{$n}[$index][0]-$ANNO{$n}[$index][1]\]"
              if ( exists $ANNO{$n} && $index >= 0 );
            print "\t";
            print join( "\t", @tmp[ 1 .. 3 ] ) . "\t";
            print "\[$ANNO{$n}[$index][2]\]"
              if ( exists $ANNO{$n} && $index >= 0 );
            print "\t$tmp[4]\t";
            print join( "\t", @tmp[ 11 .. 13 ] );
            print "\n";
        }
        else    #output table
        {
            if ( $row_count == 33 )
            {
                print '\hline' . "\n" . '\end{tabular}\\\\' . "\n";
                print '\begin{tabular}[t]{cccccccccc}' . "\n";
                print '\hline' . "\n";
                print "NO.&Result&CHR&Location&\\minitab[c]{LTR\\\\length}&";
                print
"\\minitab[c]{Inserted\\\\element\\\\length}&TSR&+/-&Score&Similarity\\\\\n\\hline\n";
            }
            $row_count++;
            print "$row_count$tab";
            if ( !exists $ANNO{$n} )
            {
                print "** $tab";
            }
            else
            {

                #$ANNO{$n}[$index][3]=1 if($ANNO{$n}[$index][3]==0);
                if ( $offset == 0
                    || ( ( $ANNO{$n}[$index][2] eq $tsr ) && ( $tsr ne "N" ) )
                  )    #match
                {
                    $ANNO{$n}[$index][3] = 3 if ( $ANNO{$n}[$index][3] < 3 );
                    print "C($offset)$tab";
                }
                elsif ( $index >= 0 )
                {
                    $ANNO{$n}[$index][3] = 2 if ( $ANNO{$n}[$index][3] < 2 );
                    print "P($offset)$tab";
                }
                else
                {
                    print "** $tab";
                }
            }
            $tmp[0] =~ /(\d+)/;
            print "$1$tab";
            print "\\minitab[c]{";
            if ( exists $ANNO{$n} && $index >= 0 )
            {
                print "\[$ANNO{$n}[$index][0]-$ANNO{$n}[$index][1]\]";
            }
            else
            {
                print "\[N-N\]";
            }
            print "\\\\";
            print "$tmp[1]";
            print "}$tab";

            print join( "$tab", @tmp[ 2 .. 3 ] ) . "$tab";

            print "\\minitab[c]{";
            if ( exists $ANNO{$n} && $index >= 0 )
            {
                print "\[$ANNO{$n}[$index][2]\]";
            }
            else
            {
                print "\[N\]";
            }
            print "\\\\";
            print "$tmp[4]";
            print "}$tab";

            print "\\minitab[c]{";
            if ( exists $ANNO{$n} && $index >= 0 )
            {
                print "\[$ANNO{$n}[$index][4]\]";
            }
            else
            {
                print "\[N\]";
            }
            print "$tmp[11]";
            print "}$tab";

            print "$tmp[12]($domain_score)$tab$tmp[14]";

            #print join("$tab",@tmp[11 .. 12]);
            print "\\\\";
            print "\n";

            #print "\\hline\n";
        }

        #print $_."\n";
        #print "$tmp[0] : $1 - $2 $Pscore{$tmp[0]}[$index]\n";
    }
}
if ( $tab eq "&" )
{
    print '\hline' . "\n" . '\end{tabular}' . "\n";
}

my $total_miss   = 0;
my $total_anno   = 0;
my $total_anno_c = 0;
my $total_anno_p = 0;
foreach ( keys %ANNO )
{
    for ( my $i = 0 ; $i < @{ $ANNO{$_} } ; ++$i )
    {
        $total_anno++;
        if ( $ANNO{$_}[$i][3] == 0 )
        {
            $total_miss++;
            warn
"Unpred: $_: $ANNO{$_}[$i][0]-$ANNO{$_}[$i][1],$ANNO{$_}[$i][2]\n";
        }
        if ( $ANNO{$_}[$i][3] == 2 )
        {
            $total_anno_p++;
            warn
"Partial: $_: $ANNO{$_}[$i][0]-$ANNO{$_}[$i][1],$ANNO{$_}[$i][2]\n";
        }
        if ( $ANNO{$_}[$i][3] == 3 )
        {
            $total_anno_c++;
        }

    }
}
warn
"Total Pred:$total_pred, Correct:$total_correct($direct_correct), Partial:$total_partial, No Support:$total_nd\n";
warn
"Total Anno:$total_anno, Correct:$total_anno_c, Partial:$total_anno_p, Unpred:$total_miss\n";

close FILE;

