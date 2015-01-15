#!/bin/sh

TESTBED=""

run_dch() {
	/bin/sh $TESTROOT/../dch_git_describe.sh
}

create_dch() {
	EDITOR=true dch --create --empty --newversion 1.0
}

git_init() {
	git init --quiet .
}

sep_git_init() {
	export GBP_GIT_DIR=$TESTBED/sepgit
	mkdir sepgit
	pushd sepgit > /dev/null
	git_init
	popd > /dev/null
}

git_fill() {
	(
	echo hello > foo.txt
	git add foo.txt
	git commit -m "hello"
	git tag debian/1.0
	) > /dev/null
}

sep_git_fill() {
	pushd sepgit > /dev/null
	git_fill
	popd > /dev/null
}

setUp() {
	TESTBED=`mktemp -d`
	pushd $TESTBED > /dev/null
	mkdir -p debian
}

tearDown() {
	popd > /dev/null 
	[ -z "$TESTBED" ] && exit 1

	rm -rf $TESTBED/.git

	rm -f $TESTBED/debian/changelog
	[ -d $TESTBED/debian ] && rmdir $TESTBED/debian

	[ -d $TESTBED/sepgit ] && rm -rf $TESTBED/sepgit

	rmdir $TESTBED
}

testNoDCH() {
	assertFalse "Did not fail even due to dch absence" run_dch
}


testNoGit() {
	create_dch
	assertFalse "Did not fail even due to git absence" run_dch
}

testEmptyDCH() {
	git_init

	touch debian/changelog
	assertFalse "Did not fail even due to empty DCH" run_dch
}

testGbpSeperatedDirEmpty() {
	create_dch
	mkdir $TESTBED/sepgit
	export GBP_GIT_DIR=$TESTBED/sepgit
	assertFalse "Did not fail even due to empty GBP_GIT_DIR" run_dch
}

testGbpSeperatedDirDoesNotExist() {
	create_dch
	export GBP_GIT_DIR=$TESTBED/sepgit
	assertFalse "Did not fail even due not existing GBP_GIT_DIR" run_dch
}

testGbpSeperatedDirVanillaTag() {
	create_dch
	sep_git_init
	sep_git_fill
	assertTrue "Simple GBP run failed" run_dch
}



TESTROOT=$(pwd)
	
echo "Running tests:"

. shunit2
