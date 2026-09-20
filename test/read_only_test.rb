# frozen_string_literal: true

require 'test_helper'

class ReadOnlyTest < ActiveSupport::TestCase
  setup do
    @event = Customer::Events::CustomerCreated.create!(
      first_name: 'John',
      last_name: 'Doe',
      email: "john_#{SecureRandom.hex(4)}@example.com",
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )
  end

  test 'a persisted event is read-only' do
    assert_predicate @event, :readonly?
    assert_raises(ActiveRecord::ReadOnlyRecord) { @event.save! }
  end

  test 'an event loaded from the database is read-only' do
    reloaded = RailsSimpleEventSourcing::Event.find(@event.id)

    assert_predicate reloaded, :readonly?
  end

  test 'write access cannot be lifted on an event from outside' do
    assert_not_respond_to @event, :enable_write_access!
    assert_not_respond_to @event, :disable_write_access!

    assert_raises(NoMethodError) { @event.enable_write_access! }
  end

  test 'write access stays public on aggregates' do
    customer = Customer.find(@event.aggregate_id)

    assert_respond_to customer, :enable_write_access!
    assert_respond_to customer, :disable_write_access!

    customer.enable_write_access!

    assert_not_predicate customer, :readonly?
  end
end
