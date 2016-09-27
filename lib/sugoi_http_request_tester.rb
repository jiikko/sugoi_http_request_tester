require "sugoi_http_request_tester/version"
require "sugoi_http_request_tester/request_set"
require "sugoi_http_request_tester/request_set/exporter"
require "sugoi_http_request_tester/sorted_request_list"
require "sugoi_http_request_tester/request"
require "sugoi_http_request_tester/thread_list"
require "sugoi_http_request_tester/runner"
require 'json'
require 'net/http'
require 'digest/md5'
require 'forwardable'
require 'tempfile'

# Todo
# https

module SugoiHttpRequestTester
  def self.new(host:, limit: nil, basic_auth: nil, logs_path: , concurrency: 1)
    Runner.new(host: host,
               limit: limit,
               basic_auth: basic_auth,
               logs_path: logs_path,
               concurrency: concurrency)
  end
end
