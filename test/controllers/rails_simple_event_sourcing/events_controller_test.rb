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

    test 'index shows pagination when more events than per_page' do
      create_updates(2)

      with_per_page(1) do
        get rails_simple_event_sourcing.events_path
        assert_response :success
        assert_select '.pagination'
      end
    end

    test 'index hides pagination when all events fit on one page' do
      get rails_simple_event_sourcing.events_path
      assert_response :success
      assert_select '.pagination', count: 0
    end

    test 'index next cursor navigates to older events' do
      events = create_updates(2)
      newest = events.last

      with_per_page(1) do
        get rails_simple_event_sourcing.events_path, params: { after: newest.id }
        assert_response :success
        assert_select 'tr td .badge', count: 1
      end
    end

    test 'index prev cursor navigates to newer events' do
      create_updates(2)

      with_per_page(1) do
        get rails_simple_event_sourcing.events_path, params: { before: @event.id }
        assert_response :success
        assert_select 'tr td .badge', count: 1
      end
    end

    test 'index full forward-then-backward navigation visits all events in order' do # rubocop:disable Metrics/BlockLength
      events = [@event] + create_updates(4)
      expected_desc = events.map(&:id).reverse

      with_per_page(1) do
        forward_ids = []
        get rails_simple_event_sourcing.events_path
        forward_ids << extract_event_id
        expected_desc[1..].each_index do |_i|
          after_cursor = forward_ids.last
          get rails_simple_event_sourcing.events_path, params: { after: after_cursor }
          assert_response :success
          current_id = extract_event_id
          break if current_id.nil?

          forward_ids << current_id
        end

        assert_equal expected_desc, forward_ids, 'Forward navigation should visit events newest-to-oldest'

        backward_ids = [forward_ids.last]
        (events.size - 1).times do
          before_cursor = backward_ids.last
          get rails_simple_event_sourcing.events_path, params: { before: before_cursor }
          assert_response :success
          current_id = extract_event_id
          break if current_id.nil?

          backward_ids << current_id
        end

        assert_equal expected_desc.reverse, backward_ids, 'Backward navigation should visit events oldest-to-newest'
      end
    end

    test 'index pagination preserves search filters' do
      events = create_updates(2)

      with_per_page(1) do
        get rails_simple_event_sourcing.events_path, params: {
          after: events.last.id,
          event_type: 'Customer::Events::CustomerUpdated',
          aggregate: 'Customer',
          q: @event.aggregate_id
        }
        assert_response :success
      end
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

      get rails_simple_event_sourcing.event_path(@event)
      assert_response :success
      assert_select 'pre.json', text: /John/
      assert_select 'pre.json', text: /Doe/

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

    private

    def create_updates(count)
      count.times.map do
        Customer::Events::CustomerUpdated.create!(
          aggregate_id: @event.aggregate_id,
          first_name: 'Jane',
          last_name: 'Doe',
          email: 'jdoe@example.com',
          updated_at: Time.zone.now
        )
      end
    end

    def with_per_page(size)
      original = RailsSimpleEventSourcing.config.events_per_page
      RailsSimpleEventSourcing.config.events_per_page = size
      yield
    ensure
      RailsSimpleEventSourcing.config.events_per_page = original
    end

    def extract_event_id
      id_link = css_select('tbody tr td a').first
      return nil unless id_link

      id_link.text.strip.to_i
    end
  end
end
