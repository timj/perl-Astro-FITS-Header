use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::FITS::Header',
	       'VERSION'        => '3.0',
               'PREREQ_PM'      => { Test::More => 0 },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM  => 'lib/Astro/FITS/Header.pm',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

