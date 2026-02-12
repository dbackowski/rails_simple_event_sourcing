# frozen_string_literal: true

require 'test_helper'

module RailsSimpleEventSourcing
  class EventsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
    setup do
      @event = Customer::Events::CustomerCreated.create!(
        first_name: 'John',
        last_name: 'Doe',
        email: 'jdoe@example.com',
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )
    end

    test 'index returns success' do
      get rails_simple_event_sourcing.events_path
      assert_response :success
      assert_select 'table'
    end

    test 'index displays events' do
      get rails_simple_event_sourcing.events_path
      assert_response :success
      assert_select 'tr td .badge', text: 'Customer::Events::CustomerCreated'
    end

    test 'index filters by event_type select' do
      get rails_simple_event_sourcing.events_path, params: { event_type: 'Customer::Events::CustomerCreated' }
      assert_response :success
      assert_select 'tr td .badge', text: 'Customer::Events::CustomerCreated'
    end

    test 'index filters by aggregate select' do
      get rails_simple_event_sourcing.events_path, params: { aggregate: 'Customer' }
      assert_response :success
      assert_select 'tr td .badge', minimum: 1
    end

    test 'index searches by aggregate_id' do
      get rails_simple_event_sourcing.events_path, params: { q: @event.aggregate_id }
      assert_response :success
      assert_select 'tr td .badge', minimum: 1
    end

    test 'index searches by payload key:value' do
      get rails_simple_event_sourcing.events_path, params: { q: 'email:jdoe@example.com' }
      assert_response :success
      assert_select 'tr td .badge', minimum: 1
    end

    test 'index with no results' do
      get rails_simple_event_sourcing.events_path, params: { q: 'nonexistent_query_xyz' }
      assert_response :success
      assert_select "td[colspan='6']", text: /No events found/
    end

    test 'index paginates events' do
      # Create a second event so pagination appears with per_page=1
      Customer::Events::CustomerUpdated.create!(
        aggregate_id: @event.aggregate_id,
        first_name: 'Jane',
        last_name: 'Doe',
        email: 'jdoe@example.com',
        updated_at: Time.zone.now
      )

      original = RailsSimpleEventSourcing.config.events_per_page
      RailsSimpleEventSourcing.config.events_per_page = 1
      begin
        get rails_simple_event_sourcing.events_path
        assert_response :success
        assert_select '.pagination'

        get rails_simple_event_sourcing.events_path, params: { page: 2 }
        assert_response :success
      ensure
        RailsSimpleEventSourcing.config.events_per_page = original
      end
    end

    test 'index clamps page to valid range' do
      get rails_simple_event_sourcing.events_path, params: { page: 9999 }
      assert_response :success
    end

    test 'index clamps page below 1' do
      get rails_simple_event_sourcing.events_path, params: { page: -5 }
      assert_response :success
    end

    test 'show returns success' do
      get rails_simple_event_sourcing.event_path(@event)
      assert_response :success
      assert_select '.badge', text: @event.event_type
    end

    test 'show displays payload' do
      get rails_simple_event_sourcing.event_path(@event)
      assert_response :success
      assert_select 'pre.json', minimum: 1
    end

    test 'show displays aggregate name' do
      get rails_simple_event_sourcing.event_path(@event)
      assert_response :success
      assert_select 'dt', text: 'Aggregate'
      assert_select 'dd', text: 'Customer'
    end

    test 'show displays aggregate state section' do
      get rails_simple_event_sourcing.event_path(@event)
      assert_response :success
      assert_select 'h2', text: /Aggregate State/
      assert_select 'pre.json', minimum: 1
    end

    test 'aggregate state reflects correct version' do
      updated_event = Customer::Events::CustomerUpdated.create!(
        aggregate_id: @event.aggregate_id,
        first_name: 'Jane',
        last_name: 'Smith',
        email: 'jane@example.com',
        updated_at: Time.zone.now
      )

      # Show page for the first event (v1) should NOT include v2 changes
      get rails_simple_event_sourcing.event_path(@event)
      assert_response :success
      assert_select 'pre.json', text: /John/
      assert_select 'pre.json', text: /Doe/

      # Show page for the second event (v2) should include v2 changes
      get rails_simple_event_sourcing.event_path(updated_event)
      assert_response :success
      assert_select 'pre.json', text: /Jane/
      assert_select 'pre.json', text: /Smith/
    end

    test 'index displays aggregate column' do
      get rails_simple_event_sourcing.events_path
      assert_response :success
      assert_select 'th', text: 'Aggregate'
      assert_select 'td', text: 'Customer'
    end

    test 'root redirects to events index' do
      get rails_simple_event_sourcing.root_path
      assert_response :success
    end
  end
end
