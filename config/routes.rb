# frozen_string_literal: true

RailsSimpleEventSourcing::Engine.routes.draw do
  root to: "events#index", as: :events
  get ":id", to: "events#show", as: :event
end
