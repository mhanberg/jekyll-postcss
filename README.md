# Jekyll  PostCSS
[![Build Status](https://travis-ci.com/mhanberg/jekyll-postcss.svg?branch=master)](https://travis-ci.com/mhanberg/jekyll-postcss)
[![Gem Version](https://badge.fury.io/rb/jekyll-postcss.svg)](https://badge.fury.io/rb/jekyll-postcss)

A plugin to use PostCSS plugins like [Autoprefixer](https://github.com/postcss/autoprefixer) or [Tailwind CSS](https://github.com/tailwindcss/tailwindcss) with Jekyll.

The goal of this project is to be able to use modern CSS tooling with Jekyll, without the hassle of dealing with other build tools. It should be as easy as `bundle exec jekyll serve`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-postcss'
```
And then add this line to your application's `_config.yml`:

```yml
# _config.yml

plugins:
  - jekyll-postcss
```

## Usage

Make sure you have [postcss](https://github.com/postcss/postcss) installed.

Add your PostCSS plugins to a `postcss.config.js` file in the root of your repository.

```javascript
// postcss.config.js

module.exports = {
  plugins: [
    require("autoprefixer") // example of plugin you might use
    ...(process.env.JEKYLL_ENV == "production" // example of only using a plugin in production
      ? [require("cssnano")({ preset: "default" })]
      : [])
  ]
};
```

All CSS and SCSS/Sass files will now be processed by PostCSS.

### SCSS/Sass

If using SCSS/Sass, you must have [postcss-scss](https://github.com/postcss/postcss-scss) installed and configured in your `postcss.config.js`

```javascript
module.exports = {
  parser: 'postcss-scss',
  plugins: [
    // ...
  ]
};
```

### Notes

jekyll-postcss will run a development server when `JEKYLL_ENV` is set to `development`. This is the default value if you don't set it elsewhere. When building your site for production or staging, make sure to set the `JEKYLL_ENV` appropriately, or else your deploy may fail, e.g., `JEKYLL_ENV=production bundle exec jekyll build`.

Also note that your `.css` files still need to have a [front matter](https://jekyllrb.com/docs/step-by-step/03-front-matter/) for them to be processed by Jekyll.

```
---
---

/* Example using Tailwind */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/mhanberg/jekyll-postcss](https://github.com/mhanberg/jekyll-postcss). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jekyll PostCSS project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mhanberg/jekyll-postcss/blob/master/CODE_OF_CONDUCT.md).
