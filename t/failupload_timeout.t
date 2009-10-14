no strict 'refs';
no warnings 'redefine';
use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

# Overwrite LWP::UserAgent::request to emulate the server closing the
# connection on us. Which can happen e.g. if the network sucks or if
# we C-z flickr_upload

BEGIN {
	our $old_request = *{"LWP::UserAgent::request"}{CODE};
	our $times = 0;
}

sub LWP::UserAgent::request {
	$times ++;

	# Return the real LWP::UserAgent::request
	if ($times == 3) {
		*LWP::UserAgent::request = $old_request;
		goto &LWP::UserAgent::request;
	}

	bless({
		_content => "500 Server closed connection without sending any data back\n",
		_headers => bless({
			"client-date"	 => "Wed, 14 Oct 2009 14:44:46 GMT",
			"client-warning" => "Internal response",
			"content-type"	 => "text/plain",
		}, "HTTP::Headers"),
		_msg => "Server closed connection without sending any data back",
		_rc => 500,
		_request => 'fix',
	}, "HTTP::Response"),
}

my $api_key = '8dcf37880da64acfe8e30bb1091376b7';
my $not_so_secret = '2f3695d0562cdac7';

# grab auth token. If none, fail nicely.
my $pw = '******';
open( F, '<', 't/password' ) || (print STDERR "No password file\n" && exit 0);
$pw = <F>;
chomp $pw;
close F;

my $ua = Flickr::Upload->new({'key'=>$api_key, 'secret'=>$not_so_secret});
ok(defined $ua);

my $rc = $ua->upload(
	'photo' => 't/testimage.jpg',
	'auth_token' => $pw,
	'tags' => "test kernel perl cat dog",
	'description' => "Flickr Upload test for $0",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

ok( defined $rc );
