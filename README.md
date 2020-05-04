# SpinRewriter Ruby Gem

[Spin Rewriter](http://www.spinrewriter.com/) is an online
service for spinning text (synonym substitution) that creates unique version(s)
of existing text. This package provides a way to easily interact with
[SpinRewriter API](http://www.spinrewriter.com/api). Usage requires an
account, [get one here](http://www.spinrewriter.com/registration).

This gem is basically a direct port of the official [Python client](https://github.com/niteoweb/spinrewriter), including a few idiosyncracies found in the original.
It's not exactly the greatest Ruby code, but it works.

## Features

- Supports all available API calls (`api_quota`, `text_with_spintax`, `unique_variation`, `unique_variation_from_spintax`)
- Supports the same options as the Python module

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'spin_rewriter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spin_rewriter

## Usage

After installing it, this is how you use it::

Initialize SpinRewriter.

    > require 'spin_rewriter'
    > rewriter = SpinRewriter::Api.new('username', 'api_key')

Request processed spun text with spintax.

    > text = "This is the text we want to spin."
    > rewriter.text_with_spintax(text)
    "{This is|This really is|That is|This can be} some text that we'd {like to
    |prefer to|want to|love to} spin."

Request a unique variation of processed given text.

    > rewriter.unique_variation(text)
    "This really is some text that we'd love to spin."


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PandaWhisperer/spin_rewriter.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
