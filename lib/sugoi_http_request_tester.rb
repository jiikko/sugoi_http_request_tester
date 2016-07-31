require "sugoi_http_request_tester/version"
require "sugoi_http_request_tester/request_list"
require "sugoi_http_request_tester/request_list/exporter"
require "sugoi_http_request_tester/request"
require "sugoi_http_request_tester/thread_list"
require "sugoi_http_request_tester/runner"
require 'json'
require 'net/http'
require 'digest/md5'
require 'forwardable'

# Todo
# https

module SugoiHttpRequestTester
  EXPORT_BASE_DIR = 'output'
  EXPORT_REQUEST_LIST_PATH =  "#{EXPORT_BASE_DIR}/request_list"
  EXPORT_ACCESSED_LIST_PATH = "#{EXPORT_BASE_DIR}/accessed_list"
  EXPORT_MANUAL_LIST_PATH =   "#{EXPORT_BASE_DIR}/manual_list"

  def self.new(host:, limit: nil, basic_auth: nil, logs_path: , concurrency: 1)
    Runner.new(host: host,
               limit: limit,
               basic_auth: basic_auth,
               logs_path: logs_path,
               concurrency: concurrency)
  end
end
