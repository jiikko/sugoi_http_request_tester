module SugoiHttpRequestTester
  class Export
    def initialize(requests)
      @requests = requests
    end

    def to_array
      list = []
      sorted_requests = SortedRequestList.new(@requests)
      @requests.each do
        request = sorted_requests.pop
        list << request.to_json if request
      end
      list
    end

    # should unlink to tempfile.
    def to_file
      tempfile = Tempfile.new('part_export')
      File.write(tempfile, to_array.join("\n"))
      tempfile
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
