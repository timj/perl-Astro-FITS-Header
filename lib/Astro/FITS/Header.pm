package Astro::FITS::Header;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::FITS::Header

#  Purposes:
#    Implements a FITS Header Block

#  Language:
#    Perl object

#  Description:
#    This module wraps a FITS header block as a perl object as a hash
#    containing an array of FITS::Header::Items and a lookup hash for
#    the keywords.

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

Astro::FITS::Header - A FITS header

=head1 SYNOPSIS

  $item = new Astro::FITS::Header( @array );

=head1 DESCRIPTION

Stores information about a FITS header block in an object. Takes an array
of FITS header cards as input and stores them in a blessed hash containing
an anonymous array of FITS::Header::Items and a keyword lookup table
implemented as an anonymous hash.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::FITS::Header::Item;

'$Revision$ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from an array of FITS header cards. 

  $item = new Astro::FITS::Header( @header );

returns an object reference to a Header object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the header block into the class
  my ( @header, %lookup );
  my $block = bless { HEADER => \@header,
                      LOOKUP  => \%lookup }, $class;
                          
  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;
  
}

# I T E M ------------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<item>

Returns a FITS::Header:Item object referenced by index.

   $item = $header->item($index);

=cut

sub item {
   my ( $self, $index ) = @_;
   
   return undef unless defined $index;
   
   # grab and return the Header::Item at $index
   return ${$self->{HEADER}}[$index];
 
}

# I T E M   B Y   N A M E  -------------------------------------------------

=item B<itembyname>

Returns an array of Header::Items for the requested keyword

   @value = $header->itembyname($keyword);

=cut

sub itembyname {
   my ( $self, $keyword ) = @_;
   
   # grab the index array from lookup table
   my @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # loop over the indices and grab the Header::Items
   my @items;
   for( my $i=0; $i<scalar(@index); $i++ ) {
      my $item = ${$self->{HEADER}}[$index[$i]];
      push( @items, $item ); 
   }
   
   # return the values array
   return @items;
}

# I N D E X   --------------------------------------------------------------

=item B<index>

Returns an array of indices for the requested keyword

   @index = $header->index($keyword);

=cut

sub index {
   my ( $self, $keyword ) = @_;
   
   # grab the index array from lookup table
   my @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # return the values array
   return @index;
}

# V A L U E  ---------------------------------------------------------------

=item B<value>

Returns an array of values for the requested keyword

   @value = $header->value($keyword);

=cut

sub value {
   my ( $self, $keyword ) = @_;
   
   # grab the index array from lookup table
   my @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # loop over the indices and grab the values
   my @values;
   for( my $i=0; $i<scalar(@index); $i++ ) {
      my $value = ${$self->{HEADER}}[$index[$i]]->value();
      push( @values, $value ); 
   }
   
   # return the values array
   return @values;
}

# C O M M E N T -------------------------------------------------------------

=item B<comment>

Returns an array of values for the requested keyword

   @comment = $header->comment($keyword);

=cut

sub comment {
   my ( $self, $keyword ) = @_;
      
   # grab the index array from lookup table
   my @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # loop over the indices and grab the comments
   my @comments;
   for( my $i=0; $i<scalar(@index); $i++ ) {
      my $comment = ${$self->{HEADER}}[$index[$i]]->comment();
      push( @comments, $comment ); 
   }
   
   # return the values array
   return @comments;
}

# I N S E R T -------------------------------------------------------------

=item B<insert>

Inserts a FITS header card object at position $index

   $header->insert($index, $item);

the object $item is not copied, multiple inserts of the same object mean 
that future modifications to the one instance of the inserted object will
modify all inserted copies.

=cut

sub insert{
   my ($self, $index, $item) = @_;
   
   # splice the new FITS header card into the array
   splice @{$self->{HEADER}}, $index, 0, $item;
   
   # rebuild the lookup table

   # empty the hash 
   my %empty_hash;
   $self->{LOOKUP} = \%empty_hash;

   # loop over the existing header array
   for ( my $i = 0; $i<scalar(@{$self->{HEADER}}); $i++) {

      # grab the keyword from each header item;
       
      my $keyword = ${$self->{HEADER}}[$i]->keyword();
            
      # need to account to repeated keywords (e.g. COMMENT)
      unless ( exists ${$self->{LOOKUP}}{$keyword} &&
               defined ${$self->{LOOKUP}}{$keyword} ) {
         # new keyword
         ${$self->{LOOKUP}}{$keyword} = [ $i ];
      } else {     
         # keyword exists, push the current index into the array
         push( @{${$self->{LOOKUP}}{$keyword}}, $i );
      }   
   }
   
}


# R E P L A C E  B Y  N A M E ---------------------------------------------

=item B<replace>

Replace FITS header card at index $index with card $item

   $header->replace($index, $item);

returns the replaced card.

=cut

sub replace{
   my ($self, $index, $item) = @_;

   # remove the specified item and replace with $item
   my @cards = splice @{$self->{HEADER}}, $index, 1, $item;
   
   # rebuild the lookup table

   # empty the hash 
   my %empty_hash;
   $self->{LOOKUP} = \%empty_hash;

   # loop over the existing header array
   for ( my $j = 0; $j<scalar(@{$self->{HEADER}}); $j++) {

      # grab the keyword from each header item;
      my $key = ${$self->{HEADER}}[$j]->keyword();
            
      # need to account to repeated keywords (e.g. COMMENT)
      unless ( exists ${$self->{LOOKUP}}{$key} &&
               defined ${$self->{LOOKUP}}{$key} ) {
         # new keyword
         ${$self->{LOOKUP}}{$key} = [ $j ];
      } else {     
         # keyword exists, push the current index into the array
         push( @{${$self->{LOOKUP}}{$key}}, $j );
      }   
   }
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 
 
# R E M O V E -------------------------------------------------------------

=item B<remove>

Removes a FITS header card object at position $index

   $card = $header->remove($index);

returns the removed card.

=cut

sub remove{
   my ($self, $index) = @_;
   
   # remove the  FITS header card from the array
   my @cards = splice @{$self->{HEADER}}, $index, 1;
   
   # rebuild the lookup table

   # empty the hash 
   my %empty_hash;
   $self->{LOOKUP} = \%empty_hash;

   # loop over the existing header array
   for ( my $i = 0; $i<scalar(@{$self->{HEADER}}); $i++) {

      # grab the keyword from each header item;
       
      my $keyword = ${$self->{HEADER}}[$i]->keyword();
            
      # need to account to repeated keywords (e.g. COMMENT)
      unless ( exists ${$self->{LOOKUP}}{$keyword} &&
               defined ${$self->{LOOKUP}}{$keyword} ) {
         # new keyword
         ${$self->{LOOKUP}}{$keyword} = [ $i ];
      } else {     
         # keyword exists, push the current index into the array
         push( @{${$self->{LOOKUP}}{$keyword}}, $i );
      }   
   }
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 

# R E P L A C E  B Y  N A M E ---------------------------------------------

=item B<replacebyname>

Replace FITS header cards with keyword $keyword with card $item

   $card = $header->replacebyname($keyword, $item);  

returns the replaced card.

=cut

sub replacebyname{
   my ($self, $keyword, $item) = @_;
   
   # grab the index array from lookup table
   my @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the keywords
   my @cards;
   for( my $i=0; $i<scalar(@index); $i++ ) {
      @cards = splice @{$self->{HEADER}}, $index[$i], 1, $item;
   }   
   
   # rebuild the lookup table

   # empty the hash 
   my %empty_hash;
   $self->{LOOKUP} = \%empty_hash;

   # loop over the existing header array
   for ( my $j = 0; $j<scalar(@{$self->{HEADER}}); $j++) {

      # grab the keyword from each header item;
      my $key = ${$self->{HEADER}}[$j]->keyword();
            
      # need to account to repeated keywords (e.g. COMMENT)
      unless ( exists ${$self->{LOOKUP}}{$key} &&
               defined ${$self->{LOOKUP}}{$key} ) {
         # new keyword
         ${$self->{LOOKUP}}{$key} = [ $j ];
      } else {     
         # keyword exists, push the current index into the array
         push( @{${$self->{LOOKUP}}{$key}}, $j );
      }   
   }
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 

# R E M O V E  B Y   N A M E -----------------------------------------------

=item B<removebyname>

Removes a FITS header card object by name

  $card = $header->removebyname($keyword);

returns the removed card.

=cut

sub removebyname{
   my ($self, $keyword) = @_;
   
   # grab the index array from lookup table
   my @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the keywords
   my @cards;
   for( my $i=0; $i<scalar(@index); $i++ ) {
      @cards = splice @{$self->{HEADER}}, $index[$i], 1;
   }   
   
   # rebuild the lookup table

   # empty the hash 
   my %empty_hash;
   $self->{LOOKUP} = \%empty_hash;

   # loop over the existing header array
   for ( my $j = 0; $j<scalar(@{$self->{HEADER}}); $j++) {

      # grab the keyword from each header item;
      my $key = ${$self->{HEADER}}[$j]->keyword();
            
      # need to account to repeated keywords (e.g. COMMENT)
      unless ( exists ${$self->{LOOKUP}}{$key} &&
               defined ${$self->{LOOKUP}}{$key} ) {
         # new keyword
         ${$self->{LOOKUP}}{$key} = [ $j ];
      } else {     
         # keyword exists, push the current index into the array
         push( @{${$self->{LOOKUP}}{$key}}, $j );
      }   
   }
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 

# S P L I C E --------------------------------------------------------------
 
=item B<splice>

Implements a standard splice operation for FITS headers

   @cards = $header->splice($offset [,$length [, @list]]);
   $last_card = $header->splice($offset [,$length [, @list]]);

Removes the FITS header cards from the header designated by $offset and
$length, and replaces them with @list (if specified) which must be an
array of FITS::Header::Item objects. Returns the cards removed. If offset 
is negative, counts from the end of the FITS header.

=cut

sub splice {
   my $self = shift;
   
   # check for arguments
   my @cards;
   
   if ( scalar(@_) == 0 ) {
      # none
      @cards = splice @{$self->{HEADER}};
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } elsif ( scalar(@_) == 1 ) {
      # $offset
      my ( $offset ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset;          
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } elsif ( scalar(@_) == 2 ) {
      # $offset and $length
      my ( $offset, $length ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset, $length;
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } else {
      # $offset, $length and @list 
      my ( $offset, $length, @list ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset, $length;	
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   }
}
   
# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an array of FITS header cards as input.

  $header->configure( @array );

=back

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguements
  return undef unless defined @_;

  # grab the arguement list
  my @array = @_;  

  # loop over the passed array
  for ( my $i = 0; $i<scalar(@array); $i++) {

     # build array of Header::Items
     my $item = new Astro::FITS::Header::Item( Card => $array[$i] );
     push (@{$self->{HEADER}}, $item);

     # build the lookup table 
     my $keyword = $item->keyword();
     
     # need to account to repeated keywords (e.g. COMMENT)
     unless ( exists ${$self->{LOOKUP}}{$keyword} &&
              defined ${$self->{LOOKUP}}{$keyword} ) {
        # new keyword
	${$self->{LOOKUP}}{$keyword} = [ $i ];
     } else {     
	# keyword exists, push the current index into the array
        push( @{${$self->{LOOKUP}}{$keyword}}, $i );
     }
  }
  
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2001 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
