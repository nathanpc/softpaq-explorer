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

our $fail_counter = 0;

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

	# Go through the records parsing them.
	my @records = ();
	foreach my $rec (@strrecords) {
		my %record = parse_record($rec);
		push @records, \%record;
	}

	print "FAILS: $fail_counter\n";
}

=item I<%record> = C<parse_record>(I<$str>)

Transforms the text record from an index file into a hash containing the
elements of the record.

=cut

sub parse_record {
	my ($str) = @_;

	# Apply the big ugly regex.
	$str =~ m/
		^(?<exename>[^\s]+)\s+(?<url>[^\s]+)\s+(?<size>[^\s]+)\s+(?<date>[^\r\n]+)?[\r\n]+
		TITLE:(?<title>[^\r\n]+)[\r\n]+
		VERSION:(?<version>[^\r\n]+)[\r\n]+
		LANGUAGE:(?<lang>[^\r\n]+)[\r\n]+
		PRODUCTS\sAFFECTED:(?<products>.+)(?=[\r\n]+OS:)[\r\n]+
		OS:(?<os>.+)(?=[\r\n]+SUPERSEDES:)[\r\n]+
		SUPERSEDES:(?<supersedes>[^\r\n]+)[\r\n]+
	/sx;

	# Check if we actually were able to parse the record.
	if (not %+) {
		print "FAILED TO PARSE THIS RECORD:\n";
		print Dumper($str);
		$fail_counter++;
		carp "Couldn't parse the record";
		print "\n\n";
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

	# Ignore the first record since it's just a header.
	shift @records;
	
	return sanitize_records(@records);
}

=item I<@sanitized_recs> = C<sanitize_records>(I<@slurp_records>)

Grabs the slurped records and sanitizes them a bit.

=cut

sub sanitize_records {
	my @dirty = @_;
	my @records = ();

	# Go through the records finding the ones that were cut in half.
	for (my $i = 0; $i < scalar(@dirty); $i++) {
		my $record = $dirty[$i];
		
		# Check if the record is complete.
		if ($record =~ /SUPERSEDES:([^\r\n]+)[\r\n]+$/) {
			push @records, $record;
		}

		# Looks like we need to join two "records" that were split.
		$i++;
		$record .= $dirty[$i];
		push @records, $record;
	}

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
