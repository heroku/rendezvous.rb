# Rendezvous

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'rendezvous'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rendezvous

## Usage

```
require 'rendezvous'
require 'heroku-api'
require 'netrc'

username, api_key = Netrc.read['api.heroku.com']

heroku = Heroku::API.new(:api_key => api_key)

env = { 'TERM' => ENV['TERM'] }
begin
  env['COLUMNS']  = `tput cols`.strip
  env['LINES']    = `tput lines`.strip
rescue
end

data = heroku.post_ps(
  'testable',
  'bash',
  { :attach => true, :ps_env => env }
).body

Rendezvous.start(
  :url => data['rendezvous_url']
)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
