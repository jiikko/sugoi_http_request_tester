require 'spec_helper'

describe SugoiHttpRequestTester do
  it 'has a version number' do
    expect(SugoiHttpRequestTester::VERSION).not_to be nil
  end

  describe '#run' do
    describe '::OutputFormat::Array' do
      context 'when sequential' do
        it 'be array' do
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
          tester.line_parse_block = ->(line){
            /({.*})/ =~ line
            json = JSON.parse($1)
            { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
          }
          tester.import_logs!
          array = tester.run
          expect(array.size).to eq 3
          expect { tester.run }.to raise_error RuntimeError
        end
      end
      context 'when sequential' do
        it 'be array' do
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
            concurrency: 1,
          )
          tester.line_parse_block = ->(line){
            /({.*})/ =~ line
            json = JSON.parse($1)
            { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
          }
          tester.import_logs!
          array = tester.run
          expect(array.size).to eq 3

          array = tester.run
          expect(array.size).to eq 3
        end
      end
    end

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
      tester.line_parse_block = ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
      tester.import_logs!
      tester.run
      expect(tester.instance_eval { @request_list.size }).to eq 3
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
      tester.line_parse_block = ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
      tester.import_logs!
      expect(tester.instance_eval { @request_list.size }).to eq 1
    end
  end

  describe '#export_request_list!' do
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
        tester.import_logs!
        file = tester.export_request_list!
        expect(file.readlines.size).to eq 3
        tester.clear_request_list!
        expect(tester.instance_eval { @request_list.size }).to eq 0
        tester.import_request_list_from_file(file)
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
      tester.line_parse_block = ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
      tester.import_logs!
      file = tester.export_request_list!
      expect(file.readlines.size).to eq 3
      tester.clear_request_list!
      expect(tester.instance_eval { @request_list.size }).to eq 0
      tester.import_request_list_from_file(file)
      expect(tester.instance_eval { @request_list.size }).to eq 3
    end
  end

  it 'per exportすること' do
    log = <<-LOG
{"mt":"GET","pt":"/index.html","ua":"ddd"}
{"mt":"GET","pt":"/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/events/index2.html","ua":"ddd"}
{"mt":"GET","pt":"/events/index3.html","ua":"Mobile"}
{"mt":"GET","pt":"/events/index4.html","ua":"Mobile"}
{"mt":"GET","pt":"/events/index41.html","ua":"Mobile"}
{"mt":"GET","pt":"/events/index5.html","ua":"Mobile"}
{"mt":"GET","pt":"/help/index1.html","ua":"Mobile"}
{"mt":"GET","pt":"/help/index2.html","ua":"Mobile"}
{"mt":"GET","pt":"/help/index5.html","ua":"Mobile"}
{"mt":"GET","pt":"/info/index3.html","ua":"Mobile"}
{"mt":"GET","pt":"/info/index4.html","ua":"Mobile"}
{"mt":"GET","pt":"/info/index6.html","ua":"Mobile"}
    LOG
    File.write('spec/logs/log1', log)
    tester = SugoiHttpRequestTester.new(
      host: 'example.com',
      limit: 100,
      logs_path: 'spec/logs/*',
    )
    tester.line_parse_block = ->(line){
      /({.*})/ =~ line
      json = JSON.parse($1)
      { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
    }
    tester.import_logs!
    # export_format: :file
    file = tester.export_request_list!
    expect(tester.instance_eval { @request_list.size }).not_to eq 0
    expect(file.readlines.size).to eq 13
    file.unlink

    # export_format: :array
    list = tester.export_request_list!(export_format: :array)
    expect(list.size).to eq 13
    expect(list.is_a?(Array)).to eq true

    # URLが均等になっているかの確認
    file = tester.export_request_list!
    expect(tester.instance_eval { @request_list.size }).not_to eq 0
    texts = file.readlines
    expect(JSON.parse(texts[0])['path']).to eq "/index.html"
    expect(JSON.parse(texts[1])['path']).to eq "/events/index5.html"
    expect(JSON.parse(texts[2])['path']).to eq "/help/index5.html"
    expect(JSON.parse(texts[3])['path']).to eq "/info/index6.html"
    expect(JSON.parse(texts[4])['path']).to eq "/index2.html"
    expect(JSON.parse(texts[5])['path']).to eq "/help/index2.html"
    file.unlink
  end
end
