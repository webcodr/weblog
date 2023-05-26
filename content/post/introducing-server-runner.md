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

Currently you have to clone the [GitHub repository](https://github.com/webcodr/server-runner) and compile Server Runner yourself. I have tested it with macOS and Windows 11, it works well, but is still under development. If something goes wrong, the program will throw a panic event and just exits with error messages, so a graceful error handling is still missing.

After finishing Server Runner, I have to set up some tests and GitHub actions to build executables for macOS, Linux and Windows. I have not decided to distribute the executables yet. Homebrew, apt etc. would be nice, but I would have to add it to multiple package managers for a good availability. NPM is much easier and broadly available, as is a Docker image. 

## Source Code

~~~ rust
use clap::Parser;
use std::env;
#[cfg(windows)]
use std::os::windows::process::CommandExt;
use std::process::{Child, Command};
use std::thread;
use std::time::Duration;

#[derive(Parser)]
struct Args {
    #[arg(short, long, default_value = "servers.yaml")]
    config: String,
}

#[derive(serde::Deserialize)]
struct Server {
    name: String,
    url: String,
    command: String,
}

#[derive(serde::Deserialize)]
struct Config {
    servers: Vec<Server>,
    command: String,
}

struct ServerProcess {
    name: String,
    process: Child,
}

fn run_command(command: &String) -> Result<Child, std::io::Error> {
    let command_parts: Vec<&str> = command.split(" ").collect();
    let mut cmd = Command::new(command_parts[0]);

    for i in 1..command_parts.len() {
        cmd.arg(command_parts[i]);
    }

    #[cfg(windows)]
    {
        cmd.creation_flags(0x08000000);
    }
    cmd.spawn()
}

fn check_server(server: &Server) -> bool {
    println!("Checking server {} on url {}", &server.name, &server.url);

    let result = match reqwest::blocking::get(&server.url) {
        Ok(response) => response.status(),
        Err(error) => {
            if error.is_connect() {
                return false;
            } else {
                panic!("Could not connect to server")
            }
        }
    };

    return result.is_success();
}

fn get_config(filename: &String) -> Result<Config, config::ConfigError> {
    let cwd = env::current_dir().unwrap();
    let config_file_path = cwd.join(&filename);
    let settings = config::Config::builder()
        .add_source(config::File::new(
            config_file_path.to_str().unwrap(),
            config::FileFormat::Yaml,
        ))
        .build()
        .expect(&format!(
            "Could not find configuration file {}",
            &config_file_path.to_str().unwrap()
        ));

    settings.try_deserialize::<Config>()
}

fn main() {
    let args = Args::parse();
    let config = get_config(&args.config).expect("Could not load server config");
    let mut server_processes = Vec::with_capacity(config.servers.len());

    println!("Running on {}", env::consts::OS);
    println!(
        "Current working directory: {}",
        env::current_dir().unwrap().display()
    );

    for server in &config.servers {
        println!("Starting server {}", server.name);
        let process = match run_command(&server.command) {
            Ok(child) => child,
            Err(_) => panic!("Could not start server"),
        };

        let server_process = ServerProcess {
            name: server.name.to_string(),
            process,
        };

        server_processes.push(server_process);
    }

    loop {
        let mut ready = true;

        for server in &config.servers {
            if check_server(&server) == false {
                println!("Server {} not ready, waiting 1 s", &server.name);
                ready = false;
            }
        }

        if ready == true {
            let mut process = match run_command(&config.command) {
                Ok(child) => child,
                Err(_) => panic!("Could not execute command"),
            };

            println!("Running command {}", &config.command);

            process.wait().unwrap();

            println!("Command {} finished successfully", &config.command);

            break;
        } else {
            thread::sleep(Duration::from_secs(1));
        }
    }

    for mut server_process in server_processes {
        println!("Stopping server {}", server_process.name);
        server_process
            .process
            .kill()
            .expect("Failed to stop server process");
    }
}
~~~

