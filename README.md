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


The Rendezvous class reads and writes from `STDIN` and `STDOUT`.  If you want to manage that programatically, you can pass in other IO objects.

```
    rz = Rendezvous.new({input:StringIO.new, output:StringIO.new, url: data['rendezvous_url']})
    rz.start
    # log the output, remember to rewind so it can be read
    rz.output.rewind
    log.debug("Results:#{rz.output.readlines.join}")
```

Since the Rendezvous class uses blocking IO, you may want to wrap it in a Thread so your main thread can continue while data is being read.

```
Thread.new do
  begin
    # set an activity timeout so it doesn't block forever
    rz = Rendezvous.new({input:StringIO.new, output:StringIO.new, url: data['rendezvous_url'], activity_timeout:300})
    rz.start
    # do something with output ...
  rescue => e
    log.error("Error capturing output for dyno\n#{e.message}")
  end
  
  log.debug("completed capturing output for dyno")
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
