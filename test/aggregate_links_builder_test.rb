# frozen_string_literal: true

require 'test_helper'

class AggregateLinksBuilderTest < ActiveSupport::TestCase
  test 'returns empty hash when data is nil' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(nil).call

    assert_equal({}, result)
  end

  test 'returns empty hash when data is empty' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new({}).call

    assert_equal({}, result)
  end

  test 'ignores keys that do not end with _id' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(first_name: 'John', email: 'john@example.com').call

    assert_equal({}, result)
  end

  test 'ignores _id keys with blank values' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(customer_id: nil).call

    assert_equal({}, result)
  end

  test 'ignores _id keys with empty string values' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(customer_id: '').call

    assert_equal({}, result)
  end

  test 'ignores _id keys that do not resolve to an event-sourced class' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(nonexistent_model_id: '123').call

    assert_equal({}, result)
  end

  test 'returns link for a key matching an event-sourced aggregate with events' do
    customer = create_customer

    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(customer_id: customer.id).call

    assert_includes result, 'customer_id'
    link = result['customer_id']
    assert_equal 'Customer', link[:aggregate_type]
    assert_equal customer.id, link[:aggregate_id]
    assert link[:event_id].present?
  end

  test 'returns the latest event id for the aggregate' do
    customer = create_customer

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Updated',
      last_name: 'Name',
      email: 'updated@example.com',
      updated_at: Time.zone.now
    )

    latest_event = RailsSimpleEventSourcing::Event
                   .where(eventable_type: 'Customer', aggregate_id: customer.id.to_s)
                   .order(version: :desc).first

    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(customer_id: customer.id).call

    assert_equal latest_event.id, result['customer_id'][:event_id]
  end

  test 'ignores _id key when no events exist for the aggregate' do
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(customer_id: 999_999).call

    assert_equal({}, result)
  end

  test 'handles string keys' do
    customer = create_customer

    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new('customer_id' => customer.id).call

    assert_includes result, 'customer_id'
  end

  test 'builds links for multiple aggregates' do
    customer1 = create_customer
    create_customer

    data = { customer_id: customer1.id }
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(data).call

    assert_equal 1, result.size
    assert_equal customer1.id, result['customer_id'][:aggregate_id]
  end

  test 'filters out non-id keys while keeping valid id keys' do
    customer = create_customer

    data = { customer_id: customer.id, first_name: 'John', email: 'test@example.com' }
    result = RailsSimpleEventSourcing::AggregateLinksBuilder.new(data).call

    assert_equal 1, result.size
    assert_includes result, 'customer_id'
  end

  private

  def create_customer
    event = Customer::Events::CustomerCreated.create!(
      first_name: 'Jane',
      last_name: 'Doe',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )
    Customer.find(event.aggregate_id)
  end
end
