package Astro::FITS::Header::NDF;

=head1 NAME

Astro::FITS::Header::NDF - Manipulate FITS headers from NDF files

=head1 SYNOPSIS

  use Astro::FITS::Header::NDF;

  $hdr = new Astro::FITS::Header::NDF( Cards => \@cards );
  $hdr = new Astro::FITS::Header::NDF( ndfID => $indf );
  $hdr = new Astro::FITS::Header::NDF( File => $file );

  $hdr->writehdr( $indf );
  $hdr->writehdr( File => $file );

=head1 DESCRIPTION

This module makes use of the Starlink L<NDF|NDF> module to read and write to
and NDF FITS extension or to a C<.HEADER> block in an HDS container file.

It stores information about a FITS header block in an object. Takes an hash as an arguement, with either an array reference pointing to an array of FITS header cards, or a filename, or (alternatively) and NDF identifier.

=cut

use strict;
use Carp;
use NDF qw/ :ndf :dat :err /;

use base qw/ Astro::FITS::Header /;

use vars qw/ $VERSION /;

$VERSION = '0.02';

=head1 METHODS

=over 4

=item B<configure>

Reads a FITS header from an NDF.

  $hdr->configure( Cards => \@cards );
  $hdr->configure( ndfID => $indf );
  $hdr->configure( File => $filename );

Accepts an NDF identifier or a filename. If both ndfID and File keys
exist, ndfID key takes priority.

If the file open does not work, a second attempt is made with
".HEADER" appended in case this was a UKIRT-style HDS container.

=cut

sub configure {
  my $self = shift;

  my %args = @_;

  my ($indf, $started);
  my $task = ref($self);

  return $self->SUPER::configure(%args) if exists $args{Cards};

  # Store the definition of good locally
  my $status = &NDF::SAI__OK;
  my $good = $status;


  # Start error system (this may be the first time we hit
  # starlink)
  err_begin( $status );

  # Start NDF
  ndf_begin();

  # Read the args hash
  if (exists $args{ndfID}) {
    $indf = $args{ndfID};

  } elsif (exists $args{File}) {
    # Remove trailing .sdf
    my $file = $args{File};
    $file =~ s/\.sdf$//;

    # Open it
    ndf_find(&NDF::DAT__ROOT(), $file, $indf, $status);

    # If status is bad, try assuming it is a HDS container
    # with UKIRT style .HEADER component
    if ($status != $good) {
      # dont want to contaminate existing status
      my $lstat = $good;
      $file .= ".HEADER";
      ndf_find(&NDF::DAT__ROOT(), $file, $indf, $lstat);

      # flush bad status if we succedded
      err_annul($status) if $lstat == $good;

    }


  } else {

    $status = &NDF::SAI__ERROR;
    err_rep(' ',
	    "$task: Argument hash does not contain ndfID, File or Cards",
	   $status);

  }

  if ($status == $good) {

    # Find the FITS extension
    ndf_xloc($indf, 'FITS', 'READ', my $xloc, $status);

    if ($status == $good) {

      # Variables...
      my (@dim, $ndim, $nfits, $maxdim);

      # Get the dimensions of the FITS array
      # Should only be one-dimensional
      $maxdim = 7;
      dat_shape($xloc, $maxdim, @dim, $ndim, $status);

      if ($status == $good) {

        if ($ndim != 1) {
          $status = &SAI__ERROR;
          err_rep(' ',"$task: Dimensionality of FITS array should be 1 but is $ndim", $status);

        }

      }

      # Set the FITS array to empty
      my @fits = ();   # Note that @fits only exists in this block

      # Read the FITS extension
      dat_get1c($xloc, $dim[0], @fits, $nfits, $status);

      # Annul the locator
      dat_annul($xloc, $status);

      # Check status and read into hash
      if ($status == $good) {

	# Parse the FITS array
	$self->SUPER::configure( Cards => \@fits );

      } else {

        err_rep(' ',"$task: Error reading FITS array", $status);

      }

    } else {

      # Add my own message to status
      err_rep(' ', "$task: Error locating FITS extension",
             $status);

    }

    # Close the NDF identifier (if we opened it)
    ndf_annul($indf, $status) if exists $args{File};
  }

  # Shutdown
  ndf_end($status);
  if ($status != $good) {
    err_flush($status);
    croak "Error during header read from NDF\n";
  }
  err_end($status);

  # It is possible to annul the errors before exiting if we want
  # or to flush them out.
  return;

}


=item B<writehdr>

Write a fits header to an NDF.

  $hdr->writehdr( ndfID => $indf );
  $hdr->writehdr( File => $file );

Accepts an NDF identifier or a filename.  If both ndfID and File keys
exist, ndfID key takes priority.

Returns undef on error, true if the header was written successfully.

=cut

sub writehdr {

  my $self = shift;
  my %args = @_;

  # Store the definition of good locally
  my $status = &NDF::SAI__OK;
  my $good = $status;


  # Start error system (this may be the first time we hit
  # starlink)
  err_begin( $status );

  # Start NDF
  ndf_begin();

  # Look in the args hash and open the output file if needed
  my $ndfid;
  if (exists $args{ndfID}) {
    $ndfid = $args{ndfID};
  } elsif (exists $args{File}) {
    my $file = $args{File};
    $file =~ s/\.sdf//;
    ndf_open(&NDF::DAT__ROOT(), $file, 'UPDATE', 'UNKNOWN',
	     $ndfid, my $place, $status);

    # If status is bad, try assuming it is a HDS container
    # with UKIRT style .HEADER component
    if ($status != $good or $ndfid == 0) {
      # dont want to contaminate existing status
      my $lstat = $good;
      my $hdsfile .= $file . ".HEADER";
      ndf_open(&NDF::DAT__ROOT(), $hdsfile, 'UPDATE', 'UNKNOWN',
	       $ndfid, $place, $lstat);

      # flush bad status if we succedded
      err_annul($status) if $lstat == $good;

    }

    # KLUGE : need to get NDF__NOID from the NDF module at some point
    if ($ndfid == 0 && $status == $good) {
      # could create it :-)
      $status = &NDF::SAI__ERROR;
      err_rep(' ',"File '$file' does not exist to receive the header", $status);
    }

  } else {
    return undef;
  }

  # Now need to find out whether we have a FITS header in the
  # file already
  ndf_xstat( $ndfid, 'FITS', my $there, $status);

  # delete it
  ndf_xdel($ndfid, 'FITS', $status) if $there;

  # Get the fits array
  my @cards = $self->cards;

  # Write the FITS extension
  if ($#cards > -1) {

    # Write it out
    my @fitsdim = (scalar(@cards));
    ndf_xnew($ndfid, 'FITS', '_CHAR*80', 1, @fitsdim, my $fitsloc, $status);
    dat_put1c($fitsloc, scalar(@cards), @cards, $status);
    dat_annul($fitsloc, $status);
  }

  # Shutdown
  ndf_end($status);
  if ($status != $good) {
    err_flush($status);
    croak "Error during header write from NDF\n";
  }
  err_end($status);

  # It is possible to annul the errors before exiting if we want
  # or to flush them out.
  return;


}


=back

=head1 NOTES

This module requires the Starlink L<NDF|NDF> module.

=head1 SEE ALSO

L<NDF>, L<Astro::FITS::Header>, L<Astro::FITS::Header::Item>
L<Astro::FITS::Header::CFITSIO>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=cut

1;
