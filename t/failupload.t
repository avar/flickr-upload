use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload', 'upload') };

use_ok('LWP::UserAgent');

my $ua = LWP::UserAgent->new;
ok(defined $ua);

$ua->agent( "$0/1.0" );

my $rc = upload(
	$ua,
	'photo' => 't/Kernel & perl.jpg',
	'email' => 'cpb@cpan.org',
	'password' => 'bad_pass',
	'tags' => "test kernel perl cat dog",
	'is_public' => 1,
	'is_friend' => 1,
	'is_family' => 1
);

ok( not defined $rc );

exit 0;
