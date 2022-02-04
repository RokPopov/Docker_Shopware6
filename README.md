## How to run this image

This image is based on the latest Apache version in the [official PHP image](https://registry.hub.docker.com/_/php/) and requires MySQL or MARIADB images. Requirements for database versions will differ depending on the Shopware6 base version. The image is build to work with a reverse proxy instead of binding the HTTP ports directly. You can find the running steps outlisted bellow or use the ```docker-composer``` file instead.

```
# Create a network for Reverse Proxy, DBand Magento 2.
$ docker network create backend
# Run MariaDB/MySQL database image
$ docker run -d —name mariadb —net backend -e  MARIADB_ROOT_PASSWORD=shopware6 mariadb:10.4
# Run Reverse Proxy image (if needed)
$ docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro nginxproxy/nginx-proxy
# Run Shopware6 base image
$ docker run -d --name sw6 -e USE_SSL=1 -e LETSENCRYPT_HOST=subdomain.yourdomain.tld -e LETSENCRYPT_EMAIL=mail@yourdomain.tld  --net backend -e VIRTUAL_HOST=subdomain.yourdomain.tld -e SHOPWARE_HOST=subdomain.yourdomain.tld shopware6
```
# !! TODO Running with SSL

Create a network then run database as before
```
# Create a network for Reverse Proxy, DB and Magento 2.
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

# Environmental variables
