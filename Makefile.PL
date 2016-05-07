use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Astro::FITS::Header',
  VERSION_FROM => 'lib/Astro/FITS/Header.pm',
  LICENSE => 'gpl',
  ABSTRACT_FROM => 'lib/Astro/FITS/Header.pm',
  AUTHOR => [
    'Alasdair Allan <aa@astro.ex.ac.uk>',
    'Tim Jenness <tjenness@cpan.org>',
    'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>',
    'Craig DeForest <deforest@boulder.swri.edu>',
    'Jim Lewis <jrl@ast.cam.ac.uk>',
  ],
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources =>  {
      repository => {
        type => "git",
        url => "git://github.com/timj/perl-Astro-FITS-Header.git",
        web => "https://github.com/timj/perl-Astro-FITS-Header/",
      },
      homepage => 'https://github.com/timj/perl-Astro-FITS-Header/',
    },
    prereqs => {
      runtime => {
        recommends => {
          'Astro::FITS::CFITSIO' => 0,
        },
        suggests => {
          'Starlink::AST' => 0,
        },
      },
    },
  },
  TEST_REQUIRES => {
    'Test::More' => 0,
  },
  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 0,
  },
);
