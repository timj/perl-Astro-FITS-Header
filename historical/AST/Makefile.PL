use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'      => 'Astro::FITS::Header::AST',
	      'VERSION_FROM'   => 'AST.pm',
              'PREREQ_PM' => {
			     },
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'AST.pm',
		AUTHOR     => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
	     );

