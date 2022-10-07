#!/bin/bash

DEBIAN_FRONTEND=noninteractive
RESTY_VERSION=$1
dir=/tmp/openresty-$RESTY_VERSION
shift

add_dynamic_module=""
_module() {
	_url="$1"
	cd $dir
	url=$(echo $_url | awk -F'|' '{print $1}')
	module=$(echo $_url | awk -F'|' '{print $2}')
	srcdir=$(echo $_url | awk -F'|' '{print $3}')
	if [ -z "$module" ]; then
		module=$(basename $(echo $url | cut -d'/' -f5-) .git)
	fi
	add_dynamic_module="$add_dynamic_module --add-dynamic-module=$dir/$module/$srcdir"
	if [ ! -d "$dir/$module" ]; then
		cd $dir
		echo $git_clone $_url
		$git_clone $_url
	else
		cd $dir/$module
		git pull origin master
	fi
}

for url in $MODULES; do
	if [ -z "$url" ]; then continue; fi
	_module $url
done

cd $dir

eval ./configure $@ $add_dynamic_module
exit 0
