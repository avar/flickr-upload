use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload', 'upload') };

use_ok('LWP::UserAgent');

# grab a password. If no password, fail nicely.
my $pw = '******';
open( F, '<', 't/password' ) or (print STDERR "No password file\n" && exit 0);
$pw = <F>;
chomp $pw;
close F;

my $ua = LWP::UserAgent->new;
ok(defined $ua);

$ua->agent( "$0/1.0" );

my $rc = upload(
	$ua,
	'photo' => 't/Kernel & perl.jpg',
	'email' => 'cpb@cpan.org',
	'password' => $pw,
	'tags' => "test kernel perl cat dog",
	'description' => "Flickr Upload test for $0",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

ok( defined $rc );

exit 0;
