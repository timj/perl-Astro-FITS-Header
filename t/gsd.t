#!perl
# Testing GSD read of fits headers

use strict;

use Test;
BEGIN { plan tests => 3 };

eval "use Astro::FITS::Header::GSD;";
if ($@) {
  for (1..3) {
    skip("Skip GSD module not available", 1);
  }
  exit;
}

ok(1);

# Read-only
my $gsdfile = "test.gsd";

my $hdr = new Astro::FITS::Header::GSD( File => $gsdfile );
ok( $hdr );

# Get the telescope name
my $item = $hdr->itembyname( 'C1TEL' );
ok( $item->value, "JCMT");
