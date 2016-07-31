module SugoiHttpRequestTester
  class RequestList::Exporter
    def initialize(requests: , per: nil, limit_part_files_count: nil)
      @requests = requests
      @per = per
      @limit_part_files_count = limit_part_files_count # per されたバケットの数
      @export_paths = []
    end

    def export
      if has_per_param?
        per_export
      else
        bulk_export
      end
      @export_done = true
    end

    def export_paths
      if exported?
        @export_paths
      else
        raise 'not excute export yet'
      end
    end

    private

    def per_export

    end

    def bulk_export
      File.write(EXPORT_REQUEST_LIST_PATH,
                 @requests.map { |request| request.to_json }.join("\n"))
      @export_paths << EXPORT_REQUEST_LIST_PATH
    end

    def has_per_param?
      !!@per
    end

    def exported?
      @export_done
    end
  end
end
