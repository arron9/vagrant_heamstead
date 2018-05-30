#!/usr/bin/env bash

mkdir /etc/nginx/ssl 2>/dev/null

PATH_SSL="/etc/nginx/ssl"
PATH_KEY="${PATH_SSL}/${1}.key"
PATH_CSR="${PATH_SSL}/${1}.csr"
PATH_CRT="${PATH_SSL}/${1}.crt"

if [ ! -f $PATH_KEY ] || [ ! -f $PATH_CSR ] || [ ! -f $PATH_CRT ]
then
  openssl genrsa -out "$PATH_KEY" 2048 2>/dev/null
  openssl req -new -key "$PATH_KEY" -out "$PATH_CSR" -subj "/CN=$1/O=Vagrant/C=UK" 2>/dev/null
  openssl x509 -req -days 365 -in "$PATH_CSR" -signkey "$PATH_KEY" -out "$PATH_CRT" 2>/dev/null
fi

block="server {
    listen ${3:-80};
    listen ${4:-443} ssl http2;
    server_name $1;   

    charset utf-8;

    location / {
	   root \"$2\";

       index index.html index.htm index.php;
	
       if (-e \$request_filename) {
			break;
		}
		if (!-e \$request_filename) {
			rewrite ^/(.*)$ /index.php/\$1 last;
			break;
		}
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$1-error.log error;

    sendfile off;

    client_max_body_size 100m;

    location ~ \.php {	
        root \"$2\";	
        try_files \$uri =404;	
	    fastcgi_pass unix:/var/run/php/php$5-fpm.sock;
		 set \$path_info \"\";
                set \$real_script_name \$fastcgi_script_name;
                if (\$fastcgi_script_name ~ \"^(.+\.php)(.*)\$\") {
                        set \$real_script_name \$1;
			            set \$path_info \$2;
                }
                #include fastcgi.conf;
				include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME \$document_root\$real_script_name;
                fastcgi_param SCRIPT_NAME \$real_script_name;
                fastcgi_param PATH_INFO \$path_info;
        

        #fastcgi_intercept_errors off;
        #fastcgi_buffer_size 16k;
        #fastcgi_buffers 4 16k;
        #fastcgi_connect_timeout 300;
        #fastcgi_send_timeout 300;
        #fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }

    ssl_certificate     /etc/nginx/ssl/$1.crt;
    ssl_certificate_key /etc/nginx/ssl/$1.key;
}

"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
