---
date: 2018-04-25T17:27:26+02:00
title: "Awesome tests with Vue and Jest"
draft: false
---

Jest is a very neat JavaScript testing library from Facebook. It's mostly syntax-compatible with Jasmine and needs zero
or very less configuration. Code coverage reports are there out-of-the-box and with sandboxed tests and snapshot testing
it has some unique features.

## Set-up Jest

### Vue CLI

You are using Vue CLI? Consider yourself lucky, the set-up of Jest could not be simpler:

~~~ sh
yarn add --dev jest @vue/cli-plugin-unit-jest
vue invoke unit-jest
~~~

Vue CLI will do the rest and also create an example spec for the HelloWorld component.

### DIY

Install all necessary dependencies:

~~~ sh
yarn add --dev @vue/test-utils babel-jest jest jest-serializer-vue vue-jest
~~~

Create `jest.config.js` in your project root directory:

~~~ javascript
module.exports = {
  moduleFileExtensions: ['js', 'json', 'vue'],
  transform: {
    '^.+\\.vue$': 'vue-jest',
    '^.+\\.js?$': 'babel-jest'
  },
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  snapshotSerializers: ['jest-serializer-vue'],
  testMatch: ['<rootDir>/src/tests/**/*.spec.js']
}
~~~

Please adjust the paths in `moduleNameMapper` and `testMatch` to your project.

You should also add a modern JavaScript preset to your `.babelrc` file:

~~~ javascript
{
  "presets": ["es2015"]
}
~~~

#### Optional step

Add the following line to your `.gitignore` file:

~~~ sh
/coverage
~~~

The set-up is now complete. Let's write a test file!

## Writing tests

Here is a litte example Vue component:

~~~ html
<template>
  <ul class="demo">
    <li class="demo__item" v-for="value in values" :key="value">{{ value }}</li>
  </ul>
</template>

<script>
export default {
  name: 'demo',
  data () {
    return {
      values: []
    }
  },
  created() {
    this.fetchValues()
  },
  methods: {
    async fetchValues() {
      const response = await fetch('/api/demo/values')
      this.values = await response.json()
    }
  }
}
</script>
~~~

The component `Demo` will fetch some values after its creation and display them in an unordered list. This is example is quite
simple, but testing is a little more complex due to the usage of `fetch`, `async` and `await`.

Of course, there are some tools to help us:

~~~ sh
yarn add --dev fetch-mock flush-promises
~~~

Now, let's write a test:

~~~ javascript
import { shallow } from '@vue/test-utils'
import fetchMock from 'fetch-mock'
import flushPromises from 'flush-promises'
import Demo from '@/components/Demo.vue'

const values = [
  'foo',
  'bar'
]

describe('Demo.vue', () => {
  beforeEach(() => {
    fetchMock.get('/api/demo/values', values)
  })

  it('renders component', async () => {
    const wrapper = shallow(Demo)
    await flushPromises()

    expect(wrapper.vm.values).toEqual(values)
  })

  afterEach(() => {
    fetchMock.restore()
  })
})
~~~

### What's going on?

1. `shallow` from Vue Test Utils creates a wrapper of the rendered and mounted component, any child components will be stubs. 
If you need child components in your test, please use `mount` instead of `shallow`.

2. `fetchMock` will create a mocked version of the Fetch API. In this case it will return the defined values for a GET request to
`/api/demo/values`. If you send a request that's not defined in fetchMock, it will throw an exception and break your tests.

3. The test itself is defined as async to use `await` for `flushPromises()`. It will wait until the mocked request is finished and the values are stored in the component's data.

4. You can now access the data property `values` and compare the content to the response of the mocked HTTP request.

## Conclusion

Setting up Jest for Vue is easy, even if you have to do it manually. 

**A little warning**: setting up Jest for an existing app can be tedious. 
The current AngularJS app of our customer can't be tested with Jest, at least for now. The AngularJS HTTP mock does not work and I haven't figured out the problem yet.

But enough of Angular: the real deal comes with the testing itself. Async/await is a nice and simple way for testing asynchronous behaviour. 
I don't think this could be easier and it's a reliable method with the power of modern JavaScript. Try to imagine what the demo test would look like in ES5 ... 