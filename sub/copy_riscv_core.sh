#~ /bin/bash

repo_name="riscv_core"
release_dir="/repos/release/$repo_name"

xls_file="$release_dir/version_history.xls"
version_file="$release_dir/version.cfg"

latest_version=$(< "$version_file")

rm -r $repo_name
cp -r $release_dir/v$latest_version $repo_name
