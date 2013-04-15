# BrowserStack Screenshots

A ruby gem for working with [BrowserStack](http://browserstack.com/screenshots) through its [API](http://www.browserstack.com/screenshots/api).

## Installation

Add this line to your application's Gemfile:

    gem 'browserstack-screenshot'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browserstack-screenshot

## Example of Use

First, you probably want to require it:

``` ruby
require 'screenshot'
```

### Creating Client
Creates a new client instance.

* `settings`: A hash of settings that apply to all requests for the new client.
  * `:username`: The username for the BrowserStack account.
  * `:password`: The password for the BrowserStack account.

``` ruby
settings = {:username: "foo", :password: "foobar"}
client = Browserstack::Screenshots::Client.new(settings)
```

###API

####Getting available os and browsers
Fetches all available browsers. [API info](http://www.browserstack.com/screenshots/api#browser-list)

``` ruby
client.get_os_and_browsers #returns a hash
```

####Generating Screenshots
Frame the config object according to the format given. [Format info](http://www.browserstack.com/screenshots/api#job-ids)

Eg settings object:
``` ruby
settings = 
{
	:url=>"www.google.com",
	:callback_url=>"http://example.com/pingback_url",
	:win_res=>"1024x768",
	:mac_res=>"1920x1080",
	:quality=>"compressed",
	:browsers=>[
			{:os=>"Windows",:os_version=>"7",:browser=>"ie",:browser_version=>"8.0"},
			{:os=>"Windows",:os_version=>"XP",:browser=>"ie",:browser_version=>"7.0"}
	]
}
```
`callback_url`, `win_res`, `mac_res` and `quality` being optional parameters.

A job id is returned when a valid request is made.

``` ruby
job_id = client.start_screenshots settings
```

####Checking/Polling the status of the job
Use this method to check if the job is complete. 
``` ruby
client.job_complete? job_id	#returns `true` or `false`
```

Or you can fetch the job state
``` ruby
client.job_state job_id	#returns `queue` or `processing` or `done`
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request