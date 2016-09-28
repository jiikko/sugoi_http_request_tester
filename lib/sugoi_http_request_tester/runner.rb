module SugoiHttpRequestTester
  class Runner
    attr_writer :line_parse_block

    def initialize(options = {})
      @logs_path = options[:logs_path]
      @request_list = RequestSet.new(limit: options[:limit])
      @line_parse_block = default_json_parse_block
      @thread_list = ThreadList.new(options[:concurrency])
      Request.host = options[:host]
      Request.basic_auth = options[:basic_auth]
    end

    def run
      @results = []
      if @thread_list.size <= 1
        sequential_run
      else
        concurrent_run
      end
      @results
    end

    def run!
      run
    end

    def import_logs!
      clear_request_list!
      Dir.glob(@logs_path).each do |file_name|
        File.open(file_name).each_line do |line|
          break unless @request_list << Request.new(@line_parse_block.call(line))
        end
      end
    end

    def import_request_list_from_file(path)
      clear_request_list!
      File.open(path).each_line do |line|
        break unless @request_list << Request.new(@line_parse_block.call(line))
      end
    end

    def import_request_list_from(list)
      clear_request_list!
      list.each do |hash|
        @request_list << Request.new(hash)
      end
    end

    def clear_request_list!
      @request_list.clear
    end

    def export_request_list!(export_format: :file)
      @exporter = RequestSet::Exporter.new(requests: @request_list.requests,
                                           export_format: export_format)
      @exporter.export!
    end

    private

    def results
      @output_format_instance.to_format
    end

    def add_result(request: , code: nil)
      @thread_list.mutex_synchronize do
        @results << request.to_hash.merge(status_code: code.to_i)
      end
    end

    def default_json_parse_block
      ->(line){
        /({.*})/ =~ line
        json = JSON.parse($1)
        { method: json['mt'], user_agent: json['ua'], path: json['pt'] }
      }
    end

    def sequential_run
      @request_list.each do |request|
        add_result(request.run)
      end
    end

    def concurrent_run
      raise 'not exists living thread_list' unless @thread_list.live?
      @request_list.each do |request|
        @thread_list.push_queue({
          request: request, # for exception
          block:   ->(){ add_result(request.run) }
        })
      end
      @thread_list.join
    end
  end
end
