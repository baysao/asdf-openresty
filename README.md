# asdf-openresty

```
asdf plugin add openresty https://github.com/baysao/asdf-openresty.git
```

# How it's work

						  +---------------------------------+
						  |   	      	  			     	|
			+-------------+   openresty/openresty_docker 	|
			|             |           	  			     	|
			|          	  +---------------------------------+
			v
	  +-----+---------+
      |       		  |
	  |    docker2sh  |
	  |               |
	  +------+--------+
			 |
			 |
	   +-----v-------------------+
	   |  	   	    	   	     |
	   |   install to /usr/local |
	   |       	    	   	     |
	   +-----+-------------------+
			 |
			 |
			 |
	   +-----v-----------------------+
	   |   move to asdf install dir  |
	   |   	   	with versioning      |
	   +-----+-----------------------+
			 |
			 |
			 |
	   +-----v-------------------------------------------------+
	   |    add dir lib to /etc/ld.so.conf.d/0openresty.conf   |
	   |     		 	 	   			   			           |
	   +-------------------------------------------------------+
