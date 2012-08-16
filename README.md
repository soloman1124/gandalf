# Gandalf

Manages the state of the current user

## Installation

Add this line to your application's Gemfile:

    gem 'gandalf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gandalf

## Usage

Simply include the module into your application controller as so:

```ruby
class ApplicationController < ActionController::Base
  include Gandalf
  
  ...
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
