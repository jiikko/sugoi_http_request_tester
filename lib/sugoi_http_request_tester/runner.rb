module SugoiHttpRequestTester
  class Runner
    def initialize(options = {})
      @host = options[:host]
      @accessed_list = []
      @manual_list = []
      @basic_auth = options[:basic_auth]
      @logs_path = options[:logs_path]
      @request_list = RequestList.new(limit: options[:limit])
      @line_parser_block = json_parse_block
      @thread_list = ThreadList.new(5)
    end

    def load_and_run
      load_logs
      run
    end

    def run
      @request_list.each do |request|
        if /GET/ =~ request.method
          @thread_list.push_queue do
            Net::HTTP.start(@host) do |http|
              req = Net::HTTP::Get.new(request.path)
              req.add_field('User-Agent', request.user_agent) unless request.user_agent.nil?
              req.basic_auth *@basic_auth unless @basic_auth.nil?
              response = http.request(req)
              add_result(to: :accessed_list, request: request, code: response.code)
            end
          end
        else
          add_result(to: :manual_list, request: request)
        end
      end
      @thread_list.join
      export
    end

    def load_logs
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        File.open(file_name).each_line do |line|
          break unless @request_list << Request.new(@line_parser_block.call(line))
        end
      end
    end

    def load_exported_request_list
      File.open(EXPORT_REQUEST_LIST_PATH).each_line do |line|
        break unless @request_list << Request.new(json_parse_block.call(line))
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
      @thread_list.mutex_synchronize do
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
    end

    def json_parse_block
      ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
    end
  end
end
