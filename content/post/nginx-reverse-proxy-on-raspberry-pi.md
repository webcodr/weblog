---
date: 2018-02-17T22:28:05+01:00
title: NGINX Reverse Proxy on Raspberry Pi with Let's Encrypt
---

Another weekend, another guide. This time I will show you, how to setup a reverse proxy with NGINX on a Raspberry Pi and secure the connection with a certificate from Let's Encrypt.

***NOTICE OF CAUTION BEGIN*** 

Your Raspberry Pi will be exposed to the internet on port 80 for HTTP and port 443 for HTTPS/TLS. A potential attacker could have access to your network. Please make sure, that you keep yourself up to date on security issues and install updates regularly.

To secure your network, I recommend an isolated VLAN for your Pi and the web servers.

If this makes you uncomfortable, please re-consider running web servers within your network, that can be accessed from outside.

***NOTICE OF CAUTION END*** 

Still here? Okay, you have been warned. Let's go.

Please make sure, to forward port 80 and 443 from your router to the Raspberry Pi.

## Install NGNIX and Certbot

This guide assumes that you're running the latest version of Raspian on your Pi. It's based on Debian Stretch. If you're using an older version based Jessie or even Wheezy, please consider a dist upgrade. This is not without risk, so back-up your current installation!

If you're already running a web server on your Pi, you should disable it. Otherwise NGINX will not be able to use port 80 and 443. If you need that other web server, you should configure it to run on other ports and use NGINX to forward the connections.

Now, to the installation:

~~~ sh
sudo apt-get update
sudo apt-get install nginx-full certbot -y
~~~

The NGINX service will automatically start after APT finished.

## Issue a certificate

In order to create a certificate, Certbot will need access to port 80, but that's no problem. Look at the following command:

~~~ sh
sudo certbot certonly --authenticator standalone -d example.com --pre-hook "service nginx stop" --post-hook "service nginx start"
~~~

This tells certbot to issue a certificate for `example.com` by using a standalone web server to validate the domain for the Let's Encrypt service. In order to run the server, you have to shutdown NGINX until certbot is finished. The pre hook and post hook parameters will help you with that.

After the certificate is successfully issued, your new certificate and all other necessary files will be available here: `/etc/letsencrypt/live/example.com`

## Configure NGINX

Don't like vim? Just use whatever editor you prefer instead.

Add a new site config to NGINX:

~~~ sh
sudo vim /etc/nginx/sites-enabled/example.com
~~~

All files in `/etc/nginx/sites-enabled/` will be automatically used by NGINX.

Here is a config for `example.com`, that will be forwarded to `10.0.0.2`.

Please adjust it to your needs and paste/save it.

~~~ nginx
server {
  listen 80;
  server_name example.com;

  location / {
    proxy_pass http://10.0.0.2:80;
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
  ssl_stapling on;
  ssl_stapling_verify on;
  ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem; 

  location / {
    proxy_pass https://10.0.0.2:443;
  }
}
~~~

To test your config, use the following command:

~~~ sh
sudo nginx -t
~~~

The validator will tell you, if anything is wrong and why it's not working.

No errors? Great, just restart NGINX and your reverse proxy is working.

~~~ sh
sudo service nginx restart
~~~

## Certificate auto-renewal

The certbot certificate renewal will renew all certificates you created with cerbot.

Checking the renewal process:

~~~ sh
sudo certbot renew --dry-run --pre-hook "service nginx stop" --post-hook "service nginx start"
~~~ 

The parameter `--dry-run` allows to test the renewal without actually replacing the certificates.

In order to renew the certificates automatically, open crontab for root:

~~~ sh
sudo crontab -e
~~~

Add the following cron job and save.

~~~ sh
0 0 1 * * sudo certbot renew --pre-hook "service nginx stop" --post-hook "service nginx start"
~~~

And you're done. From now on, you're certificates will be renewed every month automatically.

More domains? No problem, just issue the certificate and add another site config.

