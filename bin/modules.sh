#!/bin/bash
#echo "$0 $@" >/app/build/_build/module.sh
NPS_VERSION=1.13.35.2-stable
DEBIAN_FRONTEND=noninteractive
dir=$1
prefix=$2
module=$3

shift 3
add_dynamic_module=""
_lib_maxmind() {
	cd $dir
	git clone --recursive https://github.com/maxmind/libmaxminddb
	cd libmaxminddb
	./bootstrap
	./configure
	make install
}
_lib_lmdb() {
	cd $dir
	if [ ! -d "lmdb" ]; then git clone https://github.com/LMDB/lmdb.git; fi
	cd lmdb/libraries/liblmdb/
	git pull origin master
	make -j$(nproc) install
	export LMDB_INC=/usr/local/include
	export LMDB_LIB=/usr/local/lib
}
_lib_sregex() {
        cd $dir
        if [ ! -d "sregex" ]; then
                git clone https://github.com/openresty/sregex.git
        fi
        cd sregex
        git pull origin master
        make -j$(nproc) install
}

_lib_hyperscan() {
	cd $dir
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
	curl -skLO https://www.over-yonder.net/~fullermd/projects/libcidr/libcidr-1.2.3.tar.xz
	tar -xJf libcidr-1.2.3.tar.xz
	cd libcidr-1.2.3
	make install
}
_lib_pcre(){
	cd $dir
	curl -skLO https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
	tar xvzf pcre-8.44.tar.gz
	cd pcre-8.44
	./configure ; make install
}
_lib_jwt() {
	cd $dir
	curl -skLO https://github.com/benmcollins/libjwt/archive/v1.10.2.tar.gz
	tar xvzf v1.10.2.tar.gz
	cd libjwt-1.10.2
	autoreconf -i
	./configure
	make -j$(nproc) install
}
_lib_xtea() {
	cd $dir
	if [ ! -d "xxtea-c" ]; then git clone https://github.com/xxtea/xxtea-c.git; fi
	cd xxtea-c
	cmake .
	make -j$(nproc) install
}
_lib_gd() {
cd $dir
git clone https://github.com/ImageOptim/libimagequant.git
cd libimagequant
./configure ; make libimagequant;make install
git clone https://github.com/libgd/libgd.git
cd libgd
./configure
make install
}
_lib_small_light() {
	cd $dir
	if [ ! -d "ngx_small_light" ]; then git clone https://github.com/cubicdaiya/ngx_small_light.git; fi
	cd ngx_small_light
	git pull origin master
	./setup --with-imlib2 --with-gd
}
_lib_ssdeep() {
	cd $dir
	if [ ! -d "ssdeep" ]; then git clone https://github.com/ssdeep-project/ssdeep.git; fi
	cd ssdeep
	git pull origin master
	./bootstrap
	./configure
	make -j$(nproc) install
}
_lib_injection(){
 	cd $dir
	git clone https://github.com/client9/libinjection.git
	cd libinjection; make install
	install src/libinjection.so /usr/local/lib
}
_ngx_brotli(){
	cd $dir
	git clone https://github.com/google/ngx_brotli.git
	cd ngx_brotli
	git submodule update --init
}
_ngx_modsecurity() {
	_lib_lmdb
	_lib_maxmind
	cd $dir
	if [ ! -d "ModSecurity" ]; then
		git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
	fi
	cd ModSecurity
	git pull origin v3/master
	git submodule init
	git submodule update
	./build.sh
	./configure --with-lmdb
	make -j$(nproc) install
}
_dependencies() {
	_lib_injection
	_lib_lmdb
	_lib_sregex
	_lib_cidr
	_lib_jwt
	_lib_xtea
	_lib_ssdeep
	_ngx_modsecurity
	_lib_small_light
}

_module() {
    _url="$1"
    shift
    _opt="$@"
	cd $dir
	url=$(echo $_url | awk -F'|' '{print $1}')
	srcdir=$(echo $_url | awk -F'|' '{print $2}')
	echo "srcdir:$srcdir"
	module=$(basename $(echo $url | cut -d'/' -f5-) .git)
	echo "module:$module"
	add_dynamic_module="$add_dynamic_module --add-dynamic-module=$dir/$module/$srcdir $_opt"
	if [ ! -d "$dir/$module" ]; then
		cd $dir
		echo git clone $url
		git clone $url
	else
		cd $dir/$module
		git pull origin master
	fi
	if [ "$module" = "nginx-link-function" ]; then
		install $dir/nginx-link-function/src/ngx_link_func_module.h /usr/local/include/
	fi
	 if [ "$module" = "https://github.com/SpiderLabs/ModSecurity-nginx.git" ]; then
			_ngx_modsecurity
	#		_module $module  --with-compat
	 fi
	if [ "$module" = "https://github.com/google/ngx_brotli.git" ]; then
		_ngx_brotli
	fi
	if [ "$module" = "https://github.com/vislee/ngx_http_waf_module.git" ]; then
			_lib_pcre
			_lib_hyperscan
	fi
	#	_$module
}
_pagespeed() {
	#if [ ! -d "$dir/pagespeed" ];then
	cd $dir
	echo "$dir/pagespeed/incubator-pagespeed-ngx-$NPS_VERSION"
	#if [ ! -d "$dir/pagespeed/incubator-pagespeed-ngx-$NPS_VERSION" ]; then
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
#fi
# cd $dir
# eval ./configure --prefix=/app/bin/openresty $@ \
# 	--add-dynamic-module=$dir/pagespeed/incubator-pagespeed-ngx-$NPS_VERSION \
# 	$add_dynamic_module


urls="\
	https://github.com/Taymindis/nginx-link-function \
	https://github.com/winshining/nginx-http-flv-module.git \
	https://github.com/SpiderLabs/ModSecurity-nginx.git \
	https://github.com/vozlt/nginx-module-sts.git \
	https://github.com/vozlt/nginx-module-stream-sts.git \
	https://github.com/vozlt/nginx-module-vts.git \
	https://github.com/baysao/ngx_stream_dns_proxy_module.git \
	https://github.com/nginx-modules/ngx_cache_purge.git \
	https://github.com/arut/nginx-live-module.git \
	https://github.com/arut/nginx-ts-module.git \
	https://github.com/leev/ngx_http_geoip2_module.git \
	https://github.com/kaltura/nginx-vod-module.git \
"
urls1="\
	https://github.com/nbs-system/naxsi.git|naxsi_src \
	https://github.com/kaltura/nginx-secure-token-module.git \
	https://github.com/fdintino/nginx-upload-module.git \
	https://github.com/TeslaGov/ngx-http-auth-jwt-module.git \
	https://github.com/ruslantalpa/lua-upstream-cache-nginx-module.git \
	https://github.com/baysao/nginx_secure_cookie_module.git \
	https://github.com/baysao/nginx_http_recaptcha_module.git \
	https://github.com/kyprizel/testcookie-nginx-module.git \
	https://github.com/cubicdaiya/ngx_small_light.git \
	https://github.com/baysao/ngx_http_twaf_variables.git \
	https://github.com/baysao/nginx-eval-module.git \
"
	if [ "$module" = "all" ]; then
		_dependencies
		_pagespeed
		for _url in $urls; do _module $_url; done
	#elif [ "$module" = "https://github.com/vislee/ngx_http_waf_module.git" ]; then
	#	_lib_pcre
	#	_lib_hyperscan
	#	_module $module
#	elif [ "$module" = "https://github.com/SpiderLabs/ModSecurity-nginx.git" ]; then
#		_ngx_modsecurity
#		_module $module  --with-compat
	#elif [ "$module" = "twaf" ]; then
	 #   _module https://github.com/ruslantalpa/lua-upstream-cache-nginx-module.git
	 #   _module https://github.com/baysao/ngx_http_twaf_variables.git
	#elif [ "$module" = "vts" ]; then
        #	_module https://github.com/vozlt/nginx-module-vts.git
	#	_module https://github.com/vozlt/nginx-module-sts.git --with-stream 
        #	_module https://github.com/vozlt/nginx-module-stream-sts.git 
	#elif [ "$module" = "brotli" ]; then
	#	_ngx_brotli
	#	_module https://github.com/google/ngx_brotli.git
	#elif [ "$module" = "pagespeed" ]; then
	#	_pagespeed
	elif [ "$module" != "none" ]; then
		_module $module
	fi


echo $add_dynamic_module
cd $dir
echo ./configure --prefix=$prefix $@ \
     $add_dynamic_module
sleep 3
eval ./configure --prefix=$prefix $@ \
	$add_dynamic_module
exit 0
_remove() {
	#cd $dir/build/nginx-1.15.8;./configure
	cd $dir
	if [ ! -d "redis_nginx_adapter" ]; then git clone https://github.com/wandenberg/redis_nginx_adapter.git; fi
	cd redis_nginx_adapter
	git pull origin master
	./configure --with-nginx-dir=$dir/build/nginx-1.15.8
	make install
	urls1="\
        https://github.com/wandenberg/nginx-push-stream-module.git \
        https://github.com/weibocom/nginx-upsync-module.git \
        https://github.com/xiaokai-wang/nginx-stream-upsync-module.git \
        https://github.com/vozlt/nginx-module-sysguard.git \
        #git clone https://github.com/GUI/nginx-upstream-dynamic-servers.git
        #https://github.com/nginx-modules/ngx_http_acme_module.git \
        https://github.com/kwojtek/nginx-rtmpt-proxy-module.git \
        https://github.com/baysao/nginx_requestid.git \
        https://github.com/kaltura/nginx_mod_akamai_g2o.git \
        https://github.com/baysao/nginx-ua-parse-module.git \
        https://github.com/baysao/nginx-esi.git \
        https://github.com/baysao/nginx-json-var-module.git \
        https://github.com/baysao/ngx_json_extractor_module.git \
        https://github.com/baysao/ngx_lmdb.git \
        https://github.com/baysao/ngx_log_if.git \
        https://github.com/baysao/nginx-video-thumbextractor-module.git \
        https://github.com/baysao/nginx-let-module.git \
        https://github.com/baysao/nginx-selective-cache-purge-module.git \
        https://github.com/Trax-retail/url-protector-nginx-module.git|module \
        https://github.com/baysao/ngx_access_token.git \
        https://github.com/nginx-modules/ngx_http_hmac_secure_link_module.git \
        https://github.com/chipitsine/nginx-eval-module.git \
        https://github.com/baysao/nginx_http_recaptcha_module.git \
        https://github.com/baysao/nginx_secure_cookie_module.git \
        https://github.com/baysao/nginx-http-concat.git \
        https://github.com/FRiCKLE/ngx_slowfs_cache.git \
        https://github.com/baysao/nginx-upstream-fair.git \
        "
	#git clone https://github.com/fooinha/nginx-json-log.git
}
