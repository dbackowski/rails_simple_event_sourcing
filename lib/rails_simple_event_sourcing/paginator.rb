# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Paginator
    attr_reader :per_page

    def initialize(scope:, per_page:, cursor: nil, direction: :next)
      @scope = scope
      @per_page = per_page
      @cursor = cursor&.to_i
      @direction = direction
    end

    def records
      @records ||= fetch_records
    end

    def next_cursor
      records.last&.id
    end

    def prev_cursor
      records.first&.id
    end

    def next?
      records
      @has_next
    end

    def prev?
      records
      @has_prev
    end

    private

    def fetch_records
      if @cursor.nil?
        fetch_forward(@scope.order(id: :desc), has_prev: false)
      elsif @direction == :prev
        fetch_backward(@scope.where('id > ?', @cursor).order(id: :asc))
      else
        fetch_forward(@scope.where(id: ...@cursor).order(id: :desc), has_prev: true)
      end
    end

    def fetch_forward(scoped_query, has_prev:)
      rows, has_more = paginate(scoped_query)
      @has_prev = has_prev
      @has_next = has_more
      rows
    end

    def fetch_backward(scoped_query)
      rows, has_more = paginate(scoped_query)
      @has_next = true
      @has_prev = has_more
      rows.reverse
    end

    def paginate(scoped_query)
      rows = scoped_query.limit(@per_page + 1).to_a
      [rows.first(@per_page), rows.size > @per_page]
    end
  end
end
