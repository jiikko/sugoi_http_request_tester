# 1つのperにパラメータ違いの似たURLが固まらないようにバラす

module SugoiHttpRequestTester
  class SortedRequestList
    def initialize(requests)
      sort!(requests)
      @requests = requests # TODO
    end

    def pop
      @requests.pop
    end

    private

    def sort!(requests)
      @requests = requests.group_by do |request|
        request.path =~ %r!([\w\d\-_]+)!
        $1
      end
    end
  end
end
