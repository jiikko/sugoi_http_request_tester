module SugoiHttpRequestTester
  class RequestSet
    extend Forwardable

    def_delegators :@requests, :size, :clear

    def initialize(limit: nil)
      @requests = {}
      if limit.is_a?(Numeric)
        @limit = limit
        @limit_counter = 0
      end
    end

    def <<(request)
      if under_limit?
        @requests[request.hash] = request
        true
      else
        false
      end
    end

    def requests
      @requests.values
    end

    def each(&block)
      @requests.each do |_hash, request|
        yield request
      end
    end

    private

    def under_limit?
      if @limit.is_a?(Numeric)
        @limit_counter += 1
        @limit_counter <= @limit
      else
        true
      end
    end
  end
end
