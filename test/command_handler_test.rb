# frozen_string_literal: true

require 'test_helper'

class CommandHandlerTest < ActiveSupport::TestCase
  test 'returns failure result when command is invalid' do
    command = Customer::Commands::Create.new(first_name: '', last_name: '', email: '')

    result = RailsSimpleEventSourcing::CommandHandler.new(command).call

    assert_not result.success?
    assert_includes result.errors[:first_name], "can't be blank"
    assert_includes result.errors[:last_name], "can't be blank"
    assert_includes result.errors[:email], "can't be blank"
  end

  test 'delegates to the registered handler and returns success result' do
    command = Customer::Commands::Create.new(first_name: 'John', last_name: 'Doe', email: 'john@example.com')

    result = RailsSimpleEventSourcing::CommandHandler.new(command).call

    assert result.success?
    assert_instance_of Customer, result.data
    assert_equal 'John', result.data.first_name
  end

  test 'resolves handler via naming convention fallback' do
    assert RailsSimpleEventSourcing.config.use_naming_convention_fallback

    command = Customer::Commands::Create.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com')

    result = RailsSimpleEventSourcing::CommandHandler.new(command).call

    assert result.success?
  end

  test 'raises CommandHandlerNotFoundError when no handler is found' do
    unhandled_command_class = Class.new(RailsSimpleEventSourcing::Commands::Base)

    command = unhandled_command_class.new

    error = assert_raises(RailsSimpleEventSourcing::CommandHandler::CommandHandlerNotFoundError) do
      RailsSimpleEventSourcing::CommandHandler.new(command).call
    end

    assert_match(/No handler found for/, error.message)
    assert_match(/Register one with CommandHandlerRegistry.register/, error.message)
  end

  test 'raises CommandHandlerNotFoundError with convention lookup details when fallback is enabled' do
    stub_command_class = Class.new(RailsSimpleEventSourcing::Commands::Base) do
      def self.to_s
        'Fake::Commands::Missing'
      end
    end

    command = stub_command_class.new

    error = assert_raises(RailsSimpleEventSourcing::CommandHandler::CommandHandlerNotFoundError) do
      RailsSimpleEventSourcing::CommandHandler.new(command).call
    end

    assert_match(/Tried convention-based lookup: Fake::CommandHandlers::Missing/, error.message)
  end

  test 'raises CommandHandlerNotFoundError without convention details when fallback is disabled' do
    original_value = RailsSimpleEventSourcing.config.use_naming_convention_fallback
    RailsSimpleEventSourcing.config.use_naming_convention_fallback = false

    unhandled_command_class = Class.new(RailsSimpleEventSourcing::Commands::Base)
    command = unhandled_command_class.new

    error = assert_raises(RailsSimpleEventSourcing::CommandHandler::CommandHandlerNotFoundError) do
      RailsSimpleEventSourcing::CommandHandler.new(command).call
    end

    assert_match(/No handler found for/, error.message)
    assert_no_match(/Tried convention-based lookup/, error.message)
  ensure
    RailsSimpleEventSourcing.config.use_naming_convention_fallback = original_value
  end

  test 'resolves handler from registry before falling back to naming convention' do
    dummy_handler_class = Class.new(RailsSimpleEventSourcing::CommandHandlers::Base) do
      def call
        success_result(data: 'from_registry')
      end
    end

    command = Customer::Commands::Create.new(first_name: 'John', last_name: 'Doe', email: 'registry@example.com')
    RailsSimpleEventSourcing::CommandHandlerRegistry.register(Customer::Commands::Create, dummy_handler_class)

    result = RailsSimpleEventSourcing::CommandHandler.new(command).call

    assert result.success?
    assert_equal 'from_registry', result.data
  ensure
    RailsSimpleEventSourcing::CommandHandlerRegistry.deregister(Customer::Commands::Create)
  end

  test 'does not invoke handler when command validation fails' do
    command = Customer::Commands::Create.new(first_name: '', last_name: '', email: '')

    assert_no_changes -> { Customer.count } do
      assert_no_changes -> { RailsSimpleEventSourcing::Event.count } do
        RailsSimpleEventSourcing::CommandHandler.new(command).call
      end
    end
  end
end
