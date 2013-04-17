# BrowserStack Screenshots

A ruby gem for [BrowserStack](http://browserstack.com)'s [Screenshot](http://browserstack.com/screenshots) [API](http://www.browserstack.com/screenshots/api).

## Installation

Add this line to your application's Gemfile:

    gem 'browserstack-screenshot'

And then execute:

    bundle

Or install it yourself as:

    gem install browserstack-screenshot

## Example of Use

First, you need to require the screenshot gem:

``` ruby
require 'screenshot'
```

### Creating Client
Creates a new client instance.

* `settings`: A hash of settings that apply to all requests for the new client.
  * `:username`: The username for the BrowserStack account.
  * `:password`: The password for the BrowserStack account.

``` ruby
settings = {:username => "foo", :password => "foobar"}
client = Screenshot::Client.new(settings)
```

###API

####Getting available os and browsers
Fetches all available browsers. [API info](http://www.browserstack.com/screenshots/api#browser-list)

``` ruby
client.get_os_and_browsers 	#returns a hash
```

####Generating Screenshots
Frame the config object according to the format given. [Format info](http://www.browserstack.com/screenshots/api#job-ids)

Eg settings object:
``` ruby
params = {
	:url => "www.google.com",
	:callback_url => "http://example.com/pingback_url",
	:win_res => "1024x768",		#Options : "1024x768", "1280x1024"
	:mac_res => "1920x1080", 	#Options : "1024x768", "1280x960", "1280x1024", "1600x1200", "1920x1080"
	:quality => "compressed",	#Options : "compressed", "original"
	:tunnel => false,
	:browsers => [
			{:os=>"Windows",:os_version=>"7",:browser=>"ie",:browser_version=>"8.0"},
			{:os=>"Windows",:os_version=>"XP",:browser=>"ie",:browser_version=>"7.0"}
	]
}
```
`callback_url`, `win_res`, `mac_res`, `quality` and `tunnel` being optional parameters.

#####For testing Local/Internal Server setup
* First setup local tunnel using the command line method as mentioned [here](http://www.browserstack.com/local-testing#setup)
* Pass `:tunnel => true` in the params object



A request id is returned when a valid request is made.

``` ruby
request_id = client.generate_screenshots params
```

####Checking/Polling the status of the request
Use this method to check if the requested screenshots are complete. 
``` ruby
client.screenshots_done? request_id	#returns `true` or `false`
```

Or you can fetch the request state
``` ruby
client.screenshots_status request_id	#returns `queue` or `processing` or `done`
```

####Fetching the response of the requested screenshots
``` ruby
client.screenshots request_id
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request