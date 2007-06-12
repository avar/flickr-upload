use ExtUtils::MakeMaker;

sub MY::postamble {
	return "ChangeLog:Makefile\n\tgit-log --pretty=full . >ChangeLog \n\n";
}

WriteMakefile(
	NAME              => 'Flickr::Upload',
	VERSION           => '1.27',
	ABSTRACT          => 'Module for uploading images to flickr.com',
	AUTHOR            => 'Christophe Beauregard <cpb@cpan.org>',
	PREREQ_PM         => {
		'LWP::UserAgent' => 1,
		'HTTP::Request::Common' => 1,
		'XML::Parser::Lite::Tree' => 0.03,
		'Flickr::API' => 0.07,
		'Pod::Usage' => 1,
		'Getopt::Long' => 1,
	},
	'EXE_FILES' => [ 'flickr_upload' ],
	'clean' => { FILES => 'ChangeLog' },
	'depend' => { 'distdir' => 'ChangeLog' },
);
