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
#    the keywords.  May be tied to a single hash for convenience.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)
#    Tim Jenness (t.jenness@jach.hawaii.edu)
#    Craig DeForest (deforest@boulder.swri.edu)

#  Revision:
#     $Id$

#  Copyright:
#     Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council. 
#     Portions copyright (C) 2002 Southwest Research Institute
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

# Operator overloads
use overload '""' => "stringify",
  fallback => 1;

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
		      LASTKEY => undef,
		      TieRetRef => 0,
		    }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# I T E M ------------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<tieRetRef>

Indicates whether the tied object should return multiple values
as a single string joined by newline characters (false) or 
it should return a reference to an array containing all the values.

Only affects the tied interface.

  tie %keywords, "Astro::FITS::Header", $header, tiereturnsref => 1;
  $ref = $keywords{COMMENT};

Defaults to returning a single string in all cases (for backwards
compatibility)

=cut

sub tiereturnsref {
  my $self = shift;
  if (@_) {
    $self->{TieRetRef} = shift;
  }
  return $self->{TieRetRef};
}

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
in list context, or the first matching Header::Item if called in scalar
context. Returns C<undef> if the keyword does not exist.

   @items = $header->itembyname($keyword);
   $item = $header->itembyname($keyword);



=cut

sub itembyname {
   my ( $self, $keyword ) = @_;
            
   # resolve the items from the index array from lookup table
   # grab the index array from the lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   my @items = map {${$self->{HEADER}}[$_]} @index;
   
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

   # If the array is empty and we get a negative index we
   # must convert it to an index of 0 to prevent a:
   #   Modification of non-creatable array value attempted, subscript -1
   # fatal error
   # This can occur with a tied hash and the %{$tieref} = %new
   # construct
   $index = 0 if (scalar(@{$self->{HEADER}} == 0 && $index < 0));

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

Configures the object, takes an array of FITS header cards 
or an array of Astro::FITS::Header::Item objects as input.

  $header->configure( Cards => \@array );
  $header->configure( Items => \@array );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  if (exists $args{Cards} && defined $args{Cards}) {

    # First translate each incoming card into a Item object
    # Any existing cards are removed
    @{$self->{HEADER}} = map {
      new Astro::FITS::Header::Item( Card => $_ );
    } @{ $args{Cards} };

    # Now build the lookup table. There would be a slight efficiency
    # gain to include this in a loop over the cards but prefer
    # to reuse the method for this rather than repeating code
    $self->_rebuild_lookup;

  } elsif (exists $args{Items} && defined $args{Items}){
    # We have an array of Astro::FITS::Header::Items
    @{$self->{HEADER}} = @{ $args{Items} };
    $self->_rebuild_lookup;
  }
}

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'Astro::FITS::Header';
}

# P R I V A T  E   M E T H O D S ------------------------------------------

=back

=head2 Operator Overloading

These operators are overloaded:

=over 4

=item B<"">

When the object is used in a string context the FITS header
block is returned as a single string.

=cut

sub stringify {
  my $self = shift;
  return join("\n", $self->cards )."\n";
}

=back

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

The C<FITS::Header> object can also be tied to a hash: 

   use Astro::FITS::Header;

   $header = new Astro::FITS::Header( Cards => \@array );
   tie %hash, "Astro::FITS::Header", $header   

   $value = $hash{$keyword};
   $hash{$keyword} = $value;

   print "keyword $keyword is present" if exists $hash{$keyword};

   foreach my $key (keys %hash) {
      print "$key = $hash{$key}\n";
   }

=head2 Basic hash translation

Header value type is determined on-the-fly by parsing of the input values.
Anything that parses as a number or a logical is converted to that before
being put in a card (but see below).

Per-card comment fields can be accessed using the tied interface by specifying
a key name of "key_COMMENT". This works because in general "_COMMENT" is too
long to be confused with a normal key name.

  $comment = $hdr{CRPIX1_COMMENT};

will return the comment associated with CRPIX1 header item. The comment
can be modified in the same way:

  $hdr{CRPIX1_COMMENT} = "An axes";

Keywords are CaSE-inNSEnSiTIvE, unlike normal hash keywords.  All
keywords are translated to upper case internally, per the FITS standard.

=head2 Comment cards

Comment cards are a special case because they have no normal value and
their comment field is treated as the hash value.  The keywords
"COMMENT" and "HISTORY" are magic and refer to comment cards; all other
keywords create normal valued cards.  If you don't like that behavior,
don't use the tied interface.

=head2 Multi-card values

Multiline string values are broken up, one card per line in the
string.  Extra-long string values are handled gracefully: they get
split among multiple cards, with a backslash at the end of each card
image.  They're transparently reassembled when you access the data, so
that there is a strong analogy between multiline string values and multiple
cards.  

In general, appending to hash entries that look like strings does what
you think it should.  In particular, comment cards have a newline
appended automatically on FETCH, so that

  $hash{HISTORY} .= "Added multi-line string support";

adds a new HISTORY comment card, while

  $hash{TELESCOP} .= " dome B";

only modifies an existing TELESCOP card.

You can make multi-line values by feeding in newline-delimited
strings, or by assigning from an array ref.  If you ask for a tag that
has a multiline value it's always expanded to a multiline string, even
if you fed in an array ref to start with.  That's by design: multiline
string expansion often acts as though you are getting just the first
value back out, because perl string-to-number conversion stops at the
first newline.  So:

  $hash{CDELT1} = [3,4,5];
  print $hash{CDELT1} + 99,"\n$hash{CDELT1}";

prints "102\n3\n4\n5", and then 

  $hash{CDELT1}++;
  print $hash{CDELT1};

prints "4".

In short, most of the time you get what you want.  But you can always fall
back on the non-tied interface by calling methods like so:

  ((tied $hash)->method())

Note that multi-valued items are always returned as a string separated
with newlines. If this is not required (and the original values are to
be treated separately) the tie can be configured using
C<tiereturnsref>.

  tie %keywords, "Astro::FITS::Header", $header, tiereturnsref => 1;

When tiereturnsref is true, multi-valued items will be returns via a
reference to an array (ties do not respect calling context). Note that
if this is configured you will have to test each return value to see
whether it is returning a real value or a reference to an array if you
are not sure whether there will be more than one card with a duplicate
name.

=head2 Type forcing

Because perl uses behind-the-scenes typing, there is an ambiguity
between strings and numeric and/or logical values: sometimes you want
to create a STRING card whose value could parse as a number or as a
logical value, and perl kindly parses it into a number for you.  To
force string evaluation, feed in a trivial hash array:

  $hash{NUMSTR} = 123;     # generates an INT card containing 123.
  $hash{NUMSTR} = '123';   # generates an INT card containing 123.
  $hash{NUMSTR} = ['123']; # generates a STRING card containing '123'.
  $hash{NUMSTR} = [123];   # generates a STRING card containing '123'.

  $hash{ALPHA} = 'T';      # generates a LOGICAL card containing T. 
  $hash{ALPHA} = ['T'];    # generates a STRING card containing 'T'.

Calls to keys() or each() will, by default, return the keywords in the order 
n which they appear in the header.

When the key refers to a subheader entry, a hash reference is returned.
If a hash reference is stored in a value it is converted to a
C<Astro::FITS::Header> object.

=cut

# List of known comment-type fields
%Astro::FITS::Header::COMMENT_FIELD = (
  "COMMENT"=>1,
  "HISTORY"=>1
);


# constructor
sub TIEHASH {
  my ( $class, $obj, %options ) = @_;
  my $newobj = bless $obj, $class;

  # Process options
  for my $key (keys %options) {
    my $method = lc($key);
    if ($newobj->can($method)) {
      $newobj->$method( $options{$key});
    }
  }

  return $newobj;
}

# fetch key and value pair
# MUST return undef if the key is missing else autovivification of 
# sub header will fail

sub FETCH {
  my ($self, $key) = @_;

  $key = uc($key);

  # If the key has a _COMMENT suffix we are looking for a comment
  my $wantvalue = 1;
  if ($key =~ /_COMMENT$/) {
    $wantvalue = 0;
    # Remove suffix
    $key =~ s/_COMMENT$//;
  }

  # if we are of type COMMENT we want to retrieve the comment regardless
  # We find this by getting the first item that matches
  my $item = ($self->itembyname($key))[0];
  $wantvalue = 0 if ((defined $item) && (defined $item->type) && ($item->type eq 'COMMENT'));

  # Retrieve all the values/comments. Note that we go through the entire
  # header for this in case of multiple matches
  my @values = ($wantvalue ? $self->value( $key ) : $self->comment($key) );

  # Return value depends on return context. If we have one value it does not
  # matter, just return it. In list context want all the values, in scalar
  # context join them all with a \n
  # Note that in a TIED hash we do not have access to the calling context
  # we are ALYWAYS in scalar context.
  my @out;

  # Sometimes we want the array to remain an array
  if ($self->tiereturnsref) {
    @out = @values;
  } else {

    # Join everything together with a newline
    # BUT we are careful here to prevent stringification of references
    # at least for the case where we only have one value. We also must
    # handle the case where we have no value to return (without turning
    # it into a null string since that ruins autovivification of sub headers)
    if (scalar(@values) <= 1) {
      @out = @values;
    } else {

      # Multi values so join
      @out = ( join("\n", @values) );

      # This is a hangover from the STORE (where we add a \ continuation character)
      # to multiline strings
      for my $out (@out) {
	$out =~ s/\\\n//gs if (defined($out));
      }
    }
  }

  # If we have COMMENTs it seems we should add a trailing newline
  # I do not think we should be doing this but it seems like this has now
  # become part of the standard interface.
  if ((defined $item) && (defined $item->type) && ($item->type eq 'COMMENT')) {
    @out = map { $_ . "\n" } @out;
  }

  # If we have a header we need to tie it to another hash
  my $ishdr = (defined $item && defined $item->type && $item->type eq 'HEADER');
  for my $hdr (@out) {
    if ((UNIVERSAL::isa($hdr, "Astro::FITS::Header")) || $ishdr) {
      my %header;
      tie %header, ref($hdr), $hdr;
      # Change in place
      $hdr = \%header;
    }
  }

  # Can only return a scalar
  # So return the first value if tiereturnsref is false and an array ref
  # if tiereturnsref is true.
  my $out;
  if ($self->tiereturnsref && scalar(@out) > 1) {
    $out = \@out;
  } else {
    $out = $out[0];
  }

  return $out;
}

# store key and value pair
#
# Multiple-line kludges (CED):
#
#    * Array refs get handled gracefully by being put in as multiple cards.
#
#    * Multiline strings get broken up and put in as multiple cards.
#
#    * Extra-long strings get broken up and put in as multiple cards, with 
#      an extra backslash at the end so that they transparently get put back
#      together upon retrieval.
#

sub STORE {
  my ($self, $keyword, $value) = @_;
  my @values;

  # skip the shenanigans for the normal case
  # or if we have an Astro::FITS::Header
  if (UNIVERSAL::isa($value, "Astro::FITS::Header")) {
    @values = ($value);
  } elsif (ref $value eq 'HASH') {
    # Convert a hash to a Astro::FITS::Header
    # If this is a tied hash already just get the object
    my $tied = tied %$value;
    if (defined $tied && UNIVERSAL::isa($tied, "Astro::FITS::Header")) {
      # Just take the object
      @values = ($tied);
    } else {
      # Convert it to a hash
      my @items = map { new Astro::FITS::Header::Item( Keyword => $_,
                                                       Value => $value->{$_}
                                                     ) } keys (%{$value});

      # Create the Header object.
      @values = (new Astro::FITS::Header( Cards => \@items ));

    }

  } elsif((ref $value) || (length $value > 70) || $value =~ m/\n/s ) {
    my @val;
    # @val gets intermediate breakdowns, @values gets line-by-line breakdowns.

    # Change multiline strings into array refs
    if (ref $value eq 'ARRAY') {
      @val = @$value;

    } elsif (ref $value) {
      die "Can't put non-array ref values into a tied FITS header\n";

    } elsif( $value =~ m/\n/s ) {
      @val = split("\n",$value);
      chomp @val;

    } else {
      @val = $value;
    }

    # Cut up really long items into multiline strings
    my($val);
    foreach $val(@val) {
      while((length $val) > 70) {
	push(@values,substr($val,0,69)."\\");
	$val = substr($val,69);
      }
      push(@values,$val);
    }
  }   ## End of complicated case
  else {
    @values = ($value);
  }

  # Upper case the relevant item name
  $keyword = uc($keyword);

  # Recognise _COMMENT
  my $havevalue = 1;
  if ($keyword =~ /_COMMENT$/) {
    $keyword =~ s/_COMMENT$//;
    $havevalue = 0;
  }

  my @items = $self->itembyname($keyword);

  ## Remove extra items if necessary
  if(scalar(@items) > scalar(@values)) {
    my(@indices) = $self->index($keyword);
    my($i);
    for $i (1..(scalar(@items) - scalar(@values))) {
      $self->remove( $indices[-$i] );
    }
  }

  ## Allocate new items if necessary
  while(scalar(@items) < scalar(@values)) {

    my $item = new Astro::FITS::Header::Item(Keyword=>$keyword,Value=>undef);
    $item->type('COMMENT') if($Astro::FITS::Header::COMMENT_FIELD{$keyword}
			      || ((defined $items[0]) && 
				  (defined $items[0]->type) &&
				  ($items[0]->type eq 'COMMENT')));

    $self->insert(-1,$item);
    push(@items,$item);
  }

  ## Set values or comments
  my($i); 
  for $i(0..$#values) {
    if($Astro::FITS::Header::COMMENT_FIELD{$keyword}) {
      $items[$i]->type('COMMENT');
      $items[$i]->comment($values[$i]);
    } elsif (! $havevalue) {
      # This is actually just changing the comment
      $items[$i]->comment($values[$i]);
    } else {
      $items[$i]->type( (($#values > 0) || ref $value) ? 'STRING' : undef);

      $items[$i]->value($values[$i]);
      $items[$i]->type("STRING") if($#values > 0);
    }
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
  $self->{SEENKEY} = undef;
}

# implements keys() and each()
sub FIRSTKEY {
  my $self = shift;
  $self->{LASTKEY} = 0;
  $self->{SEENKEY} = {};
  return undef unless defined @{$self->{HEADER}};
  return ${$self->{HEADER}}[0]->keyword();
}

# implements keys() and each()
sub NEXTKEY {
  my ($self, $keyword) = @_; 
  return undef if $self->{LASTKEY}+1 == scalar(@{$self->{HEADER}}) ;

  # Skip later lines of multi-line cards...
  my($a);
  do {
    $self->{LASTKEY} += 1;  
    $a = $self->{HEADER}->[$self->{LASTKEY}];
    return undef unless defined $a;
  } while ( $self->{SEENKEY}->{$a->keyword});
  $a = $a->keyword;

  $self->{SEENKEY}->{$a} = 1;
  return $a;
}

# garbage collection
# sub DESTROY { }

# T I M E   A T   T H E   B A R  --------------------------------------------

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council
and portions Copyright (C) 2002 Southwest Research Institute.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Craig DeForest E<lt>deforest@boulder.swri.eduE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
