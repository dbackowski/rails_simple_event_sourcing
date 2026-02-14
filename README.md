# RailsSimpleEventSourcing ![tests](https://github.com/dbackowski/rails_simple_event_sourcing/actions/workflows/minitest.yml/badge.svg) ![codecheck](https://github.com/dbackowski/rails_simple_event_sourcing/actions/workflows/codecheck.yml/badge.svg)

A minimalist implementation of the event sourcing pattern for Rails applications. This gem provides a simple, opinionated approach to event sourcing without the complexity of full-featured frameworks.

If you need a more comprehensive solution, check out:
- https://www.sequent.io
- https://railseventstore.org

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Directory Structure](#directory-structure)
  - [Commands](#commands)
  - [Command Handlers](#command-handlers)
  - [Events](#events)
  - [Registering Command Handlers](#registering-command-handlers)
  - [Controller Integration](#controller-integration)
  - [Update and Delete Operations](#update-and-delete-operations)
  - [Metadata Tracking](#metadata-tracking)
  - [Event Querying](#event-querying)
  - [Events Viewer](#events-viewer)
- [Testing](#testing)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
  - [Command Handler Registry](#command-handler-registry)
  - [CommandHandlerNotFoundError](#commandhandlernotfounderror)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Immutable Event Log** - All changes stored as immutable events with full audit trail
- **Automatic Aggregate Reconstruction** - Rebuild model state by replaying events
- **Built-in Metadata Tracking** - Captures request context (IP, user agent, params, etc.)
- **Read-only Model Protection** - Prevents accidental direct model modifications
- **Command Handler Registry** - Explicit command-to-handler mapping with fallback to convention
- **Simple Command Pattern** - Clear command → handler → event flow
- **PostgreSQL JSONB Storage** - Efficient JSON storage for event payloads and metadata
- **Built-in Events Viewer** - Web UI for browsing, searching, and inspecting events
- **Minimal Configuration** - Convention over configuration approach

## Requirements

- **Ruby**: 2.7 or higher
- **Rails**: 6.0 or higher
- **Database**: PostgreSQL 9.4+ (requires JSONB support)

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

Copy migration to your app:
```bash
rails rails_simple_event_sourcing:install:migrations
```

Run the migration to create the events table:
```bash
rake db:migrate
```

This creates the `rails_simple_event_sourcing_events` table that stores your event log.

## Configuration

You can configure the behavior of the gem using the configuration block:

```ruby
# config/initializers/rails_simple_event_sourcing.rb
RailsSimpleEventSourcing.configure do |config|
  # When true, falls back to convention-based handler resolution
  # When false, requires explicit registration of all handlers
  config.use_naming_convention_fallback = true
end
```

## Usage

### Architecture Overview

The event sourcing flow follows this pattern:

```
HTTP Request → Controller → Command → CommandHandler → Event → Aggregate (Model)
                   ↓           ↓            ↓             ↓          ↓
              Pass data   Parameters    Validation +   Immutable   Database
                          + Validation   Business      Storage
                            Rules        Logic
```

**Flow breakdown:**
1. **Controller** - Receives request, creates command with params
2. **Command** - Defines parameters and validation rules (ActiveModel)
3. **CommandHandler** - Validates command, executes business logic, creates event
4. **Event** - Immutable record of what happened
5. **Aggregate** - Model updated via event

### Directory Structure

Let's start with the recommended directory structure:

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

**Note:** The top directory name (`domain/`) can be different - Rails doesn't enforce this namespace.

### Commands

Commands represent **intentions** to perform actions in your system. They are responsible for:
- Encapsulating action parameters
- Validating input data (using ActiveModel validations)
- Being immutable value objects

Think of commands as "requests to do something" - they describe what you want to happen, not how it happens.

**Example - Create Command:**

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

### Command Handlers

Command handlers contain the **business logic** for executing commands. They:
- Automatically validate the command before execution
- Perform business logic and API calls
- Create events when successful
- Handle errors gracefully
- Return a `RailsSimpleEventSourcing::Result` object

**Handler Discovery:**
Handlers can be discovered in two ways:
1. **Explicit Registration** (recommended) - Using the `CommandHandlerRegistry` to register handlers
2. **Convention-based** - Using naming convention mapping (can be disabled via configuration)

**Result Object:**
The `Result` struct has three fields:
- `success?` - Boolean indicating if the operation succeeded
- `data` - Data to return (usually the aggregate/model instance)
- `errors` - Array or hash of error messages when `success?` is false

**Helper Methods:**
The base class provides convenience methods:
- `success_result(data:)` - Creates a successful result
- `failure_result(errors:)` - Creates a failed result

**Example - Basic Handler:**

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

        # Using helper method (recommended)
        success_result(data: event.aggregate)

        # Or create Result directly
        # RailsSimpleEventSourcing::Result.new(success?: true, data: event.aggregate)
      end
    end
  end
end
```

**Example - Handler with Error Handling:**

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

        success_result(data: event.aggregate)
      rescue ActiveRecord::RecordNotUnique
        failure_result(errors: ["Email has already been taken"])
      rescue StandardError => e
        failure_result(errors: ["An error occurred: #{e.message}"])
      end
    end
  end
end
```

### Events

Events represent **facts** - things that have already happened in your system. They:
- Store immutable data about state changes
- Use past tense naming (e.g., `CustomerCreated`, not `CreateCustomer`)
- Define which aggregate (model) they apply to
- Are stored permanently in the event log

**Key Concepts:**
- `aggregate_class` - The model this event applies to (optional - some events may not modify models)
- `event_attributes` - Fields stored in the event payload
- `apply(aggregate)` - **Optional** method that applies the event to an aggregate instance
- `aggregate_id` - Links the event to a specific aggregate instance

**Example - Basic Event (Automatic Application):**

```ruby
class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :first_name, :last_name, :email, :created_at, :updated_at
    end
  end
end
```

**Automatic Attribute Application:**

By default, all attributes declared in `event_attributes` will be **automatically applied** to the aggregate. You don't need to implement the `apply` method unless you have custom logic requirements.

The default implementation sets each event attribute on the aggregate:
```ruby
# This happens automatically
aggregate.first_name = first_name
aggregate.last_name = last_name
aggregate.email = email
# ... and so on for all event_attributes
```

**Example - Custom Apply Method (When Needed):**

You may still need to implement a custom `apply` method in certain cases:
- Setting computed or derived values
- Complex business logic during application
- Handling nested objects or special data transformations
- Setting the aggregate ID explicitly (though this is usually handled automatically)

```ruby
class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :first_name, :last_name, :email, :created_at, :updated_at

      def apply(aggregate)
        # Custom logic example
        aggregate.id = aggregate_id
        aggregate.full_name = "#{first_name} #{last_name}"  # Computed value
        aggregate.email_normalized = email.downcase.strip   # Transformation

        # You can still call super to apply remaining attributes automatically
        super
      end
    end
  end
end
```

**Understanding the Event Structure:**
- `aggregate_class Customer` - Specifies which model this event modifies
- `event_attributes` - Defines what data gets stored in the event's JSON payload and what will be automatically applied
- `apply(aggregate)` - Optional method; only implement if you need custom logic beyond automatic attribute assignment
- `aggregate_id` - Auto-generated for creates, must be provided for updates/deletes

**Note on aggregate_class:**
- Optional - you can have events without an aggregate (e.g., `UserLoginFailed` for logging only)
- The corresponding model should include `RailsSimpleEventSourcing::Events` for read-only protection

### Registering Command Handlers

The recommended approach is to register command handlers explicitly using the registry. This makes the command-to-handler mapping explicit and avoids relying on naming conventions.

```ruby
# config/initializers/rails_simple_event_sourcing.rb

RailsSimpleEventSourcing.configure do |config|
  config.use_naming_convention_fallback = false
end

Rails.application.config.after_initialize do
  # Register all command handlers
  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Create,
    Customer::CommandHandlers::Create
  )

  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Update,
    Customer::CommandHandlers::Update
  )

  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Delete,
    Customer::CommandHandlers::Delete
  )
end
```

If you prefer the convention-based approach, you don't need to take any action, as the use_naming_convention_fallback is set to true by default.

### Controller Integration

Here's how to wire everything together in a controller:

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

### Update and Delete Operations

**Update Example:**

```ruby
class CustomersController < ApplicationController
  def update
    cmd = Customer::Commands::Update.new(
      aggregate_id: params[:id],
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

**Delete Example:**

```ruby
class CustomersController < ApplicationController
  def destroy
    cmd = Customer::Commands::Delete.new(aggregate_id: params[:id])
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      head :no_content
    else
      render json: { errors: handler.errors }, status: :unprocessable_entity
    end
  end
end
```

**Important:** For update and delete operations, you must pass `aggregate_id` to identify which record to modify. See the full examples in `test/dummy/app/domain/customer/`.

### Testing the API

Create a customer using curl:

```sh
curl -X POST http://localhost:3000/customers \
  -H 'Content-Type: application/json' \
  -d '{ "first_name": "John", "last_name": "Doe", "email": "john@example.com" }' | jq
```

Response:

```json
{
  "id": 1,
  "first_name": "John",
  "last_name": "Doe",
  "created_at": "2024-08-03T16:52:30.829Z",
  "updated_at": "2024-08-03T16:52:30.848Z"
}
```

### Event Querying

Open the Rails console (`rails c`) to explore the event log:

```ruby
# Get the customer
customer = Customer.last
# => #<Customer id: 1, first_name: "John", last_name: "Doe", ...>

# Access all events for this customer
customer.events
# => [#<Customer::Events::CustomerCreated...>]

# Get specific event details
event = customer.events.first
event.payload
# => {"first_name"=>"John", "last_name"=>"Doe", "email"=>"john@example.com", ...}

event.metadata
# => {"request_id"=>"2a40d4f9-509b-4b49-a39f-d978679fa5ef",
#     "request_ip"=>"::1",
#     "request_user_agent"=>"curl/8.6.0", ...}

# Query events by type
RailsSimpleEventSourcing::Event.where(event_type: "Customer::Events::CustomerCreated")

# Get events in a date range
customer.events.where(created_at: 1.week.ago..Time.now)

# Get all events for a specific aggregate
RailsSimpleEventSourcing::Event.where(eventable_type: "Customer", eventable_id: 1)
```

**Event Structure:**
- `payload` - Contains the event attributes you defined (as JSON)
- `metadata` - Contains request context (request ID, IP, user agent, params)
- `event_type` - The event class name
- `aggregate_id` - Links to the aggregate instance
- `eventable` - Polymorphic relation to the aggregate

### Metadata Tracking

To automatically capture request metadata (IP address, user agent, request ID, etc.), include the concern in your ApplicationController:

**Setup:**

```ruby
class ApplicationController < ActionController::Base
  include RailsSimpleEventSourcing::SetCurrentRequestDetails
end
```

**Default Metadata:**
By default, the following is captured:
- `request_id` - Unique request identifier
- `request_user_agent` - Client user agent
- `request_referer` - HTTP referer
- `request_ip` - Client IP address
- `request_params` - Request parameters (filtered using Rails parameter filter)

**Customizing Metadata:**
Override the `event_metadata` method in your controller:

```ruby
class ApplicationController < ActionController::Base
  include RailsSimpleEventSourcing::SetCurrentRequestDetails

  def event_metadata
    parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    {
      request_id: request.uuid,
      request_user_agent: request.user_agent,
      request_ip: request.ip,
      request_params: parameter_filter.filter(request.params),
      current_user_id: current_user&.id,  # Add custom fields
      tenant_id: current_tenant&.id
    }
  end
end
```

**Metadata Outside HTTP Requests:**
When events are created outside HTTP requests (background jobs, console, tests), metadata will be empty unless you manually set it using `CurrentRequest.metadata = {...}`.

### Events Viewer

The gem ships with a built-in web UI for browsing and inspecting your event log. It is mounted as a Rails engine.

**Setup:**

Mount the engine in your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RailsSimpleEventSourcing::Engine, at: "/event-store"
end
```

Then navigate to `/event-store` in your browser to access the viewer.

**Password Protection:**

In production you will likely want to restrict access to the events viewer.

*Using Rack::Auth::Basic middleware:*

```ruby
Rails.application.routes.draw do
  mount Rack::Auth::Basic.new(
    RailsSimpleEventSourcing::Engine,
    "Event Sourcing"
  ) { |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, "admin") &
    ActiveSupport::SecurityUtils.secure_compare(password, Rails.application.credentials.event_sourcing_password || "secret")
  }, at: "/event-sourcing"
end
```

*Using Devise authentication:*

```ruby
Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount RailsSimpleEventSourcing::Engine, at: "/event-store"
  end
end
```

**Features:**

- **Event list** - Paginated table of all events sorted by newest first, showing event type, aggregate, aggregate ID, version, and timestamp
- **Event detail** - Click any event to view its full payload, metadata, and the reconstructed aggregate state at that version
- **Version navigation** - Navigate between previous/next versions of the same aggregate from the detail page
- **Filtering** - Filter events by event type or aggregate type using dropdown selectors
- **Search** - Search by aggregate ID, or use `key:value` syntax to search within payload and metadata (e.g., `email:john@example.com`)

**Configuration:**

You can configure the number of events displayed per page (defaults to 25):

```ruby
RailsSimpleEventSourcing.configure do |config|
  config.events_per_page = 50
end
```

### Model Configuration

Models that use event sourcing should include the `RailsSimpleEventSourcing::Events` module:

```ruby
class Customer < ApplicationRecord
  include RailsSimpleEventSourcing::Events
end
```

**This provides:**
- `.events` association - Access all events for this aggregate
- Read-only protection - Prevents accidental direct modifications
- Event replay capability - Reconstruct state from events

### Immutability and Read-Only Protection

**Important Principles:**
- **Events are immutable** - Once created, events should never be modified
- **Models are read-only** - Aggregates should only be modified through events
- Both have built-in protection against accidental changes

### Soft Deletes

**Recommendation:** Use soft deletes instead of hard deletes to preserve event history.

**Why?**
- Events are linked to aggregates via foreign keys
- Hard deleting a record can orphan its events
- Event log becomes incomplete
- Cannot reconstruct historical state

**How to implement:**

```ruby
# Migration
class AddDeletedAtToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :deleted_at, :datetime
    add_index :customers, :deleted_at
  end
end

# Model
class Customer < ApplicationRecord
  include RailsSimpleEventSourcing::Events

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end
end

# Event
class Customer::Events::CustomerDeleted < RailsSimpleEventSourcing::Event
  aggregate_class Customer
  event_attributes :deleted_at

  # No need to implement apply - deleted_at will be automatically set on the aggregate
end
```

## Testing

### Setting Up Tests with Command Handler Registry

If you're using the command handler registry with `use_naming_convention_fallback = false`, you'll need to register your command handlers in your tests. There are a few approaches to handling this:

1. **Create an initializer in the test app:**

```ruby
# test/dummy/config/initializers/rails_simple_event_sourcing.rb
Rails.application.config.after_initialize do
  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Create,
    Customer::CommandHandlers::Create
  )
  # Register other handlers...
end
```

2. **Register in test_helper.rb:**

```ruby
# test/test_helper.rb
# After requiring the environment
RailsSimpleEventSourcing::CommandHandlerRegistry.register(
  Customer::Commands::Create,
  Customer::CommandHandlers::Create
)
# Register other handlers...
```

### Testing Commands

```ruby
require "test_helper"

class Customer::Commands::CreateTest < ActiveSupport::TestCase
  test "valid command" do
    cmd = Customer::Commands::Create.new(
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    )

    assert cmd.valid?
  end

  test "invalid without email" do
    cmd = Customer::Commands::Create.new(
      first_name: "John",
      last_name: "Doe"
    )

    assert_not cmd.valid?
    assert_includes cmd.errors[:email], "can't be blank"
  end
end
```

### Testing Command Handlers

```ruby
require "test_helper"

class Customer::CommandHandlers::CreateTest < ActiveSupport::TestCase
  test "creates customer and event" do
    cmd = Customer::Commands::Create.new(
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    )

    result = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    assert result.success?
    assert_instance_of Customer, result.data
    assert_equal "John", result.data.first_name
    assert_equal 1, result.data.events.count
  end

  test "handles duplicate email" do
    # Create first customer
    Customer::Events::CustomerCreated.create(
      first_name: "Jane",
      last_name: "Doe",
      email: "john@example.com"
    )

    # Try to create duplicate
    cmd = Customer::Commands::Create.new(
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    )

    result = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    assert_not result.success?
    assert_includes result.errors, "Email has already been taken"
  end
end
```

### Testing in Controllers

```ruby
require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  test "creates customer" do
    post customers_url, params: {
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    }, as: :json

    assert_response :success
    assert_equal "John", JSON.parse(response.body)["first_name"]
  end
end
```

## Limitations

Be aware of these limitations when using this gem:

- **PostgreSQL Only** - Requires PostgreSQL 9.4+ for JSONB support
- **No Event Versioning** - No built-in support for evolving event schemas over time
- **No Snapshots** - All aggregate reconstruction done by replaying all events (can be slow for aggregates with many events)
- **No Projections** - No built-in read model or projection support
- **Manual aggregate_id** - Must manually track and pass `aggregate_id` for updates/deletes
- **No Saga Support** - No built-in support for long-running processes or sagas
- **Single Database** - Events and aggregates must be in the same database

## Troubleshooting

### Command Handler Registry

The gem provides a registry pattern for explicitly mapping commands to their handlers. This is a more robust alternative to the convention-based mapping.

**Configuration:**

```ruby
# config/initializers/rails_simple_event_sourcing.rb
RailsSimpleEventSourcing.configure do |config|
  # Set to false to disable convention-based mapping
  config.use_naming_convention_fallback = false
end

# Register command handlers
Rails.application.config.after_initialize do
  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Create,
    Customer::CommandHandlers::Create
  )

  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Update,
    Customer::CommandHandlers::Update
  )

  RailsSimpleEventSourcing::CommandHandlerRegistry.register(
    Customer::Commands::Delete,
    Customer::CommandHandlers::Delete
  )
end
```

### CommandHandlerNotFoundError

**Error:** `RailsSimpleEventSourcing::CommandHandler::CommandHandlerNotFoundError: Handler Customer::CommandHandlers::Create not found` or `No handler registered for Customer::Commands::Create`

**Causes:**
1. The command handler class doesn't follow the naming convention (when using convention-based mapping)
2. The command handler hasn't been registered with the registry (when using explicit registration)

**Solutions:**
1. Ensure your handler namespace matches your command namespace:
   - Command: `Customer::Commands::Create`
   - Handler: `Customer::CommandHandlers::Create` (not `CustomerCommandHandlers::Create`)
2. Register your command handlers using the registry pattern shown above

### undefined method 'events' for Customer

**Error:** `undefined method 'events' for #<Customer>`

**Cause:** The model doesn't include the `RailsSimpleEventSourcing::Events` module.

**Solution:**
```ruby
class Customer < ApplicationRecord
  include RailsSimpleEventSourcing::Events
end
```

### ActiveRecord::ReadOnlyRecord when updating model

**Error:** `ActiveRecord::ReadOnlyRecord: Customer is marked as readonly`

**Cause:** Trying to directly modify a model that uses event sourcing.

**Solution:** Create an event instead:
```ruby
# Don't do this:
customer.update(first_name: "Jane")

# Do this:
cmd = Customer::Commands::Update.new(aggregate_id: customer.id, first_name: "Jane", ...)
RailsSimpleEventSourcing::CommandHandler.new(cmd).call
```

### Missing aggregate_id for updates

**Error:** `undefined method 'id' for nil:NilClass`

**Cause:** Forgot to pass `aggregate_id` to update/delete commands.

**Solution:**
```ruby
# Include aggregate_id in the command
cmd = Customer::Commands::Update.new(
  aggregate_id: params[:id],  # This is required
  first_name: params[:first_name],
  # ...
)
```

### Metadata is empty in tests

**Issue:** Event metadata is empty when creating events in tests.

**Cause:** Events created outside HTTP requests don't have automatic metadata.

**Solution:**
```ruby
# Manually set metadata in tests
RailsSimpleEventSourcing::CurrentRequest.metadata = {
  request_id: "test-123",
  test_mode: true
}
```

## Contributing

Contributions are welcome! Here's how you can help:

1. **Report Bugs**: Open an issue on GitHub with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Ruby/Rails/PostgreSQL versions

2. **Submit Pull Requests**:
   - Fork the repository
   - Create a feature branch (`git checkout -b feature/my-feature`)
   - Write tests for your changes
   - Ensure all tests pass (`rake test`)
   - Follow existing code style
   - Commit with clear messages
   - Push and open a PR

3. **Running Tests**:
   ```bash
   bundle install
   cd test/dummy
   rails db:create db:migrate RAILS_ENV=test
   cd ../..
   rake test
   ```

4. **Code Style**:
   - Follow Ruby style guide
   - Use RuboCop for linting
   - Write clear, descriptive variable/method names
   - Add comments for complex logic

### More Examples

See the `test/dummy/app/domain/customer/` directory for complete examples of:
- Commands (create, update, delete)
- Command handlers with error handling
- Events (created, updated, deleted)
- Controller integration

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
