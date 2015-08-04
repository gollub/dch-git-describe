#!/bin/sh

TESTBED=""


get_version() {
	dpkg-parsechangelog 2> /dev/null | grep -E '^Version:' | awk '{ print $2 }'
}

run_dch() {
	/bin/bash -x $TESTROOT/../dch_git_describe
}

create_dch() {
        VER=$1
        [ -z "$VER" ] && VER=1.0
	rm -f debian/changelog
	EDITOR=true dch --create --empty --newversion $VER
}

git_init() {
	git init --quiet .
}

sep_git_init() {
	export GBP_GIT_DIR=$TESTBED/sepgit/.git
	mkdir -p sepgit
	pushd sepgit > /dev/null
	git_init
	popd > /dev/null
}

git_tag() {
	(
        VER=$1
        [ -z "$VER" ] && VER=1.0
	git tag debian/$(echo $VER | sed 's/:/%/' | sed 's/~/_/g')
	) > /dev/null
}

git_fill() {
	(
	echo hello$1 > foo.txt
	git add foo.txt
	git commit -m "hello $1"
	) > /dev/null
}

sep_git_tag() {
	VER=$1
	pushd sepgit > /dev/null
	git_tag $VER
	popd > /dev/null
}

sep_git_fill() {
	pushd sepgit > /dev/null
	git_fill $1
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
	sep_git_init
	create_dch
	sep_git_fill
	sep_git_tag
	assertTrue "Simple GBP run failed" run_dch
}

version_test() {
	local TEST_VER=$1

	#run_dch
	#head -n1 debian/changelog
	assertTrue "Test version $TEST_VER GBP run failed" run_dch
	assertEquals $TEST_VER $(get_version | sed 's/\(.*+g\).*/\1/g' )
}

full_version_test() {
	local TEST_VER="$1"

	export GBP_GIT_DIR=$TESTBED/sepgit

	sep_git_init
	create_dch $TEST_VER
	sep_git_fill
	sep_git_tag $TEST_VER

	version_test $TEST_VER

	sep_git_fill "A"
	create_dch $TEST_VER
	version_test "$TEST_VER+1+g"

	sep_git_fill "B"
	sep_git_fill "C"
	create_dch $TEST_VER
	version_test "$TEST_VER+3+g"
}


testEpochNative() {
	full_version_test "1:2.3"
}

testEpochNonNative() {
	full_version_test "1:2.3-0vyatta3"
}

testNonNative() {
	full_version_test "2.3-0vyatta3"
}

testNative() {
	full_version_test "2.3"
}

testDFSG() {
	full_version_test "5.7.2.1~dfsg-7+vyatta3"
}

testBZR() {
	full_version_test "0.7.6~bzr1022-0vyatta1"
}

testTooMayHypehn() {
	full_version_test "2:9.4.6-1770165-2vyatta5"
}

testTooMayHypehn2() {
	full_version_test "3.4-10-0vyatta16"
}

testDebUbdate() {
	full_version_test "4.5.2-1.5+deb7u7vyatta2"
}

TESTROOT=$(pwd)
	
echo "Running tests:"

. shunit2
