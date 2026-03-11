# frozen_string_literal: true

require 'test_helper'

class EventBusTest < ActiveSupport::TestCase
  setup do
    RailsSimpleEventSourcing::EventBus.reset!
  end

  test 'dispatches event to a registered subscriber' do
    received = []
    subscriber = ->(event) { received << event }

    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, subscriber)
    event = create_customer_created_event

    assert_equal [event], received
  end

  test 'dispatches to multiple subscribers for the same event class' do
    calls = []

    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, ->(_e) { calls << :first })
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, ->(_e) { calls << :second })

    create_customer_created_event

    assert_equal %i[first second], calls
  end

  test 'does not dispatch to subscribers of a different event class' do
    received = []

    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerUpdated, ->(e) { received << e })

    create_customer_created_event

    assert_empty received
  end

  test 'dispatches to ancestor class subscribers' do
    received = []

    RailsSimpleEventSourcing::EventBus.subscribe(RailsSimpleEventSourcing::Event, ->(e) { received << e })

    event = create_customer_created_event

    assert_equal [event], received
  end

  test 'dispatches to both specific and ancestor class subscribers independently' do
    calls = []

    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, ->(_e) { calls << :specific })
    RailsSimpleEventSourcing::EventBus.subscribe(RailsSimpleEventSourcing::Event, ->(_e) { calls << :catch_all })

    create_customer_created_event

    assert_includes calls, :specific
    assert_includes calls, :catch_all
    assert_equal 2, calls.size
  end

  test 'calls the same subscriber twice if registered for both specific and ancestor class' do
    calls = []
    subscriber = ->(e) { calls << e }

    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, subscriber)
    RailsSimpleEventSourcing::EventBus.subscribe(RailsSimpleEventSourcing::Event, subscriber)

    create_customer_created_event

    assert_equal 2, calls.size
  end

  test 'does not dispatch when no subscribers are registered' do
    assert_nothing_raised { create_customer_created_event }
  end

  # Dispatch uses after_commit (not after_create), guaranteeing the event is
  # durable before subscribers run. This cannot be verified with transactional
  # tests because the test harness wraps everything in an outer transaction.

  private

  def create_customer_created_event
    Customer::Events::CustomerCreated.create!(
      first_name: 'Jane',
      last_name: 'Doe',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )
  end
end
