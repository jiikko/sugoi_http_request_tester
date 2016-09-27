# SugoiHttpRequestTester

* Send http request from access log.
* 取り込んだURLをデバイス毎にユニークにする
* 並列実行

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sugoi_http_request_tester', 'jiikko/sugoi_http_request_tester'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sugoi_http_request_tester

## Usage
```ruby
require 'sugoi_http_request_tester'

tester = SugoiHttpRequestTester.new(
  host: 'example.com',
  limit: 10000,
  logs_path: 'logs_source/*',
  concurrency: 10,
)
tester.line_parse_block = ->(line){
  /({.*})/ =~ line
  json = JSON.parse($1)
  { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
}
tester.import_logs!
tester.run!
```

# TODO
* support not GET http method
* support https
