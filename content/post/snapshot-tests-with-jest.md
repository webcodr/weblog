---
date: 2018-06-13T16:31:12+02:00
title: "Snapshot Tests With Jest"
draft: false
---

Writing tests can sometimes be a tedious task. Mocks and assertions can be a pain in the ass. The latter is especially nasty when HTML is involved. Give me the second p element from the 30th div within an article in aside etc. -- no thanks.

The creators of Jest (Facebook) have found a better way: Snapshot tests!

## How does it work?

Take a look the following assertion:

~~~ javascript
it('should create a foo bar object', () => {
  const result = foo.bar()
  expect(result).toMatchSnapshot()
})
~~~ 

`toMatchSnapshot()` takes what ever you give to `expect()`, serializes it and saves it into a file. The next test run will compare the expected value to the stored snapshot and will fail if they don't match. Jest shows a nicely formatted error message and diff view on failed tests.

This is really useful with generated HTML and/or testing UI behaviour. Just call the method and let it compare to the snapshot.

## Updating snapshots

You added something to your code and the snapshot has to be updated? No problem:

~~~ bash
jest --updateSnapshot
~~~

If you're using the Jest watcher it's even simpler. Just press `u` to update all snapshots or press `i` to update the snapshots interactively.

## What about objects with generated values?

Here's an example with an randomized id:

~~~ javascript
it('should fail every time', () => {
  const ship = {
    id: Math.floor(Math.random() * 20),
    name: 'USS Defiant'
  }

  expect(ship).toMatchSnapshot()
})
~~~

The id will change on every test run, so this test will fail every time. Well, shit? Nope. Jest got you covered:

~~~ javascript
it('should create a ship', () => {
  const ship = {
    id: Math.floor(Math.random() * 20),
    name: 'USS Defiant'
  }

  expect(ship).toMatchSnapshot({
    id: expect.any(Number)
  })
})
~~~

Jest will now only compare the type of the id and the test will pass.

For certain objects like a date, there is another possibility:

~~~ javascript
Date.now = jest.fn(() => 1528902424828)
~~~

A call of `Date.now()` will call the mock method and always return the same value.

## Some advice

1. Always commit your snapshots! If they are missing,CI systems will always create new snapshots and the tests will become useless.

2. Snapshot tests are an awesome tool, but don't be too lazy. They are no replacement for other assertion types, especially if you're working test-driven. Rather use them alongside with your other tests.

3. Write meaningful test names. Well, you heard that one before, didn't you? Really, it helps a a lot when tests fail or you have to look inside a snapshot file. Jest takes a test name as an id inside a snapshot file. That's why you have to update a snapshot after changing the name.
