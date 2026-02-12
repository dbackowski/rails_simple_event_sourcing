# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Paginator
    attr_reader :total_count, :total_pages, :current_page, :per_page

    def initialize(scope:, page:, per_page:)
      @scope = scope
      @per_page = per_page
      @total_count = scope.count
      @total_pages = [(@total_count.to_f / per_page).ceil, 1].max
      @current_page = (page.presence || 1).to_i.clamp(1, @total_pages)
    end

    def records
      @scope.offset((@current_page - 1) * @per_page).limit(@per_page)
    end
  end
end
