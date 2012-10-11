# Gandalf

The white wizard of user authentication and authorization. Gandalf doesn't worry about how users are represented or persisted, that's your job, but it provides an easy and consistent mechanism to tie into that logic.

Your authorization logic should not be contained in a controller or a model but rather it's own module domain

## Installation

Add this line to your application's Gemfile:

    gem 'gandalf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gandalf

## Introducing abilities

Gandalf introduces the concept of abilities (heavily influenced by [CanCan](http://github.com/ryanb/cancan), thanks Ryan!). The idea is to separate concerns on what a user can and cannot do. This means there's only one place to go to check if a user can perform a certain action or not.

## Getting started

### Authentication

Simply include the module into your application controller as so:

```ruby
class ApplicationController < ActionController::Base
  include Gandalf

  gandalf_retrieve_user do |controller|
    User.find controller.session[:user_id]
  end

  gandalf_persist_user do |controller, user|
    if user
      controller.session[:user_id] = user.id
    else
      controller.session.delete :user_id
    end
  end

  ...
end
```

### Authorization

Create an object, ideally `Ability` in your model path (or lib depending on your preference) and include the `Ability` module like so:

```ruby
class Ability
  include Gandalf::Ability

  ...
end
```

Now that your model can manage abilities. With an ability, checks are done against a user as to whether they **can** or **cannot** perform a certain action.

```ruby
class Ability
  include Gandalf::Ability

  def initialize user
    can :read, Post
    can :update, Post do |action, post|
      post.author == user
    end
    can [:update, :delete], :all do |action, subject|
      user.admin?
    end
    cannot :delete, User
  end
end
```

Above any user can **read** a `Post` but only the author can **update** it. If the user has admin privledges they are update to **update** and **delete** not just posts but **all** objects. `:all` is a wildcard for all objects while `:manage` is a wildcard for all actions. Negative abilities can be defined to counter a user's ability. In this example the admin user's ability to delete users is revoked.

Once all abilities are defined checking whether a user *can* or *cannot* perform is very simple:

```ruby
ability = Ability.new current_user
ability.can? :read, post
ability.cannot? :delete, post.author
```

All ability checking is a simple true or false result. This can be used in your controllers, view, anywhere. As an added help if `Gandalf` is added to a controller then you can simply call `can?` and `cannot?` in your controllers and views after defining a method to retrieve the current ability:

```ruby
class ApplicationController < ActionController::Base
  ...
  def current_ability
    @current_ability ||= Ability.new current_user
  end
  ...
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

Licensed under the MIT License.