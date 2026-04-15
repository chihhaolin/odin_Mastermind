require_relative '../lib/code'
require_relative '../lib/feedback'
require_relative '../lib/board'
require_relative '../lib/computer_player'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
