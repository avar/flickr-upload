package Flickr::Upload;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Parser::Lite::Tree;
use Data::Dumper;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Flickr::Upload ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [ qw(upload check_upload make_upload_request upload_request) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = do { my @r = (q$Revision$ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub uploader_tag($$) {
	my $t = shift;
	my $tag = shift;

	return undef unless defined $t and exists $t->{'children'};

	for my $n ( @{$t->{'children'}} ) {
		next unless $n->{'name'} eq "uploader";
		next unless exists $n->{'children'};

		for my $m (@{$n->{'children'}} ) {
			next unless exists $m->{'name'}
				and $m->{'name'} eq $tag
				and exists $m->{'children'};

			return $m->{'children'}->[0]->{'content'};
		}
	}
	return undef;
}

=head1 NAME

Flickr::Upload - Upload images to C<flickr.com>

=head1 SYNOPSIS

	use LWP::UserAgent;
	use Flickr::Upload qw(upload);

	my $ua = LWP::UserAgent->new;
	upload(
		$ua,
		'photo' => '/tmp/image.jpg',
		'email' => 'self@example.com',
		'password' => 'pr1vat3',
		'tags' => 'me myself eye',
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
	) or die "Failed to upload /tmp/image.jpg";

=head1 DESCRIPTION

Upload an image to L<flickr.com>.

=head1 FUNCTIONS

=head2 upload

	my $photoid = upload(
		$ua,
		'photo' => '/tmp/image.jpg',
		'email' => 'self@example.com',
		'password' => 'pr1vat3',
		'tags' => 'me myself eye',
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
		'async' => 0,
	);

Taking a L<LWP::UserAgent> as an argument (C<$ua>), this is basically a
direct interface to the Flickr Photo Upload API. Required parameters are
C<photo>, C<email>, and C<password>. C<uri> may be provided if you don't
want to use the default, L<http://www.flickr.com/tools/uploader_go.gne>
(i.e. you have a custom server running somewhere that supports the API).

Returns the resulting identifier of the uploaded photo on success,
C<undef> on failure. According to the API documentation, after an upload the
user should be directed to the page
L<http://www.flickr.com/tools/uploader_edit.gne?ids=$photoid>.

If the C<async> option is non-zero, the photo will be uploaded
asynchronously and a successful upload returns a ticket number. See
L<http://flickr.com/services/api/upload.async.html>. The caller can then
periodically poll for a photo id using the C<check_upload> call.

=cut
#'

sub upload($%) {
	my $ua = shift;
	die "expecting a LWP::UserAgent" unless $ua->isa('LWP::UserAgent');
	my %args = @_;

	# these are the only things _required_ by the uploader.
	return undef unless $args{'photo'} and -f $args{'photo'};
	return undef unless $args{'email'};
	return undef unless $args{'password'};

	# create a request object and execute it
	my $req = make_upload_request( %args );
	return undef unless defined $req;

	return upload_request( $ua, $req );
}

=head2 check_upload

	my %status2txt = (0 => 'not complete', 1 => 'completed', 2 => 'failed');
	my @rc = check_upload( $ua, @ticketids );
	for( @rc ) {
		print "Ticket $_->{id} has $status2txt{$_->{complete}}\n";
		print "\tPhoto id is $_->{photoid}\n" if exists $_->{photoid};
	}

This function will check the status of one or more asynchronous uploads. A
list of ticket identifiers are provided (C<@ticketids>) and each is
checked.

On success, a list of hash references is returned. Each
hash contains a C<id> (the ticket id), C<complete> and, if
completed, C<photoid> members. C<invalid> may also be returned.
Status codes (for C<complete>) are as documented at
L<http://flickr.com/services/api/upload.async.html> and, actually, the
returned fields are identical to those listed in the C<ticket> tag of the
response.  The returned list isn't guaranteed to be in any particular order.

This function polls a web server, so avoid calling it too frequently.

=cut
#'

sub check_upload($@) {
	my $ua = shift;
	die "expecting a LWP::UserAgent" unless $ua->isa('LWP::UserAgent');

	return () unless @_;	# no tickets

	my $uri = 'http://www.flickr.com/tools/uploader_check.gne?tickets='
		. ((@_ == 1) ? $_[0] : join(',', @_));

	my $res = $ua->request( GET $uri );
	return () unless defined $res;

	my $tree = XML::Parser::Lite::Tree::instance()->parse($res->content());
	return () unless defined $tree;

	my @rc;
	return undef unless defined $tree and exists $tree->{'children'};
	for my $n ( @{$tree->{'children'}} ) {
		next unless $n->{'name'} eq "uploader";
		next unless exists $n->{'children'};

		for my $m (@{$n->{'children'}} ) {
			next unless exists $m->{'name'}
				and $m->{'name'} eq 'ticket'
				and exists $m->{'attributes'};

			# okay, this is maybe a little lazy...
			push @rc, $m->{'attributes'};
		}
	}

	return @rc;
}

=head2 make_upload_request

	my $req = make_upload_request(
		'email' => 'self@example.com',
		'password' => 'pr1vat3',
		'tags' => 'me myself eye',
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
	);
	$req->header( 'X-Greetz' => 'hi cal' );
	my $resp = $ua->request( $req );

Creates an L<HTTP::Request> object loaded with all the flick upload
parameters.

Takes all the same parameters as L<upload>, except that the photo argument
isn't required. This in intended so that the caller can include it by
messing directly with the HTTP content (via C<$DYNAMIC_FILE_UPLOAD> or
the L<HTTP::Message> class, among other things).

Returns a standard L<HTTP::Response> POST object. The caller can manually
do the upload or just call the L<upload_request> function.

=cut
#'

sub make_upload_request(%) {
	my %args = @_;

	# these are the only things _required_ by the uploader.
	return undef unless $args{'email'};
	return undef unless $args{'password'};

	my $uri = $args{'uri'} || 'http://www.flickr.com/tools/uploader_go.gne';

	# passed in separately, so remove from the hash
	delete $args{uri};

	if( exists $args{photo} and ref $args{photo} ne "ARRAY" ) {
		# unlikely that the caller would set up the photo as an array,
		# but...
		$args{photo} = [ $args{photo} ];
	}

	return POST $uri, 'Content_Type' => 'form-data', 'Content' => \%args;
}

=head2 upload_request

	my $photoid = upload_request( $ua, $request );

Taking L<LWP::UserAgent> and L<HTTP::Request> objects as arguments, this
executes the request and processes the result as a flickr upload. It's
assumed that the request looks a lot like something created with
L<make_upload_request>.

Returns the resulting identifier of the uploaded photo (or ticket for
asynchronous uploads) on success, C<undef> on failure. According to the
API documentation, after an upload the user should be directed to the
page L<http://www.flickr.com/tools/uploader_edit.gne?ids=$photoid>.

=cut
#'

sub upload_request($$) {
	my $ua = shift;
	die "expecting a LWP::UserAgent" unless $ua->isa('LWP::UserAgent');
	my $req = shift;
	die "expecting a HTTP::Request" unless $req->isa('HTTP::Request');

	my $res = $ua->request( $req );

	my $tree = XML::Parser::Lite::Tree::instance()->parse($res->content());

	my $photoid = uploader_tag($tree, 'photoid');
	my $ticketid = uploader_tag($tree, 'ticketid');
	unless( defined $photoid or defined $ticketid ) {
		my $err = uploader_tag($tree, 'verbose');
		print STDERR "upload failed: ", ($err || $res->content()), "\n";
		return undef;
	}

	return (defined $photoid) ? $photoid : $ticketid;
}

1;
__END__

=head1 SEE ALSO

L<http://flickr.com/services/api/>.

=head1 AUTHOR

Christophe Beauregard, L<cpb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is not an official Flickr.com (or Ludicorp) service.

Copyright (C) 2004 by Christophe Beauregard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.
