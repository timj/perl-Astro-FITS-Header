#!/stardev/Perl/bin/perl -w

# strict
use strict;

# load test modules
use lib ".";  
use Astro::FITS::Header;
use Astro::FITS::Header::Item;

# load general modules
use Data::Dumper;
use Carp;

# load test
use Test;
BEGIN { plan tests => 22 };

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# read header file
my @raw = <DATA>;
chomp @raw;
		  
# LOGICAL
my $item_logical1 = new Astro::FITS::Header::Item( Card => $raw[0] );
my $item_logical2 = new Astro::FITS::Header::Item(
                                  Keyword => 'LOGICAL',
		                  Value   => 'T',
			          Comment => 'Testing the LOGICAL type',
			          Type    => 'LOGICAL' );
ok( "$item_logical1", "$item_logical2");
ok( "$item_logical1", $raw[0]);
ok( "$item_logical2", $raw[0]);

# INTEGER
my $item_integer1 = new Astro::FITS::Header::Item( Card => $raw[1] );
my $item_integer2 = new Astro::FITS::Header::Item(
                                  Keyword => 'INTEGER',
		                  Value   => -32,
			          Comment => 'Testing the INT type',
			          Type    => 'INT' );
ok( "$item_integer1", "$item_integer2");
ok( "$item_integer1", $raw[1]);
ok( "$item_integer2", $raw[1]);

# FLOAT
my $item_float1 = new Astro::FITS::Header::Item( Card => $raw[2] );
my $item_float2 = new Astro::FITS::Header::Item(
                                  Keyword => 'FLOAT',
		                  Value   => 12.5,
			          Comment => 'Testing the FLOAT type',
			          Type    => 'FLOAT' );
ok( "$item_float1", "$item_float2");
ok( "$item_float1", $raw[2]);
ok( "$item_float2", $raw[2]);

# STRING
my $item_string1 = new Astro::FITS::Header::Item( Card => $raw[3] );
my $item_string2 = new Astro::FITS::Header::Item(
                                  Keyword => 'STRING',
		                  Value   => 'string',
			          Comment => 'Testing the STRING type',
			          Type    => 'STRING' );
ok( "$item_string1", "$item_string2");
ok( "$item_string1", $raw[3]);
ok( "$item_string2", $raw[3]);

# COMMENT
my $item_comment1 = new Astro::FITS::Header::Item( Card => $raw[4] );
my $item_comment2 = new Astro::FITS::Header::Item(
                                  Keyword => 'COMMENT',
			          Comment => 'Testing the COMMENT type',
			          Type    => 'COMMENT' );
ok( "$item_comment1", "$item_comment2");
ok( "$item_comment1", $raw[4]);
ok( "$item_comment2", $raw[4]);

# HISTORY
my $item_history1 = new Astro::FITS::Header::Item( Card => $raw[5] );
my $item_history2 = new Astro::FITS::Header::Item(
                                  Keyword => 'HISTORY',
			          Comment => 'Testing the HISTORY type',
			          Type    => 'COMMENT' );
ok( "$item_history1", "$item_history2");
ok( "$item_history1", $raw[5]);
ok( "$item_history2", $raw[5]);

# END line
my $item_end1 = new Astro::FITS::Header::Item( Card => $raw[6] );
my $item_end2 = new Astro::FITS::Header::Item( Keyword => 'END');
ok( "$item_end1", "$item_end2");
ok( "$item_end1", $raw[6]);
ok( "$item_end2", $raw[6]);

#keyword
#value
#comment
#type
#card

exit;

# T I M E   A T   T H E   B A R ----------------------------------------------

__DATA__
LOGICAL =                    T / Testing the LOGICAL type                       
INTEGER =                  -32 / Testing the INT type                           
FLOAT   =                 12.5 / Testing the FLOAT type                         
STRING  = 'string  '           / Testing the STRING type                        
COMMENT   Testing the COMMENT type                                              
HISTORY   Testing the HISTORY type                                              
END                                                                             
