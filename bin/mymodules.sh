#!/bin/bash

NPS_VERSION=1.13.35.2-stable
DEBIAN_FRONTEND=noninteractive

prefix=/usr/local

RESTY_VERSION=$1
dir=/tmp/openresty-$RESTY_VERSION
shift
rm="echo rm"
add_dynamic_module=""
_lib_jasson() {
	cd $dir
	$rm -rf jansson
	git clone https://github.com/akheron/jansson.git
	cd jansson
	autoreconf -i
	./configure --prefix=$prefix
	make install
}
_lib_maxmind() {
	cd $dir
	$rm -rf libmaxminddb
	git clone --recursive https://github.com/maxmind/libmaxminddb
	cd libmaxminddb
	./bootstrap
	./configure --prefix=$prefix
	make install
}
_lib_lmdb() {
	cd $dir
	$rm -rf lmdb
	if [ ! -d "lmdb" ]; then git clone https://github.com/LMDB/lmdb.git; fi
	cd lmdb/libraries/liblmdb/
	git pull origin master
	make -j$(nproc) install
	export LMDB_INC=/usr/local/include
	export LMDB_LIB=/usr/local/lib
}
_lib_sregex() {
	cd $dir
	$rm -rf sregex
	if [ ! -d "sregex" ]; then
		git clone https://github.com/openresty/sregex.git
	fi
	cd sregex
	git pull origin master
	make -j$(nproc) install
}

_lib_hyperscan() {
	cd $dir
	$rm -rf hyperscan
	if [ ! -d "hyperscan" ]; then
		git clone https://github.com/intel/hyperscan.git
	fi
	cd hyperscan
	git pull origin master
	cmake -DBUILD_STATIC_AND_SHARED=ON .
	make -j$(nproc) install
}
_lib_cidr() {
	cd $dir
	$rm -rf libcidr-1.2.3
	curl -skLO https://www.over-yonder.net/~fullermd/projects/libcidr/libcidr-1.2.3.tar.xz
	tar -xJf libcidr-1.2.3.tar.xz
	cd libcidr-1.2.3
	make install
}
_lib_pcre() {
	cd $dir
	$rm -rf pcre-8.44
	curl -skLO https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
	tar xvzf pcre-8.44.tar.gz
	cd pcre-8.44
	./configure --prefix=$prefix
	make install
}
_lib_jwt() {
	cd $dir
	$rm -rf libjwt-1.10.2
	curl -skLO https://github.com/benmcollins/libjwt/archive/v1.10.2.tar.gz
	tar xvzf v1.10.2.tar.gz
	cd libjwt-1.10.2
	autoreconf -i
	./configure --prefix=$prefix
	make -j$(nproc) install
}
_lib_xtea() {
	cd $dir
	$rm -rf xxtea-c
	if [ ! -d "xxtea-c" ]; then git clone https://github.com/xxtea/xxtea-c.git; fi
	cd xxtea-c
	cmake .
	make -j$(nproc) install
}
_lib_gd() {
	cd $dir
	$rm -rf libimagequant
	git clone https://github.com/ImageOptim/libimagequant.git
	cd libimagequant
	./configure --prefix=$prefix
	make libimagequant
	make install
	$rm -rf libgd
	git clone https://github.com/libgd/libgd.git
	cd libgd
	./configure --prefix=$prefix
	make install
}
_lib_small_light() {
	cd $dir
	$rm -rf ngx_small_light
	if [ ! -d "ngx_small_light" ]; then git clone https://github.com/cubicdaiya/ngx_small_light.git; fi
	cd ngx_small_light
	git pull origin master
	./setup --with-imlib2 --with-gd
}
_lib_ssdeep() {
	cd $dir
	$rm -rf ssdeep
	if [ ! -d "ssdeep" ]; then git clone https://github.com/ssdeep-project/ssdeep.git; fi
	cd ssdeep
	git pull origin master
	./bootstrap
	./configure --prefix=$prefix
	make -j$(nproc) install
}
_lib_injection() {
	cd $dir
	$rm -rf libinjection
	git clone https://github.com/client9/libinjection.git
	cd libinjection
	make all
	make install
	install src/libinjection.so /usr/local/lib
}
_ngx_brotli() {
	cd $dir
	$rm -rf ngx_brotli
	git clone https://github.com/google/ngx_brotli.git
	cd ngx_brotli
	git submodule update --init
}
_ngx_modsecurity() {
	_lib_lmdb
	_lib_maxmind
	cd $dir
	$rm -rf ModSecurity
	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
	cd ModSecurity
	git pull origin v3/master
	git submodule init
	git submodule update
	./build.sh
	./configure --prefix=$prefix --with-lmdb
	make -j$(nproc) install
}

_pagespeed() {

	cd $dir
	echo "$dir/pagespeed/incubator-pagespeed-ngx-$NPS_VERSION"
	#if [ ! -d "$dir/pagespeed/incubator-pagespeed-ngx-$NPS_VERSION" ]; then
	$rm -rf $dir/pagespeed
	mkdir -p $dir/pagespeed
	cd $dir/pagespeed
	wget -c https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip
	unzip v${NPS_VERSION}.zip
	nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d)
	cd "$nps_dir"
	NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
	NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
	psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
	[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
	wget -c ${psol_url}
	tar -xzvf $(basename ${psol_url}) # extracts to psol/
	#fi
	add_dynamic_module="$add_dynamic_module --add-dynamic-module=$dir/pagespeed/incubator-pagespeed-ngx-$NPS_VERSION"
}
MODULES="\
	https://github.com/Taymindis/nginx-link-function \
	https://github.com/SpiderLabs/ModSecurity-nginx.git \
	https://github.com/vozlt/nginx-module-sts.git \
	https://github.com/vozlt/nginx-module-stream-sts.git \
	https://github.com/vozlt/nginx-module-vts.git \
	https://github.com/baysao/ngx_stream_dns_proxy_module.git \
	https://github.com/nginx-modules/ngx_cache_purge.git \
	https://github.com/leev/ngx_http_geoip2_module.git \
        https://github.com/apache/incubator-pagespeed-ngx.git|pagespeed|incubator-pagespeed-ngx-$NPS_VERSION \
"

_dependencies() {
	_lib_jasson
	_lib_injection
	_lib_lmdb
	_lib_sregex
	_lib_cidr
	_lib_jwt
	_lib_xtea
	_lib_ssdeep
	_ngx_modsecurity
	#_lib_small_light
	_pagespeed
}

apt install -y build-essential cmake autoconf libtool wget uuid-dev python2-minimal
ln -sf /usr/bin/python2 /usr/bin/python
_dependencies
echo $MODULES
exit 0
