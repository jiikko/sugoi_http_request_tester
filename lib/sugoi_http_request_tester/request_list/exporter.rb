module SugoiHttpRequestTester
  class RequestList::Exporter
    def initialize(requests: , per: nil, limit: nil)
      @requests = requests
      @per = per
      @limit = limit # per されたバケットの数
    end

    def export
      if is_per?
        per_export
      else
        bulk_export
      end
    end

    private

    def per_export
    end

    def bulk_export
      File.write(EXPORT_REQUEST_LIST_PATH,
                 @requests.map { |request| request.to_json }.join("\n"))
    end

    def is_per?
      !!@per
    end
  end

end
