use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::FITS::Header',
	       'VERSION'        => '2.8.0',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM  => 'Header.pm',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

