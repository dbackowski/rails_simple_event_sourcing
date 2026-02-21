# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventsController < ApplicationController
    def index
      @event_types = event_types
      @aggregates = aggregates
      paginate(search_events)
    end

    def show
      @event = Event.find(params[:id])
      @aggregate_state = @event.aggregate_state
      find_adjacent_versions
    end

    private

    def event_types
      return Event.descendants.map(&:name).sort if Rails.env.production?

      Event.distinct.pluck(:event_type).sort
    end

    def aggregates
      return Event.descendants.filter_map(&:aggregate_class).map(&:name).uniq.sort if Rails.env.production?

      Event.where.not(eventable_type: nil).distinct.pluck(:eventable_type).sort
    end

    def search_events
      EventSearch.new(
        scope: Event.all,
        event_type: params[:event_type],
        aggregate: params[:aggregate],
        query: params[:q]
      ).call
    end

    def paginate(scope)
      @paginator = Paginator.new(
        scope:,
        per_page: RailsSimpleEventSourcing.config.events_per_page,
        cursor: params[:after] || params[:before],
        direction: params[:before].present? ? :prev : :next
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
