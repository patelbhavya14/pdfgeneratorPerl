#!/usr/bin/perl

use strict;
use warnings;

use PDF::API2;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

my ($picture) = get_data();

my $pdf = PDF::API2->new( -file => "$0.pdf" );

my $page = $pdf->page;
$page->mediabox( 105 / mm, 148 / mm );
$page->cropbox( 7.5 / mm, 7.5 / mm, 97.5 / mm, 140.5 / mm );

my $photo = $page->gfx;
die("Unable to find image file: $!") unless -e $picture;
my $photo_file = $pdf->image_jpeg($picture);
$photo->image( $photo_file, 7.5 / mm, 7.5 / mm, 97.5 / mm, 140.5 / mm );

$pdf->save;
$pdf->end();

sub get_data {
    print "Enter image name:\n";
    my $img = <STDIN>;
    chomp $img;
    (
    "./$img"
    );
}
