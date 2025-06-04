---
date: 2018-04-27T23:10:16+02:00
title: "Introducing DeliveryGuy"
draft: false
---

I like the Fetch API. It's supported by all modern browsers, easy to use and has some really good polyfills for older devices. But Fetch has one major flaw: it will only throw errors if there is a network problem.

That's a really odd decision from my point of view. Nearly any HTTP library out there throws errors or rejects the promise in case of a HTTP error.

A Fetch response object has the property `ok` to determine if the server responded with an error, but that's not very comfortable to use.

Since my team and I have decided to use Fetch in a Vue-based web app, I decided to create a little wrapper for much more convenience. Say hello to DeliveryGuy.

## Usage

Well, surprise, it's a Node module, so just use any package manager you like. My personal choice is yarn.

`yarn install delivery-guy`

### Example

~~~ javascript
import { deliverJson } from 'delivery-guy'

const getItems = async () => {
  try {
    const items = await deliverJson('/api/items')
    console.log(items)
  } catch (e) {
    console.error(e.message)
    console.log('HTTP Status', e.response.status)
    console.log('Response Body'. e.responseBody)
  }
}
~~~

### What's going on here?

DeliveryGuy exports two main functions:

- `deliver()` will return a [response promise](https://developer.mozilla.org/en-US/docs/Web/API/Response) like `fetch()` does.
- `deliverJson()` presumes your response body contains JSON. It's basically a shortcut and returns the promise of `Response.json()`.

Both will accept the same two parameters as `fetch()` does and pass them along.

If the server responds with a HTTP error, DeliveryGuy will throw an error.

Due to the inheritance limitations of built-in classes with ES5 I mentioned in my [last post]({{< relref "2018-04-27_why-custom-errors-in-javascript-are-broken.md" >}}), it's only possible to set custom properties of a custom error class.

DeliveryGuy provides additional two properties on an error object:

- `response` has the original response object of a Fetch call.
- `responseBody` contains the response body and will try to parse it as JSON. If `JSON.parse` fails, it will return the response body in its original state.

## TL;DR

DeliveryGuy allows you comfortably call the Fetch API without a hassle on HTTP errors. Just use `try/catch` and you're done.

Please let me know on [GitHub](https://github.com/WebCodr/delivery-guy) if you have feedback, a feature request or found a bug. Thank you!
