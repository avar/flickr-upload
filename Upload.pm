package Flickr::Upload;

use 5.008003;
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
	'all' => [ qw(upload) ],
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

sub upload {
	my $ua = shift;
	my %args = @_;

	# these are the only things _required_ by the uploader.
	return undef unless $args{'photo'} and -f $args{'photo'};
	return undef unless $args{'email'};
	return undef unless $args{'password'};

	my $photo = $args{'photo'};
	my $uri = $args{'uri'} || 'http://www.flickr.com/tools/uploader_go.gne';

	# strip these from the hash so we can just drop it into the request
	delete $args{$_} for(qw(photo uri));

	my $req = POST $uri,
		'Content_Type' => 'form-data',
		'Content' => [
			'photo' => [ $photo ],
			%args,
		];

	my $res = $ua->request( $req );

	my $tree = XML::Parser::Lite::Tree::instance()->parse($res->content());

	my $photoid = uploader_tag($tree, 'photoid');
	unless( defined $photoid ) {
		my $err = uploader_tag($tree, 'verbose');
		print STDERR "upload failed: ", ($err || $res->content()), "\n";
		return undef;
	}

	return $photoid;
}

1;
__END__

=head1 NAME

Flickr::Upload - Upload images to L<flickr.com>

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

=head1 SEE ALSO

L<http://flickr.com/services/api/>.

=head1 AUTHOR

Christophe Beauregard, L<cpb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is not an official Flickr.com (or Ludicorp) service. I'm sure
if they knew about it they could suggest some additional words saying just
how little they're responsible for anything that might go wrong with this
code.

Copyright (C) 2004 by Christophe Beauregard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
