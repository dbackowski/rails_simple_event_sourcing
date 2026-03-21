# frozen_string_literal: true

require 'test_helper'

class EventBusTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    RailsSimpleEventSourcing::EventBus.reset!
    Customer::Subscribers::Logger.reset!
    Customer::Subscribers::Notifier.reset!
  end

  test 'dispatches event to a registered subscriber via job' do
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, Customer::Subscribers::Logger)

    event = create_customer_created_event

    assert_enqueued_jobs 1
    perform_enqueued_jobs

    assert_equal [event.id], Customer::Subscribers::Logger.received_event_ids
  end

  test 'enqueues a job per subscriber for the same event class' do
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, Customer::Subscribers::Logger)
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, Customer::Subscribers::Notifier)

    create_customer_created_event

    assert_enqueued_jobs 2
  end

  test 'does not enqueue jobs for subscribers of a different event class' do
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerUpdated, Customer::Subscribers::Logger)

    create_customer_created_event

    assert_enqueued_jobs 0
  end

  test 'dispatches to ancestor class subscribers' do
    RailsSimpleEventSourcing::EventBus.subscribe(RailsSimpleEventSourcing::Event, Customer::Subscribers::Logger)

    event = create_customer_created_event

    assert_enqueued_jobs 1
    perform_enqueued_jobs

    assert_equal [event.id], Customer::Subscribers::Logger.received_event_ids
  end

  test 'enqueues jobs for both specific and ancestor class subscribers' do
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, Customer::Subscribers::Logger)
    RailsSimpleEventSourcing::EventBus.subscribe(RailsSimpleEventSourcing::Event, Customer::Subscribers::Notifier)

    create_customer_created_event

    assert_enqueued_jobs 2
  end

  test 'enqueues two jobs when same subscriber registered for both specific and ancestor class' do
    RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, Customer::Subscribers::Logger)
    RailsSimpleEventSourcing::EventBus.subscribe(RailsSimpleEventSourcing::Event, Customer::Subscribers::Logger)

    create_customer_created_event

    assert_enqueued_jobs 2
  end

  test 'does not enqueue when no subscribers are registered' do
    create_customer_created_event

    assert_enqueued_jobs 0
  end

  test 'raises ArgumentError when subscribing with a lambda' do
    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, ->(e) { e })
    end
  end

  test 'raises ArgumentError when subscribing with a proc' do
    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, proc { |e| e })
    end
  end

  test 'raises ArgumentError when subscribing with a plain class' do
    plain_class = Class.new { def self.call(event); end }
    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing::EventBus.subscribe(Customer::Events::CustomerCreated, plain_class)
    end
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
