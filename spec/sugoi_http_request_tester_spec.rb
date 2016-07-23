require 'spec_helper'

describe SugoiHttpRequestTester do
  it 'has a version number' do
    expect(SugoiHttpRequestTester::VERSION).not_to be nil
  end

  describe '#run' do
    it 'be to set @request_list' do
      log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"ddd"}
      LOG
      File.write('spec/logs/log1', log)
      tester = SugoiHttpRequestTester.new(
        host: 'example.com',
        limit: 100,
        basic_auth: [ENV['OUTING_BASIC_AUTH_USER'], ENV['OUTING_BASIC_AUTH_PASSWORD']],
        logs_path: 'spec/logs/*',
      ) do |line|
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      end
      tester.load_logs
      tester.run
      expect(tester.instance_eval { @request_list.requests }.size).to eq 3
    end
  end

  describe '#export_request_list' do
    it 'exportすること' do
      log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"ddd"}
      LOG
      File.write('spec/logs/log1', log)
      tester = SugoiHttpRequestTester.new(
        host: 'example.com',
        limit: 100,
        basic_auth: [ENV['OUTING_BASIC_AUTH_USER'], ENV['OUTING_BASIC_AUTH_PASSWORD']],
        logs_path: 'spec/logs/*',
      ) do |line|
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      end
      tester.load_logs
      tester.export_request_list
      expect(File.open(SugoiHttpRequestTester::EXPORT_REQUEST_LIST_PATH).readlines.size).to eq 3
    end
  end
end
