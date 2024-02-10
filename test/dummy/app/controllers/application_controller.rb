class ApplicationController < ActionController::Base
  include RailsSimpleEventSourcing::SetCurrentRequestDetails
end
