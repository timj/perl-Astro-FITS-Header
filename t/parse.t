# test suite for Astro::FITS::Header module
# also tests Astro::FITS::Header::Item as a byproduct

use Test;
BEGIN { plan tests => 6 };

use Astro::FITS::Header;
use Astro::FITS::Header::Item;

use Carp;
use File::Spec;

# test the test system
ok(1);

# open the example header file
my $filename = File::Spec->catfile('t','fits.header');
open ( FH, $filename ) || croak ('Cannot open header file');

# read and then close header file
my @raw = <FH>;
close(FH);

# build header array
ok( my $header = new Astro::FITS::Header( @raw ) );

# build a test card
ok( my $test_card = new Astro::FITS::Header::Item(
                                  Keyword => 'LIFE',
		                  Value   => 42,
			          Comment => 'Life the Universe and everything',
			          Type    => 'int' ) );

# do an insert	
ok ($header->insert(1, $test_item) );


# do a splice
my @cards;
ok (scalar(@cards = $header->splice( 0, 2, $test_item)),2);	

# comparison cards
my @comparison = ( 'SIMPLE  =                    T /  file does conform to FITS standard            ', 'BITPIX  =                  -32 /  number of bits per data pixel                 ');

ok( @cards == @comparison );
