# SugoiHttpRequestTester

* run http request from access log.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sugoi_http_request_tester'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sugoi_http_request_tester

## Usage
```ruby
tester = SugoiHttpRequestTester.new(
  host: 'example.com',
  limit: 100,
  logs_path: 'spec/logs/*',
  concurrency: 3,
)
tester.set_line_parse_block = ->(line){
  /({.*})/ =~ line
  json = JSON.parse($1)
  { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
}
tester.import_logs
tester.run
```

## Contributing

Bug reports and pull requests are welcome.
