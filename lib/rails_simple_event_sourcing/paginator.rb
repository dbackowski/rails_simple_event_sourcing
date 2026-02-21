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
        fetch_first_page
      elsif @direction == :prev
        fetch_prev_page
      else
        fetch_next_page
      end
    end

    def fetch_first_page
      rows = @scope.order(id: :desc).limit(@per_page + 1).to_a
      @has_prev = false
      @has_next = rows.size > @per_page
      rows.first(@per_page)
    end

    def fetch_next_page
      rows = @scope.where(id: ...@cursor).order(id: :desc).limit(@per_page + 1).to_a
      @has_prev = true
      @has_next = rows.size > @per_page
      rows.first(@per_page)
    end

    def fetch_prev_page
      rows = @scope.where('id > ?', @cursor).order(id: :asc).limit(@per_page + 1).to_a
      @has_next = true
      @has_prev = rows.size > @per_page
      rows.first(@per_page).reverse
    end
  end
end
