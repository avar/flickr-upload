use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

use_ok('LWP::UserAgent');

$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

# grab a password. If no password, fail nicely.
my $pw = '******';
open( F, '<', 't/password' ) or (print STDERR "No password file\n" && exit 0);
$pw = <F>;
chomp $pw;
close F;

my $req = Flickr::Upload::make_upload_request(
	'description' => "Flickr Upload test for $0",
	'email' => 'cpb@cpan.org',
	'photo' => 't/Kernel & perl.jpg',
	'password' => $pw,
	'tags' => "test kernel perl cat dog",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

# all we want to do is replace the default content generator with something
# that will spit out a '.' for each kilobyte and pass the data back.
my $gen = $req->content();
die unless ref($gen) eq "CODE";

$req->content(
	sub {
		my $chunk = &$gen();
		print "." x (length($chunk)/1024);
		return $chunk;
	}
);

my $ua = LWP::UserAgent->new;
ok(defined $ua);

$ua->agent( "$0/1.0" );

my $photoid = Flickr::Upload::upload_request( $ua, $req );
ok( defined $photoid );

print "\n";

exit 0;
