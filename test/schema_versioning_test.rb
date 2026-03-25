# frozen_string_literal: true

require 'test_helper'

class SchemaVersioningTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  setup do
    @original_version = Customer::Events::CustomerCreated.schema_version_number
    @original_upcasters = Customer::Events::CustomerCreated.upcasters.dup
  end

  teardown do
    Customer::Events::CustomerCreated.current_version(@original_version)
    Customer::Events::CustomerCreated.upcasters.clear
    Customer::Events::CustomerCreated.upcasters.merge!(@original_upcasters)
  end

  test 'defaults schema_version to 1 when current_version is not called' do
    event = Customer::Events::CustomerDeleted.create!(
      aggregate_id: create_event.aggregate_id,
      deleted_at: Time.zone.now
    )

    assert_equal 1, event.schema_version
  end

  test 'sets schema_version to the declared current_version' do
    event = create_event

    assert_equal 2, event.schema_version
  end

  test 'schema_version_number defaults to 1' do
    assert_equal 1, Customer::Events::CustomerDeleted.schema_version_number
  end

  test 'schema_version_number returns declared version' do
    assert_equal 2, Customer::Events::CustomerCreated.schema_version_number
  end

  test 'payload is returned unchanged when schema_version matches current_version' do
    event = create_event(first_name: 'John', last_name: 'Doe')

    reloaded = event.class.find(event.id)

    assert_equal 'John', reloaded.payload['first_name']
    assert_equal 'Doe', reloaded.payload['last_name']
  end

  test 'upcasts payload from older schema_version to current_version' do
    event = create_event(first_name: 'john', last_name: 'Doe')

    # Simulate an old v1 event with a "name" field instead of first_name/last_name
    simulate_old_event(
      event,
      schema_version: 1,
      payload: { 'name' => 'John Doe', 'email' => 'test@example.com' }
    )
    old_event = event.class.find(event.id)

    assert_equal 1, old_event.schema_version
    assert_equal 'John', old_event.payload['first_name']
    assert_equal 'Doe', old_event.payload['last_name']
  end

  test 'chains multiple upcasters sequentially' do
    Customer::Events::CustomerCreated.current_version 3
    Customer::Events::CustomerCreated.upcaster(2) do |data|
      data['last_name'] = data['last_name'].upcase if data['last_name']
      data
    end

    event = create_event(first_name: 'john', last_name: 'doe')

    # Simulate a v1 event — upcaster(1) from dummy + upcaster(2) from test should both run
    simulate_old_event(
      event,
      schema_version: 1,
      payload: { 'name' => 'john doe', 'email' => 'test@example.com' }
    )
    old_event = event.class.find(event.id)

    assert_equal 'john', old_event.payload['first_name']
    assert_equal 'DOE', old_event.payload['last_name']
  end

  test 'partial upcast runs only needed upcasters' do
    Customer::Events::CustomerCreated.current_version 3
    Customer::Events::CustomerCreated.upcaster(2) do |data|
      data['last_name'] = data['last_name'].upcase if data['last_name']
      data
    end

    event = create_event(first_name: 'john', last_name: 'doe')

    # Simulate a v2 event — only upcaster(2) should run
    simulate_old_event(event, schema_version: 2)
    old_event = event.class.find(event.id)

    assert_equal 'john', old_event.payload['first_name']
    assert_equal 'DOE', old_event.payload['last_name']
  end

  test 'raises error when upcaster is missing for a version' do
    Customer::Events::CustomerCreated.current_version 3
    # Intentionally skip upcaster(2)

    event = create_event

    simulate_old_event(event, schema_version: 2)
    old_event = event.class.find(event.id)

    error = assert_raises(RuntimeError) { old_event.payload }
    assert_match(/Missing upcaster from version 2 to 3/, error.message)
  end

  test 'does not upcast new records' do
    event = Customer::Events::CustomerCreated.new(
      first_name: 'John',
      last_name: 'Doe',
      email: "john_#{SecureRandom.hex(4)}@example.com",
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )

    assert_equal 'John', event.payload['first_name']
  end

  test 'payload returns nil when payload is nil' do
    event = Customer::Events::CustomerCreated.new
    assert_nil event.payload
  end

  test 'does not set schema_version for events without aggregate_class' do
    event = Customer::Events::CustomerEmailTaken.create!(
      first_name: 'John',
      last_name: 'Doe',
      email: "john_#{SecureRandom.hex(4)}@example.com"
    )

    assert_nil event.schema_version
  end

  test 'returns payload unchanged for events without aggregate_class' do
    event = Customer::Events::CustomerEmailTaken.create!(
      first_name: 'John',
      last_name: 'Doe',
      email: "john_#{SecureRandom.hex(4)}@example.com"
    )

    reloaded = event.class.find(event.id)

    assert_equal 'John', reloaded.payload['first_name']
  end

  test 'upcasted payload is used during aggregate replay' do
    event = create_event(first_name: 'john', last_name: 'Doe')

    # Simulate a v1 event with "name" field
    simulate_old_event(
      event,
      schema_version: 1,
      payload: {
        'name' => 'John Doe', 'email' => 'test@example.com',
        'created_at' => '2026-01-01', 'updated_at' => '2026-01-01'
      }
    )

    customer = Customer.find(event.aggregate_id)
    customer.first_name = nil
    customer.last_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(customer).replay_stream

    assert_equal 'John', customer.first_name
    assert_equal 'Doe', customer.last_name
  end

  private

  def simulate_old_event(event, schema_version:, payload: nil)
    attrs = { schema_version: schema_version }
    attrs[:payload] = payload if payload
    RailsSimpleEventSourcing::Event.where(id: event.id).update_all(attrs) # rubocop:disable Rails/SkipsModelValidations
  end

  def create_event(attrs = {})
    Customer::Events::CustomerCreated.create!(
      {
        first_name: 'Jane',
        last_name: 'Doe',
        email: "jane_#{SecureRandom.hex(4)}@example.com",
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      }.merge(attrs)
    )
  end
end
