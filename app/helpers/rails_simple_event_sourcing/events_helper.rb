# frozen_string_literal: true

module RailsSimpleEventSourcing
  module EventsHelper
    def pagination_window(current_page, total_pages, window: 2) # rubocop:disable Metrics/MethodLength
      return [1] if total_pages <= 1

      pages = []
      left = [current_page - window, 1].max
      right = [current_page + window, total_pages].min

      if left > 1
        pages << 1
        pages << :gap if left > 2
      end

      (left..right).each { |p| pages << p }

      if right < total_pages
        pages << :gap if right < total_pages - 1
        pages << total_pages
      end

      pages
    end
  end
end
