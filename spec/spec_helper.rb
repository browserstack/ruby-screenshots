require 'rspec'
require 'webmock/rspec'

# Load the gem under test from source (not the installed copy).
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'screenshot'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  # WebMock: block all real outbound HTTP so a misconfigured spec can't
  # accidentally hit production BrowserStack with the dummy credentials.
  config.before(:suite) do
    WebMock.disable_net_connect!
  end
  config.after(:each) do
    WebMock.reset!
  end
end
