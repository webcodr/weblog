---
date: 2018-04-27T10:50:35+02:00
title: "Why custom errors in JavaScript with Babel are broken"
draft: false
---

Have you ever tried to use an custom error class in JavaScript? Well, it does work to a certain extend. But if you want
to add custom methods or call `instanceof` to determine the error type it will not work properly.

Here is a little example of a custom error class:

~~~ javascript
class MyError extends Error {
  constructor(foo = 'bar', ...params) {
    super(...params)
    
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, MyError)
    }
    
    this.foo = foo
  }
  
  getFoo() {
    return this.foo
  }
}

try {
  throw new MyError('myBar')
} catch(e) {
  console.log(e instanceof MyError) // -> false
  console.log(e.getFoo()) // -> Uncaught TypeError: e.getFoo is not a function
}
~~~

Works fine in any browser with ES6/ES2015 support, but if you transpile the example with Babel to ES5 and execute the code, you will get the results shown in the comments.

## Why

Due to limitations of ES5 it's not possible to inherit from built-in classes like `Error`, see the [Babel docs](https://babeljs.io/docs/usage/caveats/#classes).

### Possible solution

The docs mention a plug-in called `babel-plugin-transform-builtin-extend` to resolve this issue, but if you have to support older browsers it may not help. In order to work the plug-in needs support for `__proto__`. Take a guess which browser does not support `__proto__` ... and of course, it's the web developers best friend aka Internet Explorer. Thankfully it affects only version 10 and below.

### Workaround

If it's not feasable to use the plug-in, you can at least access properties set in the constructor. A call to `e.foo` in the example is possible, but `e instanceof MyError` will return `false`, since you will always get an instance of `Error`.

Nothing of this ideal. We have to wait until it's possible to use ES6/ES2015 directly. Yes, we all could set our transpile targets to ES6/ES2015 today, but our clients usually won't allow it. Some customer is always browsing the web with an ancient device/browser.
