#!/usr/bin/perl
use strict;
use warnings;
# use Getopt::Std; # tested work on school machine
use File::Copy qw(copy);

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
my $commitMsgFileName = ".commitMsg";


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
		echo \"-1\" > $rootDirName/$branchName/$branchStateCommitNumberFileName;";
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

sub getCurrentCommitNumber {
	open (FILE, '<', "$rootDirName/".getCurrentBranch()."/$branchStateCommitNumberFileName");
	my $firstLine = <FILE>;
	chomp $firstLine;
	close FILE;
	return $firstLine;
}

sub getCurrentCommitFolderPath {
	return "$rootDirName/".getCurrentBranch()."/".getCurrentCommitNumber()."/";
}

sub getPreviousCommitFolderPath {
	my $previousCommitNum = getCurrentCommitNumber();
	$previousCommitNum -= 1;
	return "$rootDirName/".getCurrentBranch()."/".$previousCommitNum."/";
}

sub getCurrentBranchAddedFilePath {
	return "$rootDirName/".getCurrentBranch()."/$branchStateAddedFileFileName";
}

sub getCurrentBranchTrackedFilesIndexPath {
	return "$rootDirName/".getCurrentBranch()."/$branchStateTrackedFilesIndexFileName";
}

sub getAllFilesListedInBranchTrackedFilesIndexFile {
	open(my $fh, '<', getCurrentBranchTrackedFilesIndexPath()) 
		or die ".trackedFilesIndex does not exists $!";
	chomp(my @trackedFiles = <$fh>);
	close $fh;
	return @trackedFiles;
}

sub getAllFilesAddedToAddedFileTemporaryFile {
	open(my $fh, '<', getCurrentBranchAddedFilePath()) 
		or die ".BranchAddedFile does not exists $!";
	chomp(my @addedFiles = <$fh>);
	close $fh;
	return @addedFiles;
}

sub increaseBranchCommitNumberByOne {
	my $newCommitNum = 1 + getCurrentCommitNumber(); 
	open (FILE, '>', "$rootDirName/".getCurrentBranch()."/$branchStateCommitNumberFileName") 
		or die "CommitNumberFile does not exists $!";
	print FILE $newCommitNum;
	close FILE;
}

sub createAndInitNewCommitFolder {
	my ($commitMsg) = @_;

	# get next commit number
	my $nextCommitNum = getCurrentCommitNumber() + 1;
	# print "next commit number: $nextCommitNum\n";

	# create new commit folder
	my $return = mkdir "$rootDirName/".getCurrentBranch()."/$nextCommitNum";
	if ($return != 1) {
		die "Error creating new folder:".$!."\n";
	}

	# create new .commitMsg file and write commit msg
	system "touch "."$rootDirName/".getCurrentBranch()."/$nextCommitNum/$commitMsgFileName";
	open (FILE, ">", "$rootDirName/".getCurrentBranch()."/$nextCommitNum/$commitMsgFileName");
	print FILE $commitMsg;
	close FILE;

	# increase commit nubmer
	increaseBranchCommitNumberByOne();
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

	# Get already added files
	my @addedFiles = ();

	if (-e getCurrentBranchAddedFilePath()) {
		@addedFiles = getAllFilesAddedToAddedFileTemporaryFile();
	} else {
		system "touch ".getCurrentBranchAddedFilePath();
	}
	my %addedFilesHash = map { $_ => 1 } @addedFiles;

	# print "already exists files: \n";
	# foreach (sort keys %addedFilesHash) {
	# 	print "$_ : $addedFilesHash{$_}\n";
	# }

	# prepare write to .branchStatesAddedFile
	open(my $write_fh, '>>', getCurrentBranchAddedFilePath());

	foreach my $file (@filesToAdd) {
		if (-e $file and -f $file) {
			# check if it already exists in addedFilesHash			
			if(!exists($addedFilesHash{$file})) { 
				# write to `addedFile` 
				print $write_fh "$file\n";
			}
		} else {
			print "$file does not valid blah blah\n";
		}
	}

	close($write_fh);
}

sub commit {
	my ($commitMsg) = @_;
	checkIfRootDirExist();	

	if (! -e getCurrentBranchAddedFilePath()) {
		print "Nothing to commit, not sure just create a new commit or abort current execution\n";
		return;
	}

	# create the new commit directory, add commit message file
	createAndInitNewCommitFolder($commitMsg);

	# write addedFile to branchStatestrackedFilesIndex(committed tracking) if file not exists in trackingFile
	## get files listed in trackingFileIndex and added files
	my @trackedFiles = getAllFilesListedInBranchTrackedFilesIndexFile();
	my %trackedFilesHash = map { $_ => 1 } @trackedFiles;
	my @addedFiles = getAllFilesAddedToAddedFileTemporaryFile();
	## append to trackingFileIndex is file exists in addedFile but not trackingFileIndex
	open (my $write_fh, '>>', getCurrentBranchTrackedFilesIndexPath());
	foreach my $addedFile (@addedFiles) {
		if (!exists($trackedFilesHash{$addedFile})) {
			print $write_fh "$addedFile\n";
		}
	}
	close($write_fh);

	# copy files in addedFileIndex from disk to newly created commit folder
	my $currentCommitFolderPath = getCurrentCommitFolderPath();
	foreach my $addedFile (@addedFiles) {
		copy($addedFile, $currentCommitFolderPath.$addedFile);
	}

	# copy rest of tracked files from last commit folder 
	my $previousCommitFolderPath = getPreviousCommitFolderPath();
	if (-e $previousCommitFolderPath and -d $previousCommitFolderPath) { 
		# get rest of tracked files
		foreach my $addedFile (@addedFiles) {
			if (exists $trackedFilesHash{$addedFile}) {
				delete $trackedFilesHash{$addedFile}; 
			}
		}

		foreach my $trackedFile (keys %trackedFilesHash) {
			copy($previousCommitFolderPath.$trackedFile, $currentCommitFolderPath.$trackedFile);
		}
	}

	# remove temporary addedFile index file
	unlink getCurrentBranchAddedFilePath();

	# print Info
	print "Committed as commit ".getCurrentCommitNumber()."\n";
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

} elsif($ARGV[0] eq "commit") {
	# extract flags
	my $flag_a_set = 0;
	my $flag_m_set = 0;
	my $commitMsg = 0;
	foreach my $arg (@ARGV[1..@ARGV-1]) {
		if ($arg =~ m/^\-/) {
			if ($arg eq "-a") {
				$flag_a_set = 1;
			} elsif ($arg eq "-m") {
				$flag_m_set = 1;
			} else {
				die "unknown commit flag blah blah\n";
			}
		} elsif ($flag_m_set) {
			# make an assumption here, if -m set, the next msg do not start with - is commit msg
			$commitMsg = $arg;
		} else {
			die "unknown commit option\n";
		}
	}

	# do commit
	if ($flag_a_set) {
		
	}
	if ($flag_m_set) {
		commit($commitMsg);
	} else {
		die "no commit message blah blah\n";
	}
} else {
	die "legit.pl: error: unknown command $ARGV[0]\n".$helpMessage;
}


