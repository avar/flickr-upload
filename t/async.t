use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload', 'upload', 'check_upload' ) };

use_ok('LWP::UserAgent');

use Data::Dumper;

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
	'async' => 1,
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

print STDERR "Got ticket id '$rc'\n";

do {
	sleep 1;
	my @checked = check_upload( $ua, $rc );

	for( @checked ) {
		if( $_->{id} == $rc and $_->{complete} ) {
			ok( $_->{complete} == 1 );	# completed
			ok( defined $_->{photoid} and $_->{photoid} );
			print STDERR "Got photoid '$_->{photoid}'\n";
			$rc = undef;
		}
	}
} while( defined $rc );

exit 0;
