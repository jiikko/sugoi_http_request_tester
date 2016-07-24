module SugoiHttpRequestTester
  class Runner
    def initialize(options = {})
      @accessed_list = []
      @manual_list = []
      @logs_path = options[:logs_path]
      @request_list = RequestList.new(limit: options[:limit])
      @line_parser_block = json_parse_block
      @thread_list = ThreadList.new(options[:concurrency])
      Request.host = options[:host]
      Request.basic_auth = options[:basic_auth]
    end

    def run
      if @thread_list.size <= 1
        sequential_run
      else
        concurrent_run
      end
    end

    def sequential_run
      @request_list.each do |request|
        add_result(request.run)
      end
      export
    end

    def concurrent_run
      @request_list.each do |request|
        @thread_list.push_queue do
        add_result(request.run)
        end
      end
      @thread_list.join
      export
    end

    def import_logs
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        File.open(file_name).each_line do |line|
          break unless @request_list << Request.new(@line_parser_block.call(line))
        end
      end
    end

    def import_exported_request_list
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
