use ExtUtils::MakeMaker;

sub MY::postamble {
	return "ChangeLog:\n\tcvs2cl.pl -r --show-dead -S --utc\n\n";
}

WriteMakefile(
	NAME              => 'Flickr::Upload',
	VERSION_FROM      => 'Upload.pm',
	ABSTRACT          => 'Module for uploading images to flickr.com',
	AUTHOR            => 'Christophe Beauregard <cpb@cpan.org>',
	PREREQ_PM         => {
		'LWP::UserAgent' => 1,
		'HTTP::Request::Common' => 1,
		'XML::Parser::Lite::Tree' => 0.03,
	},
	'EXE_FILES' => [ 'flickr_upload' ],
	'clean' => { FILES => 'ChangeLog' },
	'depend' => { 'distdir' => 'ChangeLog' },
);
