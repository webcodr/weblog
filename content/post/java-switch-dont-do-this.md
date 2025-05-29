---
date: 2025-05-28T20:22:07+02:00
title: "Please don't do this with switch statements"
draft: false
---

The classic C-like switch statement is fine, but it has its flaws. It's no coincidence that modern languages like Kotlin or Rust offer alternatives like `when` or `match` or a more fine-tuned version of `switch` like Zig.

I'm currently the in early stages of rewriting a large and complex Java code base to Kotlin. Some parts of this codebase are really ugly and uncessarily complicated and convoluted. Yesterday I crossed the path of a nasty use of a switch statement in a operation on a Java Stream. Unfortunately I can't share the real code, but imagine something like this:

~~~ java
int value1;
int value2;

for (...) {
    switch (enum) {
        case Enum.FOO:
            if (something) {
                if (somethingElse) {
                    value1 = someConvulutedStreamOperations();
                    value2 = someOtherConvulutedStreamOperations();
                    // imagine 30 more lines here
                } else {
                    value2 = 0;
                }

                break;
            }

        case Enum.BAR:
        default:
            value1 = 1;
            value2 = 2;

            break;
    }
}
~~~

This was part of a Java class with over 1,000 lines of code. Streams with many operations everywhere and sometimes very deep nesting thanks to old-style Java code. The original case for `Enum.FOO` stretches over almost the whole display space, so it's not easy to spot any potential pitfalls. After I ran IntelliJ's Kotlin migration tool and cleaned up all errors, it was time to run the unit tests and four out of 24 failed.

As you can imagine it's not straight forward to find problems in such a large and complex class but I came across a notice of an unused value assignment. Why it was there was also not clear immediately, so I compared the original Java file with the Kotlin version.

Since Kotlin has no `switch` IntelliJ converted it to `when`. Unlike it's Java counterpart `when` can handle `null` and is exhaustive with enums. There also no `break` keyword and that's exactly the problem here.

Look at the Java code and think about what happens on `Enum.FOO` if `something` is true but `somethingElse` isn't. The `break` keyword is not triggered and the `switch` statement goes on to the default block. As result `value1` and `value2` are assigned their values.

IntelliJ's migration tool is quite good, but it didn't catch that and the generated `when` statement was wrong. That's also the reason for the unused assignment notice. I assume the migration tool was confused by the scope of `break` since both `switch` and `for` can use it. Also there is no real match in Kotlin for such a structure. You have to assign the values of both variables for every branch inside the `when` statement. After fixing that all tests ran successfully.

It's a really good example how not to use `switch` statements, especially with nested control structures in a case. Since the original author of the code is no longer available, I can only guess why it was written this way. Probably to avoid duplication or even unintended. Well, it could seem as an elegant solution if you're familiar with the code, but to other people it's just an unnecessary pitfall that should be avoided. It's untuitive at best, not easy to comprehend and can lead to nasty bugs, especially if it's unintended behaviour. That's why Kotlin, Rust, Zig and other modern languages avoid breaks in their alternatives to switch statements in the first place.
