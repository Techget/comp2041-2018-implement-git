#!/usr/bin/perl
use strict;
use warnings;

###### Universal variables
my $helpMessage = <<'END_MESSAGE';
Usage: legit.pl <command> [<args>]
blah blah
END_MESSAGE
my $rootDirName = ".legit";
my $legitStateCurrentBranchFileName = ".legitStatesCurrentBranch";
my $branchStateTrackedFilesIndexFileName = ".branchStatesTrackedFilesIndex";
my $branchStateCommitNumberFileName = ".branchStatesCommitNumber";
my $branchStateAddedFileFileName = ".branchStatesAddedFiles"; # ad hoc, only exists between add and commit
my $masterBranchName = "master";


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

sub checkIfRootDirExist {
	if (!(-e $rootDirName and -d $rootDirName)) {
		die "$0: error: .legit does not exit, please init first blah blah\n";
	}
}

sub getCurrentBranch {
	open( FILE, "<$rootDirName/$legitStateCurrentBranchFileName" ); 
    my @LINES = <FILE>; 
    close(FILE);
    chomp $LINES[0];
    return $LINES[0];
}

# sub createCommit {

# }



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

	system "touch $rootDirName/$legitStateCurrentBranchFileName;
		echo \"master\" > $rootDirName/$legitStateCurrentBranchFileName";
	initBranch($masterBranchName);
}

sub add {
	my @filesToAdd = @_;
	checkIfRootDirExist();	

	# Get already tracked files
	open(my $fh, '<', "$rootDirName/".getCurrentBranch()."/$branchStateTrackedFilesIndexFileName");
	chomp(my @trackedFiles = <$fh>);
	close $fh;

	if (-e "$rootDirName/".getCurrentBranch()."/$branchStateAddedFileFileName") {
		open (my $fh, '<', "$rootDirName/".getCurrentBranch()."/$branchStateAddedFileFileName");
		while (my $line = <$fh>) {
			chomp $line;
			push @trackedFiles, $line;
		}
	} else {
		system "touch "."$rootDirName/".getCurrentBranch()."/$branchStateAddedFileFileName";
	}
	my %trackedFilesHash = map { $_ => 1 } @trackedFiles;

	# print "already exists files: \n";
	# foreach (sort keys %trackedFilesHash) {
	# 	print "$_ : $trackedFilesHash{$_}\n";
	# }

	# prepare write to .branchStatesAddedFile
	open(my $write_fh, '>>', "$rootDirName/".getCurrentBranch()."/$branchStateAddedFileFileName");

	foreach my $file (@filesToAdd) {
		if (-e $file and -f $file) {
			# check if it already exists in trackedFilesHash			
			if(!exists($trackedFilesHash{$file})) { 
				# write to `addedFile` 
				print $write_fh "$file\n";
			}
		} else {
			print "$file does not valid blah blah\n";
		}
	}

	close($write_fh);
}


###### main switch case
if (@ARGV == 0) {
	print $helpMessage;
	exit 0;
}

if ($ARGV[0] eq "init") {
	init();
} elsif($ARGV[0] eq "add") {
	add(@ARGV[1..@ARGV-1]);
} else {
	print "legit.pl: error: unknown command $ARGV[0]\n".$helpMessage;
}


