#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: pTandem.pl
#
#        USAGE: ./pTandem.pl (optional: # of threads)  
#
#  DESCRIPTION: wrapper for tandem software. The script will scan the data directory
#				and automatically create different input.xml files, this makes possible
#				to execute tandem for several input files wothout the need to modify
#				manually the xml files. The script also can be used to run tandem in
#				parallel mode passing as a commend line parameter the number of threads.
#
#      OPTIONS: int: number of threads to be used.
# REQUIREMENTS: x!Tandem or TPP in $PATH
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Felipe da Veiga Leprevost (Leprevost, F.V.), felipevl@umich.edu
# ORGANIZATION: University of Michigan.
#      VERSION: 1.0
#      CREATED: 05/06/2015 03:23:16 PM
#     REVISION: 001
#===============================================================================

use strict;
use warnings;
use utf8;
use v5.18;
use Parallel::ForkManager;

my ($MAX_PROCESSES) = @ARGV;

if ( !defined $MAX_PROCESSES ) {
	
	$MAX_PROCESSES = 1;
	say "only one core will be used, single file processing.";

} else {

	say "$MAX_PROCESSES cores will be used, multiple file processing";
}

my %map;
my $input;

chomp (my @data = `ls -1 data/`);

open( my $file, '<', 'input.xml' ) or die "Cannot find input file";
my @input = <$file>;

for my $line ( @input ) {

	$input .= $line;
}

for my $file ( @data ) {

	$map{$file} = $input;
}

system("mkdir temp/");
for my $key ( keys %map ) {
	
	$map{$key} =~ s/_file_/$key/;
	open( my $out, '>', "temp/input_$key.xml" );
	say $out $map{$key};
}

my @files = keys %map;

my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

DATA_LOOP:
for my $file ( keys %map ) {

	my $pid = $pm->start and next DATA_LOOP;
	#say "tandem temp/input_$file";
	system("tandem temp/input_$file.xml > log/$file.log");

	$pm->finish;
}
$pm->wait_all_children;

1;
