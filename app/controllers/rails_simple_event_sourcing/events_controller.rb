# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventsController < ApplicationController
    def index
      load_filter_options
      scope = search_events
      paginate(scope)
    end

    def show
      @event = Event.find(params[:id])
      @aggregate_state = @event.aggregate_state
      find_adjacent_versions
    end

    private

    def load_filter_options
      @event_types = Event.distinct.pluck(:event_type).sort
      @aggregates = Event.where.not(eventable_type: nil).distinct.pluck(:eventable_type).sort
    end

    def search_events
      scope = Event.order(created_at: :desc)
      EventSearch.new(
        scope:,
        event_type: params[:event_type],
        aggregate: params[:aggregate],
        query: params[:q]
      ).call
    end

    def paginate(scope)
      @paginator = Paginator.new(
        scope:,
        page: params[:page],
        per_page: RailsSimpleEventSourcing.config.events_per_page
      )
    end

    def find_adjacent_versions
      return if @event.aggregate_id.blank?

      scope = Event.where(aggregate_id: @event.aggregate_id)
      @previous_version = scope.where(version: ...@event.version).order(version: :desc).first
      @next_version = scope.where('version > ?', @event.version).order(version: :asc).first
    end
  end
end
