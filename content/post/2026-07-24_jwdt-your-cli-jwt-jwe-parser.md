---
title: jwtd - your fully local CLI JWT decoder
date: 2026-07-24T20:28:38+00:00
topics: [developer-tools, security, ai]
description: jwtd is a fully local CLI tool for decoding JWTs, verifying JWS signatures, and decrypting JWE tokens — no token ever leaves your machine.
---
A few months ago I looked for a local JWT decoder and didn't like what I found, so I decided write a small CLI-based decoder that works fully offline. No token will ever leave the machine it's running on.

Nothing big, just a tiny program written in Go to decode a JWT with go-jose and print the JSON contents to the console. I wanted a short name. JWT decode or `jwtd`. No fancy name, just a useful tool.

A friend asked if it could verify signatures or decrypt JWE contents. Nope, but that was a perfect opportunity to try Opus 4.6 which was pretty new at the time.

Many iterations and tokens later, the `jwtd` can do much more. Yes, it's mostly written by AI agents, but it's still small enough to understand what's going on and there's a pretty large test suite to ensure quality. I use multiple models and regularly check with if something can be improved, make security audits etc. -- I will not ship a program I can't understand or I feel insecure about.

## What?

The main focus is still decoding JWTs and show the contents. Of course with colored output and timestamps are human-readable (an expiration warning for `exp` fields is coming soon). We support a wide variety of JWS signatures, JWE key types and JWE content encryption algorithms.

There's an interactive mode for tokens and keys, so you didn't have to clean up your history afterwards. You can also pipe a token into `jwtd` if you like. We're also accepting keys via environment variable and even support raw HMAC secrets.

## Where?

All major operating systems are supported, but to be honest, my main focus is macOS and Linux. You can get `jwtd` via Homebrew, the AUR, Fedora COPR, Nix and Scoop. WinGET is coming soon. There are also pre-built deb and rpm packages available on GitHub.

## How?

To decode a token just supply it as argument:

~~~ sh
$ jwtd eyJhbGciOiJSUzI1NiIs...

Header:
{
  "alg": "RS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "user_2048",
  "admin": true,
  "iat": "2026-07-22T03:00:00Z (1784689200)",
  "exp": "2026-07-22T04:00:00Z (1784692800)",
  "note": null
}

Signature: eyJfX2p3dGRfXyI...
~~~

Need to verify a JWS signature?

~~~sh
jwtd --key /path/to/public-key.pem eyJhbGciOiJSUzI1NiIs...
~~~

For decryption just use the private key instead of the public key.

Don't want to pass the key path as parameter? No problem, just use the environment variable `JWTD_KEY`.

To use the interactive mode just omit the token or the value of the key parameter.

That's just a small overview, you can find a full usage guide, every installtion option and more on the official website [jwtd.sh](https://jwtd.sh/) or on [GitHub](https://github.com/webcodr/jwtd).
