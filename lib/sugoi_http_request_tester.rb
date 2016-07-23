require "sugoi_http_request_tester/version"
require 'json'
require 'net/http'
require 'digest/md5'

# load_request_list をexportする. ログから抽出して次回起動から高速にするため
#
# parallel
# UAをリクエストンに含める

module SugoiHttpRequestTester
  EXPORT_REQUEST_LIST_PATH =  'output/request_list'
  EXPORT_ACCESSED_LIST_PATH = 'output/accessed_list'
  EXPORT_MANUAL_LIST_PATH =   'output/manual_list'

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

    def export
      text = requests.map { |request| request.to_hash }.join("\n")
      File.write(EXPORT_MANUAL_LIST_PATH, text)
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

    def to_hash
      { method: @method,
        user_agent: @user_agent,
        path: @path,
        mt: @method,
        ua: @user_agent,
        pt: @path,
      }
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

    def load_and_run
      load_logs
      run
    end

    def run
      @request_list.requests.each do |request|
        if /GET/ =~ request.method
          Net::HTTP.start(@host) do |http|
            req = Net::HTTP::Get.new(request.path)
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

    def export_request_list
      @request_list.export
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
        @accessed_list << [request.to_hash, code].join(',')
      when :manual_list
        @manual_list << request.to_hash
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
