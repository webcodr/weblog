---
date: 2017-01-08T20:00:00+01:00
title: Webpack 2 with Pug and SASS
displayLanguage: en
---
Until now I used some Gulp tasks with Jade and SASS to create the HTML and CSS files as a base for the webcodr blog theme. A crude little setup, but it worked.

I decided to write an replacement with Webpack 2 and to share it with you: [WebCodr/design GitHub repo](https://github.com/WebCodr/design)

## First steps

The original setup used the identend SASS syntax and Jade templates. Since the indented syntax is more trouble than it's worth, I had to convert to the SCSS syntax, a superset of the CSS syntax.

Unfortunately there was a copyright claim for "Jade" and they had to rename the project to Pug. The Jade Node module is still available but unmaintained. It's time to use Pug.

### SASS to SCSS

Don't worry, that's quite simple. The SASS people provide a tool called `sass-convert` and it's really easy to use:

~~~ bash
sass-convert --from=sass --to=scss -R assets/styles/
~~~

Just pass the tool the format you want to convert, the new format, `-R` for recursive conversion and add the directory name. After `sass-convert` finished, you find the new SCSS files along with their SASS predecessors. You can now delete the old SASS files, adjust your build tool and you're done.

### Jade to Pug

It depends on your templates how easy or complicated this step is. My template files are rather simple, so just renaming the file extensions from `.jade` to `.pug` and using Pug instead of Jade did the job. If you are having trouble, there is a [migration guide from Jade to Pug](https://pugjs.org/api/migration-v2.html).

## Using Webpack 2

Webpack 2 isn`t finished yet. The current version is 2.2.0 RC3, but even the Beta version were stable enough to use it for production purposes.

Here's my `package.json` file with all necessary modules:

~~~ json
{
  "name": "WebCodr_Design",
  "version": "2.0.0",
  "scripts": {
    "server": "webpack-dev-server",
    "dist": "webpack --config webpack.config.prod.babel.js"
  },
  "dependencies": {},
  "devDependencies": {
    "autoprefixer": "^6.6.1",
    "babel-core": "^6.21.0",
    "babel-preset-es2015": "^6.18.0",
    "css-loader": "^0.26.1",
    "csso-loader": "^0.2.1",
    "extract-text-webpack-plugin": "^2.0.0-beta.4",
    "html-loader": "^0.4.4",
    "node-sass": "^4.1.1",
    "postcss-loader": "^1.2.1",
    "pug": "^2.0.0-beta6",
    "pug-html-loader": "^1.0.10",
    "sanitize.css": "^4.1.0",
    "sass-loader": "^4.1.1",
    "webpack": "2.2.0-rc.3",
    "webpack-dev-server": "2.2.0-rc.0"
  }
}
~~~

I wrote two little helper scripts to run a dev server on port `8080` and to build a production version of the assets, mainly the CSS file. Currently there is no JavaScript file for webcodr. But it would be really easy to add JavaScript to the Webpack config.

### The Webpack config or where the magic happens

I can't stand the old JavaScript syntax anymore, so I write all my stuff in ES2015 and that's why Babel is present in the dev dependencies.

~~~ javascript
import webpack from 'webpack'
import path from 'path'
import autoprefixer from 'autoprefixer'
import ExtractTextPlugin from 'extract-text-webpack-plugin'

let extractStyles = new ExtractTextPlugin('[name].css')
let extractHtml = new ExtractTextPlugin('[name].html')

let config = {
  stats: {
    assets: false,
    colors: true,
    version: false,
    hash: true,
    timings: true,
    chunks: false,
    chunkModules: false
  },
  entry: {
    index: [
      path.resolve(__dirname, 'templates/index.pug')
    ],
    post: [
      path.resolve(__dirname, 'templates/post.pug')
    ],    
    'css/application': [
      path.resolve(__dirname, 'assets/styles/application.scss')
    ]
  },
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: '[name].js'
  },
  module: {
    rules: [
      {
        test: /\.pug$/,
        loader: extractHtml.extract({
          loader: ['html-loader', 'pug-html-loader?pretty&exports=false']
        })
      },
      {
        test: /\.scss$/,
        loader: extractStyles.extract({
          loader: [
            {
              loader: 'css-loader'
            },
            {
              loader: 'postcss-loader'
            },
            {
              loader: 'sass-loader'
            }
          ]
        })
      }
    ]
  },
  plugins: [
    new webpack.LoaderOptionsPlugin({
      minimize: false,
      debug: true,
      options: {
        postcss: [
          autoprefixer({
            browsers: ['last 2 version', 'Explorer >= 10', 'Android >= 4']
          })
        ],
        sassLoader: {
          includePaths: [
            path.resolve(__dirname, 'node_modules/sanitize.css/')
          ]
        }
      }
    }),
    extractStyles,
    extractHtml
  ]
}

export default config
~~~

Explanations:

- `stats`: Webpack 2 is really verbose, this options will help to make it shut up. ;)

- `entry`: I defined three entry points for Webpack. Two for Pug files and one for my SCSS file. The property name is the filename for saving the finished file and the array item points to the source file.

- `output`: Defines where to put the files and how to name them.

- `module`: The module rules tell Webpack what to do with different file extensions. Since Webpack 2 is JavaScript module bundler it creates JavaScript files and we have to use a plug-in to get HTML and CSS files. The extract text plug-in looks for the content of the defined loaders and extracts it into the file you want.
  
    To convert Pug into HTML I had to use the Pug HTML loader and the HTML loader. The extract text plug-in now knows what to extract of the generated JavaScript files.

    The same goes for SASS. The SASS loader converts SASS into CSS, after that the PostCSS loader applies the Autoprefixer and finally the CSS loader tells the extract text plug-in what to do.

- `plugins`: `webpack.LoaderOptionsPlugin` contains the loader config for Webpack 1 loaders. Webpack 2 compatible loaders can be configured directly with the loader definition. As you can see, PostCSS loader and SASS loader are not compatible with Webpack 2 yet.

     After the configuration of the legacy loaders, I just had to add the extraction plug-in instances and that's it.

When Webpack is started, it will iterate through the entry points and apply the appropriate rules based on the regular expressions in the property `test`. Each rule applies the loaders in reverse order, so the last loader will be applied first. The loaders itself obtain their configs from the query as the Pug HTML loader does or the from the loader options plug-in, only the extract text plug-in is an exception as it needs two configurations: the loaders and where to put the extracted content.

After Webpack is finished, the files are located in the output directory. There are two files for each entry point: a HTML or CSS file and JavaScript file. As mentioned above, Webpack 2 is a JavaScript module bundler and can only create JavaScript files without help from plug-ins. Without extraction, this JavaScript files would contain the HTML or CSS code as a Webpack runtime module and could be used within JavaScript.

You could now open one of the HTML files in your browser, but there's a better way. You would have to manually start Webpack for each change to make ... meh.

~~~ bash
yarn run server
~~~

This will start the Webpack Dev Server on Port `8080`. It watches for changes and re-builds all affected files. You just have to reload the browser tab. Not comfy enough? There is a possibility of auto-reloading and even hot JavaScript module replacement which will be explored in a future blog post.

### Adding JavaScript support

What do you think? Is it complicated to create JavaScript files with a JavaScript module bundler? Of course not!

Add the following rule to your config:

~~~ javascript
{
  test: /\.js$/,
  exclude: /node_modules\/*/,
  use: ['babel-loader'],
  options: {
    presets: [
      ['es2015']
    ]
  }
}
~~~

Any entry point with JavaScript files will be processed with Babel for ES2015 support. Pretty neat, huh?

Need ES2016 or ES2017? No problem, just add a suitable Babel preset with npm or yarn to your project and adjust the config.

You're using TypeScript or CoffeeScript? No problem, just look for a compatible loader.

## Conclusion

Some say Webpack is too complicated. Well, it can be quite confusing if you're just using it without knowledge what it really does, but it's no rocket science.

I used Webpack to replace a rather large and complex collection of Gulp tasks to build the assets for the website of a customer. For certain things like SVG sprite maps I still use Gulp, but all other tasks are done by Webpack faster and way more easy, especially things like hashes in filenames for production purposes or automatically splitting the main JavaScript file into an application file and a vendor file with certain libraries/frameworks like AngularJS.

The same goes for Karma to run the Jasmine tests. Just add the Webpack plug-in for Karma, make some small adjustments to the Webpack config, let Webpack handle the rest and you're done.

Compared to the old Gulp tasks, the Webpack setup is easier to understand, faster and much more fun to use. New team members have not to dig into a bunch of Gulp tasks and related helper methods. A quick introduction to the Webpack config is mostly enough to understand how it works.

If you have about 1,000 lines of code with Gulp tasks and helper functions or some really small tasks and a about 150 lines of Webpack config, what do you prefer?

## TL;DR

Use Webpack 2, it's awesome. :P
