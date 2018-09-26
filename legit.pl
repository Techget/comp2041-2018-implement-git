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
my $masterBranchName = "master";


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

	OUTER: foreach my $file (@filesToAdd) {
		if (-e $file and -f $file) {
			# check if it already exists in trackFileIndex
			print "$rootDirName/".getCurrentBranch()."/$branchStateTrackedFilesIndexFileName";
			open(my $fh, '<', "$rootDirName/".getCurrentBranch()."/$branchStateTrackedFilesIndexFileName");
			INNER: while(my $line = <$fh>)  {   
			    if ($line eq $file) {
			    	print "File $file already added blah blah\n";
			    	close($fh);
			    	last OUTER;
			    }
			}
			close($fh);
			# append to .branchStatesTrackedFilesIndex,append
			open(my $write_fh, '>>', "$rootDirName/".getCurrentBranch()."/$branchStateTrackedFilesIndexFileName");  
			print $write_fh "$file\n";
			close($write_fh);
		} else {
			print "$file does not valid blah blah\n";
		}
	}
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



