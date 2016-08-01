# 1つのperにパラメータ違いの似たURLが固まらないようにバラす

module SugoiHttpRequestTester
  class SortedRequestList
    def initialize(requests)
      @paths_list = group_by_path(requests.dup).values
      @index = 0
    end

    def pop
      item = @paths_list[@index] && @paths_list[@index].pop
      @paths_list.delete_if { |list| list.size == 0 }
      @index = @index + 1
      if @paths_list[@index].nil?
        @index = 0
      end
      item
    end

    private

    def group_by_path(requests)
      requests.group_by do |request|
        request.path =~ %r!([\w\d\-_]+)!
        $1
      end
    end
  end
end
