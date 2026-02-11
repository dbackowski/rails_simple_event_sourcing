# frozen_string_literal: true

require 'test_helper'

module RailsSimpleEventSourcing
  class EventSearchTest < ActiveSupport::TestCase
    setup do
      @event = Customer::Events::CustomerCreated.create!(
        first_name: 'John',
        last_name: 'Doe',
        email: 'jdoe@example.com',
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )
    end

    test 'no filters returns all events' do
      results = EventSearch.new(scope: Event.all).call
      assert_includes results, @event
    end

    test 'filters by event_type' do
      results = EventSearch.new(scope: Event.all, event_type: 'Customer::Events::CustomerCreated').call
      assert_includes results, @event

      results = EventSearch.new(scope: Event.all, event_type: 'Customer::Events::CustomerUpdated').call
      assert_not_includes results, @event
    end

    test 'filters by aggregate' do
      results = EventSearch.new(scope: Event.all, aggregate: 'Customer').call
      assert_includes results, @event

      results = EventSearch.new(scope: Event.all, aggregate: 'NonExistent').call
      assert_empty results
    end

    test 'plain value matches aggregate_id exactly' do
      results = EventSearch.new(scope: Event.all, query: @event.aggregate_id).call
      assert_includes results, @event

      # partial aggregate_id should NOT match
      results = EventSearch.new(scope: Event.all, query: "#{@event.aggregate_id}99").call
      assert_not_includes results, @event
    end

    test 'key:value matches payload field using containment' do
      results = EventSearch.new(scope: Event.all, query: 'email:jdoe@example.com').call
      assert_includes results, @event
    end

    test 'key:value does not match wrong key' do
      results = EventSearch.new(scope: Event.all, query: 'first_name:jdoe@example.com').call
      assert_not_includes results, @event
    end

    test 'key:value does not match wrong value' do
      results = EventSearch.new(scope: Event.all, query: 'email:other@example.com').call
      assert_not_includes results, @event
    end

    test 'combines event_type and query filters' do
      results = EventSearch.new(
        scope: Event.all,
        event_type: 'Customer::Events::CustomerCreated',
        query: 'email:jdoe@example.com'
      ).call
      assert_includes results, @event

      results = EventSearch.new(
        scope: Event.all,
        event_type: 'Customer::Events::CustomerUpdated',
        query: 'email:jdoe@example.com'
      ).call
      assert_empty results
    end
  end
end
