# Discretion

**tldr; Discretion is a simple privacy/authorization framework for Rails projects. You define `can_see?(viewer)` methods in a model class to determine if a given viewer is allowed to view/load/read the model (record). If so, you can query and load the record as you normally would in Rails (e.g. using `find`, `where`, `limit`, ...). If not, then Discretion will throw an exception when you try to fetch the record. Something similar is done for writes (via `can_write?(viewer, changes, new_record)`) and deletions (via `can_destroy?(viewer)`).**

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

The idea is simple: we colocate the read and write policies with the model definitions themselves by defining `can_see?(viewer)` and optionally `can_write?(viewer, changes, new_record)` and `can_destroy?(viewer)`. The semantics are straightforward: given a `viewer` (typically a `User` but can be anything you want -- more on this below), can that viewer see the record encapsulated by the model class?

For example, let's say we have a web app for a large non-profit organization which has staff who have to raise money from donors. So we might have models like `Donor`, `Staff`, and `Donation`. Below we will describe how we would set up authorization/privacy policies for these models using Discretion.

### Opt-In

Discretion uses an Opt-In strategy: you must tell discretion which models should use discretion. To do this, you use the `use_discretion` directive in your model definition. When you do this, you **must** then define a `can_see?(viewer)` method. You can also optionally define `can_write?(viewer, changes, new_record)` and/or `can_destroy?(viewer)`. These methods can have any visibility (private, protected, or public). If you don't define `can_write?(viewer, changes, new_record)`, then Discretion will only allow the write (`update` in Rails parlance) if `can_see?(viewer)` returns true. Similarly, if you don't define `can_destroy?(viewer)`, then Discretion will only allow the destruction of the record if `can_write?(viewer, {}, false)` returns `true`, and if neither `can_destroy?` and `can_write?`, destruction will only be allowed if `can_see?(viewer)` is `true`. Again, if you opt your model in to Discretion via `use_discretion`, you **must** implement at least `can_see?(viewer)` so that Discretion knows what to do in all cases of loading, updating, and destroying instances of that record class.

So, continuing with our running example of a non-profit organization with `Donor`s, `Staff`, and `Donation`s, we might start with some basic privacy policies like this:

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
  
  def can_write?(viewer, _changes, _new_record)
    # Only the recipient can edit an existing donation.
    viewer == recipient
  end
end
```

Note that `can_write?` is passed the `changes` Hash (cf. https://api.rubyonrails.org/classes/ActiveModel/Dirty.html#method-i-changes) for the update and the `new_record` boolean flag indicating if the record is being created or not. With these, you can write more complex write policies (e.g. anyone can create a new thing, but only admins can edit existing things or no one can ever change the `foobar` attribute after creation).

### Destroy policies

If you define `can_destroy?(viewer)` on the model class, then Discretion will use that to determine whether the current viewer is allowed to destory the record. Otherwise, it will allow the destruction of the record as long as the viewer also has authority to write the object.

### Per-attribute privacy

This is a more advanced usage of Discretion, but one that you will probably need eventually as your models get more complex. For example, let's say we wanted to protect the `email`s of `Donor`s, so that a `Donor` can only see their own `email` and no one else can. We could do this like so:

```ruby
  class Donor < ApplicationRecord
    use_discretion
    
    # Only logged-in Donors can see their own emails.
    discreetly_read(:email) { |viewer, record| viewer == record }
    
    ...
    
    def can_see?(viewer)
      # The Donor can see themselves (duh) and so can any Staff.
      viewer == self || viewer.is_a?(Staff)
    end
  end
```

Here we are saying that the `email` attribute should be readable if and only if the logged-in viewer **is** the Donor in question. This is useful e.g. when you are using GraphQL which will pluck the set of attributes requested by the client query. For exmaple, you may deem it acceptable for all `Staff` to see `Donor`s' names, but not `email`s. So if you accidentally were to query for a `Donor`'s `email` when a `Staff` is logged-in, it won't work (Discretion will raise the `Discretion::CannotSeeError`).

### Wait what's the `viewer` object though?

You decide. Since `viewer` is given as an argument to `can_see?`, `can_write?`, `can_destroy?`, etc., it's really for you to help you write privacy/authorization policies without having to store the current viewer elsewhere. Discretion exposes two helper methods for setting and retrieving the current `viewer`, and there is no expectation about what kind of object it is. For example, if you set the `current_user` in your base `ApplicationController` class, you could do something like this:

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

If you want to retrieve that anywhere later (you may never have to), you can do so by `Discretion.current_viewer`.

### Middleware

Discretion has a Railtie which adds a middleware which sets the `current_viewer` from [Clearance](https://github.com/thoughtbot/clearance) if Clearance is detected (I use Clearance for my projects so I wrote this for convenience). I **might** add functionality to detect the current user from other authentication frameworks in the future. In the meantime, you can add your own middleware to set the `current_viewer` in Discretion, looking something like this:

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

Discretion is totally opaque and should not require any changes in how you query for or write records. That is, you can just query for things normally using `find`, `where`, `limit`, etc. You can also `create`/`update`/`destroy` records as you normally would, and Discretion will check your `can_see?`, `can_write?`, and `can_destroy?` policies for all of these actions.

### Getting around Discretion

Sometimes you will want to bypass Discretion's read and/or write protections. For example, you may be writing a Rake task to do a mass migration of some sort and you don't want to bother faking the `Discretion.current_viewer` before reading/writing every record. I have provided two mechanisms for bypassing Discretion.

The first is `Discretion.omnisciently do ... end`. Omniscience is the ability to **see** everything. So, if you wanted to do a mass-validation over all the `Donation` records in your db, you might do:

```ruby
Discretion.omnisciently do
  Donation.in_batches.each_record do |donation|
    # ... do a bunch of reads on the donation, but writes will still be protected by Discretion. ...
  end
end
```

The second is `Discretion.omnipotently do ... end`. Omnipotence is the ability to **write** everything. Omnipotence implies Omniscience so if you wanted to change the attribute of every `Donation` in the db, you might do:

```ruby
Discretion.omnipotently do
  Donation.in_batches.each_reecord do |donation|
    donation.update!(...) # or even donation.destroy!
  end
end
```

Use these **carefully**, as they turn off the deep read and/or write protections provided by Discretion. For example, you may need to use one of both of these tools in a login controller, but you should be __really__ careful because if you mess up you might introduce a vulnerability in your application where privacy is not enforced correctly. [WITH GREAT POWER...](https://en.wikipedia.org/wiki/Uncle_Ben#%22With_great_power_comes_great_responsibility%22).

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abeland/discretion.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
