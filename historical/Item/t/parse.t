
use Test;
BEGIN { plan tests => 2 };

use Astro::FITS::Header::Item;

ok(1);



my $item = new Astro::FITS::Header::Item( Keyword => 'TEST',
					  Value => 5,
					  Comment => "Comment",
					);

ok($item->keyword, 'TEST');

