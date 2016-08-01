module SugoiHttpRequestTester
  class Runner
    def initialize(options = {})
      @logs_path = options[:logs_path]
      @request_list = RequestSet.new(limit: options[:limit])
      @line_parser_block = json_parse_block
      @thread_list = ThreadList.new(options[:concurrency])
      Request.host = options[:host]
      Request.basic_auth = options[:basic_auth]
      Dir.mkdir(EXPORT_BASE_DIR) unless File.exists?(EXPORT_BASE_DIR)
    end

    def run
      File.write(EXPORT_ACCESSED_LIST_PATH, '')
      File.write(EXPORT_MANUAL_LIST_PATH, '')
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
    end

    def concurrent_run
      @request_list.each do |request|
        @thread_list.push_queue { add_result(request.run) }
      end
      @thread_list.join
    end

    def import_logs
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        File.open(file_name).each_line do |line|
          break unless @request_list << Request.new(@line_parser_block.call(line))
        end
      end
    end

    def import_request_list_from_file
      clear_request_list!
      File.open(EXPORT_REQUEST_LIST_PATH).each_line do |line|
        break unless @request_list << Request.new(json_parse_block.call(line))
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

    def export_request_list!(per: nil, limit_part_files_count: nil)
      @exporter = RequestSet::Exporter.new(requests: @request_list.requests,
                                            per: per,
                                            limit_part_files_count: limit_part_files_count)
      @exporter.export
    end

    def request_list_export_files
      @exporter.export_files
    end

    def set_line_parse_block=(block)
      @line_parser_block = block
    end

    private

    def add_result(to: , request: , code: nil)
      @thread_list.mutex_synchronize do
        case to
        when :accessed_list
          puts code
          File.open(EXPORT_ACCESSED_LIST_PATH, 'a') do |f|
            f.puts([request.to_json, code].join(','))
          end
        when :manual_list
          File.open(EXPORT_MANUAL_LIST_PATH, 'a') do |f|
            f.puts(request.to_json)
          end
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
