use strict;
use Test::More;
use List::Util qw(shuffle);

# The $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD facility allows us
# to supply a callback that'll get the contents of each chunk in the
# multipart POST request to flickr. By inspecting the whole multipart
# request we can determine how far along the upload is and display an
# accurate progres meter via Term::ProgressBar.

# Ideally there would be a callaback that would be called with the
# contents of each logical form field in the multipart chunk, since
# that isn't the case we'll have to build an ad-hoc parser that gets
# called with each chunk in the multipart request and returns the
# number of bytes of the file that has been uploaded.

my $NUM_TESTS = 9001;
my @IMAGE_SIZE_RANGE = ( 500, 1000 );

plan tests => $NUM_TESTS;

my @PARTS = (
q[--%ID%
Content-Disposition: form-data; name="photo"; filename="%IMAGE_NAME%"
Content-Type: %IMAGE_TYPE%

%IMAGE_DATA%],
q[--%ID%
Content-Disposition: form-data; name="async"

1],
q[--%ID%
Content-Disposition: form-data; name="api_sig"

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX],
q[--%ID%
Content-Disposition: form-data; name="auth_token"

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX],
q[--%ID%
Content-Disposition: form-data; name="title"

Test],
q[--%ID%
Content-Disposition: form-data; name="api_key"

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX],
q[--%ID%
Content-Disposition: form-data; name="description"

Test picture],
);

for my $num_test (1 .. $NUM_TESTS) {
	my $image_name = "Testimage.png";
	my $image_type = "image/png";
	my $image_size = 512 + int rand 1024;
	my $image_data = ('x' x $image_size);
	my $chunk_size = 128 + int rand 256;
	my $id = 'qBXwGcnVvxg14vk2iUnT8v2YB3FilB3b3rmAmVeq';
	my @parts = shuffle @PARTS;
	my @mod_parts = map {
		s/\n/\r\n/g;
		s/%ID%/$id/g;
		s/%IMAGE_NAME%/$image_name/g;
		s/%IMAGE_TYPE%/$image_type/g;
		s/%IMAGE_DATA%/$image_data/g;
		$_;
	} @parts;
	my $whole_message = join("\r\n", @mod_parts) . "\r\n" . "--$id\r\n";
	my @split_message = unpack "(Z$chunk_size)*", $whole_message;

	my $state = {};
	my $size;

	for my $part (@split_message) {
		$size += callback(\$part, $image_size, $state);
	}

	cmp_ok $size, '==', $image_size, "Correct size (img_size: $image_size) (chunk_size: $chunk_size)";
}

sub callback
{
	my ($chunk, $img_size, $s) = @_;

	# If we've run past the end of the image there's nothing to do but
	# report no image content in this sector.
	return 0 if $s->{done};

	unless ($s->{in}) {
		# Since we haven't found the image yet append this chunk to
		# our internal data store, we do this because we have to do a
		# regex match on m[Content-Type...] which might be split
		# across multiple chunks
		$s->{data} .= $$chunk;

		if ($s->{data} =~ m[Content-Type: image/[a-z-]+\r\n\r\n]g) {
			# We've found the image inside the stream, record this,
			# delete ->{data} since we don't need it, and see how much
			# of the image this particular chunk gives us.
			$s->{in} = 1;
			my $size = length substr($s->{data}, pos($s->{data}), -1);
			delete $s->{data};

			$s->{size} = $size;

			if ($s->{size} >= $img_size) {
				# The image could be so small that we've already run
				# through it in chunk it starts in, mark as done and
				# return the total image size

				$s->{done} = 1;
				return $img_size;
			} else {
				return $s->{size};
			}
		} else {
			# Are we inside the image yet? No!
			return 0;
		}
	} else {
		my $size = length $$chunk;

		if (($s->{size} + $size) >= $img_size) {
			# This chunk finishes the image

			$s->{done} = 1;

			# Return what we had left
			return $img_size - $s->{size};
		} else {
			# This chunk isn't the last one

			$s->{size} += $size;

			return $size;
		}
	}
}
