module RailsSimpleEventSourcing
  Result = Struct.new(:success?, :data, :errors, keyword_init: true)
end
