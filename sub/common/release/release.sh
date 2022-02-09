#! /bin/bash

repo_name="common"
release_dir="/projects/hydra/release/$repo_name"

xls_file="$release_dir/version_history.xls"
version_file="$release_dir/version.cfg"

githash=$(git rev-parse HEAD)
curr_version=$(< "$version_file")

git status

read -p "*Warning: Please stash any uncommitted changes!* Is the git status up-to-date? (y/n) " confirm

if ([[ $confirm == [yY] || $confirm == [yY][eE][sS] ]])
then
	read -p "The latest version is v$curr_version. What is the new version, with hash v$githash? " next_version
	read -p "New version will be from v$curr_version to v$next_version. Proceed? (y/n) " confirm_final
	if ([[ $confirm_final == [yY] || $confirm_final == [yY][eE][sS] ]])
	then
		echo "$next_version,$githash" | tee -a $xls_file > /dev/null
		echo "$next_version" | tee $version_file > /dev/null
		#git stash
		rm -rf common
		mkdir common && mkdir common/vip && mkdir common/sip && mkdir common/vip/cocotb && mkdir common/sip/src
		cp -r ../sip/src/* common/sip/src && cp ../vip/cocotb/common.py common/vip/cocotb/common.py
		echo "$next_version,$githash" | tee common/version.cfg > /dev/null
		mv common $release_dir/v$next_version
		#git stash pop
	else
		echo "Aborting!"
	fi
else
	echo "Please commit all changes before proceeding!"
	exit 1
fi
