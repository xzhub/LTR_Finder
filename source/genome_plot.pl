#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  genome_plot.pl
#
#        USAGE:  ./genome_plot.pl
#
#  DESCRIPTION:  draw genome in a pic, with detail reserved.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  2006年12月24日 10时17分47秒 CST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use GD;

if ( @ARGV < 1 )
{
    print "usage:$0 data_file pic_dir\n";
    exit 0;
}
my ( $block_split_len, $block_flank_len, $min_gap_pixel, $scale ) =
  ( 10, 2, 3, 1 );    #this will be changed later
my ( $x_margin, $y_margin ) = ( 50,  50 );
my ( $max_x,    $max_y )    = ( 800, 400 );
my $show_axis = 0;
my ( $pipe_height, $text_y_offset, $text_x_offset, $exon_height ) =
  ( 80, 15, 0, 11 );
my ( $txt_width, $txt_height ) =
  ( gdMediumBoldFont->width, gdMediumBoldFont->height );
my ( $s_txt_width, $s_txt_height ) =
  ( gdSmallFont->width, gdSmallFont->height );
my ( $x, $y );

#($w,$h) = (gdLargeFont->width,gdLargeFont->height);
my @meta_data;           #each region
my @data;                #[name,pos1,pos2..]
my @block;               #[begin,end,start_pixel]
my @pipe;                #[begin,end,pipe_id]
my @used_text_region;    #[lx,ly,rx,ry], rec used text region
my @TextAll;
my ( $pre_pipe, $total_pipe ) = ( 1, 1 );

#[label,line_to,begin,end]

my $im;
my (
    $White,   $Black,   $Gray,    $Silver,  $Red,        $Green,
    $Blue,    $Yellow,  $Purple,  $Olive,   $Navy,       $Aqua,
    $Lime,    $Maroon,  $Teal,    $Fuchsia, $DodgerBlue, $Color_A,
    $Color_T, $Color_G, $Color_C, $Color_X
);
my %element_color;

my $data_file = "/dev/stdin";
my $outdir    = $ARGV[0];
if ( @ARGV >= 2 )
{
    $data_file = $ARGV[0];
    $outdir    = $ARGV[1];
}

open( FILE, "$data_file" ) || die $!;
$/ = '>';
<FILE>;
my $curr_name;
my $total_count = 0;
while (<FILE>)
{
    $/ = "\n";
    $_ =~ s/\s*>$//s;
    if ( $_ !~ /\n/ )
    {
        $/ = '>';
        next;
    }
    $total_count++;
    ClearData();
    $curr_name = ReadInData($_);    #fill in meta_data and data
                                    #warn "$curr_name\n";

    #find a good pic size
    my $sc = 1;
    ( $block_split_len, $block_flank_len, $min_gap_pixel, $scale ) =
      ( 40, 4, 4, 1 );
    ClusterData();                  #fill @block
    if ( $max_x > 800 )             #get a smaller size
    {
        @block = ();
        ( $block_split_len, $block_flank_len, $min_gap_pixel, $scale ) =
          ( 20, 2, 2, 1 );
        ClusterData();              #fill @block
        $sc = 2;
    }
    if ( $max_x > 1600 )            #tiny size
    {
        @block = ();
        ( $block_split_len, $block_flank_len, $min_gap_pixel, $scale ) =
          ( 10, 1, 1, 1 );
        ClusterData();              #fill @block
        $sc = 3;
        $max_x += $x_margin;
        $max_y += $y_margin;
        $x_margin = $x_margin * 1.5;
        $y_margin = $y_margin * 1.5;
    }
    ( $x, $y ) = ( $x_margin, $max_y - $y_margin );    #zero-point
    InitPic( $max_x, $max_y + 10 );
    InitColor();

    #DrawText(0,0,'lt',0,$sc);
    Draw();
    RealAttachText();
    open( OUT, ">$outdir/$total_count.png" ) || die $!;
    print OUT $im->png;
    close(OUT);
    $/ = '>';
}
close FILE;

#########################################
#########################################
sub ClearData
{
    @meta_data        = ();    #each region
    @data             = ();    #[name,pos1,pos2..]
    @block            = ();    #[begin,end,start_pixel]
    @pipe             = ();    #[begin,end,pipe_id]
    @used_text_region = ();    #[lx,ly,rx,ry], rec used text region
    %element_color    = ();

    #warn "element :".(keys %element_color)."\n";
}

sub Draw
{

    #draw block
    my $y_pixel = $y;
    if ($show_axis)
    {
        $im->line(
            $block[0][2],
            $y_pixel + 0.2 * $pipe_height,
            ( $block[-1][1] - $block[-1][0] ) * $scale + $block[-1][2],
            $y_pixel + 0.2 * $pipe_height,
            $element_color{'underline'}
        );
    }
    DrawText( $x_margin * 0.5, $y_margin * 0.5, 'lb', 0, "Fig: " . $curr_name );
    foreach (@block)
    {
        my $begin_pixel = $$_[2];
        my $end_pixel   = ( $$_[1] - $$_[0] ) * $scale + $begin_pixel;

        #warn" draw $begin_pixel,$y_pixel,$end_pixel,$y_pixel-5*$pipe_height\n";
        $im->filledRectangle( $begin_pixel, $y_margin, $end_pixel,
            $y_pixel + 0.5 * $pipe_height - 1,
            $element_color{'Block'} );    #$Yellow);
        if ($show_axis)
        {
            $im->line(
                $begin_pixel,
                $y_pixel + 0.2 * $pipe_height - 1,
                $begin_pixel,
                $y_pixel + 0.2 * $pipe_height - 3,
                $element_color{'underline'}
            );
            DrawText( $begin_pixel, $y_pixel + 0.2 * $pipe_height,
                'ct', 0, $$_[0], 2 );
            $im->line(
                $end_pixel, $y_pixel + 0.2 * $pipe_height - 1,
                $end_pixel,
                $y_pixel + 0.2 * $pipe_height - 3,
                $element_color{'underline'}
            );
            DrawText( $end_pixel, $y_pixel + 0.2 * $pipe_height,
                'ct', 0, $$_[1], 2 );
        }
    }

    foreach (@data)
    {
        my $label = $$_[0];
        my @pos   = @$_;
        shift @pos;
        my $signal = shift @pos;

        #print join(",",@pos)."\n";
        my $curr_pipe = FindVaildPipe( $pos[0], $pos[-1] );
        $pre_pipe = $curr_pipe;
        push @pipe, [ $pos[0], $pos[-1], $curr_pipe ];    #rec this pipe
               #warn "pipe: $curr_pipe\n";

        my ( $begin_pixel, $end_pixel, $y_pixel );
        my $begin   = $pos[0];
        my $end     = $pos[-1];
        my $block_b = FindBlock($begin);
        my $block_e = FindBlock($end);
        $begin_pixel =
          ( $begin - $block[$block_b][0] ) * $scale + $block[$block_b][2];
        $end_pixel =
          ( $end - $block[$block_e][0] ) * $scale + $block[$block_e][2];
        $y_pixel = $y - $curr_pipe * $pipe_height;
        push @used_text_region,
          [
            $begin_pixel + 1,
            $y_pixel - $exon_height + 1,
            $end_pixel - 1,
            $y_pixel - 1
          ];    #don't draw text on Exon
        DrawSignal( $signal, $curr_pipe );
        DrawText( $begin_pixel, $y_pixel - $exon_height,
            'lb', $end_pixel - $begin_pixel + 1, $label );

        #DrawText($begin_pixel,$y_pixel,'rt',$end_pixel-$begin_pixel+1,$begin);
        #DrawText($end_pixel,$y_pixel,'lt',$end_pixel-$begin_pixel+1,$end);
        DrawText( $begin_pixel, $y_pixel, 'rt', 0, $begin );
        DrawText( $end_pixel,   $y_pixel, 'lt', 0, $end );
        for ( my $i = 0 ; $i < @pos - 1 ; $i += 2 )
        {
            if ( $i != 0 )
            {
                my $pre_end = $end_pixel;
                ( $begin_pixel, $end_pixel, $y_pixel ) =
                  DrawExon( $pos[$i], $pos[ $i + 1 ], $curr_pipe, '' );
                DrawLengthLine(
                    $pre_end, $begin_pixel, $y_pixel,
                    $pos[$i] - $pos[ $i - 1 ] + 1,
                    $element_color{'Intron'}, $Black
                );
            }
            else
            {
                ( $begin_pixel, $end_pixel, $y_pixel ) =
                  DrawExon( $pos[$i], $pos[ $i + 1 ], $curr_pipe, '' );
            }
        }
    }
}

sub DrawSignal
{
    my ( $str, $p ) = @_;
    my @sig = split( /,|;/, $str );
    for ( my $i = 0 ; $i < @sig - 2 ; $i += 3 )
    {
        my $id      = $sig[ $i + 2 ];
        my $begin   = $sig[$i];
        my $end     = $sig[ $i + 1 ];
        my $block_b = FindBlock($begin);
        my $block_e = FindBlock($end);
        my $begin_pixel =
          ( $begin - $block[$block_b][0] ) * $scale + $block[$block_b][2];
        my $end_pixel =
          ( $end - $block[$block_e][0] ) * $scale + $block[$block_e][2];
        my $y_pixel = $y - $p * $pipe_height;
        DrawOneSignal( $begin_pixel, $end_pixel, $y_pixel, $id );
    }
}

sub DrawOneSignal
{
    my ( $begin_pixel, $end_pixel, $y_pixel, $id ) = @_;
    if ( $id eq 'PBS' || $id eq 'PPT' || $id eq 'TSR' )
    {
        $im->arc(
            0.5 * ( $begin_pixel + $end_pixel ),
            $y_pixel - 0.5 * $exon_height,
            $end_pixel - $begin_pixel + 1,
            $exon_height,
            0,
            360,
            $element_color{$id}
        );
        $im->fill(
            0.5 * ( $begin_pixel + $end_pixel ),
            $y_pixel - 0.5 * $exon_height,
            $element_color{$id}
        );
    }
    else
    {
        if ( exists $element_color{$id} )
        {
            $im->filledRectangle( $begin_pixel, $y_pixel - $exon_height,
                $end_pixel, $y_pixel, $element_color{$id} );
        }
        else
        {
            $im->filledRectangle( $begin_pixel, $y_pixel - $exon_height,
                $end_pixel, $y_pixel, $element_color{'RH'} );
        }

        if ( exists $element_color{$id} )
        {

      #DrawText(0.5*($begin_pixel+$end_pixel),$y_pixel-$exon_height,'cb',0,$id);
            DrawText( 0.5 * ( $begin_pixel + $end_pixel ),
                $y_pixel, 'ct', 0, $id );
        }
        else
        {

    #DrawText(0.5*($begin_pixel+$end_pixel),$y_pixel-$exon_height,'cb',0,$id,1);
            DrawText( 0.5 * ( $begin_pixel + $end_pixel ),
                $y_pixel, 'ct', 0, $id, 1 );
        }

    }
}

sub DrawExon
{
    my ( $begin, $end, $p, $str ) = @_;
    my $block_b = FindBlock($begin);
    my $block_e = FindBlock($end);

    #warn "block: $block_b, $block_e\n";
    if ( $block_b == $block_e )    #draw full exon
    {
        my $begin_pixel =
          ( $begin - $block[$block_b][0] ) * $scale + $block[$block_b][2];
        my $end_pixel =
          ( $end - $block[$block_b][0] ) * $scale + $block[$block_b][2];
        my $y_pixel = $y - $p * $pipe_height;
        $im->rectangle( $begin_pixel, $y_pixel, $end_pixel,
            $y_pixel - $exon_height,
            $element_color{'Exon'} );
        if ($str)
        {

            #lb-LeftBottom lt-LeftTop rb-RightBottom rt-RightTop
            DrawText( $begin_pixel, $y_pixel - $exon_height,
                'lb', $end_pixel - $begin_pixel + 1, $str );

            #$im->string(gdMediumBoldFont,$begin_pixel-$text_x_offset,
            #    $y_pixel-$exon_height-$text_y_offset,$str,$Black);
        }
        DrawLengthLine(
            $begin_pixel, $end_pixel,
            $y_pixel - $exon_height * 0.5,
            $end - $begin + 1,
            -1, $Blue
        );
        return ( $begin_pixel, $end_pixel, $y_pixel - $exon_height * 0.5 );
    }
    else    #diff block
    {
        my $begin_pixel =
          ( $begin - $block[$block_b][0] ) * $scale + $block[$block_b][2];
        my $end_pixel =
          ( $block[$block_b][1] - $block[$block_b][0] ) * $scale +
          $block[$block_b][2];
        my $y_pixel = $y - $p * $pipe_height;
        my ( $b_p, $e_p );
        $b_p = $begin_pixel;
        $im->line( $begin_pixel, $y_pixel, $end_pixel, $y_pixel,
            $element_color{'Exon'} );
        $im->line(
            $begin_pixel, $y_pixel - $exon_height,
            $end_pixel, $y_pixel - $exon_height,
            $element_color{'Exon'}
        );
        $im->line( $begin_pixel, $y_pixel, $begin_pixel,
            $y_pixel - $exon_height,
            $element_color{'Exon'} );

        $begin_pixel = $block[$block_e][2];
        $end_pixel =
          ( $end - $block[$block_e][0] ) * $scale + $block[$block_e][2];
        $e_p = $end_pixel;
        $im->line( $begin_pixel, $y_pixel, $end_pixel, $y_pixel,
            $element_color{'Exon'} );
        $im->line(
            $begin_pixel, $y_pixel - $exon_height,
            $end_pixel, $y_pixel - $exon_height,
            $element_color{'Exon'}
        );
        $im->line( $end_pixel, $y_pixel, $end_pixel, $y_pixel - $exon_height,
            $element_color{'Exon'} );

        if ($str)
        {

            #text pos, align mode, max len, string
            DrawText( $b_p, $y_pixel - $exon_height, 'lb', 0, $str );
        }

        DrawLengthLine(
            $b_p, $e_p,
            $y_pixel - $exon_height * 0.5,
            $end - $begin + 1,
            -1, $Blue
        );
        return ( $b_p, $e_p, $y_pixel - $exon_height * 0.5 );
    }
}

sub FindBlock
{
    my ($pos) = @_;
    for ( my $i = 0 ; $i < @block ; ++$i )
    {
        if ( $block[$i][0] <= $pos && $block[$i][1] >= $pos )
        {
            return $i;
        }
    }
    return -1;
}

sub DrawLengthLine
{
    my ( $begin_pixel, $end_pixel, $y_pixel, $length, $color, $t_color ) = @_;
    $begin_pixel++;
    $end_pixel--;
    my $mid = 0.5 * ( $end_pixel + $begin_pixel );
    if (
        length($length) * $s_txt_width <
        $end_pixel - $begin_pixel )    #long enough
    {
        $im->line( $begin_pixel, $y_pixel,
            $mid - 0.6 * length($length) * $s_txt_width,
            $y_pixel, $color )
          if ( $color != -1 );
        $im->line( $end_pixel, $y_pixel,
            $mid + 0.5 * length($length) * $s_txt_width,
            $y_pixel, $color )
          if ( $color != -1 );

        #$im->string(gdMediumBoldFont,$mid-0.5*length($length)*$txt_width+1,
        #        $y_pixel-6,$length,$t_color);
        #  cb-CenterBottom
        DrawText( $mid, $y_pixel, 'cm', 0, $length, 1 );
    }
    else    #short
    {
        $im->line( $begin_pixel, $y_pixel, $end_pixel, $y_pixel, $color )
          if ( $color != -1 );

        #$im->string(gdMediumBoldFont,$mid-0.5*length($length)*$txt_width+1,
        #        $y_pixel+5,$length,$t_color);
        #   ct-CenterTop
        DrawText( $mid, $y_pixel + 6, 'ct', 0, $length, 1 );
    }
}

sub DrawText
{    #l,c,r   t,m,b
    my ( $tx, $ty, $align_mode, $max_length, $txt, $use_small ) = @_;
    my $txt_block_height;
    my $txt_block_width;
    my @tmp_str;
    my ( $curr_txt_width, $curr_txt_height );
    my $small = 0;
    my $i;
    if ( defined $use_small && $use_small )
    {
        $small = $use_small;
    }

    if ( $small == 1 )
    {
        ( $curr_txt_width, $curr_txt_height ) =
          ( gdSmallFont->width, gdSmallFont->height );
    }
    elsif ( $small == 2 )
    {
        ( $curr_txt_width, $curr_txt_height ) =
          ( gdTinyFont->width, gdTinyFont->height );
    }
    else
    {
        ( $curr_txt_width, $curr_txt_height ) =
          ( gdMediumBoldFont->width, gdMediumBoldFont->height );
    }

    if ( $max_length > 0 && length($txt) * $curr_txt_width > $max_length )
    {
        my $char_num = int( $max_length / $curr_txt_width );
        my $b        = 0;
        my $e        = 0;
        for ( $i = 1 ; $i < length($txt) ; ++$i )
        {
            if ( ( $i - $b ) >= $char_num )
            {
                my $add = "";

                #add '-' at line end
                if ( $e <= $b )
                {
                    $e = $b + $char_num;

                    #    $add='-';
                }
                push @tmp_str, substr( $txt, $b, $e - $b + 1 ) . $add;
                $b = $e + 1;
                $e = $i;
            }

            if ( substr( $txt, $i, 1 ) =~ / |,|;|:|]|\)/ )
            {
                if ( ( $i - $b ) >= $char_num && ( $e - $b ) <= $char_num )
                {
                    push @tmp_str, substr( $txt, $b, $e - $b + 1 );
                    $b = $e + 1;
                    $e = $i;
                }
                elsif ( ( $i - $b ) <= $char_num )
                {
                    $e = $i;
                }
            }

            if ( substr( $txt, $i, 1 ) =~ /\[|\(/ )
            {
                $e = $i - 1;
            }

        }
        if ( $b < length($txt) )
        {
            push @tmp_str, substr( $txt, $b );
        }

        if ( @tmp_str > 3 )
        {
            $#tmp_str = 2;
            substr( $tmp_str[2], length( $tmp_str[2] ) - 1 ) = ".";
        }

        my $real_txt_max_count = 0;
        foreach my $each_line (@tmp_str)
        {
            $each_line =~ s/\s+$//;
            $each_line =~ s/^\s+//;
            if ( $real_txt_max_count < length($each_line) )
            {
                $real_txt_max_count = length($each_line);
            }
        }

        $txt_block_height = ( $#tmp_str + 1 ) * ($curr_txt_height);
        $txt_block_width = $real_txt_max_count * $curr_txt_width;
    }
    else
    {
        push @tmp_str, $txt;
        $txt_block_height = ($curr_txt_height);
        $txt_block_width  = length($txt) * $curr_txt_width;
    }

    my ( $txt_block_lx, $txt_block_ly );
    my ( $txt_block_rx, $txt_block_ry );
    if ( $align_mode =~ /l/ )
    {
        $txt_block_lx = $tx;
        $txt_block_rx = $tx + $txt_block_width;
    }
    elsif ( $align_mode =~ /c/ )
    {
        $txt_block_lx = $tx - 0.5 * $txt_block_width;
        $txt_block_rx = $tx + 0.5 * $txt_block_width;
    }
    elsif ( $align_mode =~ /r/ )
    {
        $txt_block_lx = $tx - $txt_block_width;
        $txt_block_rx = $tx;
    }

    if ( $align_mode =~ /t/ )
    {
        $txt_block_ly = $ty;
        $txt_block_ry = $ty + $txt_block_height;
    }
    elsif ( $align_mode =~ /m/ )
    {
        $txt_block_ly = $ty - 0.5 * $txt_block_height;
        $txt_block_ry = $ty + 0.5 * $txt_block_height;
    }
    elsif ( $align_mode =~ /b/ )
    {
        $txt_block_ly = $ty - $txt_block_height - 1;
        $txt_block_ry = $ty;
    }

    my ( $offset_x, $offset_y ) = FindTxtRegion(
        $txt_block_lx, $txt_block_ly, $txt_block_rx,
        $txt_block_ry, \$align_mode
    );
    $txt_block_lx += $offset_x;
    $txt_block_rx += $offset_x;
    $txt_block_ly += $offset_y;
    $txt_block_ry += $offset_y;
    for ( $i = 0 ; $i < @tmp_str ; ++$i )
    {

        if ( $small == 1 )
        {

            #$im->string(gdSmallFont,$txt_block_lx,
            #       $txt_block_ly+$i*$curr_txt_height,$tmp_str[$i],$Black);
            push @TextAll,
              [
                gdSmallFont,                           $txt_block_lx,
                $txt_block_ly + $i * $curr_txt_height, $tmp_str[$i],
                $Black
              ];
        }
        elsif ( $small == 2 )
        {

            #$im->string(gdTinyFont,$txt_block_lx,
            #       $txt_block_ly+$i*$curr_txt_height,$tmp_str[$i],$Black);
            push @TextAll,
              [
                gdTinyFont,                            $txt_block_lx,
                $txt_block_ly + $i * $curr_txt_height, $tmp_str[$i],
                $Black
              ];
        }
        else
        {

            #$im->string(gdMediumBoldFont,$txt_block_lx,
            #       $txt_block_ly+$i*$curr_txt_height,$tmp_str[$i],$Black);
            push @TextAll,
              [
                gdMediumBoldFont,                      $txt_block_lx,
                $txt_block_ly + $i * $curr_txt_height, $tmp_str[$i],
                $Black
              ];
        }
    }

    if ( $offset_x != 0 || $offset_y != 0 )
    {
        my $line_y;
        if ( $align_mode =~ /t/ )
        {
            $line_y = $txt_block_ly;
        }
        else    #if($align_mode=~/b/)
        {
            $line_y = $txt_block_ry;
        }
        $im->line( $txt_block_lx, $line_y, $txt_block_rx, $line_y,
            $element_color{'underline'} );
        my $line_x;
        if ( $align_mode =~ /l/ )
        {
            $line_x = $txt_block_lx;
        }
        elsif ( $align_mode =~ /r/ )
        {
            $line_x = $txt_block_rx;
        }
        elsif ( $align_mode =~ /c/ )
        {
            $line_x = 0.5 * ( $txt_block_rx + $txt_block_lx );
        }

        $im->line( $line_x, $line_y, $tx, $ty, $element_color{'underline'} );
    }
}

sub RealAttachText
{
    foreach (@TextAll)
    {
        $im->string( @{$_} );
    }
    @TextAll = ();
}

sub FindTxtRegion
{
    my ( $a, $b, $c, $d, $r_mode ) = @_;
    my ( $offset_x, $offset_y ) = ( 0, 0 );
    my ( $ox, $oy );
    my @ori_pos = ( $a, $b, $c, $d );
    my $good = 0;
    for ( my $i = 0 ; $i < 4 ; ++$i )
    {
        ( $ox, $oy ) = FindUnusedTxtRegion( $a, $b, $c, $d, $r_mode );
        if ( $ox != 0 || $oy != 0 )
        {
            $a += $ox;
            $c += $ox;
            $b += $oy;
            $d += $oy;
        }
        else
        {
            $good = 1;
            last;
        }
        $offset_x += $ox;
        $offset_y += $oy;
    }
    if ( $good == 0 )    #not found good place
    {
        ( $a, $b, $c, $d ) = @ori_pos;
        $$r_mode =~ tr/t/b/;    #change align mode, only change 't' yo 'b'
        ( $offset_x, $offset_y ) = ( 0, 0 );
        for ( my $i = 0 ; $i < 10 ; ++$i )
        {
            ( $ox, $oy ) = FindUnusedTxtRegion( $a, $b, $c, $d, $r_mode );
            if ( $ox != 0 || $oy != 0 )
            {
                $a += $ox;
                $c += $ox;
                $b += $oy;
                $d += $oy;
            }
            else
            {
                $good = 1;
                last;
            }
            $offset_x += $ox;
            $offset_y += $oy;
        }
    }
    push @used_text_region,
      [ $a - 0.5 * $txt_width, $b, $c + 0.5 * $txt_width, $d ];
    return ( $offset_x, $offset_y );    #return one, even not find a good place
}

sub FindUnusedTxtRegion
{
    my ( $a, $b, $c, $d, $r_mode ) = @_;
    my ( $offset_x, $offset_y ) = ( 0, 0 );
    foreach (@used_text_region)
    {
        if ( $a > $$_[2] || $c < $$_[0] )
        {
            next;
        }
        if ( $b > $$_[3] || $d < $$_[1] )
        {
            next;
        }

        if ( $$r_mode =~ /t/ )
        {
            $offset_y = $$_[3] + 2 - $b;
        }
        elsif ( $$r_mode =~ /b/ )
        {
            $offset_y = $$_[1] - 2 - $d;
        }
        elsif ( $$r_mode =~ /l/ )
        {
            $offset_x = $$_[2] + 2 - $a;
        }
        elsif ( $$r_mode =~ /r/ )
        {
            $offset_x = $$_[0] - 2 - $c;
        }
    }
    return ( $offset_x, $offset_y );
}

sub FindVaildPipe
{
    my ( $begin, $end ) = @_;
    for ( my $i = 0 ; $i < 1000 ; ++$i )
    {
        my $flag = 0;
        foreach (@pipe)
        {
            if ( $$_[0] <= $end && $$_[1] >= $begin && $i == $$_[2] )
            {
                $flag = 1;
                last;
            }
        }
        if ( $flag == 0 )
        {

            #if($pre_pipe==0 && $total_pipe>4 && $i==0)
            #{
            #    return 3;
            #}
            #else

            #find if exon lay on a txt
            my $block_b = FindBlock($begin);
            my $block_e = FindBlock($end);
            my $begin_pixel =
              ( $begin - $block[$block_b][0] ) * $scale + $block[$block_b][2];
            my $end_pixel =
              ( $end - $block[$block_e][0] ) * $scale + $block[$block_e][2];
            my $y_pixel = $y - $i * $pipe_height;

#push @used_text_region,[$begin_pixel+1,$y_pixel-$exon_height+1,$end_pixel-1,$y_pixel-1];
            my $mode = 'lt';
            my ( $ox, $oy ) = FindUnusedTxtRegion(
                $begin_pixel + 1,
                $y_pixel - $exon_height + 1,
                $end_pixel - 1,
                $y_pixel - 1, \$mode
            );
            if ( $ox == 0 && $oy == 0 )
            {
                return $i;
            }
            else
            {
                next;
            }
        }
    }
    return -1;
}

sub ClusterData
{
    @meta_data = sort { $a <=> $b } @meta_data;
    my $tmp         = 0;
    my $start_pixel = $x_margin;
    my $gap_pixel   = 0;

    my $max_x_pixel;

    my @block_tmp;
    push @block_tmp, $meta_data[0];
    for ( my $i = 0 ; $i < @meta_data ; ++$i )
    {
        if ( $meta_data[$i] - $meta_data[ $i - 1 ] - 1 > $block_split_len )
        {
            push @block_tmp, $meta_data[ $i - 1 ];
            push @block_tmp, $meta_data[$i];
        }
    }
    push @block_tmp, $meta_data[-1];

    for ( my $i = 0 ; $i < @block_tmp - 1 ; $i += 2 )
    {
        my $begin = $block_tmp[$i] - $block_flank_len;
        my $end   = $block_tmp[ $i + 1 ] + $block_flank_len;
        if ( $begin < 0 )
        {
            $begin = 0;
        }
        my $gap = 0;
        if ( $i != 0 )
        {
            $gap = $end - $block[-1][1] - 1;
            $start_pixel =
              ( $block[-1][1] - $block[-1][0] + 1 ) * $scale + $block[-1][2];
        }
        $gap_pixel = $min_gap_pixel;
        $gap_pixel = log($gap) / log($block_split_len) * $min_gap_pixel
          if ( $gap > $block_split_len );
        push @block, [ $begin, $end, $start_pixel + $gap_pixel ];
        $max_x_pixel =
          ( $end - $begin ) * $scale + $start_pixel + $gap_pixel + $x_margin;
    }
    $max_x = $max_x_pixel;

    #find max_y
    @data = sort { $$a[2] <=> $$b[2] } @data;
    my $max_pipe = 1;
    for ( my $i = 0 ; $i < @data - 1 ; ++$i )
    {
        my $count = 1;
        for ( my $j = $i + 1 ; $j < @data ; ++$j )
        {
            if ( $data[$j][2] <= $data[$i][-1] )    #overlap
            {
                $count++;
            }
            if ( $count > $max_pipe )
            {
                $max_pipe = $count;
            }
            if ( $data[$j][2] > $data[$i][-1] )
            {
                last;
            }
        }
    }
    $total_pipe = $max_pipe;

    #warn "block count $max_pipe\n";
    $max_y = ($max_pipe) * $pipe_height + $y_margin;
}

sub InitPic
{
    my ( $Width, $Height ) = @_;

    # create a new GIF
    $im = new GD::Image( $Width + 1, $Height + 1 );

    my $Colors = 256;

    # require 'color_palette.pl';
    # ini colors palette
    (
        $White,   $Black,   $Gray,    $Silver,  $Red,        $Green,
        $Blue,    $Yellow,  $Purple,  $Olive,   $Navy,       $Aqua,
        $Lime,    $Maroon,  $Teal,    $Fuchsia, $DodgerBlue, $Color_A,
        $Color_T, $Color_G, $Color_C, $Color_X
      )
      = (
        $im->colorAllocate( 0xFF, 0xFF, 0xFF ),    # White
        $im->colorAllocate( 0,    0,    0 ),       # Black
        $im->colorAllocate( 0x80, 0x80, 0x80 ),    # Gray
        $im->colorAllocate( 0xC0, 0xC0, 0xC0 ),    # Silver
        $im->colorAllocate( 0xFF, 0,    0 ),       # Red
        $im->colorAllocate( 0x00, 0x80, 0x00 ),    # Green
        $im->colorAllocate( 0,    0,    0xFF ),    # Blue
        $im->colorAllocate( 0xFF, 0xFF, 0x00 ),    # Yellow
        $im->colorAllocate( 0x80, 0,    0x80 ),    # Purple
        $im->colorAllocate( 0x80, 0x80, 0x00 ),    # Olive
        $im->colorAllocate( 0,    0,    0x80 ),    # Navy
        $im->colorAllocate( 0,    0xFF, 0xFF ),    # Aqua
        $im->colorAllocate( 0,    0xFF, 0 ),       # Lime
        $im->colorAllocate( 0x80, 0,    0 ),       # Maroon
        $im->colorAllocate( 0,    0x80, 0x80 ),    # Teal
        $im->colorAllocate( 0xFF, 0,    0xFF ),    # Fuchsia

        $im->colorAllocate( 0x1E, 0x90, 0xFF ),    # DodgerBlue
        $im->colorAllocate( 0xFF, 0,    0 ),       # Color_A
        $im->colorAllocate( 0xFF, 0xFF, 0 ),       # Color_T
        $im->colorAllocate( 0,    0,    0xFF ),    # Color_G
        $im->colorAllocate( 0,    0xFF, 0xFF ),    # Color_C
        $im->colorAllocate( 0xFF, 0xFF, 0xFF )     # Color_X
      );

    #for(my $i = 0; $i<$Colors; $i++) { $im->colorAllocate($i, $i,$i);}

    #	$im->transparent($White);
    $im->transparent(-1);

    #	$im->interlaced(1);			#  cool venetian blinds effect
}

sub InitColor
{
    $element_color{'Exon'}      = $Blue;
    $element_color{'Intron'}    = $Red;
    $element_color{'underline'} = $im->colorAllocate( 0x66, 0x99, 0xFF );
    $element_color{'RT'}        = $im->colorAllocate( 0x66, 0xcc, 0xFF )
      ;    #$im->colorAllocate(0x33,0x66,0x99);
    $element_color{'IN(core)'}   = $im->colorAllocate( 0xFF, 0xCC, 0x66 );
    $element_color{'IN(c-term)'} = $im->colorAllocate( 0xFF, 0x66, 0xCC );
    $element_color{'RH'}         = $im->colorAllocate( 0xCC, 0x66, 0xFF );
    $element_color{'TSR'}        = $im->colorAllocate( 0x99, 0x33, 0x33 );
    $element_color{'PBS'}        = $im->colorAllocate( 0x66, 0x99, 0xCC );
    $element_color{'PPT'}        = $im->colorAllocate( 0xCC, 0xCC, 0x66 );
    $element_color{'Start'}      = $im->colorAllocate( 0x99, 0xCC, 0x66 );
    $element_color{'Stop'}       = $im->colorAllocate( 0xCC, 0x99, 0x66 );
    $element_color{'Block'} = $im->colorAllocate( 0xF0, 0xF0, 0xF0 );    #  Back

}

sub ReadInData
{
    my ($str) = @_;
    my @array = split( "\n", $str );
    my $name = shift @array;
    foreach (@array)
    {
        chomp $_;
        my @t = split( "\t", $_ );

        #my @pos=split(";",$t[0]);
        #foreach(@pos)
        #{
        #    my @p=split(",",$_);
        #    push @meta_data,[@p];
        #}

        my @pos = split( /,|;/, $t[0] );
        push @data, [ $t[1], $t[2], @pos ];
        push @meta_data, @pos;
        @pos = split( /,|;/, $t[2] );
        for ( my $i = 0 ; $i < @pos - 2 ; $i += 3 )
        {
            push @meta_data, $pos[$i];
            push @meta_data, $pos[ $i + 1 ];
        }
    }
    return $name;
}
