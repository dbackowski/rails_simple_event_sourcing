# frozen_string_literal: true

require 'test_helper'

class SnapshotTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  test 'create_snapshot! saves current aggregate state at latest version' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")
    customer.create_snapshot!

    snapshot = RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )

    assert_not_nil snapshot
    assert_equal 'John', snapshot.state['first_name']
    assert_equal 'Doe', snapshot.state['last_name']
    assert_equal 1, snapshot.version
  end

  test 'create_snapshot! does nothing when aggregate has no events' do
    customer = Customer.new(
      first_name: 'John',
      last_name: 'Doe',
      email: "john_#{SecureRandom.hex(4)}@example.com"
    )
    customer.enable_write_access!
    customer.save!

    customer.create_snapshot!

    assert_nil RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )
  end

  test 'create_snapshot! upserts when called multiple times' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")
    customer.create_snapshot!

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )

    customer.reload
    customer.create_snapshot!

    snapshots = RailsSimpleEventSourcing::Snapshot.where(aggregate_type: 'Customer', aggregate_id: customer.id.to_s)
    assert_equal 1, snapshots.count
    assert_equal 'Jane', snapshots.first.state['first_name']
    assert_equal 2, snapshots.first.version
  end

  test 'EventPlayer restores state from snapshot and skips replayed events' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )

    customer.reload
    customer.create_snapshot!

    # Delete events to prove replay comes from snapshot, not events table
    RailsSimpleEventSourcing::Event.where(aggregate_id: customer.id).delete_all

    fresh = Customer.find(customer.id)
    fresh.first_name = nil
    fresh.last_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh).replay_stream

    assert_equal 'Jane', fresh.first_name
    assert_equal 'Smith', fresh.last_name
  end

  test 'EventPlayer falls back to full replay when no snapshot exists' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    fresh = Customer.find(customer.id)
    fresh.first_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh).replay_stream

    assert_equal 'John', fresh.first_name
  end

  test 'EventPlayer replays only delta events after snapshot' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")
    customer.create_snapshot!  # snapshot at v1

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )

    fresh = Customer.find(customer.id)
    fresh.first_name = nil
    fresh.last_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh).replay_stream

    assert_equal 'Jane', fresh.first_name
    assert_equal 'Smith', fresh.last_name
  end

  test 'aggregate_state ignores snapshot newer than requested version' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )

    customer.reload
    customer.create_snapshot!  # snapshot at v2

    # Ask for historical state at v1 — snapshot at v2 must be ignored
    event = RailsSimpleEventSourcing::Event.find_by(aggregate_id: customer.id, version: 1)
    state = event.aggregate_state

    assert_equal 'John', state['first_name']
    assert_equal 'Doe', state['last_name']
  end

  test 'auto-snapshot created when version is multiple of snapshot_interval' do
    RailsSimpleEventSourcing.config.snapshot_interval = 2

    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    assert_nil RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )

    snapshot = RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )

    assert_not_nil snapshot
    assert_equal 2, snapshot.version
    assert_equal 'Jane', snapshot.state['first_name']
  ensure
    RailsSimpleEventSourcing.config.snapshot_interval = 1
  end

  test 'auto-snapshot not created when version is not a multiple of snapshot_interval' do
    RailsSimpleEventSourcing.config.snapshot_interval = 5

    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    assert_nil RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )
  ensure
    RailsSimpleEventSourcing.config.snapshot_interval = 1
  end

  test 'create_snapshot! stores schema fingerprint of aggregate class' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")
    customer.create_snapshot!

    snapshot = RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )

    assert_equal RailsSimpleEventSourcing::Snapshot.fingerprint_for(Customer), snapshot.schema_fingerprint
  end

  test 'EventPlayer ignores snapshot with mismatched schema fingerprint' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")
    customer.create_snapshot!

    # Simulate an aggregate schema change by corrupting the fingerprint
    snapshot = RailsSimpleEventSourcing::Snapshot.find_by!(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )
    snapshot.update!(
      schema_fingerprint: 'stale-fingerprint',
      state: { 'first_name' => 'STALE', 'last_name' => 'STALE' }
    )

    fresh = Customer.find(customer.id)
    fresh.first_name = nil
    fresh.last_name = nil

    RailsSimpleEventSourcing::EventPlayer.new(fresh).replay_stream

    # Should fall back to full replay from events, not the stale snapshot
    assert_equal 'John', fresh.first_name
    assert_equal 'Doe', fresh.last_name
  end

  test 'stale snapshot is overwritten with fresh fingerprint on next snapshot' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")
    customer.create_snapshot!

    snapshot = RailsSimpleEventSourcing::Snapshot.find_by!(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )
    snapshot.update!(schema_fingerprint: 'stale-fingerprint')

    customer.reload
    customer.create_snapshot!

    snapshots = RailsSimpleEventSourcing::Snapshot.where(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )

    assert_equal 1, snapshots.count
    assert_not_equal 'stale-fingerprint', snapshots.first.schema_fingerprint
    assert_equal RailsSimpleEventSourcing::Snapshot.fingerprint_for(Customer), snapshots.first.schema_fingerprint
  end

  test 'create_or_update! does not overwrite a newer snapshot with an older version' do
    customer = create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer.id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )

    customer.reload
    customer.create_snapshot! # snapshot at v2

    # Simulate a late after_commit callback from the v1 event
    RailsSimpleEventSourcing::Snapshot.create_or_update!(
      aggregate_type: 'Customer',
      aggregate_id: customer.id,
      state: { 'first_name' => 'John', 'last_name' => 'Doe' },
      version: 1,
      schema_fingerprint: RailsSimpleEventSourcing::Snapshot.fingerprint_for(Customer)
    )

    snapshot = RailsSimpleEventSourcing::Snapshot.find_by(
      aggregate_type: 'Customer',
      aggregate_id: customer.id.to_s
    )

    assert_equal 2, snapshot.version
    assert_equal 'Jane', snapshot.state['first_name']
    assert_equal 'Smith', snapshot.state['last_name']
  end

  test 'no auto-snapshot when snapshot_interval is nil' do
    RailsSimpleEventSourcing.config.snapshot_interval = nil

    assert_nil RailsSimpleEventSourcing.config.snapshot_interval

    create_customer(first_name: 'John', last_name: 'Doe', email: "john_#{SecureRandom.hex(4)}@example.com")

    assert_equal 0, RailsSimpleEventSourcing::Snapshot.count
  ensure
    RailsSimpleEventSourcing.config.snapshot_interval = 1
  end

  private

  def create_customer(attrs = {})
    event = Customer::Events::CustomerCreated.create!(
      {
        first_name: 'John',
        last_name: 'Doe',
        email: "customer_#{SecureRandom.hex(4)}@example.com",
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      }.merge(attrs)
    )
    Customer.find(event.aggregate_id)
  end
end
