use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

use_ok('LWP::UserAgent');

# grab a password. If no password, fail nicely.
my $pw = '******';
open( F, '<', 't/password' ) or (print STDERR "No password file\n" && exit 0);
$pw = <F>;
chomp $pw;
close F;

# slurp in the photo
my $photo = 't/Kernel & perl.jpg';
my $photobuf = '';
open( F, '<', $photo ) or die $!;
while(<F>) { $photobuf .= $_; }
close F;

ok( $photobuf ne '' );

my $req = Flickr::Upload::make_upload_request(
	'description' => "Flickr Upload test for $0",
	'email' => 'cpb@cpan.org',
	'password' => $pw,
	'tags' => "test kernel perl cat dog",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

# HACK: this will be recalculated when the content is regenerated, but
# if we leave it as it is we get a nasty warning because the added part
# will invalidate the existing value.
$req->remove_header( 'Content-Length' );

# we didn't provide a photo when we made the message because we're
# trying to generate the message from a data buffer, not a file.
# Now that we have a request, add in the actual image.
my $p = new HTTP::Message(
	[
		'Content-Disposition'
			=> qq(form-data; name="photo"; filename="$photo"),
		'Content-Type' => 'image/jpeg',
	],
	$photobuf,
);
$req->add_part( $p );

my $ua = LWP::UserAgent->new;
ok(defined $ua);

$ua->agent( "$0/1.0" );

my $photoid = Flickr::Upload::upload_request( $ua, $req );
ok( defined $photoid );

exit 0;
