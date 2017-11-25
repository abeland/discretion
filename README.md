# Discretion

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discretion'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install discretion

## Usage

(Please note that currently (and for the foreseeable future), Discretion only works with ActiveRecord)


### High Level Idea

The idea is simple: we colocate the read and write policies with the model definitions themselves by defining `can_see?(viewer)` and optionally `can_write?(viewer)`. The semantics are straightforward: given a `viewer` (typically a `User` but can be anything you want -- more on this below), can that viewer see the record encapsulated by the model class?

For example, let's say we have a web app for a large non-profit organization which has staff who have to raise money from donors. So we might have models like `Donor`, `Staff`, and `Donation`s. Below we will describe how we would set up authorization/privacy policies for these models using Discretion.

### Opt-In

Discretion uses an Opt-In strategy: you must tell discretion which models should use discretion. To do this, you use the `use_discretion` directive in your model definition. When you do this, you **must** then define a `can_see?(viewer)` method. It can have any visibility (private, protected, or public). So, continuing with our running example of a non-profit organization with `Donor`s, `Staff`, and `Donation`s, we might start with some basic privacy policies like this:

```ruby
class Staff < ApplicationRecord
  use_discretion

  ...
  
  private
  
  def can_see?(viewer)
    # Only Staff of the organization can see Staff members.
    viewer.is_a?(Staff)
  end
```

```ruby
class Donor < ApplicationRecord
  use_discretion
  
  ...
  
  def can_see?(viewer)
    # Only the Donor herself or Staff of the organization can see the Donor.
    viewer == self || viewer.is_a?(Staff)
  end
```

```ruby
class Donation < ApplicationRecord
  use_discretion
  
  belongs_to :donor
  belongs_to :recipient, class_name: 'Staff', foreign_key: 'staff_id'
  
  ...
  
  def can_see?(viewer)
    # Only the Donor for the donation or the Staff recipient of the donation can see the Donation.
    viewer == donor || viewer == recipient
  end
end
```

### Write policies

You can optionally distinguish write policies from read policies. If you don't, then Discretion will assume that if the current viewer `can_see?` the record, that it `can_write?` it as well. So we might edit our running example to only allow the recipient of a `Donation` to edit it (i.e. the recipient staff member recording donations):

```ruby
class Donation < ApplicationRecord
  use_discretion
  
  belongs_to :donor
  belongs_to :recipient, class_name: 'Staff', foreign_key: 'staff_id'
  
  ...
  
  def can_see?(viewer)
    # Only the Donor for the donation or the Staff recipient of the donation can see the Donation.
    viewer == donor || viewer == recipient
  end
  
  def can_write?(viewer)
    # Only the recipient can edit the donation.
    viewer == recipient
  end
end
```

### Wait what's the `viewer` object though?

You decide. Since `viewer` is given as an argument to `can_see?` and `can_write?`, it's really for you to help you write privacy/authorization policies without having to store the current viewer elsewhere. Discretion exposes two helper methods for setting and retrieving the current `viewer`, and there is no expectation about what kind of object it is. For example, if you set the `current_user` in your base `ApplicationController` class, you could do something like this:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_discretion_current_user
  
  def current_user
    # I use RequestStore instead of static variables as the latter could persist across requests depending on the server.
    RequestStore[:current_user] ||= current_user_from_cookies
  end

  private
  
  def current_user_from_cookies
    ... fetch user from session cookies ...
  end
  
  def set_discretion_current_user
    Discretion.set_current_viewer(current_user)
  end
```

If you want to retrieve that anywhere later (you may never have to), you can do so by `Discretion.get_current_viewer`.

### Middleware

Discretion has a Railtie which adds a middleware which sets the `current_viewer` from [Clearance](https://github.com/thoughtbot/clearance) (I use Clearance). I **might** add functionality to detect the current user from other authentication frameworks in the future. In the meantime, you can add your own middleware to set the `current_viewer` in Discretion, looking something like this:

```ruby
module MyApp
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      Discretion.set_current_viewer(current_user_from_some_other_source)
      @app.call(env)
    end
  end
end
```

Again, if you use [Clearance](https://github.com/thoughtbot/clearance), you shouldn't have to do anything and `current_viewer` will be set from the `env[:clearance].current_user` value (exposed by Clearance's middleware) in Discretion's middleware.

### But what about roles and such?

Discretion's scope is focused and limited to privacy/authorization. It's a **non-goal** of this project to handle enumeration of roles or permissions or ACLs on actual objects with respect to other objects. There are other gems which do this well. I personally like [Rolify](https://github.com/RolifyCommunity/rolify), and Rolify can be used with Discretion in very nifty ways. Continuing our non-profit organization example, we can use Rolify to create an `admin` role for Staff members, and allow admins of the organization as well as recipients of a donation to edit `Doantion`s:

```ruby
class Organization < ApplicationRecord
  has_many :donations
end

...

class Donation < ApplicationRecord
  use_discretion
  
  belongs_to :organization
  belongs_to :donor
  belongs_to :recipient, class_name: 'Staff', foreign_key: 'staff_id'
  
  ...
  
  def can_see?(viewer)
    # Only the Donor for the donation or the Staff recipient of the donation can see the Donation.
    viewer == donor || viewer == recipient || viewer.has_role?(:admin, organization) # <- rolify in third disjunct
  end
  
  def can_write?(viewer)
    # Only the recipient can edit the donation.
    viewer == recipient || viewer.has_role?(:admin, organization) # <- rolify in second disjunct
  end
end
```

### Querying for and writing records

Discretion is totally opaque and should not require any changes in how you query for or write records. That is, you can just query for things normally using `find`, `where`, `limit`, etc. You can also `create`/`update`/`destroy`/`delete` records as you normally would, and Discretion will check your `can_see?` and `can_write?` policies for all of these actions.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abeland/discretion.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
