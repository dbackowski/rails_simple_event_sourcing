# frozen_string_literal: true

require 'test_helper'

class CommandHandlerRegistryTest < ActiveSupport::TestCase
  test 'registers a handler for a command class' do
    dummy_command = Class.new
    dummy_handler = Class.new

    RailsSimpleEventSourcing::CommandHandlerRegistry.register(dummy_command, dummy_handler)

    assert_equal dummy_handler, RailsSimpleEventSourcing::CommandHandlerRegistry.handler_for(dummy_command)
  end

  test 'raises CommandAlreadyRegisteredError when registering a command class twice' do
    dummy_command = Class.new
    dummy_handler = Class.new
    another_handler = Class.new

    RailsSimpleEventSourcing::CommandHandlerRegistry.register(dummy_command, dummy_handler)

    error = assert_raises(RailsSimpleEventSourcing::CommandHandlerRegistry::CommandAlreadyRegisteredError) do
      RailsSimpleEventSourcing::CommandHandlerRegistry.register(dummy_command, another_handler)
    end

    assert_match(/Command handler already registered for/, error.message)
  end

  test 'returns nil for an unregistered command class' do
    unregistered_command = Class.new

    assert_nil RailsSimpleEventSourcing::CommandHandlerRegistry.handler_for(unregistered_command)
  end

  test 'registers multiple different command classes independently' do
    command_a = Class.new
    command_b = Class.new
    handler_a = Class.new
    handler_b = Class.new

    RailsSimpleEventSourcing::CommandHandlerRegistry.register(command_a, handler_a)
    RailsSimpleEventSourcing::CommandHandlerRegistry.register(command_b, handler_b)

    assert_equal handler_a, RailsSimpleEventSourcing::CommandHandlerRegistry.handler_for(command_a)
    assert_equal handler_b, RailsSimpleEventSourcing::CommandHandlerRegistry.handler_for(command_b)
  end
end
