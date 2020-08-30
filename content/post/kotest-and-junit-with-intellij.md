---
date: 2020-08-29T22:26:07+02:00
title: "Kotest and JUnit with IntelliJ or: don’t frak up your toolchain upgrades"
draft: false
---
My team and I recently decided to use Kotlin for new features in our existing project. It was a great choice to implement a new authentication process and we’re now rewriting some older parts of the application from Java to Kotlin.

Actually I wanted to use Kotlin for a while now, but there were only minor tasks within the Java part of the project. That finally changed and we can focus to improve the Java backend drastiscally.

Part of this process was a library update. We decided to upgrade JUnit from 4 to 5. A big pain in the ass. I don’t think, I would do it again. JUnit 5 was also part of a bigger problem, even if it was actually PEBCAC.

## Kotest and MockK features

If you already know about Kotest or want to know more about the problem I had, just skip to next headline. The Kotest introduction is a little bit longer.

As I dived more and more into Kotlin, I stumbled over a Kotest. A really neat testing framework for Kotlin. There’s nothing wrong with JUnit, but Kotest gives you way more awesome ways to structure your tests.

A little example:

```kt
package io.webcodr.demo

import io.webcodr.demo
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.mockk.*

class UserServiceTest : FunSpec() {
    private val userRepository = mockk<UserRepository>()
    private val service = UserService(userRepository)
    private lateint var user: User

    init {
        beforeTest {
            user = User(1, "Jane", "Doe", "jane@doe.com")
        }

        afterTest {
            clearAllMocks()
        }

        context("getUser()") {
            fun verifyRepoCalls() {
                verify {
                    userRepository.findById(1)
                }

                confirmVerified(userRepository)
            }

            test("should succeed") {
                every {
                    userRepository.findById(1)
                } returns user

                service.getUser(1).shouldBe(user)

                verifyRepoCalls()
            }

            test("should fail") {
                every {
                    userRepository.findById(1)
                } throws UserNotFoundException()

                shouldThrow<UserNotFoundException> {
                    service.getUser(1)
                }

                verifyRepoCalls()
            }
        }
    }
}

```

Kotest offers serveral different styles to write tests. I chose the `FunSpec` style for this example. You could also use a BDD-like or Jasmine-like style, if you want to.

It’s much more intuitive to nest tests with Kotest. To be fair, JUnit 5 allows you to use `@Nested` with an inner class to acomplish nesting as well, but it’s not as intuitive and harder to read than trailing lambdas.

Assertions are also a little easier to write. Kotest has over 100 different matchers. You can use them as extensions functions, like in the example above or alternatively as infix functions, for example `service.getUser(1) shouldBe user`. It’s also quite simple to write custom matchers.

There are many more features like soft assertions, tagging, easy temporay file creation or handling for non-deterministic test cases.

For mocking we decided to use MockK, since it’s way more intuitive to use than Mockito with Kotlin. Don’t get me wrong, Mockito is a great library, but it has one flaw: the `when` method. `when` is a keyword in Kotlin and to use it with Mockito, you need to write it in backticks. That’s quite ugly and not intuitive at all.

So, in summary, Kotest offers a bunch of pretty neat features and is very intuitive to use. Of course, JUnit can achieve much of this as well, it’s just not that shiny and little harder to read.

## The actual problem or: why the frak is there IntelliJ in the title?

If you migrate an old codebase to Kotlin and want to use Kotest, you will have no choice and have to use JUnit and Kotest in coexistence.

That shouldn’t be a problem, since Kotest uses the JUnit 5 Jupiter engine under the hood. But …

As I wrote a new service in Kotlin and some tests with Kotest, I could not start the JUnit tests anymore. As soon as the maven depedency of Kotest was present, IntelliJ didn’t recognize JUnit tests and used the Kotest files only. With `mvn test` (Maven Surefire) everything worked fine.

I tried several things and was ready to give up. Search engines didn’t find anything about this problem. Nothing on GitHub, nothing on Stack Overflow.

I hate to give up, so I decided to create a small demo project to open a GitHub issue. Well, that didn’t work out as intended, since the discovery of JUnit tests in the demo project worked fine. The IntelliJ JUnit runner did what it was supposed to: run JUnit and Kotest.

Well, frak. There must be some kind configuration problem with my real project. I already looked at the IntelliJ runner config, Maven files etc. — nothing worked.

I compared the Maven files from both codebases and there was one difference: my real project did not include the JUnit Jupiter Engine depedency. Bingo. I added to the Maven file and guess what? It worked like a charm.

What an embarassment. As we upgraded from JUnit 4 to 5, we forgot to add the new depedency for the engine. I don’t know why the tests worked at all, but it seems the engine is not really necessary for all cases. But it can screw up test discovery quite well, if you forget it.

The dependency configuration in POM file should like this:

```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-api</artifactId>
    <version>${junit.version}</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-engine</artifactId>
    <version>${junit.version}</version>
    <scope>test</scope>
</dependency>
```

Well, that was a long post, but IMO it was necessary to show how this problem came to be and even if you have no trouble at all, perhaps you’ll consider to use Kotest. It’s awesome!

## Gradle

I’m not sure, but this issue could happen with Gradle as well, when you are migrating to JUnit 5.
