#! /bin/bash
sudo yum update -y

# install nginx
sudo amazon-linux-extras install nginx1
sudo systemctl restart nginx

# install some other packages
sudo yum install -y nmap
sudo yum install -y curl

# server ip address - see https://unix.stackexchange.com/questions/456853/get-and-use-server-ip-address-on-bash/456855
IPADDR=$(ip -4 addr show eth0 | awk '/inet/ {print $2}' | sed 's#/.*##')

# add server ip address to default index.html page
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
sudo echo "<html><body><div><p style="font-family:'Courier New'">nginx http server<br/>private ip = $IPADDR</p></div></body></html>" > /usr/share/nginx/html/index.html
sudo systemctl restart nginx
