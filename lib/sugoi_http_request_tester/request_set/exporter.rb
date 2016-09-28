module SugoiHttpRequestTester
  class Export
    def initialize(requests)
      @requests = requests
    end

    def to_array
      sorted_requests.map(&:to_hash)
    end

    # should unlink to tempfile.
    def to_file
      tempfile = Tempfile.new('part_export')
      File.write(tempfile, sorted_requests.map(&:to_json).join("\n"))
      tempfile
    end

    private

    def sorted_requests
      list = []
      sorted_request_list = SortedRequestList.new(@requests)
      @requests.each do
        request = sorted_request_list.pop
        list << request if request
      end
      list
    end
  end

  class RequestSet::Exporter
    def initialize(requests: , export_format: nil)
      @requests = requests
      @export_format = export_format
    end

    def export!
      export = Export.new(@requests)
      case @export_format
      when :file
        export.to_file
      when :array
        export.to_array
      else
        raise('unkown format')
      end
    end

    private

    def has_per_param?
      !!@per
    end
  end
end
