#!/usr/bin/env perl

=head1 NAME

C<App::SoftPAQIndexParser> - Parses the SoftPAQ archive index file.

=cut

package App::SoftPAQIndexParser;

use strict;
use warnings;
use autodie;
use utf8;
use Carp;
use Data::Dumper;

=head1 METHODS

=over 4

=item C<main>()

The script's main entry point.

=cut

sub main {
	# Check if the index file was supplied.
	if (scalar(@ARGV) < 1) {
		die "Index file must be supplied.\n";
	}

	# A little header section.
	print "SoftPAQ Archive Index Parser\n";

	# Get the records in the index.
	my @strrecords = slurp_records($ARGV[0]);

	# Ignore the first record since it's just a header.
	shift @strrecords;

	# Go through the records parsing them.
	my @records = ();
	foreach my $rec (@strrecords) {
		my %record = parse_record($rec);
		push @records, \%record;
	}
}

=item I<%record> = C<parse_record>(I<$str>)

Transforms the text record from an index file into a hash containing the
elements of the record.

=cut

sub parse_record {
	my ($str) = @_;

	# Apply the big ugly regex.
	$str =~ m/
		^(?<exename>[^\s]+)\s+(?<url>[^\s]+)\s+(?<size>[^\s]+)\s+(?<date>[^\r\n]+)?[\r\n]{1,2}
		TITLE:(?<title>[^\r\n]+)[\r\n]{1,2}
		VERSION:(?<version>[^\r\n]+)[\r\n]{1,2}
		LANGUAGE:(?<lang>[^\r\n]+)[\r\n]{1,2}
		PRODUCTS\sAFFECTED:(?<products>[^\r\n]+)(?<ignored>[\r\n]{1,2}\s+\-[^\r\n]+)?[\r\n]{1,2}
		OS:(?<os>[^\r\n]+)[\r\n]{1,2}
		SUPERSEDES:(?<supersedes>[^\r\n]+)[\r\n]+
	/x;

	# Check if we actually were able to parse the record.
	if (not %+) {
		croak "Couldn't parse the record";
	}

	# Capture groups in a writeable hash.
	my %record = %+;

	# Sanitize the hash.
	foreach my $key (keys %record) {
		# Trim whitespace.
		$record{$key} =~ s/^\s+|\s+$//g;

		# Check for undefineds.
		if (length($record{$key}) == 0) {
			$record{$key} = undef;
		}
	}

	# Ensure we have the date field present.
	unless (exists $record{date}) {
		$record{date} = undef;
	}

	return %record;
}

=item I<@slurp_records> = C<slurp_records>(I<$fname>)

Slurps the records from an index file and returns them.

=cut

sub slurp_records {
	my ($fname) = @_;

	# Slurp it up.
	open my $fh, '<', $fname;
	local $/ = "\r\n\r\n";
	my @records = <$fh>;
	close $fh;
	
	return @records;
}

main();

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
