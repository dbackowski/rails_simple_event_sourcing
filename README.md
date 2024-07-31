# RailsSimpleEventSourcing ![tests](https://github.com/dbackowski/rails_simple_event_sourcing/actions/workflows/minitest.yml/badge.svg) ![codecheck](https://github.com/dbackowski/rails_simple_event_sourcing/actions/workflows/codecheck.yml/badge.svg)

This is a very minimalist implementation of an event sourcing pattern, if you want a full-featured framework in ruby you can check out one of these:
- https://www.sequent.io
- https://railseventstore.org

I wanted to learn how to build this from scratch and also wanted to build something that would be very easy to use since most of the fully featured frameworks like the two above require a lot of configuration and learning.

### Important notice

This plugin will only work with Postgres database because it uses JSONB data type which is only supported by this database.

## Usage

So how does it all work?

Let's start with the directory structure:

```
app/
├─ domain/
│  ├─ customer/
│  │  ├─ command_handlers/
│  │  │  ├─ create.rb
│  │  ├─ events/
│  │  │  ├─ customer_created.rb
│  │  ├─ commands/
│  │  │  ├─ create.rb
```

The name of the top directory can be different because Rails does not namespace it.

Based on the example above, the usage looks like this

Command -> Command Handler -> Create Event (which under the hood writes changes to the appropriate model)

Explanation of each of these blocks above:

- `Command` - is responsible for any action you want to take in your system, it is also responsible for validating the input parameters it takes (you can use the same validations you would normally use in models).

Example:

```ruby
class Customer
  module Commands
    class Create < RailsSimpleEventSourcing::Commands::Base
      attr_accessor :first_name, :last_name, :email

      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
    end
  end
end
```

- `CommandHandler` - is responsible for handling the passed command (it automatically checks if a command is valid), making additional API calls, and finally creating a proper event. This should always return the `RailsSimpleEventSourcing::Result` struct.

This struct has 3 keywords:
- `success?:` true/false (whether everything went ok, commands are automatically validated, but still there may be some API call here, etc., so you can return false if some API call failed)
- `data:` data that you want to return eg. to the controller (in the example above the `event.eventable` will return a proper instance of the Customer model)
- `errors:` in a scenario when you set success?: false you can also return here some errors related to this (see: `test/dummy/app/domain/customer/command_handlers/create.rb` for an example)

Example:

```ruby
class Customer
  module CommandHandlers
    class Create < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        event = Customer::Events::CustomerCreated.create(
          first_name: @command.first_name,
          last_name: @command.last_name,
          email: @command.email,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        )

        RailsSimpleEventSourcing::Result.new(success?: true, data: event.eventable)
      end
    end
  end
end
```

- `Event` - is responsible for storing immutable data of your actions, you should use past tense for naming events since an event is something that has already happened (e.g. customer was created)

Example:

```ruby
class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_model_name Customer
      event_attributes :first_name, :last_name, :email, :created_at, :updated_at

      def apply(aggregate)
        aggregate.id = aggregate_id
        aggregate.first_name = first_name
        aggregate.last_name = last_name
        aggregate.email = email
        aggregate.created_at = created_at
        aggregate.updated_at = updated_at
      end
    end
  end
end
```

In the example above:
- `aggregate_model_name` is used for the corresponding model (each model is normally set to read-only mode since the only way to modify it should be via events), this param is optional since you can have an event that is not applied to the model, e.g. UserLoginAlreadyTaken
- `event_attributes` - defines params that will be stored in the event and these params will be available to apply to the model via the `apply(aggregate)` method (where aggregate is an instance of your model passed in aggregate_model_name).

Here is an example of a custom controller that uses all the blocks described above:

```ruby
class CustomersController < ApplicationController
  def create
    cmd = Customer::Commands::Create.new(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email]
    )
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      render json: handler.data
    else
      render json: { errors: handler.errors }, status: :unprocessable_entity
    end
  end
end
```

There is a sample application in the `test/dummy/app` directory so you can see how updates and deletes are handled.

One thing to note here is that it would be better to do soft-deletes (mark record as deleted) instead of deleting records from the DB, since every record has relations called `events` when you have all the events that were applied to it.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "rails_simple_event_sourcing"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install rails_simple_event_sourcing
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
