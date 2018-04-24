---
date: 2018-04-24T16:21:49+02:00
title: "Vue Loader Setup in Webpack"
draft: false
---

Since it's no option to use Vue CLI in my current project, I had to manually add `vue-loader` to the Webpack
config. Well, I was positively surprised how simple it was. Especially compared to a manual set-up of Angular 2 shortly 
after its launch in late 2016, while Angular CLI was an alpha version and buggy as hell.

## Shall we begin?

### Modules

Let's add the necessary modules to the package:

~~~ sh
yarn add --dev vue-loader vue-template-compiler
yarn add vue
~~~

If you want to use a template engine like Pug or prefer TypeScript over JavaScript, you can add the respective
Webpack loader package, `pug-loader` for example. Webpack will also tell you in detail, if modules are missing.

### Webpack

Just add the following rule to your Webpack config:

~~~ javascript
{
  test: /\.vue$/,
  use: [
    {
      loader: 'vue-loader'
    }
  ]
}
~~~

Webpack will now be able to use import statements with Vue single file components.

If you want to have a separate JavaScript file with your Vue application, you can add a new entry point:

~~~ javascript
{
  entry: {,
    'current-application': [
      path.resolve(__dirname, 'js/current-application.js')
    ],
    'vue-application': [
      path.resolve(__dirname, 'js/vue-application.js')
    ]
  }
}
~~~

Not fancy enough? How about vendor chunks?

~~~ javascript
{
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          chunks: 'initial',
          test: /node_modules\/(?!(vue|vue-resource)\/).*/,
          name: 'vendor',
          enforce: true
        },
        'vue-vendor': {
          chunks: 'initial',
          test: /node_modules\/(vue|vue-resource)\/.*/,
          name: 'vue-vendor',
          enforce: true
        }
      }
    }
  }
}
~~~

This will separate your vendor files from `node_modules` into `vendor.js` and `vue-vendor.js`. The property `test` contains
a regex to determine which modules should go into the vendor chunks.

Of course, this comes not even close to what Vue CLI can do. I highly recommend to use Vue CLI when it's feasible. It's 
quite easy to configure while not being dumbed down, has an excellent documentation and is very well maintained. At least
for our customer's set-up it would be difficult to use Vue CLI at the moment, but we are eager to migrate to Vue CLI asap.
