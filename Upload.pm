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
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = do { my @r = (q$Revision$ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub uploader_status($) {
	my $t = shift;

	return undef unless defined $t and exists $t->{'children'};

	for my $n ( @{$t->{'children'}} ) {
		next unless $n->{'name'} eq "uploader";
		next unless exists $n->{'children'};

		for my $m (@{$n->{'children'}} ) {
			next unless exists $m->{'name'};
			next unless $m->{'name'} eq "status";
			next unless exists $m->{'children'};

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
	return undef unless $args{'tags'};

	my $tags = join( " ", @{$args{'tags'}} );
	my $photo = $args{'photo'};
	my $uri = $args{'uri'} || 'http://www.flickr.com/tools/uploader_go.gne';

	# strip these from the hash so we can just drop it into the request
	delete $args{$_} for(qw(tags photo uri));

	my $req = POST $uri,
		'Content_Type' => 'form-data',
		'Content' => [
			'tags' => $tags,
			'photo' => [ $photo ],
			%args,
		];

	my $res = $ua->request( $req );

print STDERR "\n",$res->content(),"\n\n";

	my $tree = XML::Parser::Lite::Tree::instance()->parse($res->content());

	# FIXME: should figure out the error code and warn()
	unless( uploader_status($tree) eq "ok" ) {
		warn($res->content());
		return undef;
	}

	# done
	return 1;
}

1;
__END__

=head1 NAME

Flickr::Upload - Upload images to L<flickr.com>

=head1 SYNOPSIS

	use LWP::UserAgent;
	use Flickr::Upload qw(upload);

	my $ua = LWP::UserAgent->new;
	$ua->agent( "$0/1.0" );

	upload(
		$ua,
		'photo' => '/tmp/image.jpg',
		'email' => 'self@example.com',
		'password' => 'pr1vat3',
		'tags' => ['me', 'myself', 'eye'],
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
	) or die "Failed to upload /tmp/image.jpg";

=head1 DESCRIPTION

Upload an image to L<flickr.com>.

=head1 FUNCTIONS

=head2 upload


=head1 SEE ALSO

=head1 AUTHOR

Christophe Beauregard, E<lt>cpb@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Christophe Beauregard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
