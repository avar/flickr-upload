use ExtUtils::MakeMaker;

sub MY::postamble {
	return <<END;
ChangeLog: Makefile
	git-log --pretty=fuller --decorate . >ChangeLog

META.yml: Makefile
	touch META.yml

END
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
		'Flickr::API' => 0.07,
		'Pod::Usage' => 1,
		'Getopt::Long' => 1,
	},
	'EXE_FILES' => [ 'flickr_upload' ],
	'clean' => { FILES => 'ChangeLog META.yml' },
	'depend' => {'create_distdir' => 'ChangeLog  META.yml'},
);
