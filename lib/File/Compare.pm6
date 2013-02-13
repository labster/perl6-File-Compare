module File::Compare;
use v6;

my $MAX = 16*1024*1024;    # Default maximum bytes for .read

sub files_are_equal (Str $left_filename, Str $right_filename, Int :$max_bytes = $MAX) is export {
	unless $max_bytes > 0 { die "Argument \$max_bytes must be a positive number" } 

	my $left_path  = $left_filename\.path;
	my $right_path = $right_filename.path;

	fail "Cannot read file: '$right_filename'" unless $right_path.r;
	fail "Cannot read file: '$left_filename'"  unless $left_path\.r;

	return False unless (my $size = $left_path.s) == $right_path.s;
	return True  if $size == 0;

	my $left  = $left_path\.open;
	my $right = $right_path.open;

	$size min= $max_bytes;

	while my $lhs := $left.read($size) {
		my $rhs := $right.read($size) or return False;

		# decode to binary string because Buf evq Buf is *incredibly* slow
		$rhs.decode('Binary') eq $lhs.decode('Binary') or return False;
	}
	return False if $right.read($size); #i.e. if right still has data somehow

	True;

}

sub files_are_different (Str $left_filename, Str $right_filename, Int :$max_bytes = $MAX) is export {
	my $result = files_are_equal($left_filename, $right_filename, max_bytes => $max_bytes);
	$result ~~ Failure ?? $result !! !$result;
}


=begin pod

=head1 NAME

File::Compare - Compare files to check for equality/difference

=head1 SYNOPSIS

	use File::Compare;
	
	say files_are_equal("file1.txt", "file2.txt");
	files_are_different("foo", "bar") ?? say "diff" !! say "same";

	say "we match" if files_are_equal("x.png", "y.png", max_bytes=> 4*1024*1024);
	say "OH NOES" if files_are_different("i/dont/exist", "me/neither") ~~ Failure;

=head1 DESCRIPTION

File::Compare checks two files, and compares them as byte-buffers.  The function C<files_are_equal> returns Bool::True if the files have the same contents, Bool::False if any bytes are different, and a Failure object if an error occurs.  The other function, C<files_are_different>, returns the opposite boolean values, and is simply provided for code readability sugar.

Both functions can take an optional named parameter, C<max_bytes>, which accepts any positive integer as a number of bytes.  This parameter tells File::Compare what size of chunks should be read from the disk at once, since the read operation is often the slowest.  The default reads 8 MiB of each file at a time.  A smaller value may be more useful in a memory-limited environment, or when files are most likely different.  A larger value could improve performance when files are most likely the same.

=head2 TODO

Support IO objects.

=head1 SEE ALSO

* L<File::Find::Duplicates> - searches directories and lists of files to find duplicate items.

=head1 AUTHOR

Brent "Labster" Laabs, 2013.

Released under the same terms as Perl 6; see the LICENSE file for details.

=end pod

