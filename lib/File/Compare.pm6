module File::Compare;
use v6;

our $foo = "bar";

sub alike (Str $left_filename, Str $right_filename, :$max_bytes = 16*1024*1024) {

	my $left_path  = $left_filename\.path;
	my $right_path = $right_filename.path;
        fail "Cannot read: '$right_filename'" unless $right_path.r;
        fail "Cannot read: '$left_filename'"  unless $left_path\.r;

	return False unless (my $size = $left_path.s) == $right_path.s;
	return True  if $size == 0;

	my $left  = $left_path\.open;
        my $right = $right_path.open;

        $size min= $max_bytes;

	while my $lhs := $left.read($size) {
		my $rhs := $right.read($size) or return False;

		# decode to binary because Buf evq Buf is incredibly slow
		$rhs.decode('Binary') eq $lhs.decode('Binary') or return False;
	}
	return False if $right.read($size); #i.e. if right still has data somehow

	return True;

}

sub different (Str $left_filename, Str $right_filename, :$max_bytes = 8*1024*1024) {
	my $result = alike($left_filename, $right_filename, $max_bytes);
	$result ~~ Exception ?? $result !! !$result;
}

=begin pod

=head1 NAME

File::Compare - Compare files, byte-by-byte

=head1 SYNOPSIS

	use File::Compare;
	
	say File::Compare::alike("file1.txt", "file2.txt");
	say File::Compare::different("foo", "bar");

	say "We match!" if File::Compare::alike("x.png", "y.png", maxbytes=> 4*1024*1024);


=head1 DESCRIPTION

File::Compare checks two files, and compares them as byte-buffers.  The function C<alike> returns Bool::True if the files have the same contents, Bool::False if any bytes are different, and an Exception object if an error occurs.  The other function, C<different>, returns the opposite boolean values, and is simply provided for code readability sugar.

Both functions can take an optional named parameter, C<maxbytes>, which accepts any positive integer as a number of bytes.  This parameter tells File::Compare what size of chunks should be read from the disk at once, since the read operation is often the slowest.  The default reads 8 MiB of each file at a time.  A smaller value may be more useful in a memory-limited environment, or when files are most likely different.  A larger value could improve performance when files are most likely the same.


=head1 SEE ALSO

* L<File::Find::Duplicates> - searches directories and lists of files to find duplicate items.

=head1 AUTHOR

Brent "Vorticity" Laabs, 2012.

Released under the same terms as Perl 6; see the LICENSE file for details.

=end pod

