# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Flickr-Upload.t'

#########################

use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use_ok('LWP::UserAgent');

my $ua = LWP::UserAgent->new;
ok(defined $ua);

$ua->agent( "$0/1.0" );

my $rc = flickr_upload(
	'filename' => 't/Kernel & perl.jpg',
	'email' => 'cpb@cpan.org',
	'password' => 'fl1ckrt3st',
	'tags' => ['me', 'myself', 'eye'],
	'is_public' => 1,
	'is_friend' => 1,
	'is_family' => 1
);

ok( $rc );

exit 0;
