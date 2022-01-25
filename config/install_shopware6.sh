if [[ -e ./public/index.php  ]]; then
	echo "Shopware6 already extracted."
else tar -xf shopware6_development.tar.gz --strip-components 1
     rm shopware6_development.tar.gz
     tar -xf shopware6_platform.tar.gz --strip-components 1 -C platform
     rm shopware6_platform.tar.gz
fi

if [ $USE_SSL -eq 1 ]; then
	PROTOCOL="https"
#TODO append file to apache configuration with linux command and gracefully restart apache	
else 
	PROTOCOL="http"
fi	
 
echo "const:
  APP_ENV: \"$APP_ENV\"
  APP_URL: \"$PROTOCOL://$SHOPWARE_HOST\"
  DB_HOST: \"$DB_HOST\"
  DB_PORT: \"3306\"
  DB_NAME: \"$DB_NAME\"
  DB_USER: \"$DB_USER\"
  DB_PASSWORD: \"$DB_PASSWORD\"" >> .psh.yaml.override

if [[ -e /usr/local/bin/composer ]]; then
        echo "Composer already exists."
else
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php --quiet
        rm composer-setup.php
        mv composer.phar /usr/local/bin/composer
fi

if [[ -d /var/www/html/vendor/shopware ]]; then
	echo "Shopware6 already installed."
else 
	./psh.phar install
	chown www-data:www-data config/jwt/public.pem
	chown www-data:www-data config/jwt/private.pem
fi

sed -i "s/#TRUSTED_PROXIES=.*/TRUSTED_PROXIES=127.0.0.1, 127.0.0.2, ::1/g" .env
IS_COMMAND_SUCCESS=$?

if [[ $IS_COMMAND_SUCCESS -ne 0 ]]; then
	echo "Failed to change trusted proxy."
else 
	echo "Successfully changed trusted proxy."
fi

if [[-e /etc/apache2/sites-available/shopware6_apache.conf ]]; then
	a2ensite shopware6_apache.conf
	a2dissite 000-default.conf
else 
	echo "<VirtualHost *:80>
		ServerName $SHOPWARE_HOST
   		DocumentRoot /var/www/html/public
	      <Directory /var/www/html>
	      	Options Indexes FollowSymLinks MultiViews
		AllowOverride All
      		Order allow,deny
      		allow from all
      		Require all granted
   	      </Directory>
		ErrorLog ${APACHE_LOG_DIR}/shopware-platform.error.log
		CustomLog ${APACHE_LOG_DIR}/shopware-platform.access.log combined
		LogLevel debug
	      </VirtualHost>" >> /etc/apache2/sites-available/shopware6_apache.conf
	a2ensite shopware6_apache.conf
	a2dissite 000-default.conf
fi

exec apache2-foreground
