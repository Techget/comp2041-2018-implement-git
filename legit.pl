#!/usr/bin/perl
use strict;
use warnings;
use File::Copy qw(copy);
use File::Compare;
use File::Copy::Recursive qw(dircopy);

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
sub mergeTwoArrayUnique {
	my ($one_ref, $two_ref) = @_;
    my @one = @{ $one_ref };       # dereferencing and copying each array
    my @two = @{ $two_ref };

	my @vals = ();
	push @vals, @one, @two;
	my %out;
	map { $out{$_}++ } @vals;
	my @uniqueMerged = keys %out;
	return @uniqueMerged;
}

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
	if (-e getCurrentBranchAddedFilePath()) {
		open(my $fh, '<', getCurrentBranchAddedFilePath()) 
			or die ".BranchAddedFile does not exists $!";
		chomp(my @addedFiles = <$fh>);
		close $fh;
		return @addedFiles;
	} else {
		return ();
	}
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

sub commitDashA {
	my @addedFiles = getAllFilesAddedToAddedFileTemporaryFile();
	my @trackedFiles = getAllFilesListedInBranchTrackedFilesIndexFile();
	my @merged = mergeTwoArrayUnique(\@addedFiles, \@trackedFiles);

	my %addedFilesHash = map { $_ => 1 } @addedFiles;

	if (! -e getCurrentBranchAddedFilePath()) {
		system "touch ".getCurrentBranchAddedFilePath();
	}
	# '>' will overwrite current file
	open (FILE, '>', getCurrentBranchAddedFilePath()) or die "cannot open $!";
	foreach (@merged) {
		print FILE "$_\n";
	}
	close (FILE);
}


sub rmStatusCheck {
	my (@rmFiles) = @_;
	my $currentBranch = getCurrentBranch();
	my $currentCommit = getCurrentCommitNumber();

	foreach my $file (@rmFiles) {
		if (compare($file, "$rootDirName/$currentBranch/$currentCommit/$file") != 0) {
			die "$file is different to the last commit\n";
		}
	}

	return 1;
}

sub rmCachedFiles {
	my (@rmFiles) = @_;
	my %rmFilesHash = map { $_ => 1 } @rmFiles;

	my @trackedFiles = getAllFilesListedInBranchTrackedFilesIndexFile();

	# overwrite
	open (FILE, '>', getCurrentBranchTrackedFilesIndexPath());
	foreach my $file (@trackedFiles) {
		if (!exists $rmFilesHash{$file}) {
			print FILE "$file\n";
		}
	}
	close (FILE);
}

sub rmFiles {
	my (@rmFiles) = @_;

	rmCachedFiles(@rmFiles);

	foreach my $file (@rmFiles) {
		unlink $file;
	}
}

sub createNewBranch {
	my ($branchName) = @_;
	my $newBranchPath = "$rootDirName/$branchName/";

	# check branch does not exists in .legit/
	if (-d $newBranchPath) {
		print "branch already exists\n";
		exit 1;
	}

	mkdir $newBranchPath;	
	dircopy("$rootDirName/".getCurrentBranch()."/", $newBranchPath);
}

sub deleteBranch {
	my ($branchName) = @_;
	my $branchPath = "$rootDirName/$branchName/";

	if (! -d $branchPath) {
		print "branch does not exist\n";
		exit 1;
	}

	rmdir $branchPath;
}

sub branchCheckout {
	my ($branchName) = @_;
	my $branchPath = "$rootDirName/$branchName/";

	# check if the branch exists
	if (! -d $branchPath) {
		print "branch does not exist\n";
		exit 1;
	}

	# change the .legitStatesCurrentBranch
	open (FILE, '>', "$rootDirName/$legitStateCurrentBranchFileName") or die "cannot open $!";
	print FILE $branchName;
	close (FILE);
}



###### main function
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
		# merge temporary addFileIndex and branchStatesTrackedIndex
		commitDashA();
	}
	if ($flag_m_set) {
		commit($commitMsg);
	} else {
		die "no commit message blah blah\n";
	}
} elsif ($ARGV[0] eq "log") {
	checkIfRootDirExist();
	# ls get the filenames, 

	# sort in reverse order, 

	# print out

} elsif ($ARGV[0] eq "show") {
	checkIfRootDirExist();
	# just show the file in specified spciefied folder

} elsif ($ARGV[0] eq "rm") {
	checkIfRootDirExist();
	# extract flags
	my $flag_force_set = 0;
	my $flag_cached_set = 0;
	foreach my $arg (@ARGV[1..@ARGV-1]) {
		if ($arg =~ m/^\-/) {
			if ($arg eq "--cached") {
				$flag_cached_set = 1;
			} elsif ($arg eq "--forced") {
				$flag_force_set = 1;
			} else {
				die "unknown rm option\n";
			}
		} 
	}

	my @args = @ARGV[1..@ARGV-1];
	my @rmFiles = grep(!/^\-/, @args);

	if ($flag_cached_set && ($flag_force_set || rmStatusCheck(@rmFiles))) {
		rmCachedFiles(@rmFiles);
	} elsif ($flag_force_set || rmStatusCheck(@rmFiles)) {
		rmFiles(@rmFiles);
	}
} elsif ($ARGV[0] eq "status") {
	checkIfRootDirExist();
	# compare between files in the folder with files in the lastest commit folder

	# if it not in the commit folder, then check if the addedFileIndex exists

	# if both not, untracked

	# Also, compare .branchStatesTrakcedFileIndex with files in the folder, if mismatch,
	# should be file deleted manually

	# last but not least, in the example the `e - deleted`, I think should not exist, since deleted 
	# in folder and index, should no longer have knowledge about that file, check on piazza, if still needed
	# one ugly fix is: record the deleted fild in another file, may call that `.branchStatesRMedFiles` 

} elsif ($ARGV[0] eq "branch") {
	checkIfRootDirExist();
	my $flag_d_set = 0;
	foreach my $arg (@ARGV[1..@ARGV-1]) {
		if ($arg =~ m/^\-/) {
			if ($arg eq "-d") {
				$flag_d_set = 1;
			}
		}
	}

	my @args = @ARGV[1..@ARGV-1];
	my @branchNames = grep(!/^\-/, @args);
	# make an assumption, only one branch name for each command
	my $branchName = $branchNames[0];

	if ($flag_d_set) {
		# delete branch
		deleteBranch($branchName);
	} else {
		# create new branch
		createNewBranch($branchName);
	}
} elsif ($ARGV[0] eq "checkout") {

	checkIfRootDirExist();
	branchCheckout($ARGV[1]);

} elsif ($ARGV[0] eq "merge") {
	checkIfRootDirExist();
	# use commit number, last modfieid time to merge

} else {
	die "legit.pl: error: unknown command $ARGV[0]\n".$helpMessage;
}


