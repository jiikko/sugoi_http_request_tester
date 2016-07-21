# SugoiHttpRequestTester

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
  basic_auth: [ENV['OUTING_BASIC_AUTH_USER'], ENV['OUTING_BASIC_AUTH_PASSWORD']],
  logs_path: 'logs/*',
) do |line|
  /({.*})/ =~ line
  JSON.parse($1)
end
tester.run
```

## Contributing

Bug reports and pull requests are welcome.
