module SugoiHttpRequestTester
  class Part
    def initialize(requests, per, limit_part_count)
      @requests = requests
      @per = per
      @limit_part_count = limit_part_count
    end

    def array
      requests_list = []
      sorted_requests = SortedRequestList.new(@requests)
      @limit_part_count.times do
        temp_requests = []
        @per.times do
          request = sorted_requests.pop
          request ? (temp_requests << request.to_hash) : break
        end
        temp_requests.empty? ? break : requests_list << temp_requests
      end
      requests_list
    end

    # should unlink to tempfile.
    def files
      array.map do |requests|
        tempfile = Tempfile.new('part_export')
        File.write(tempfile.path,
                  requests.map { |request| request.to_json }.join("\n"))
        puts tempfile.path # for debug
        tempfile
      end
    end
  end

  class Bulk
    def initialize(requests)
      @requests = requests
    end

    def array
      @requests.map { |request| request.to_json }
    end

    # should unlink to tempfile.
    def files
      tempfile = Tempfile.new('part_export')
      File.write(tempfile, array.join("\n"))
      [tempfile]
    end
  end

  class RequestSet::Exporter
    def initialize(requests: , per: nil, export_format: nil, limit_part_count: nil)
      @requests = requests
      @per = per
      @limit_part_count = limit_part_count || 30
      @export_files = []
      @export_format = export_format
    end

    def results
      export_format_instance =
        if has_per_param?
          Part.new(@requests, @per, @limit_part_count)
        else
          Bulk.new(@requests)
        end
      case @export_format
      when :file
        export_format_instance.files
      when :array
        export_format_instance.array
      else
      end
    end

    private

    def has_per_param?
      !!@per
    end
  end
end
