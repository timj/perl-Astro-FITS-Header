package Astro::FITS::Header::CFITSIO;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::FITS::Header::CFITSIO

#  Purposes:
#    Sub-class of Astro::FITS::Header, reads and write to FITS files

#  Language:
#    Perl object

#  Description:
#    This module sub-classes Astro::FITS::Header, which wraps a FITS 
#    header block as a perl object as a hash containing an array of
#    FITS::Header::Items and a lookup hash for the keywords. This 
#    sub-class allows direct read and write from a raw FITS HDU on
#    disk.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id$

#  Copyright:
#     Copyright (C) 2001 Particle Physics and Astronomy Research Council. 
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::Header::CFITSIO - Manipulates FITS headers from a FITS file

=head1 SYNOPSIS

  use Astro::FITS::Header::CFITSIO;
  
  $header = new Astro::FITS::Header::CFITSIO( Cards => \@array );
  $header = new Astro::FITS::Header::CFITSIO( File => $file );
  $header = new Astro::FITS::Header::CFITSIO( fitsID => $ifits );

  $header->writehdr( File => $file );
  $header->writehdr( fitsID => $ifits );

=head1 DESCRIPTION

This module makes use of the L<CFITSIO|CFITSIO> module to read and write 
directly to a FITS HDU.

It stores information about a FITS header block in an object. Takes an hash as an arguement, with either an array reference pointing to an array of FITS header cards, or a filename, or (alternatively) and FITS identifier.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::FITS::Header::Item;
use base qw/ Astro::FITS::Header /;

use CFITSIO qw / :longnames :constants /;
use Carp;

'$Revision$ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<configure>

Reads a FITS header from a FITS HDU

  $header->configure( Cards => \@cards );
  $header->configure( fitsID => $ifits );
  $header->configure( File => $file );

Accepts an FITS identifier or a filename. If both fitsID and File keys
exist, fitsID key takes priority.

=cut

sub configure {
  my $self = shift;
  
  my %args = @_;
  
  # itialise the inherited status to OK.  
  my $status = 0;
  my $ifits;

  return $self->SUPER::configure(%args) if exists $args{Cards};
  
  # read the args hash
  if (exists $args{fitsID}) {
     $ifits = $args{fitsID};
  } elsif (exists $args{File}) {
     $ifits = CFITSIO::open_file( $args{File}, CFITSIO::READWRITE(), $status );
  } else {
     croak("Arguement hash does not contain fitsID, File or Cards");
  }

  # file sucessfully opened?
  if( $status == 0 ) {
  
     # Get size of FITS header
     my ($numkeys, $morekeys);
     $ifits->get_hdrspace( $numkeys, $morekeys, $status);      

     # Set the FITS array to empty
     my @fits = ();
     
     # read the cards, including END card
     for my $i (0 .. $numkeys) {
        $ifits->read_record($i+1, my $card, $status);
        push(@fits, $card);   
     }
     
     if ($status == 0) {
        # Parse the FITS array
        $self->SUPER::configure( Cards => \@fits );
     } else {
        # Report bad exit status
        croak("Error $status reading FITS array"); 
     }
  }
 
  # clean up
  if ( $status != 0 ) {
     croak("Error $status opening FITS file");
  }
  
  # close file
  $ifits->close_file( $status );
  return;
  
}

# W R I T E H D R -----------------------------------------------------------

=item B<writehdr>

Write a FITS header to a FITS file

  $header->writehdr( File => $file );
  $header->writehdr( fitsID => $ifits );

Its accepts a FITS identifier or a filename. If both fitsID and File keys
exist, fitsID key takes priority.

Returns undef on error, true if the header was written successfully.

=cut

sub writehdr {
  my $self = shift;
  my %args = @_;

  return $self->SUPER::configure(%args) if exists $args{Cards};
   
  # itialise the inherited status to OK.  
  my $status = 0;
  my $ifits;   
  
  # read the args hash
  if (exists $args{fitsID}) {
     $ifits = $args{fitsID};
  } elsif (exists $args{File}) {
     $ifits = CFITSIO::open_file( $args{File}, CFITSIO::READWRITE(), $status );
  } else {
     croak("Argument hash does not contain fitsID, File or Cards");
  }

  # file sucessfully opened?
  if( $status == 0 ) {
  
    # Get the fits array
    my @cards = $self->cards; 

    # Get size of FITS header
    my ($numkeys, $morekeys);
    $ifits->get_hdrspace( $numkeys, $morekeys, $status);      

    # write the cards, including END card
    for my $j (0 .. $#cards ) {
       $ifits->write_record($cards[$j], $status );
       print "$j $status\n";
    } 
    
    # delete the old FITS keys
    for my $i (1 .. $numkeys ) {
       $ifits->delete_record( $i, $status );
       print "$i $status\n";
    }    
    
  }
 
  # clean up
  if ( $status != 0 ) {
     croak("Error $status opening FITS file");
  }
    
  # close file
  $ifits->close_file( $status );
  return;
   
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 NOTES

This module requires Pete Ratzlaff's L<CFITSIO|CFITSIO> module, 
and  William Pence's C<cfitsio> subroutine library.

=head1 SEE ALSO

L<Astro::FITS::Header>, L<Astro::FITS::Header::Item>, L<Astro::FITS::Header::NDF>, L<CFITSIO>

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=head1 COPYRIGHT

Copyright (C) 2001 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
