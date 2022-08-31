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
use DBI;

=head1 METHODS

=over 4

=item C<main>()

The script's main entry point.

=cut

sub main {
	# Check if the required parameters were supplied.
	if (scalar(@ARGV) < 2) {
		die "Index file and database path must be supplied.\n";
	}

	# A little header section.
	print "SoftPAQ Archive Index Parser\n";

	# Get the records in the index.
	my @strrecords = slurp_records($ARGV[0]);

	# Open the database connection.
	my $dbh = DBI->connect("dbi:SQLite:dbname=" . $ARGV[1], "", "")
		or die "failed to connect to the database $DBI::errstr";

	# Go through the records parsing them.
	my $fail_counter = 0;
	foreach my $rec (@strrecords) {
		# Parse the record into a hash.
		my %record = parse_record($rec);
		if (not %record) {
			print "($fail_counter) FAILED TO PARSE RECORD:\n\"$rec\"\n\n";
			$fail_counter++;
			next;
		}

		# Insert record into the database.
		print 'Indexing ' . $record{exename} . '... ';
		my $sth = $dbh->prepare('INSERT INTO archives (exename, orig_url, ' .
			'size, rel_date, title, version, language, products, os, ' .
			'supersedes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
		$sth->bind_param(1, $record{exename});
		$sth->bind_param(2, $record{url});
		$sth->bind_param(3, $record{size});
		$sth->bind_param(4, $record{date});
		$sth->bind_param(5, $record{title});
		$sth->bind_param(6, $record{version});
		$sth->bind_param(7, $record{lang});
		$sth->bind_param(8, $record{products});
		$sth->bind_param(9, $record{os});
		$sth->bind_param(10, $record{supersedes});
		$sth->execute;
		print "done\n";
	}

	# Close the database connection.
	$dbh->disconnect;
	print "Parsing Failures: $fail_counter\n";
}

=item I<%record> = C<parse_record>(I<$str>)

Transforms the text record from an index file into a hash containing the
elements of the record.

=cut

sub parse_record {
	my ($str) = @_;

	# Apply the big ugly regex.
	$str =~ m/
		^(?<exename>[^\s]+)\s+(?<url>[^\s]+)\s+(?<size>[^\s]+)\s*(?<date>[^\r\n]+)?[\r\n]+
		TITLE:(?<title>[^\r\n]+)[\r\n]+
		VERSION:(?<version>[^\r\n]+)[\r\n]+
		LANGUAGE:(?<lang>[^\r\n]+)[\r\n]+
		PRODUCTS\sAFFECTED:(?<products>.+)(?=[\r\n]+OS:)[\r\n]+
		OS:(?<os>.+)(?=[\r\n]+SUPERSEDES:)[\r\n]+
		SUPERSEDES:(?<supersedes>[^\r\n]+)[\r\n]*$
	/sx;

	# Check if the record was parsed correctly.
	if (not %+) {
		return ();
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
	my @records = ();
	my $record = undef;

	# Slurp it up.
	open my $fh, '<', $fname;
	local $/ = "\r\n";

	# Go through the file line by line.
	while (my $line = <$fh>) {
		# Clean up the line string.
		$line =~ s/^\s+|[\s\r\n]+$//g;

		# Check if we aren't already retrieving a record.
		if (not defined $record) {
			# Check if we have the first line of a record.
			if ($line =~ /^[A-Z0-9]+\.EXE\s+ftp:\/\//) {
				$record = "$line\n";
			}
		} else {
			# Append line to record.
			$record .= "$line \n";

			# Check if we have finished retrieving a record.
			if ($line =~ /^SUPERSEDES:/) {
				# Push the new record to the list.
				push @records, $record;
				$record = undef;
			}
		}
	}

	# Close the file handle and return.
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
