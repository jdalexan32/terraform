#! /bin/bash
sudo apt-get update -y

# install nginx
sudo apt-get install nginx -y
sudo ufw allow 'Nginx HTTP'

# server ip address - see https://unix.stackexchange.com/questions/456853/get-and-use-server-ip-address-on-bash/456855
IPADDR=$(ip -4 addr show eth0 | awk '/inet/ {print $2}' | sed 's#/.*##')

# create new index.html
sudo touch /home/<USER>/index.html                                # <----------------- EDIT, REPLACE <USER> ------------------
sudo chmod 646 /home/<USER>/index.html                            # <----------------- EDIT, REPLACE <USER> ------------------
sudo echo "
    <html>
        <body>
            <div>
                <p style="font-family:'Courier New'">
                nginx http server<br/>
                private ip = $IPADDR
                </p>
            </div>
        </body>
    </html>" > /home/<USER>/index.html                          # <----------------- EDIT, REPLACE <USER> ------------------

sudo chmod 644 /home/<USER>/index.html                          # <----------------- EDIT, REPLACE <USER> ------------------

# modify /etc/nginx/sites-enabled/default
sudo chmod 646 /etc/nginx/sites-enabled/default                 # <----------------- EDIT BELOW, REPLACE <USER> ------------------
sudo echo '
    server {
       listen 80 default_server;
       root /home/<USER>/;
       index index.html;
       server_name ipaddress;
    }' > /etc/nginx/sites-enabled/default

sudo chmod 644 /etc/nginx/sites-enabled/default

# restart nginx
sudo systemctl restart nginx

# install some other packages
sudo apt-get install nmap -y
sudo apt-get install curl -y
