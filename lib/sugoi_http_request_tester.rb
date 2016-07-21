require "sugoi_http_request_tester/version"
require 'json'
require 'net/http'

module SugoiHttpRequestTester
  class Runner
    def initialize(host: , limit: nil, basic_auth: nil, logs_path: nil, block: nil)
      @host = host
      @accessed_list = []
      @manual_list = []
      @limit = limit
      @basic_auth = basic_auth
      @logs_path = logs_path
      @line_parser_block =
        if block_given?
          block
        else
          ->(line) {
            /({.*})/ =~ line
            yield JSON.parse($1)
          }
        end
    end

  def run
    lines.each do |hash|
      if /GET/ =~ hash['mt']
        Net::HTTP.start(@host) do |http|
          req = Net::HTTP::Get.new(hash['pt'])
          req.basic_auth *@basic_auth unless @basic_auth.nil?
          response = http.request(req)
          add_result(to: :accessed_list, hash: hash, code: response.code)
        end
      else
        add_result(to: :manual_list, hash: hash)
      end
    end
    export
  end

  private

  def export
    File.write('accessed_list', @accessed_list.join("\n"))
    File.write('manual_list', @manual_list.join("\n"))
  end

  # 圧縮されたファイルをここで読むとメモリ食うので解凍済みを使う
  def lines
    [].tap do |array|
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        File.open(file_name).each_line do |line|
          array << @line_parser_block.call(line)
          break if countup_and_limit?
        end
      end
    end
  end

  def add_result(to: , hash: , code: nil)
    case to
    when :accessed_list
      puts code
      @accessed_list << [hash, code].join(',')
    when :manual_list
      @manual_list << hash
    else
      raise 'bug!!'
    end
  end

  def countup_and_limit?
    if @limit_counter.nil? && @limit.is_a?(Numeric)
      @limit_counter = 0
    end
    if @limit.is_a?(Numeric)
      @limit_counter += 1
      @limit_counter > @limit
    end
  end
end

  def self.new(host:, limit: nil, basic_auth: nil, logs_path:, &block)
    Runner.new(host: host, limit: limit, basic_auth: basic_auth, logs_path: logs_path, block: block)
  end
end
