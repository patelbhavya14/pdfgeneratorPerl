#!/usr/bin/perl

use strict;
use warnings;

use PDF::API2;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

print "Enter heading:\n";
my $input = <STDIN>;
chomp $input;

my ( $paragraph1, $paragraph2, $picture ) = get_data();

my $pdf = PDF::API2->new( -file => "$0.pdf" );

my $page = $pdf->page;
$page->mediabox( 105 / mm, 148 / mm );
#$page->bleedbox(  5/mm,   5/mm,  100/mm,  143/mm);
$page->cropbox( 7.5 / mm, 7.5 / mm, 97.5 / mm, 140.5 / mm );
#$page->artbox  ( 10/mm,  10/mm,   95/mm,  138/mm);

my %font = (
    Helvetica => {
        Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
        Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
        Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
    },
    Times => {
        Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
        Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
        Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
    },
);

my $blue_box = $page->gfx;
$blue_box->fillcolor('darkblue');
$blue_box->rect( 5 / mm, 125 / mm, 95 / mm, 18 / mm );
$blue_box->fill;

my $red_line = $page->gfx;
$red_line->strokecolor('red');
$red_line->move( 5 / mm, 125 / mm );
$red_line->line( 100 / mm, 125 / mm );
$red_line->stroke;

my $headline_text = $page->text;
$headline_text->font( $font{'Helvetica'}{'Bold'}, 18 / pt );
$headline_text->fillcolor('white');
$headline_text->translate( 95 / mm, 131 / mm );
$headline_text->text_right($input);

my $left_column_text = $page->text;
$left_column_text->font( $font{'Times'}{'Roman'}, 6 / pt );
$left_column_text->fillcolor('black');
my ( $endw, $ypos, $paragraph ) = text_block(
    $left_column_text,
    $paragraph1,
    -x        => 10 / mm,
    -y        => 119 / mm,
    -w        => 41.5 / mm,
    -h        => 110 / mm - 7 / pt,
    -lead     => 7 / pt,
    -parspace => 0 / pt,
    -align    => 'justify',
);

$left_column_text->font( $font{'Times'}{'Roman'}, 6 / pt );
$left_column_text->fillcolor('black');
( $endw, $ypos, $paragraph ) = text_block(
    $left_column_text,
    $paragraph2,
    -x => 10 / mm,
    -y => $ypos,
    -w => 41.5 / mm,
    -h => 110 / mm - ( 119 / mm - $ypos ),
    -lead     => 7 / pt,
    -parspace => 0 / pt,
    -align    => 'justify',
);

my $photo = $page->gfx;
die("Unable to find image file: $!") unless -e $picture;
my $photo_file = $pdf->image_jpeg($picture);
$photo->image( $photo_file, 54 / mm, 66 / mm, 41 / mm, 55 / mm );

my $right_column_text = $page->text;
$right_column_text->font( $font{'Times'}{'Roman'}, 6 / pt );
$right_column_text->fillcolor('black');
( $endw, $ypos, $paragraph ) = text_block(
    $right_column_text,
    $paragraph,
    -x        => 54 / mm,
    -y        => 62 / mm,
    -w        => 41.5 / mm,
    -h        => 54 / mm,
    -lead     => 7 / pt,
    -parspace => 0 / pt,
    -align    => 'justify',
    -hang     => "\xB7  ",
);

$pdf->save;
$pdf->end();

sub text_block {
    
    my $text_object = shift;
    my $text        = shift;
    
    my %arg = @_;
    
    
    my @paragraphs = split( /\n/, $text );
    
    
    my $space_width = $text_object->advancewidth(' ');
    
    my @words = split( /\s+/, $text );
    my %width = ();
    foreach (@words) {
        next if exists $width{$_};
        $width{$_} = $text_object->advancewidth($_);
    }
    
    $ypos = $arg{'-y'};
    my @paragraph = split( / /, shift(@paragraphs) );
    
    my $first_line      = 1;
    my $first_paragraph = 1;
    
    
    
    while ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) {
        
        unless (@paragraph) {
            last unless scalar @paragraphs;
            
            @paragraph = split( / /, shift(@paragraphs) );
            
            $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
            last unless $ypos >= $arg{'-y'} - $arg{'-h'};
            
            $first_line      = 1;
            $first_paragraph = 0;
        }
        
        my $xpos = $arg{'-x'};
        
        # while there's room on the line, add another word
        my @line = ();
        
        my $line_width = 0;
        if ( $first_line && exists $arg{'-hang'} ) {
            
            my $hang_width = $text_object->advancewidth( $arg{'-hang'} );
            
            $text_object->translate( $xpos, $ypos );
            $text_object->text( $arg{'-hang'} );
            
            $xpos       += $hang_width;
            $line_width += $hang_width;
            $arg{'-indent'} += $hang_width if $first_paragraph;
            
        }
        elsif ( $first_line && exists $arg{'-flindent'} ) {
            
            $xpos       += $arg{'-flindent'};
            $line_width += $arg{'-flindent'};
            
        }
        elsif ( $first_paragraph && exists $arg{'-fpindent'} ) {
            
            $xpos       += $arg{'-fpindent'};
            $line_width += $arg{'-fpindent'};
            
        }
        elsif ( exists $arg{'-indent'} ) {
            
            $xpos       += $arg{'-indent'};
            $line_width += $arg{'-indent'};
            
        }
        
        while ( @paragraph
            and $line_width + ( scalar(@line) * $space_width ) +
            $width{ $paragraph[0] } < $arg{'-w'} )
        {
            
            $line_width += $width{ $paragraph[0] };
            push( @line, shift(@paragraph) );
            
        }
        
        
        my ( $wordspace, $align );
        if ( $arg{'-align'} eq 'fulljustify'
        or ( $arg{'-align'} eq 'justify' and @paragraph ) )
        {
            
            if ( scalar(@line) == 1 ) {
                @line = split( //, $line[0] );
                
            }
            $wordspace = ( $arg{'-w'} - $line_width ) / ( scalar(@line) - 1 );
            
            $align = 'justify';
        }
        else {
            $align = ( $arg{'-align'} eq 'justify' ) ? 'left' : $arg{'-align'};
            
            $wordspace = $space_width;
        }
        $line_width += $wordspace * ( scalar(@line) - 1 );
        
        if ( $align eq 'justify' ) {
            foreach my $word (@line) {
                
                $text_object->translate( $xpos, $ypos );
                $text_object->text($word);
                
                $xpos += ( $width{$word} + $wordspace ) if (@line);
                
            }
            $endw = $arg{'-w'};
        }
        else {
            
            
            if ( $align eq 'right' ) {
                $xpos += $arg{'-w'} - $line_width;
                
            }
            elsif ( $align eq 'center' ) {
                $xpos += ( $arg{'-w'} / 2 ) - ( $line_width / 2 );
                
            }
            
            # render the line
            $text_object->translate( $xpos, $ypos );
            
            $endw = $text_object->text( join( ' ', @line ) );
            
        }
        $ypos -= $arg{'-lead'};
        $first_line = 0;
        
    }
    unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);
    
    return ( $endw, $ypos, join( "\n", @paragraphs ) )
    
}

sub get_data {
    print "Enter details for first paragraph:\n";
    my $para1 = <STDIN>;
    chomp $para1;
    
    print "Enter details for second paragraph:\n";
    my $para2 = <STDIN>;
    chomp $para2;
    
    print "Enter image name:\n";
    my $img = <STDIN>;
    chomp $img;
    (
    qq|$para1|,

    qq|$para2|,

    "./$img"
    );
}
