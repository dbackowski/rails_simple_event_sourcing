require_relative "lib/rails_simple_event_sourcing/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_simple_event_sourcing"
  spec.version     = RailsSimpleEventSourcing::VERSION
  spec.authors     = ["Damian Baćkowski"]
  spec.email       = ["damianbackowski@gmail.com"]
  spec.homepage    = "https://github.com/dbackowski/rails_simple_event_sourcing"
  spec.summary     = "Rails engine for simple event sourcing."
  spec.description = "Rails simple event sourcing engine."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.2"
end
