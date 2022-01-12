tar -xf shopware6_development.tar.gz --strip-components 1

rm shopware6_development.tar.gz

tar -xf shopware6_platform.tar.gz --strip-components 1 -C platform

echo "const:
  APP_ENV: \"dev\"
  APP_URL: \"http://174.138.13.2:8080\"
  DB_HOST: \"mariadb\"
  DB_PORT: \"3306\"
  DB_NAME: \"shopware6\"
  DB_USER: \"root\"
  DB_PASSWORD: \"shopware6\"" >> .psh.yaml.override

if [[ -e /usr/local/bin/composer ]]; then
        echo "Composer already exists"
else
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php --quiet
        rm composer-setup.php
        mv composer.phar /usr/local/bin/composer
fi

