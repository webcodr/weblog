---
title: Introducing Server Runner
date: 2023-05-26T23:53:33.353Z
---
In my recent adventures with Rust, I planned to write a REST API with the help of the excellent book "Zero To Production In Rest" from Luca Palmieri. That's still happing, but as small side project, I wanted to write some kind of CLI tool.

A few weeks ago I had wrote a bash script to run some web servers and check their status until they're up and running. When all servers are ready, a command would be executed and all servers would be closed after this command is finished. Since I hate bash with passion, I asked an friend to help me: ChatGPT. 

I would never trust an AI in this day and age to write a code base for me, but for small scripts? Why not. As long as the scope is small and I can understand the code, ChatGPT is a really good tool. That script does exactly what I want and it's easy enough to understand, even for me as a bash hater.

But I wanted to this properly and so I decided to rewrite this script as a small CLI tool program in Rust: Server Runner. Well, not very creative name, but it does what is says.

## Configuration

Server Runner is quite simple and just needs a small YAML file as configuration. Here's a small example.

~~~ yaml
servers:
  - name: "Hello World"
    url: "http://localhost:3000"
    command: "node index.js"
command: "node sleep.js"
~~~

To start server runner, just run:

~~~ sh
server-runner -c servers.yaml
~~~

Server Runner will execute all server commands defined in the config section `servers` and waits until the URLs return HTTP 200. When all servers are up and running, the primary command will be started. After the command finished, all server processes will be killed off.

## How do I get it?

Server Runner is available as a [Cargo Crate](https://crates.io/crates/server-runner) and will be published soon on NPM with executables for macOS (aarch64, x86_64), Linux (aarch64, x86_86) and Windows (x86_64).

### Installation via Cargo

~~~ sh
cargo add server-runner
~~~

The source code is available on [GitHub](https://github.com/webcodr/server-runner).

