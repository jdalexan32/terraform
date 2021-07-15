#! /bin/bash
sudo apt-get -y update
sudo apt-get -y install nginx
echo '
stream {
    upstream sqlvm {
        server emcpocdb.mysql.database.azure.com:3306;
        }
        server {
            listen 3306;
            proxy_pass sqlvm;
        }
    }' >> /etc/nginx/nginx.conf
sudo systemctl restart nginx