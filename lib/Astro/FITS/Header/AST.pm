package Astro::FITS::Header::AST;

=head1 NAME

Astro::FITS::Header::AST - Manipulates FITS headers from an AST object

=head1 SYNOPSIS

  use Astro::FITS::Header::AST;

  $header = new Astro::FITS::Header::AST( FrameSet => $wcsinfo );
  $header = new Astro::FITS::Header::AST( Cards => \@cards );

  $header->writehdr( File => $file );
  $header->writehdr( fitsID => $ifits );

=head1 DESCRIPTION

This module makes use of the L<Starlink::AST|Starlink::AST> module to read 
the FITS HDU from an AST FrameSet object.

It stores information about a FITS header block in an object. Takes an hash 
as an arguement, with an array reference pointing to an Starlink::AST
FramSet object.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::FITS::Header::Item;
use base qw/ Astro::FITS::Header /;
use Carp;

require Starlink::AST;

'$Revision$ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<configure>

Reads a FITS header from a Starlink::AST FrameSet object

  $header->configure( FrameSet => $wcsinfo );
  $header->configure( Cards => \@cards );

Accepts a reference to an Starlink::AST FrameSet object.

=cut

sub configure {
  my $self = shift;
  my %args = @_;
  
  # itialise the inherited status to OK.  
  my $status = 0;

  return $self->SUPER::configure(%args) 
    if exists $args{Cards} or exists $args{Items};

  # read the args hash
  unless (exists $args{FrameSet}) {
     croak("Arguement hash does not contain FrameSet or Cards");
  }

  my $wcsinfo = $args{FrameSet};
  my @cards;
  {
     my $fchan = new Starlink::AST::FitsChan( 
                                      sink => sub { push @cards, $_[0] } );
     $fchan->Set( Encoding => "FITS-WCS" );
     $status = $fchan->Write( $wcsinfo );
  }
  return $self->SUPER::configure( Cards => \@cards );
}

# shouldn't need to do this, croak! croak!
sub writehdr {
  my $self = shift;
  croak("Not yet implemented");   
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
