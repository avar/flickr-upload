use 5.008003;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Flickr::Upload',
	VERSION_FROM      => 'Upload.pm',
	ABSTRACT_FROM  => 'Upload.pm',
	AUTHOR         => 'Christophe Beauregard <cpb@cpan.org>',
	PREREQ_PM         => {
		'LWP::UserAgent' => 1,
		'HTTP::Request::Common' => 1,
		'XML::Parser::Lite::Tree' => 0.03,
	},
	'EXE_FILES' => [ 'flickr_upload' ],
);
