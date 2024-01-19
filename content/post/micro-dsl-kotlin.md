---
date: 2024-01-19T14:33:07+02:00
title: "Micro DSLs for builders with Kotlin"
draft: false
---
The builder pattern is a great tool and it's heavily used in many Java projects and dependencies. But in a Kotlin code base it's looks a little odd and out-of-date. In this short post I will show you how to write a micro DSL on top of builder with just a few lines of code.

I'm using Spring's (ResponseCookie)[https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/http/ResponseCookie.html] class as base for the DSL as it has a builder already on-board.

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

Instead of calling the static method `ResponseCookie.from()` that returns a `ResponseCookieBuilder` object, you just give the function three parameters: two strings for name and value, and trailing lambda that contains the builder. There is no need to call the method `ResponseCookieBuilder.build()` anymore. It's shorter and better to read. To be honest, in this case the advantages are not that big, but this also just a small example. The micro DSL really shines with large and often used builders.

## How?

~~~ kotlin
fun createCookie(
    name: String, value: String, lambda: ResponseCookieBuilder.() -> Unit
) = ResponseCookie.from(name, value).apply(lambda).build()
~~~ 

Et voila, a new micro DSL is born. The trick is to derive the trailing lambda function from `ResponseCookieBuilder`. This lambda function takes an instance of `ResponseCookieBuilder` as context of `this`, so it's possible to access the methods of `ResponseCookieBuilder` inside the lambda function. All we have to do is to create an instance of `ResponseCookieBuilder` with `ResponseCookie.from()` and call Kotlin's apply method with the lambda function. It will automatically inject the instance of `ResponseCookieBuilder` into the lambda function and apply the instructions inside the lambda function on this instance. To create the `ResponseCookie` object just call the build method and return the result. In this case I'm using the single-expression syntax for `createCookie` with type inference for the return type. Why add more curly braces than necessary?

You can use this little trick with all builders. It will also help you to automate things. In my current project we're using such micro DSLs to create product configurations. The factory method contains sanity checks after the lambda function was applied to the builder object. It will also fetch a YAML file via the product ID given to the builder. This data is parsed into an object and will be put into a property of the builder object. After the configuration object is created, the factory method will add to a map.

Of course there are other ways of achieving such automation, but the micro DSL approach is simple, improves readability and can also reduce redundant code. You can even easily nest builders to create a more powerful DSL. Spring's Kotlin extensions rely also on this. Take Spring Security for example. Their fluent interface for the security configuration is awful to read and difficult to understand, but Spring also provides a Kotlin extension with a micro DSL for that. So much more intuitive and better to read. There are many more extensions like for bean creation, the MVC mock in tests etc.
