module SugoiHttpRequestTester
  class Request
    attr_accessor :method, :user_agent, :path

    def initialize(method: , user_agent: , path: )
      @method = method
      @user_agent = user_agent
      @path = path
    end

    def hash
      Digest::MD5.hexdigest([@method, @user_agent, @path].join)
    end

    def to_json
      { method: @method,
        user_agent: @user_agent,
        path: @path,
        mt: @method,
        ua: @user_agent,
        pt: @path,
      }.to_json
    end
  end
end
