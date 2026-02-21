# frozen_string_literal: true

require 'test_helper'

module RailsSimpleEventSourcing
  class PaginatorTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
    setup do
      @events = 5.times.map do |i|
        Customer::Events::CustomerUpdated.create!(
          aggregate_id: i.zero? ? nil : Event.find_by(version: 1)&.aggregate_id,
          first_name: "User#{i}",
          last_name: 'Test',
          email: "user#{i}@example.com",
          updated_at: Time.zone.now
        )
      end
    end

    test 'first page returns records in descending id order' do
      paginator = Paginator.new(scope: Event.all, per_page: 2)

      assert_equal [@events[4].id, @events[3].id], paginator.records.map(&:id)
    end

    test 'first page has no prev' do
      paginator = Paginator.new(scope: Event.all, per_page: 2)

      assert_not paginator.prev?
    end

    test 'first page has next when more records exist' do
      paginator = Paginator.new(scope: Event.all, per_page: 2)

      assert paginator.next?
    end

    test 'first page has no next when all records fit' do
      paginator = Paginator.new(scope: Event.all, per_page: 10)

      assert_not paginator.next?
    end

    test 'first page cursors point to first and last record' do
      paginator = Paginator.new(scope: Event.all, per_page: 2)

      assert_equal @events[4].id, paginator.prev_cursor
      assert_equal @events[3].id, paginator.next_cursor
    end

    test 'next page returns records after cursor in descending order' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[3].id, direction: :next)

      assert_equal [@events[2].id, @events[1].id], paginator.records.map(&:id)
    end

    test 'next page always has prev' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[3].id, direction: :next)

      assert paginator.prev?
    end

    test 'next page has next when more records exist beyond page' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[3].id, direction: :next)

      assert paginator.next?
    end

    test 'next page has no next on last page' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[1].id, direction: :next)

      assert_not paginator.next?
    end

    test 'next page returns partial page at the end' do
      paginator = Paginator.new(scope: Event.all, per_page: 3, cursor: @events[2].id, direction: :next)

      assert_equal [@events[1].id, @events[0].id], paginator.records.map(&:id)
      assert_not paginator.next?
    end

    test 'prev page returns records before cursor in descending order' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[1].id, direction: :prev)

      assert_equal [@events[3].id, @events[2].id], paginator.records.map(&:id)
    end

    test 'prev page always has next' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[1].id, direction: :prev)

      assert paginator.next?
    end

    test 'prev page has prev when more records exist beyond page' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[1].id, direction: :prev)

      assert paginator.prev?
    end

    test 'prev page has no prev when reaching the beginning' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[3].id, direction: :prev)

      assert_not paginator.prev?
    end

    test 'prev page returns partial page at the beginning' do
      paginator = Paginator.new(scope: Event.all, per_page: 3, cursor: @events[2].id, direction: :prev)

      assert_equal [@events[4].id, @events[3].id], paginator.records.map(&:id)
      assert_not paginator.prev?
    end

    test 'navigating forward through all pages one by one' do
      visited = []
      paginator = Paginator.new(scope: Event.all, per_page: 1)

      5.times do
        visited << paginator.records.first.id
        break unless paginator.next?

        paginator = Paginator.new(scope: Event.all, per_page: 1, cursor: paginator.next_cursor, direction: :next)
      end

      assert_equal @events.map(&:id).reverse, visited
    end

    test 'navigating backward through all pages one by one' do
      # Start at the last page
      paginator = Paginator.new(scope: Event.all, per_page: 1, cursor: @events[1].id, direction: :next)
      assert_equal [@events[0].id], paginator.records.map(&:id)

      visited = [paginator.records.first.id]

      while paginator.prev?
        paginator = Paginator.new(scope: Event.all, per_page: 1, cursor: paginator.prev_cursor, direction: :prev)
        visited << paginator.records.first.id
      end

      assert_equal @events.map(&:id), visited
    end

    test 'navigating forward then backward returns to same page' do
      page1 = Paginator.new(scope: Event.all, per_page: 2)
      page1_ids = page1.records.map(&:id)

      page2 = Paginator.new(scope: Event.all, per_page: 2, cursor: page1.next_cursor, direction: :next)
      assert_not_equal page1_ids, page2.records.map(&:id)

      back_to_page1 = Paginator.new(scope: Event.all, per_page: 2, cursor: page2.prev_cursor, direction: :prev)
      assert_equal page1_ids, back_to_page1.records.map(&:id)
    end

    test 'pagination respects filtered scope' do
      scope = Event.where(event_type: 'Customer::Events::CustomerUpdated')
      paginator = Paginator.new(scope: scope, per_page: 2)

      paginator.records.each do |record|
        assert_equal 'Customer::Events::CustomerUpdated', record.event_type
      end
    end

    test 'empty scope returns no records' do
      paginator = Paginator.new(scope: Event.where(event_type: 'Nonexistent'), per_page: 2)

      assert_empty paginator.records
      assert_not paginator.next?
      assert_not paginator.prev?
      assert_nil paginator.next_cursor
      assert_nil paginator.prev_cursor
    end

    test 'single record has no pagination' do
      Event.where.not(id: @events.first.id).delete_all
      paginator = Paginator.new(scope: Event.all, per_page: 1)

      assert_equal 1, paginator.records.size
      assert_not paginator.next?
      assert_not paginator.prev?
    end

    test 'cursor beyond all records returns empty for next' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: 0, direction: :next)

      assert_empty paginator.records
    end

    test 'string cursor is converted to integer' do
      paginator = Paginator.new(scope: Event.all, per_page: 2, cursor: @events[3].id.to_s, direction: :next)

      assert_equal [@events[2].id, @events[1].id], paginator.records.map(&:id)
    end

    test 'exact record count equal to per_page has no next on first page' do
      Event.where.not(id: @events[0..1].map(&:id)).delete_all
      paginator = Paginator.new(scope: Event.all, per_page: 2)

      assert_equal 2, paginator.records.size
      assert_not paginator.next?
    end
  end
end
