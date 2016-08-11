module SugoiHttpRequestTester
  class Runner
    module OutputFormat
      class File
        def initialize
          ::File.write(SugoiHttpRequestTester::EXPORT_ACCESSED_LIST_PATH, '')
          ::File.write(SugoiHttpRequestTester::EXPORT_MANUAL_LIST_PATH, '')
        end

        def add_result(to: , request: , code: nil)
          case to
          when :accessed_list
            puts code
            ::File.open(EXPORT_ACCESSED_LIST_PATH, 'a') do |f|
              f.puts([request.to_json, code].join(','))
            end
          when :manual_list
            ::File.open(EXPORT_MANUAL_LIST_PATH, 'a') do |f|
              f.puts(request.to_json)
            end
          else
            raise 'bug!!'
          end
        end

        def to_format
          true
        end
      end

      class Array
        def initialize
          @results = []
        end

        def to_format
          @results
        end

        def add_result(to: , request: , code: nil)
          @results << request.to_hash.merge(status_code: code)
        end
      end
    end

    def initialize(options = {})
      @logs_path = options[:logs_path]
      @request_list = RequestSet.new(limit: options[:limit])
      @line_parser_block = json_parse_block
      @thread_list = ThreadList.new(options[:concurrency])
      Request.host = options[:host]
      Request.basic_auth = options[:basic_auth]
      Dir.mkdir(EXPORT_BASE_DIR) unless ::File.exists?(EXPORT_BASE_DIR)
    end

    def run(output_format: :file)
      @output_format = output_format
      if @thread_list.size <= 1
        sequential_run
      else
        concurrent_run
      end
      results
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

    def import_logs!
      clear_request_list!
      Dir.glob(@logs_path).each do |file_name|
        next if /\.gz$/ =~ file_name
        ::File.open(file_name).each_line do |line|
          break unless @request_list << Request.new(@line_parser_block.call(line))
        end
      end
    end

    def import_request_list_from_file
      clear_request_list!
      ::File.open(EXPORT_REQUEST_LIST_PATH).each_line do |line|
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

    def export_request_list!(per: nil, export_format: :file, limit_part_count: nil)
      @exporter = RequestSet::Exporter.new(requests: @request_list.requests,
                                            per: per,
                                            export_format: export_format,
                                            limit_part_count: limit_part_count)
      @exporter.results
    end

    def set_line_parse_block=(block)
      @line_parser_block = block
    end

    private

    def results
      @output_format_instance.to_format
    end

    def add_result(to: , request: , code: nil)
      @thread_list.mutex_synchronize do
        output_format_instance.add_result(to: to, request: request, code: code)
      end
    end

    def output_format_instance
      @output_format_instance ||=
        case @output_format
        when :file
          OutputFormat::File.new
        when :array
          OutputFormat::Array.new
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
