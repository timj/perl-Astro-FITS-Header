#!perl

# Test that sub-headers work correctly
# Needs a better suite of tests.
use strict;
use Test;
BEGIN { plan tests => 12 };

use Astro::FITS::Header;
use Astro::FITS::Header::Item;

# Force numify to return the actual object reference.
# This allows us to verify that a header stored through
# a tie does not get reblessed or stringified.
package Astro::FITS::Header;
use overload '0+' => 'fudge', fallback => 1;
sub fudge { return $_[0] }
package main;

# build a test card
my $int_card = new Astro::FITS::Header::Item(
                               Keyword => 'LIFE',
                               Value   => 42,
                               Comment => 'Life the Universe and everything',
                               Type    => 'INT' );

# build another
my $string_card = new Astro::FITS::Header::Item(
                               Keyword => 'STUFF',
                               Value   => 'Blah Blah Blah',
                               Comment => 'So long and thanks for all the fish',
			       Type    => 'STRING' );

# and another
my $another_card = new Astro::FITS::Header::Item(
                               Keyword => 'VALUE',
                               Value   => 34.5678,
                               Comment => 'A floating point number',
                               Type    => 'FLOAT' );


# Form a header
my $hdr = new Astro::FITS::Header( Cards => [ $int_card, $string_card ]);

# and another header
my $subhdr = new Astro::FITS::Header( Cards => [ $another_card ]);
print "Subhdr: $subhdr\n";

# now create an item pointing to that subhdr
my $subitem = new Astro::FITS::Header::Item(
					    Keyword => 'EXTEND',
					    Value => $subhdr,
					   );

# Add the item
$hdr->insert(0,$subitem);

#tie
my %header;
tie %header, ref($hdr), $hdr;

# Add another item
$header{EXTEND2} = $subhdr;
ok($header{EXTEND2}{VALUE},34.5678 );

# test that we have the correct type
# This should be a hash
ok( ref($header{EXTEND}), "HASH");

# And this should be an Astro::FITS::Header
ok( UNIVERSAL::isa($hdr->value("EXTEND"), "Astro::FITS::Header"));

# Now store a hash
$header{NEWHASH} = { A => 2, B => 3};
ok( $header{NEWHASH}->{A}, 2);
ok( $header{NEWHASH}->{B}, 3);

# Now store a tied hash
my %sub;
tie %sub, ref($subhdr), $subhdr;
$header{NEWTIE} = \%sub;
my $newtie = $header{NEWTIE};
my $tieobj = tied %$newtie;

# Check class
ok( UNIVERSAL::isa($tieobj, "Astro::FITS::Header"));

# Make sure we have a long numification
my $tienum = 0 + $tieobj;
my $hdrnum = 0 + $subhdr;
ok( $tienum > 0);
ok( $hdrnum > 0);

# Compare memory addresses
ok( $tienum, $hdrnum );

printf "# The tied object is: %s\n",0+$tienum;
printf "# The original object is:: %s\n",$hdrnum;

# test values
ok($header{NEWTIE}->{VALUE}, $another_card->value);

# Test autovivification
# Note that $hdr{BLAH}->{YYY} = 5 does not work
my $void = $header{BLAH}->{XXX};
printf "# VOID is %s\n", defined $void ? $void : '(undef)';
ok(ref($header{BLAH}), 'HASH');
$header{BLAH}->{XXX} = 5;
ok($header{BLAH}->{XXX}, 5);

