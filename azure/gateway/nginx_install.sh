#! /bin/bash
sudo apt-get -y update
sudo apt-get -y install nginx       # <----------------- EDIT BELOW SERVER DATA Replace <> WITH YOUR DATA ------------------
echo '
stream {
    upstream <NAME> { 
        server <PATH:PORT>;
        }
        server {
            listen 3306;
            proxy_pass <NAME>;
        }
    }' >> /etc/nginx/nginx.conf
sudo systemctl restart nginx