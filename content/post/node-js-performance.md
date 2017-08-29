---
date: 2017-08-28T22:00:00+02:00
title: Real-world Node.js Performance Improvements
---
I just updated from Node.js 8.2.1 to 8.4.0 within my current project. The update
to V8 6.0 really shines as I noticed some major real-world performance improvements.

So I decided to do some tests with the above mentioned versions and the latest 
LTS version, 6.11.2.

## Testing methodology

The Webpack build builds contains the following tasks:

- Building of two stylesheets with SASS and Autoprefixer
- Transpiling with Babel of a large AngularJS app written in ES2015
- Copying images and some other static files
- Chunking into `vendor.js` and `application.js`

Each test ran nine times for each Node.js version.

The tests were conducted in dev mode (no minification, no uglification) with
a Debian-based Docker container on Windows 10 Pro with HyperV.

## Hardware

- Core i7-7700K (the Docker container had access to all cores)
- 16 GB RAM (8 GB for the Docker container)
- PCIe SSD

As you can see, the system has more than enough power and is significantly faster
than my MacBook. Docker on HyperV is incredibly fast and a joy to work with.

## Results

![Node.js performance benckmark](/images/node-js-webpack-benchmark.png)

The improvement between version 8.2.1 and 8.4.0 is a bummer. V8 6.0  
does a great job. Node.js 6 used Crankshaft as JIT, Node 8.0 to 8.2 used a combinaton
of Crankshaft and Turbofan (V8 5.9). As of version 8.3.0 Node.js utilizes only Turbofan with
V8 6.0.

About 10% improvement with a minor version is a really big step and I'm really
looking forward to the next V8 versions and even more power.