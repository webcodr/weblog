---
date: 2024-01-19T14:33:07+02:00
title: "Micro DSLs for builders with Kotlin"
draft: false
---
The builder pattern is a great tool and it's heavily used in many Java projects and dependencies. But in a Kotlin code base it's looks a little odd and out-of-date. In this short post I will show you how to write a micro DSL on top of builder with just a few lines of code.

I'm using Spring's [ResponseCookie](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/http/ResponseCookie.html) class as base for the DSL as it has a builder already on-board.

A little example:

~~~ kotlin
val cookie = ResponseCookie
    .from("cookie name", "cookie value")
    .httpOnly(true)
    .path("/")
    .build()
~~~

How would this look like with a micro DSL?

~~~ kotlin
val cookie = createCookie("cookie name", "cookie value") {
    httpOnly(true)
    path("/")
}
~~~

Instead of calling the static method `ResponseCookie.from()` which returns a `ResponseCookieBuilder` object, you just give the function three parameters: two strings for name and value, and trailing lambda with the builder context. There is also no need to call `ResponseCookieBuilder.build()` anymore. It's shorter and better to read. Since this is only a small example the advantages are not that big. Micro DSLs really shine with large and often used builders. They can also help to automate things, see below.

## How?

~~~ kotlin
fun createCookie(
    name: String, 
    value: String, 
    lambda: ResponseCookieBuilder.() -> Unit
) = ResponseCookie.from(name, value).apply(lambda).build()
~~~ 

Et voila, a new micro DSL is born. Deriving the trailing lambda function from `ResponseCookieBuilder` does the trick. The lambda function takes an instance of `ResponseCookieBuilder` as context of `this`, so it's possible to access the methods of the given `ResponseCookieBuilder` inside the lambda function. All we have to do is to create an instance of `ResponseCookieBuilder` with `ResponseCookie.from()` and call Kotlin's apply method on the builder object with the lambda function. It will automatically inject the current instance of `ResponseCookieBuilder` into the lambda function and apply the instructions inside the lambda function on the instance. To create a `ResponseCookie` object from the builder, just call the build method and return the result.

You can use this little trick with all builders. Need more automation? No problem! In my current project we're using such micro DSLs to create product configurations. The factory method contains sanity checks after the lambda function was applied to the builder object. It will also fetch a YAML file via the product ID given to the builder. This data is parsed into an object and will be put into a property of the builder object. After the configuration object is created, the factory method will add to a map and return the instance to store in a variable. It's now possible to directly access the configuration via its variable name or to fetch it from the map. The variable is very useful for tests, but if we have to fetch the configuration dynamically by ID from a string, the map is the way to go.

Of course there are other ways of achieving such automation, but the micro DSL approach is simple, improves readability and can also reduce redundant code. You can even easily nest builders to create a more powerful DSL. Spring's Kotlin extensions also rely on micro DSLs and extension functions. Take Spring Security for example. Their fluent interface for the security configuration is awful to read and difficult to understand, but Spring also provides a Kotlin extension with a micro DSL for that. So much more intuitive and better to read. There are many more extensions like for bean creation, the MVC mock in tests etc.
