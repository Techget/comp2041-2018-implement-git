#!/usr/bin/perl
use strict;
use warnings;

###### Universal variables
my $helpMessage = <<'END_MESSAGE';
Usage: legit.pl <command> [<args>]
blah blah
END_MESSAGE
my $rootDirName = ".legit";
my $legitStateFileName = ".legitStates";
my $branchStateTrackedFilesIndexFileName = ".branchStatesTrackedFilesIndex";
my $branchStateCommitNumberFileName = ".branchStatesCommitNumber";
my $masterBranchName = "master";


###### main switch case
if (@ARGV == 0) {
	print $helpMessage;
	exit 0;
}

if ($ARGV[0] eq "init") {
	init();
} elsif($ARGV[0] eq "add") {

} else {
	print "legit.pl: error: unknown command $ARGV[0]\n".$helpMessage;
}


###### functions
sub init {
	if (-e $rootDirName and -d $rootDirName) {
		print "$0: error: .legit already exists\n";
		return;
	}
	my $return = mkdir $rootDirName;
	if ($return != 1) {
		die "Error creating new folder:".$!."\n";
	} else {
		print "Initialized empty legit repository in $rootDirName\n";
	}

	system "touch $rootDirName/$legitStateFileName;
		echo \"current_branch = master\" > $rootDirName/$legitStateFileName";
	initBranch($masterBranchName);
}



###### helper functions
sub initBranch {
	# create new branch folder, and add .branchState file
	my ($branchName) = @_;
	my $return = mkdir $rootDirName."/$branchName";
	if ($return != 1) {
		die "Error creating new folder:".$!."\n";
	}

	system "touch $rootDirName/$branchName/$branchStateTrackedFilesIndexFileName; 
		touch $rootDirName/$branchName/$branchStateCommitNumberFileName;
		echo \"current_commit = -1\" > $rootDirName/$branchName/$branchStateCommitNumberFileName;";
}

# sub createCommit {

# }



