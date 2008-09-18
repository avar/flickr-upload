package Flickr::Upload;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
use Flickr::API;
use XML::Parser::Lite::Tree;

our $VERSION = '1.32';

our @ISA = qw(Flickr::API);

sub response_tag {
	my $t = shift;
	my $node = shift;
	my $tag = shift;

	return undef unless defined $t and exists $t->{'children'};

	for my $n ( @{$t->{'children'}} ) {
		next unless defined $n and exists $n->{'name'} and exists $n->{'children'};
		next unless $n->{'name'} eq $node;

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

	use Flickr::Upload;

	my $ua = Flickr::Upload->new(
		{
			'key' => '90909354',
			'secret' => '37465825'
		});
	$ua->upload(
		'photo' => '/tmp/image.jpg',
		'auth_token' => $auth_token,
		'tags' => 'me myself eye',
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
	) or die "Failed to upload /tmp/image.jpg";

=head1 DESCRIPTION

Upload an image to L<flickr.com>.

=head1 METHODS

=head2 new

	my $ua = Flickr::Upload->new(
		{
			'key' => '90909354',
			'secret' => '37465825'
		});

Instatiates a L<Flickr::Upload> instance. The C<key> argument is your
API key and the C<secret> is the API secret associated with it. To get an
API key and secret, go to L<http://www.flickr.com/services/api/key.gne>.

The resulting L<Flickr::Upload> instance is a subclass of L<Flickr::API>
and can be used for any other Flickr API calls.  As such,
L<Flickr::Upload> is also a subclass of L<LWP::UserAgent>.

=head2 upload

	my $photoid = $ua->upload(
		'photo' => '/tmp/image.jpg',
		'auth_token' => $auth_token,
		'tags' => 'me myself eye',
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
		'async' => 0,
	);

Taking a L<Flickr::Upload> instance C<$ua> as an argument, this is
basically a direct interface to the Flickr Photo Upload API. Required
parameters are C<photo> and C<auth_token>.  Note that the C<auth_token>
must have been issued against the API key and secret used to instantiate
the uploader.

Returns the resulting identifier of the uploaded photo on success,
C<undef> on failure. According to the API documentation, after an upload the
user should be directed to the page
L<http://www.flickr.com/tools/uploader_edit.gne?ids=$photoid>.

If the C<async> option is non-zero, the photo will be uploaded
asynchronously and a successful upload returns a ticket identifier. See
L<http://flickr.com/services/api/upload.async.html>. The caller can then
periodically poll for a photo id using the C<check_upload> method. Note
that photo and ticket identifiers aren't necessarily numeric.

=cut

sub upload {
	my $self = shift;
	die '$self is not a Flickr::Upload' unless $self->isa('Flickr::Upload');
	my %args = @_;

	# these are the only things _required_ by the uploader.
	die "Can't read photo '$args{'photo'}'" unless $args{'photo'} and -f $args{'photo'};
	die "Missing 'auth_token'" unless defined $args{'auth_token'};

	# create a request object and execute it
	my $req = $self->make_upload_request( %args );
	return undef unless defined $req;

	return $self->upload_request( $req );
}

=head2 check_upload

	my %status2txt = (0 => 'not complete', 1 => 'completed', 2 => 'failed');
	my @rc = $ua->check_upload( @ticketids );
	for( @rc ) {
		print "Ticket $_->{id} has $status2txt{$_->{complete}}\n";
		print "\tPhoto id is $_->{photoid}\n" if exists $_->{photoid};
	}

This function will check the status of one or more asynchronous uploads. A
list of ticket identifiers are provided (C<@ticketids>) and each is
checked. This is basically just a wrapper around the Flickr API
C<flickr.photos.upload.checkTickets> method.

On success, a list of hash references is returned. Each
hash contains a C<id> (the ticket id), C<complete> and, if
completed, C<photoid> members. C<invalid> may also be returned.
Status codes (for C<complete>) are as documented at
L<http://flickr.com/services/api/upload.async.html> and, actually, the
returned fields are identical to those listed in the C<ticket> tag of the
response.  The returned list isn't guaranteed to be in any particular order.

This function polls a web server, so avoid calling it too frequently.

=cut

sub check_upload {
	my $self = shift;
	die '$self is not a Flickr::API' unless $self->isa('Flickr::API');

	return () unless @_;	# no tickets

	my $res = $self->execute_method( 'flickr.photos.upload.checkTickets',
		{ 'tickets' => ((@_ == 1) ? $_[0] : join(',', @_)) } );
	return () unless defined $res and $res->{success};

	# FIXME: better error feedback

	my @rc;
	return undef unless defined $res->{tree} and exists $res->{tree}->{'children'};
	for my $n ( @{$res->{tree}->{'children'}} ) {
		next unless defined $n and exists $n->{'name'} and $n->{'children'};
		next unless $n->{'name'} eq "uploader";

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

	my $req = $uploader->make_upload_request(
		'auth_token' => '82374523',
		'tags' => 'me myself eye',
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
	);
	$req->header( 'X-Greetz' => 'hi cal' );
	my $resp = $ua->request( $req );

Creates an L<HTTP::Request> object loaded with all the flick upload
parameters. This will also sign the request, which means you won't be able to
mess any further with the upload request parameters.

Takes all the same parameters as L<upload>, except that the photo argument
isn't required. This in intended so that the caller can include it by
messing directly with the HTTP content (via C<$DYNAMIC_FILE_UPLOAD> or
the L<HTTP::Message> class, among other things). See C<t/> directory from
the source distribution for examples.

Returns a standard L<HTTP::Response> POST object. The caller can manually
do the upload or just call the L<upload_request> function.

=cut

sub make_upload_request {
	my $self = shift;
	die '$self is not a Flickr::Upload' unless $self->isa('Flickr::Upload');
	my %args = @_;

	# _required_ by the uploader.
	die "Missing 'auth_token' argument" unless $args{'auth_token'};

	my $uri = $args{'uri'} || 'http://api.flickr.com/services/upload/';

	# passed in separately, so remove from the hash
	delete $args{uri};

	# Flickr::API includes this with normal requests, but we're building a custom
	# message.
	$args{'api_key'} = $self->{'api_key'};

	# photo is _not_ included in the sig
	my $photo = $args{photo};
	delete $args{photo};

	# HACK: sign_args() is an internal Flickr::API method
	$args{'api_sig'} = $self->sign_args(\%args);

	# unlikely that the caller would set up the photo as an array,
	# but...
	if( defined $photo ) {
		$photo = [ $photo ] if ref $photo ne "ARRAY";
		$args{photo} = $photo;
	}

	my $req = POST $uri, 'Content_Type' => 'form-data', 'Content' => \%args;

	return $req;
}

=head2 upload_request

	my $photoid = upload_request( $ua, $request );

Taking (at least) L<LWP::UserAgent> and L<HTTP::Request> objects as
arguments, this executes the request and processes the result as a
flickr upload. It's assumed that the request looks a lot like something
created with L<make_upload_request>. Note that the request must be signed
according to the Flickr API authentication rules.

Returns the resulting identifier of the uploaded photo (or ticket for
asynchronous uploads) on success, C<undef> on failure. According to the
API documentation, after an upload the user should be directed to the
page L<http://www.flickr.com/tools/uploader_edit.gne?ids=$photoid>.

=cut

sub upload_request {
	my $self = shift;
	die "$self is not a LWP::UserAgent" unless $self->isa('LWP::UserAgent');
	my $req = shift;
	die "expecting a HTTP::Request" unless $req->isa('HTTP::Request');

	my $res = $self->request( $req );

	my $tree = XML::Parser::Lite::Tree::instance()->parse($res->decoded_content());
	return () unless defined $tree;

	my $photoid = response_tag($tree, 'rsp', 'photoid');
	my $ticketid = response_tag($tree, 'rsp', 'ticketid');
	unless( defined $photoid or defined $ticketid ) {
		print STDERR "upload failed:\n", $res->decoded_content(), "\n";
		return undef;
	}

	return (defined $photoid) ? $photoid : $ticketid;
}

=head2 file_length_in_encoded_chunk

	$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;
	my $photo = 'image.jpeg';
	my $photo_size = (stat($photo))[7];
	my $req = $ua->make_upload_request( ... );
	my $gen = $req->content();
	die unless ref($gen) eq "CODE";

	my $state;
	my $size;

	$req->content(
		sub {
			my $chunk = &$gen();

			$size += Flickr::Upload::file_length_in_encoded_chunk(\$chunk, \$state, $photo_size);

			warn "$size bytes have now been uploaded";

			return $chunk;
		}
	);

	$rc = $ua->upload_request( $req );

This subroutine is tells you how much of a chunk in a series of
variable size multipart HTTP chunks contains a single file being
uploaded given a reference to the current chunk, a reference to a
state variable that lives between calls, and the size of the file
being uploaded.

It can be used used along with L<HTTP::Request::Common>'s
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD facility to implement
upload progress bars or other upload monitors, see L<flickr_upload>
for a practical example and F<t/progress_request.t> for tests.

=cut

sub file_length_in_encoded_chunk
{
	my ($chunk, $s, $img_size) = @_;

	$$s = {} unless ref $$s eq 'HASH';

	# If we've run past the end of the image there's nothing to do but
	# report no image content in this sector.
	return 0 if $$s->{done};

	unless ($$s->{in}) {
		# Since we haven't found the image yet append this chunk to
		# our internal data store, we do this because we have to do a
		# regex match on m[Content-Type...] which might be split
		# across multiple chunks
		$$s->{data} .= defined $$chunk ? $$chunk : '';

		if ($$s->{data} =~ m[Content-Type: .*?\r\n\r\n]g) {
			# We've found the image inside the stream, record this,
			# delete ->{data} since we don't need it, and see how much
			# of the image this particular chunk gives us.
			$$s->{in} = 1;
			my $size = length substr($$s->{data}, pos($$s->{data}), -1);
			delete $$s->{data};

			$$s->{size} = $size;

			if ($$s->{size} >= $img_size) {
				# The image could be so small that we've already run
				# through it in chunk it starts in, mark as done and
				# return the total image size

				$$s->{done} = 1;
				return $img_size;
			} else {
				return $$s->{size};
			}
		} else {
			# Are we inside the image yet? No!
			return 0;
		}
	} else {
		my $size = length $$chunk;

		if (($$s->{size} + $size) >= $img_size) {
			# This chunk finishes the image

			$$s->{done} = 1;

			# Return what we had left
			return $img_size - $$s->{size};
		} else {
			# This chunk isn't the last one

			$$s->{size} += $size;

			return $size;
		}
	}
}

1;
__END__

=head1 SEE ALSO

L<http://flickr.com/services/api/>

L<Flickr::API>

=head1 AUTHOR

Christophe Beauregard, L<cpb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is not an official Flickr.com (or Ludicorp, or Yahoo) service.

Copyright (C) 2004,2005 by Christophe Beauregard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.
