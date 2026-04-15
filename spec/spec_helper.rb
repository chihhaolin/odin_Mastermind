ENV['RACK_ENV'] ||= 'test'

require_relative '../lib/code'
require_relative '../lib/feedback'
require_relative '../lib/board'
require_relative '../lib/computer_player'

# Web test helpers — loaded lazily so CLI-only specs don't pull in Sinatra.
module RackTestHelpers
  def self.included(base)
    require 'rack/test'
    require_relative '../web/app'

    base.include Rack::Test::Methods
    base.define_method(:app) { MastermindApp }
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Automatically tag specs under spec/web/ as request type …
  config.define_derived_metadata(file_path: %r{spec/web/}) do |meta|
    meta[:type] = :request
  end

  # … and include Rack::Test for those specs only.
  config.include RackTestHelpers, type: :request
end
