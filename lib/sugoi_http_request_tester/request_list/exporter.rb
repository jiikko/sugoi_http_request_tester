module SugoiHttpRequestTester
  class RequestList::Exporter
    def initialize(requests: , per: nil, limit_part_files_count: nil)
      @requests = requests
      @per = per
      @limit_part_files_count = limit_part_files_count || 30
      @export_files = []
    end

    def export
      if has_per_param?
        per_export
      else
        bulk_export
      end
      @export_done = true
    end

    def export_files
      if @export_done
        @export_files
      else
        raise 'not excute export yet'
      end
    end

    private

    def per_export
      requests_list = []
      @limit_part_files_count.times do
        requests = []
        @per.times do
          request = requests.pop
          request ? (requests << request) : break
        end
        requests.empty? ? break : requests_list << requests
      end
      @export_files = requests_list.map do |requests|
        tempfile = Tempfile.new('per_export')
        File.wrie(tempfile.path,
                  requests.map { |request| request.to_json }.join("\n"))
        puts tempfile.path
        tempfile
      end
    end

    def bulk_export
      File.write(EXPORT_REQUEST_LIST_PATH, @requests.map { |request| request.to_json }.join("\n"))
      file = File.open(EXPORT_REQUEST_LIST_PATH, 'r')
      @export_files << file
    end

    def has_per_param?
      !!@per
    end
  end
end
