require "sugoi_http_request_tester/version"
require 'json'
require 'net/http'
require 'digest/md5'

# load_request_list をexportする. ログから抽出して次回起動から高速にするため
#
# parallel
# format outputfile
# UAをリクエストンに含める

module SugoiHttpRequestTester
  class RequestList
    def initialize
      @requests = {}
    end

    def <<(request)
      @requests[request.hash] = request
    end

    def requests
      @requests.values
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
  end

  class Runner
    def initialize(host: , limit: nil, basic_auth: nil, logs_path: nil, block: nil)
      @host = host
      @accessed_list = []
      @manual_list = []
      @limit = limit
      @basic_auth = basic_auth
      @logs_path = logs_path
      @request_list = RequestList.new
      @line_parser_block =
        if block
          block
        else
          ->(line) {
            /({.*})/ =~ line
            json = JSON.parse($1)
            { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
          }
        end
    end

    def run
      load_request_list
      @request_list.requests.each do |request|
        if /GET/ =~ request.method
          Net::HTTP.start(@host) do |http|
            req = Net::HTTP::Get.new(request.path)
            req.basic_auth *@basic_auth unless @basic_auth.nil?
            response = http.request(req)
            add_result(to: :accessed_list, hash: request, code: response.code)
          end
        else
          add_result(to: :manual_list, hash: request)
        end
      end
      export
    end

    private

    def export
      File.write('accessed_list', @accessed_list.join("\n"))
      File.write('manual_list', @manual_list.join("\n"))
    end

    def load_request_list
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        File.open(file_name).each_line do |line|
          @request_list << Request.new(@line_parser_block.call(line))
          break if countup_and_limit?
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
