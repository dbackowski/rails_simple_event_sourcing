# frozen_string_literal: true

RailsSimpleEventSourcing::Engine.routes.draw do
  resources :events, only: [:index, :show]
  root to: "events#index"
end
