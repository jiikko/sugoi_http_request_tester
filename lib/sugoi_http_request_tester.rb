require "sugoi_http_request_tester/version"
require 'json'
require 'net/http'
require 'digest/md5'
require 'forwardable'

# parallel
# https

module SugoiHttpRequestTester
  EXPORT_REQUEST_LIST_PATH =  'output/request_list'
  EXPORT_ACCESSED_LIST_PATH = 'output/accessed_list'
  EXPORT_MANUAL_LIST_PATH =   'output/manual_list'

  class RequestList
    extend Forwardable

    def_delegators :@requests, :size, :clear

    def initialize
      @requests = {}
    end

    def <<(request)
      @requests[request.hash] = request
    end

    def requests
      @requests.values
    end

    def export
      text = requests.map { |request| request.to_json }.join("\n")
      File.write(EXPORT_REQUEST_LIST_PATH, text)
    end

    def each(&block)
      @requests.each do |_hash, request|
        yield request
      end
    end
  end

  class Request
    attr_accessor :method, :user_agent, :path

    def initialize(method: , user_agent: , path: )
      @method = method
      @user_agent = user_agent
      @path = path
    end

    def hash
      Digest::MD5.hexdigest([@method, @user_agent, @path].join)
    end

    def to_json
      { method: @method,
        user_agent: @user_agent,
        path: @path,
        mt: @method,
        ua: @user_agent,
        pt: @path,
      }.to_json
    end
  end

  class Runner
    def initialize(host: , limit: nil, basic_auth: nil, logs_path: nil)
      @host = host
      @accessed_list = []
      @manual_list = []
      @limit = limit
      @basic_auth = basic_auth
      @logs_path = logs_path
      @request_list = RequestList.new
      @line_parser_block = json_parse_block
    end

    def load_and_run
      load_logs
      run
    end

    def run
      @request_list.each do |request|
        if /GET/ =~ request.method
          Net::HTTP.start(@host) do |http|
            req = Net::HTTP::Get.new(request.path)
            req.add_field('User-Agent', request.user_agent) unless request.user_agent.nil?
            req.basic_auth *@basic_auth unless @basic_auth.nil?
            response = http.request(req)
            add_result(to: :accessed_list, request: request, code: response.code)
          end
        else
          add_result(to: :manual_list, request: request)
        end
      end
      export
    end

    def load_logs
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        File.open(file_name).each_line do |line|
          @request_list << Request.new(@line_parser_block.call(line))
          break if countup_and_limit?
        end
      end
    end

    def load_exported_request_list
      File.open(EXPORT_REQUEST_LIST_PATH).each_line do |line|
        @request_list << Request.new(json_parse_block.call(line))
        break if countup_and_limit?
      end
    end

    def clear_request_list
      @request_list.clear
    end

    def export_request_list
      @request_list.export
    end

    def set_line_parse_block=(block)
      @line_parser_block = block
    end

    private

    def export
      File.write(EXPORT_ACCESSED_LIST_PATH, @accessed_list.join("\n"))
      File.write(EXPORT_MANUAL_LIST_PATH, @manual_list.join("\n"))
    end

    def add_result(to: , request: , code: nil)
      case to
      when :accessed_list
        puts code
        @accessed_list << [request.to_json, code].join(',')
      when :manual_list
        @manual_list << request.to_json
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

    def json_parse_block
      ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
    end
  end

  def self.new(host:, limit: nil, basic_auth: nil, logs_path: )
    Runner.new(host: host, limit: limit, basic_auth: basic_auth, logs_path: logs_path)
  end
end
