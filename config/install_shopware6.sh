if [[ -e /tmp/shopware6_development.tar.gz  ]]; then
	mv /tmp/shopware6_development.tar.gz /var/www/html
else 
	echo "Shopware6 development is already moved to /var/www/html"
fi

if [[ -e /tmp/shopware6_platform.tar.gz  ]]; then
        mv /tmp/shopware6_platform.tar.gz /var/www/html
else
        echo "Shopware6 platform is already moved to /var/www/html"
fi

if [[ -e /var/www/html/public/index.php  ]]; then
	echo "Shopware6 already extracted."
else tar -xf shopware6_development.tar.gz --strip-components 1
     rm shopware6_development.tar.gz
     tar -xf shopware6_platform.tar.gz --strip-components 1 -C platform
     rm shopware6_platform.tar.gz
fi

if [ $USE_SSL -eq 1 ]; then
	PROTOCOL="https" 
	grep -q "SetEnvIf X-Forwarded-Proto \"^https$\" HTTPS" "/etc/apache2/apache2.conf"
	IFEXISTS=$?

	if [[ $IFEXISTS -eq 0 ]]; then
		echo "HTTPS config already exists in /etc/apache2/apache2.conf"
	else
		echo "<IfModule mod_setenvif.c>
		SetEnvIf X-Forwarded-Proto \"^https$\" HTTPS
		</IfModule>" >> /etc/apache2/apache2.conf
		echo "HTTPS config is added"
	fi
else
	PROTOCOL="http"
fi

echo "const:
  APP_URL: \"$PROTOCOL://$SHOPWARE_HOST\"
  DB_USER: \"$DB_USER\"
  DB_PASSWORD: \"$DB_PASSWORD\"
  DB_HOST: \"$DB_HOST\"
  DB_NAME: \"$DB_NAME\"
  DB_PORT: \"$DB_PORT\"
  APP_ENV: \"$APP_ENV\"" >> .psh.yaml.override


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
	chown www-data:www-data -R .
fi

if [[ -e /etc/apache2/sites-available/shopware6_apache.conf ]]; then
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

if [[ -e /var/www/html/config/packages/shopware.yaml ]]; then
	echo "Admin queue worker already exists"
else 
	mkdir /var/www/html/config/packages
	echo "shopware:
    admin_worker:
        enable_admin_worker: false" >> /var/www/html/config/packages/shopware.yaml
	php bin/console cache:clear
	echo "The admin queue worker config file is now created"
fi

if [[ -e /etc/cron.d/shopware6_cron ]]; then
	echo "Cron already exists"
else 
	echo "* * * * * /usr/local/bin/php /var/www/html/bin/console messenger:consume --time-limit=60 --memory-limit=512M
* * * * * /usr/local/bin/php /var/www/html/bin/console scheduled-task:run --time-limit=60 --memory-limit=512M" >> /etc/cron.d/shopware6_cron
	chmod 644 /etc/cron.d/shopware6_cron
	crontab /etc/cron.d/shopware6_cron
	echo "Cron jobs are now created"
fi

/etc/init.d/cron start

exec apache2-foreground
