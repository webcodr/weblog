---
date: 2018-04-19T20:00:00+02:00
title: Let's Encrypt Wildcard Certificates with acme.sh and CloudFlare
---

A few weeks ago Let's Encrypt finally launched ACME 2.0 with support of wildcard certificates. Woohoo!

## Wait, what are wildcard certificates?

Wildcard certificates allow you to use multiple hostnames of your domain with one certificate. Without them you need a 
separate certificate for each host like `foo.webcodr.io` and `bar.webcodr.io`. A wildcard certificate can be issued for
`*.webcodr.io` and that's it. One certificate to rule them all.

## Get started

My nginx example used certbot to issue certificates from Let's Encrypt, but there's a better tool: [acme.sh](https://github.com/Neilpang/acme.sh)

Acme.sh is written in Shell and can run on any unix-like OS. Since it's also installed with a Shell script, there's no need for a maintained package to get the latest features. Just run:

~~~ sh 
curl https://get.acme.sh | sh
~~~

That's it. The install script will copy acme.sh to your home directory, create an alias for terminal use and create a cron job to automatically renew certificates.

## DNS challenge

To issue a wildcard certificate ACME 2.0 allows only DNS-based challenges to verify your domain ownership. You can manage this manually, but challenge tokens will only work for 60 days, so you have to renew it every time a certificate expires.

Well, that sucks. But acme.sh has you covered. It supports the APIs of many DNS providers like CloudFlare, GoDaddy etc.

The following guide will show you how to use the CloudFlare API to automatically update the DNS challenge token. No CloudFlare? No problem, you can find examples for all supported DNS providers within the ache.sh docs.

## Set-up CloudFlare

Login to CloudFlare and go to your profile. You'll need the global API key.

Set your CloudFlare API key and your account email address as environment variables:

~~~ sh
export CF_Key="sdfsdfsdfljlbjkljlkjsdfoiwje"
export CF_Email="you@example.com"
~~~

I recommend to put this environment variables into your `.bashrc`, `.zshrc` or in the respective file of your favorite shell.

## Issue a wildcard certificate

~~~ sh
acme.sh --issue --dns dns_cf -d "*.webcodr.io" -w "/what/ever/dir/you/like/*.webcodr.io"
~~~

Your new certificate will be ready soon and acme.sh will automatically renew it every 60 days. Just update your web-server configuration to the new path. I recommend also to create a cron-job reloading the web-server every night to load a renewed certificate.

## Unclutter your ngnix config

If you manage multiple hosts within the same nginx, you can use `include` to put your TLS configuration in a separate file to avoid duplicates.

### Create a separate file for your TLS configuration

File: `/etc/nginx/tls-webcodr.io`

~~~ nginx
ssl_certificate /home/webcodr/.acme.sh/*.webcodr.io/*.webcodr.io.cer;
ssl_certificate_key /home/webcodr/pi/.acme.sh/*.webcodr.io/*.webcodr.io.key;
ssl_trusted_certificate /home/webcodr/.acme.sh/*.webcodr.io/ca.cer;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;
ssl_protocols TLSv1.1 TLSv1.2;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1;
ssl_prefer_server_ciphers on;
add_header Strict-Transport-Security max-age=15768000;
ssl_stapling on;
ssl_stapling_verify on;
~~~

### Update your site configuration

File: `/etc/nginx/sites-enabled/webcodr.io`

~~~ nginx
server {
  listen 80;
  server_name webcodr.io;

  location / {
    proxy_pass http://10.0.0.2:80;
  }
}

server {
  listen 443 ssl http2;
  server_name webcodr.io;
  ssl on;

  include tls-webcodr.io;

  location / {
    proxy_pass https://10.0.0.2:443;
  }
}
~~~

Repeat this for every site on a host on this domain and reload nginx. And you're done. Just one certificate and TLS config for all your sites. Pretty neat, huh?
