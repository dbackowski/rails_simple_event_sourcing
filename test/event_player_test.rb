# frozen_string_literal: true

require 'test_helper'

class EventPlayerTest < ActiveSupport::TestCase
  test 'replays single event to aggregate' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: 'john@example.com')

    fresh_customer = Customer.find(customer.id)
    fresh_customer.first_name = nil
    fresh_customer.last_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh_customer).replay_stream

    assert_equal 'John', fresh_customer.first_name
    assert_equal 'Doe', fresh_customer.last_name
  end

  test 'replays multiple events in version order' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: 'john@example.com')

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: 'jane@example.com',
      updated_at: Time.zone.now
    )

    fresh_customer = Customer.find(customer.id)
    fresh_customer.first_name = nil
    fresh_customer.last_name = nil
    fresh_customer.email = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh_customer).replay_stream

    assert_equal 'Jane', fresh_customer.first_name
    assert_equal 'Smith', fresh_customer.last_name
    assert_equal 'jane@example.com', fresh_customer.email
  end

  test 'handles aggregate with no events' do
    customer = Customer.new
    customer.first_name = 'Test'

    RailsSimpleEventSourcing::EventPlayer.new(customer).replay_stream

    assert_equal 'Test', customer.first_name
  end

  test 'applies events in ascending version order' do
    customer = create_customer(first_name: 'V1', last_name: 'User', email: 'v1@example.com')

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'V2',
      last_name: 'User',
      email: 'v2@example.com',
      updated_at: Time.zone.now
    )

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'V3',
      last_name: 'Final',
      email: 'v3@example.com',
      updated_at: Time.zone.now
    )

    fresh_customer = Customer.find(customer.id)
    fresh_customer.first_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh_customer).replay_stream

    assert_equal 'V3', fresh_customer.first_name
    assert_equal 'Final', fresh_customer.last_name
  end

  test 'replay_and_apply applies event to new aggregate without replay' do
    aggregate = Customer.new
    event = build_create_event(first_name: 'John', last_name: 'Doe')

    RailsSimpleEventSourcing::EventPlayer.new(aggregate).replay_and_apply(event)

    assert_equal 'John', aggregate.first_name
    assert_equal 'Doe', aggregate.last_name
  end

  test 'replay_and_apply replays history then applies new event' do
    customer = create_customer(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com')
    update_event = build_update_event(aggregate_id: customer.id, first_name: 'Janet', last_name: 'Smith')

    fresh_aggregate = Customer.find(customer.id)
    fresh_aggregate.first_name = nil
    fresh_aggregate.last_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh_aggregate).replay_and_apply(update_event)

    assert_equal 'Janet', fresh_aggregate.first_name
    assert_equal 'Smith', fresh_aggregate.last_name
  end

  private

  def build_create_event(attrs = {})
    Customer::Events::CustomerCreated.new(
      {
        first_name: 'Test',
        last_name: 'User',
        email: "test_#{SecureRandom.hex(4)}@example.com",
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      }.merge(attrs)
    )
  end

  def build_update_event(attrs = {})
    Customer::Events::CustomerUpdated.new(
      {
        first_name: 'Updated',
        last_name: 'User',
        email: "updated_#{SecureRandom.hex(4)}@example.com",
        updated_at: Time.zone.now
      }.merge(attrs)
    )
  end

  def create_customer(attrs = {})
    event = Customer::Events::CustomerCreated.create!(
      {
        first_name: 'Jane',
        last_name: 'Doe',
        email: "jane_#{SecureRandom.hex(4)}@example.com",
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      }.merge(attrs)
    )
    Customer.find(event.aggregate_id)
  end
end
