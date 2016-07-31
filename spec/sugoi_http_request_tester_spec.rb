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
        concurrency: 3,
      )
      tester.set_line_parse_block = ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
      tester.import_logs
      tester.run
      expect(tester.instance_eval { @request_list.size }).to eq 3
    end

    it 'manual_list を出力していること' do
      log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"ddd"}
{"mt":"POST","pt":"/index3.html","ua":"ddd"}
      LOG
      File.write('spec/logs/log1', log)
      tester = SugoiHttpRequestTester.new(
        host: 'example.com',
        limit: 100,
        basic_auth: [ENV['OUTING_BASIC_AUTH_USER'], ENV['OUTING_BASIC_AUTH_PASSWORD']],
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
      expect(File.open(SugoiHttpRequestTester::EXPORT_MANUAL_LIST_PATH).readlines.size).to eq 1
    end
  end

  describe 'limit' do
    it 'be to enable limit feature' do
      log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"ddd"}
      LOG
      File.write('spec/logs/log1', log)
      tester = SugoiHttpRequestTester.new(
        host: 'example.com',
        limit: 1,
        logs_path: 'spec/logs/*',
      )
      tester.set_line_parse_block = ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
      tester.import_logs
      expect(tester.instance_eval { @request_list.size }).to eq 1
    end
  end

  describe '#export_request_list' do
    context 'when unset limit' do
      it 'exportすること' do
        log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"Mobile"}
        LOG
        File.write('spec/logs/log1', log)
        tester = SugoiHttpRequestTester.new(
          host: 'example.com',
          logs_path: 'spec/logs/*',
        )
        tester.set_line_parse_block = ->(line){
          /({.*})/ =~ line
          json = JSON.parse($1)
          { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
        }
        tester.import_logs
        tester.export_request_list
        expect(File.open(SugoiHttpRequestTester::EXPORT_REQUEST_LIST_PATH).readlines.size).to eq 3
        tester.clear_request_list
        expect(tester.instance_eval { @request_list.size }).to eq 0
        tester.import_exported_request_list
        expect(tester.instance_eval { @request_list.size }).to eq 3
      end
    end

    it 'exportすること' do
      log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"Mobile"}
      LOG
      File.write('spec/logs/log1', log)
      tester = SugoiHttpRequestTester.new(
        host: 'example.com',
        limit: 100,
        logs_path: 'spec/logs/*',
      )
      tester.set_line_parse_block = ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
      tester.import_logs
      tester.export_request_list
      expect(tester.request_list_export_files.size).to eq 1
      export_file = tester.request_list_export_files.first
      expect(export_file.readlines.size).to eq 3
      tester.clear_request_list
      expect(tester.instance_eval { @request_list.size }).to eq 0
      tester.import_exported_request_list
      expect(tester.instance_eval { @request_list.size }).to eq 3
    end
  end

  it 'per exportすること' do
    log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/index3.html","ua":"Mobile"}
{"mt":"GET","pt":"/index4.html","ua":"Mobile"}
{"mt":"GET","pt":"/index4.html","ua":"Mobile"}
{"mt":"GET","pt":"/index5.html","ua":"Mobile"}
    LOG
    File.write('spec/logs/log1', log)
    tester = SugoiHttpRequestTester.new(
      host: 'example.com',
      limit: 100,
      logs_path: 'spec/logs/*',
    )
    tester.set_line_parse_block = ->(line){
      /({.*})/ =~ line
      json = JSON.parse($1)
      { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
    }
    tester.import_logs
    tester.export_request_list(per: 2, limit_part_files_count: 1)
  end
end
