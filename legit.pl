#!/usr/bin/perl
use strict;
use warnings;

my $helpMessage = <<'END_MESSAGE';
Usage: legit.pl <command> [<args>]

END_MESSAGE

if (@ARGV == 0) {
	print $helpMessage;
	exit 0;
}

print $ARGV[0];

if ($ARGV[0] eq "init") {

} elsif($ARGV[0] eq "add") {

} else {
	print "legit.pl: error: unknown command $ARGV[0]\n".$helpMessage;
	exit 0;
}





sub init {
	# system 
}


