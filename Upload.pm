package Flickr::Upload;

use 5.008003;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

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
	flickr_upload
);

$VERSION = do { my @r = (q$Revision$ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Flickr::Upload - Upload images to L<flickr.com>

=head1 SYNOPSIS

	use LWP::UserAgent;
	use Flickr::Upload;

	my $ua = LWP::UserAgent->new;
	$ua->agent( "$0/1.0" );

	flickr_upload(
		'filename' => '/tmp/image.jpg',
		'email' => 'self@example.com',
		'password' => 'pr1vat3',
		'tags' => ['me', 'myself', 'eye'],
		'is_public' => 1,
		'is_friend' => 1,
		'is_family' => 1
	) or die "Failed to upload /tmp/image.jpg";

=head1 DESCRIPTION

Upload an image to L<flickr.com>.

=head2 EXPORT


=head1 SEE ALSO

=head1 AUTHOR

Christophe Beauregard, E<lt>cpb@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Christophe Beauregard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
