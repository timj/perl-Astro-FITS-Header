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
#    Tim Jenness (t.jenness@jach.hawaii.edu)

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

  $header = new Astro::FITS::Header( Cards => \@array );

=head1 DESCRIPTION

Stores information about a FITS header block in an object. Takes an hash
with an array reference as an arguement. The array should contain a list
of FITS header cards as input.

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

  $item = new Astro::FITS::Header( Cards => \@header );

returns a reference to a Header object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the header block into the class
  my $block = bless { HEADER => [],
                      LOOKUP  => {},
		      LASTKEY => undef }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# I T E M ------------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<item>

Returns a FITS::Header:Item object referenced by index, C<undef> if it
does not exist.

   $item = $header->item($index);

=cut

sub item {
   my ( $self, $index ) = @_;
   
   return undef unless defined $index;
   return undef unless exists ${$self->{HEADER}}[$index];
   
   # grab and return the Header::Item at $index
   return ${$self->{HEADER}}[$index];
 
}

# K E Y W O R D ------------------------------------------------------------

=item B<keyword>

Returns keyword referenced by index, C<undef> if it does not exist.

   $keyword = $header->keyword($index);

=cut

sub keyword {
   my ( $self, $index ) = @_;
   
   return undef unless defined $index;
   return undef unless exists ${$self->{HEADER}}[$index];
   
   # grab and return the keyword at $index
   return ${$self->{HEADER}}[$index]->keyword();
 
}

# I T E M   B Y   N A M E  -------------------------------------------------

=item B<itembyname>

Returns an array of Header::Items for the requested keyword if called
in list context, or an empty array if it does not exist.

   @items = $header->itembyname($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $item = $header->itembyname($keyword);



=cut

sub itembyname {
   my ( $self, $keyword ) = @_;
            
   # resolve the items from the index array from lookup table
   my @items =
     map { ${$self->{HEADER}}[$_] } @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   return wantarray ?  @items : @items ? $items[0] : undef;
}

# I N D E X   --------------------------------------------------------------

=item B<index>

Returns an array of indices for the requested keyword if called in list
context, or an empty array if it does not exist.

   @index = $header->index($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $index = $header->index($keyword);

=cut

sub index {
   my ( $self, $keyword ) = @_;
   
   # grab the index array from lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # return the values array
   return wantarray ? @index : @index ? $index[0] : undef;

}

# V A L U E  ---------------------------------------------------------------

=item B<value>

Returns an array of values for the requested keyword if called
in list context, or an empty array if it does not exist.

   @value = $header->value($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

=cut

sub value {
   my ( $self, $keyword ) = @_;
   
   # resolve the values from the index array from lookup table
   my @values =
     map { ${$self->{HEADER}}[$_]->value() } @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the indices and grab the values
   return wantarray ? @values : @values ? $values[0] : undef;
   
}

# C O M M E N T -------------------------------------------------------------

=item B<comment>

Returns an array of comments for the requested keyword if called
in list context, or an empty array if it does not exist.

   @comment = $header->comment($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $comment = $header->comment($keyword);

=cut

sub comment {
   my ( $self, $keyword ) = @_;
      
   # resolve the comments from the index array from lookup table
   my @comments =
     map { ${$self->{HEADER}}[$_]->comment() } @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # loop over the indices and grab the comments
   return wantarray ?  @comments : @comments ? $comments[0] : undef;
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
   
   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();   
   
}


# R E P L A C E -------------------------------------------------------------

=item B<replace>

Replace FITS header card at index $index with card $item

   $card = $header->replace($index, $item);

returns the replaced card.

=cut

sub replace{
   my ($self, $index, $item) = @_;

   # remove the specified item and replace with $item
   my @cards = splice @{$self->{HEADER}}, $index, 1, $item;
   
   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();
   
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
   
   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();
   
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
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the keywords
   my @cards = map { splice @{$self->{HEADER}}, $_, 1, $item;} @index;

   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();

   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];

}

# R E M O V E  B Y   N A M E -----------------------------------------------

=item B<removebyname>

Removes a FITS header card object by name

  @card = $header->removebyname($keyword);

returns the removed cards.

=cut

sub removebyname{
   my ($self, $keyword) = @_;
   
   # grab the index array from lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   print "\@index = @index\n\n";
   
   # loop over the keywords
   my @cards = map { splice @{$self->{HEADER}}, $_, 1; } @index;

   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();
   
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
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } elsif ( scalar(@_) == 1 ) {
      # $offset
      my ( $offset ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset;          
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } elsif ( scalar(@_) == 2 ) {
      # $offset and $length
      my ( $offset, $length ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset, $length;
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } else {
      # $offset, $length and @list 
      my ( $offset, $length, @list ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset, $length;	
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   }
}

# C A R D S --------------------------------------------------------------

=item B<cards>

Return the object contents as an array of FITS cards.

  @array = $header->cards;

=cut

sub cards {
  my $self = shift;
  return map { "$_" } @{$self->{HEADER}};
}
   
# A L L I T E M S ---------------------------------------------------------   
 
=item B<allitems>

Returns the header as an array of FITS::Header:Item objects.

   @items = $header->allitems();

=cut

sub allitems {
   my $self = shift;
   return map { $_ } @{$self->{HEADER}};
} 
   
# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an array of FITS header cards as input.

  $header->configure( Cards => \@array );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  if (defined $args{Cards}) {

    # First translate each incoming card into a Item object
    # Any existing cards are removed
    @{$self->{HEADER}} = map {
      new Astro::FITS::Header::Item( Card => $_ );
    } @{ $args{Cards} };

    # Now build the lookup table. There would be a slight efficiency
    # gain to include this in a loop over the cards but prefer
    # to reuse the method for this rather than repeating code
    $self->_rebuild_lookup;

  }
}

# P R I V A T  E   M E T H O D S ------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_rebuild_lookup>

Private function used to rebuild the lookup table after modifying the
header block, its easier to do it this way than go through and add one
to the indices of all header cards following the modifed card.

=cut

sub _rebuild_lookup {
   my $self = shift;
   
   # rebuild the lookup table

   # empty the hash 
   $self->{LOOKUP} = { };

   # loop over the existing header array
   for my $j (0 .. $#{$self->{HEADER}}) {

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

}

# T I E D   I N T E R F A C E -----------------------------------------------

=back

=head1 TIED INTERFACE

The C<FITS::Header> object can also be tied to a hash

   use Astro::FITS::Header;

   $header = new Astro::FITS::Header( Cards => \@array );
   tie %hash, "Astro::FITS::Header", $header   

   $value = $hash{$keyword};
   $hash{$keyword} = $value;

   print "keyword $keyword is present" if exists $hash{$keyword};

   foreach my $key (keys %hash) {
      print "$key = $hash{$key}\n";
   }

It should be noted that if querying a value using the tied interface and the
keyword appears multiple times in the FITS HDU, then only the first occurance
will be returned. Similiarly for storing a value, only the first occurance will
be modified.

Calls to keys() or each() will, by default, return the keywords in the order 
in which they appear in the header.

=cut

# constructor
sub TIEHASH {
  my ( $class, $obj, %options ) = @_;
  return bless $obj, $class;  
}

# fetch key and value pair
sub FETCH {
  my ($self, $key) = @_;
  scalar $self->value($key);
}

# store key and value pair
sub STORE {
  my ($self, $keyword, $value) = @_;
  
  my $item = $self->itembyname($keyword);
  if (  defined $item ) {
     $item->value($value);
  } else {
     $item = new Astro::FITS::Header::Item( Keyword => $keyword,
                                            Value => $value );
     $self->insert(-1,$item);
  }

}

# reports whether a key is present in the hash
sub EXISTS {
  my ($self, $keyword) = @_;
  return undef unless exists ${$self->{LOOKUP}}{$keyword};  
}

# deletes a key and value pair
sub DELETE {
  my ($self, $keyword) = @_;
  return $self->removebyname($keyword);
}

# empties the hash
sub CLEAR {
  my $self = shift; 
  $self->{HEADER} = [ ];
  $self->{LOOKUP} = { };
  $self->{LASTKEY} = undef;
}

# implements keys() and each()
sub FIRSTKEY {
  my $self = shift;
  $self->{LASTKEY} = 0;
  return undef unless defined @{$self->{HEADER}};
  return ${$self->{HEADER}}[0]->keyword();
}

# implements keys() and each()
sub NEXTKEY {
  my ($self, $keyword) = @_; 
  return undef if $self->{LASTKEY}+1 == scalar(@{$self->{HEADER}}) ;
  $self->{LASTKEY} += 1;  
  return ${$self->{HEADER}}[$self->{LASTKEY}]->keyword();
}

# garbage collection
# sub DESTROY { }

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=end __PRIVATE_METHODS__

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
