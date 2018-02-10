---
date: 2018-02-10T22:28:05+01:00
title: NGINX Reverse Proxy on Raspberry Pi
draft: true
---

~~~ sh
sudo apt-get update
sudo apt-get install nginx-full
~~~

Add to `/etc/apt/sources.list`

~~~ sh
deb http://ftp.debian.org/debian jessie-backports main
~~~

~~~ sh
sudo apt-get update
sudo apt-get -t jessie-backports install certbot
~~~

~~~ sh
sudo certbot certonly --authenticator standalone -d example.com --pre-hook "service nginx stop" --post-hook "service nginx start"
~~~

~~~ sh
sudo vim /etc/nginx/sites-enabled/example.com
~~~

~~~ nginx
server {
  listen 80;
  server_name example.com;

  location / {
    proxy_pass http://10.0.0.1:8080;
  }
}

server {
  listen 443 ssl;
  server_name example.com;
  ssl on;

  ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem; 
  ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;
  ssl_protocols TLSv1.1 TLSv1.2;
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
  ssl_prefer_server_ciphers on;
  add_header Strict-Transport-Security max-age=15768000;
  ssl_stapling on;
  ssl_stapling_verify on;
  ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem; 

  location / {
    proxy_pass https://10.0.0.1:8443;
  }
}
~~~

Check auto-renewal:

~~~ sh
sudo certbot renew --dry-run --pre-hook "service nginx stop" --post-hook "service nginx start"
~~~ 

~~~ sh
sudo crontab -e
~~~

~~~ sh
0 0 1 * * sudo certbot renew --pre-hook "service nginx stop" --post-hook "service nginx start"
~~~

~~~ sh
sudo crontab -l
~~~

