## How to run this image

This image is based on the latest Apache version in the [official PHP image](https://registry.hub.docker.com/_/php/) and requires MySQL or MariaDB images. Requirements for database versions will differ depending on the Shopware6 base version. The image is build to work with a reverse proxy instead of binding the HTTP ports directly. You can find the running steps outlisted bellow or use the ```docker-compose``` file instead.

```
# Create a network for Reverse Proxy, DB and Shopware6.
$ docker network create backend
# Run MariaDB/MySQL database image
$ docker run -d —name mariadb —net backend -e MARIADB_ROOT_PASSWORD=shopware6 mariadb:10.4
# Run Reverse Proxy image (if needed)
$ docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro nginxproxy/nginx-proxy
# Run Shopware6 base image
$ docker run -d --name sw6 --net backend -e VIRTUAL_HOST=subdomain.yourdomain.tld -e SHOPWARE_HOST=subdomain.yourdomain.tld rokpopovledinski/shopware6:v6.4.7.0
```
# Running with SSL

Create a network then run database as before
```
# Create a network for Reverse Proxy, DB and Shopware6.
$ docker network create backend
# Run MariaDB/MySQL database image
$ docker run -d --net backend --name mariadb -e MARIADB_USER=shopware6 -e MARIADB_PASSWORD=shopware6 -e MARIADB_ROOT_PASSWORD=shopware6 -e MARIADB_DATABASE=shopware6 mariadb:10.4
```

Run Nginx reverse proxy
```
docker run -d --net backend --name nginx-proxy -p 80:80 -p 443:443 \
    --volume certs:/etc/nginx/certs \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    nginxproxy/nginx-proxy
```

Run Acme container for Let's Encrypt
```
docker run -d --name nginx-proxy-acme -e DEFAULT_EMAIL=mail@yourdomain.tld \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    nginxproxy/acme-companion
```

Run the image with SSL settings
```
docker run -d --name sw6 -e USE_SSL=1 -e LETSENCRYPT_HOST=subdomain.yourdomain.tld -e LETSENCRYPT_EMAIL=mail@yourdomain.tld  --net backend -e VIRTUAL_HOST=subdomain.yourdomain.tld -e SHOPWARE_HOST=subdomain.yourdomain.tld rokpopovledinski/shopware6:v6.4.7.0
```

# Running with Docker Compose
Assuming that the ```nginx-proxy``` container is already running in the background and the network ```backend``` is already created, the bellow ```docker-composer.yml``` file can be used.
```
version: '3.9'

services:
  db:
    image: mariadb:10.4
    container_name: mariadb
    environment:
      MARIADB_ROOT_PASSWORD: shopware6
      MARIADB_DATABASE: shopware6
      MARIADB_USER: shopware6
      MARIADB_PASSWORD: shopware6
  web:
    image: rokpopovledinski/shopware6:v6.4.7.0
    container_name: shopware6
    environment:
      - DB_HOST=mariadb
      - SHOPWARE_HOST=subdomain.yourdomain.tld
      - VIRTUAL_HOST=subdomain.yourdomain.tld
      - USE_SSL=1
      - LETSENCRYPT_HOST=subdomain.yourdomain.tld
    networks: 
      - backend
      - default
    volumes:
      - type: volume
        source: webdata
        target: /var/www/html
  sftp:
    ports:
      - 2222:22/tcp
    command: 
      - admin:admin123:33
    image: atmoz/sftp
    volumes:
      - webdata:/home/admin/web
  
volumes: 
  webdata: 

networks:
  backend:
    external:
      name: backend
```

# Environmental variables
- **SHOPWARE_HOST**: Will be used while installing Shopware6, indicates the Shopware6 host, \(default *\<will be defined\>*\), **Required**.
- **DB_USER**: Database user \(default *root*\)
- **DB_PASSWORD**: Database password \(default *shopware6*\)
- **DB_HOST**: Database location \(default *mariadb*\)
- **DB_NAME**: Database name in your Database host \(default *shopware6*\)
- **DB_PORT**: Port of the database server/instance \(default *3306*\)
- **APP_ENV**: Mode in which Shopware6 is operated \(default *dev*\)
- **USE_SSL**: Sets required SSL configs such as base-url-secure in Shopware6 config, requires `nginxproxy/acme-companion`  container and `LETSENCRYPT_HOST` env variable \(default *0*\)
