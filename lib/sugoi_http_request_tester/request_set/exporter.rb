module SugoiHttpRequestTester
  class RequestSet::Exporter
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

    # should unlink to tempfile.
    def per_export
      requests_list = []
      sorted_requests = SortedRequestList.new(@requests)
      @limit_part_files_count.times do
        temp_requests = []
        @per.times do
          request = sorted_requests.pop
          request ? (temp_requests << request) : break
        end
        temp_requests.empty? ? break : requests_list << temp_requests
      end
      @export_files = requests_list.map do |requests|
        tempfile = Tempfile.new('per_export')
        File.write(tempfile.path,
                  requests.map { |request| request.to_json }.join("\n"))
        puts tempfile.path
        tempfile
      end
    end

    # 1つのperにパラメータ違いの似たURLが固まらないようにバラす
    def sort_by_url(requests)
      groued_lis = requests.group_by { |request| request.url =~ %r!([\w\d\-_]+)!; $1 }
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
