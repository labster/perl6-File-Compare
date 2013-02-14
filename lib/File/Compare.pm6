module File::Compare;
use v6;

my $MAX = 8*1024*1024;    # Default maximum bytes for .read

sub files_are_equal (Str $left_filename, Str $right_filename, Int :$chunk_size = $MAX) is export {
	unless $chunk_size > 0 { die "Argument \$chunk_size must be a positive number" } 

	my $left_path  = $left_filename\.path;
	my $right_path = $right_filename.path;

	fail "Cannot read file: '$right_filename'" unless $right_path.r;
	fail "Cannot read file: '$left_filename'"  unless $left_path\.r;

	return False unless (my $size = $left_path.s) == $right_path.s;
	return True  if $size == 0;

	my $left  = $left_path\.open;
	my $right = $right_path.open;

	$size min= $chunk_size;

	while my $lhs := $left.read($size) {
		my $rhs := $right.read($size) or return False;

		# decode to binary string because Buf evq Buf is *incredibly* slow
		$rhs.decode('Binary') eq $lhs.decode('Binary') or return False;
	}
	return False if $right.read($size); #i.e. if right still has data somehow

	True;

}

sub files_are_different (Str $left_filename, Str $right_filename, Int :$chunk_size = $MAX) is export {
	my $result = files_are_equal($left_filename, $right_filename, chunk_size => $chunk_size);
	$result ~~ Failure ?? $result !! !$result;
}


=begin pod

=head1 NAME

File::Compare - Compare files to check for equality/difference

=head1 SYNOPSIS

	use File::Compare;
	
	if files_are_equal("file1.txt", "file2.txt")
		{ say "These are identical files"; }
	files_are_different("foo", "bar") ?? say "diff" !! say "same";

	say "we match" if files_are_equal("x.png", "y.png", chunk_size=> 4*1024*1024);
	say "OH NOES" if files_are_different("i/dont/exist", "me/neither") ~~ Failure;

=head1 DESCRIPTION

File::Compare checks two files, and compares them as byte-buffers if they are of the same size.  The function C<files_are_equal> returns Bool::True if the files have the same contents, Bool::False if any bytes are different, and a Failure object if an error occurs.  The other function, C<files_are_different>, returns the opposite boolean values, and is mostly provided for code readability sugar.  Note that Failure Boolifies to False, so the behavior is slightly different between the two functions.

Both functions can take an optional named parameter, C<chunk_size>, which accepts any positive integer.  This parameter tells File::Compare what size of chunks should be read from the disk at once, since the read operation is often the slowest.  The default reads 8 MiB of each file at a time.  A smaller value may be more useful in a memory-limited environment, or when files are most likely different.  A larger value could improve performance when files are most likely the same.

=head1 DIFFERENCES FROM PERL 5 VERSION

This code returns boolean values and Failure objects instead of 1, 0, -1 for difference, equality, and failure respectively.  The read chunk size is also increased four-fold because you're not really trying to run Rakudo on a 80486 processor, are you?

=head2 Comparing Text

This Perl 6 version drops the C<compare_text> function that was included in Perl 5.  Since most text files are of managable size, consider this code, which uses Perl's native newline handling:
	C<"file1".path.open.lines eq "file2".path.open.lines>
Functions can be evaluated on this as well:
	C<foo( "old/script.p6".path.open.lines ) eq foo( "new/script.p6".path.open.lines )>
Though, you may be better off looking at a module like L<Text::Diff> instead.

=head1 TODO

Support IO objects as parameters.

=head1 SEE ALSO

* L<File::Find::Duplicates> - Searches directories and lists of files to find duplicate items.
* L<Text::Diff> - Perform diffs on files and record sets.

=head1 AUTHOR

Brent "Labster" Laabs, 2013.

Released under the same terms as Perl 6; see the LICENSE file for details.

=end pod

