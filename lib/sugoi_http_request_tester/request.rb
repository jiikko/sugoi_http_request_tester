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

    def run(host: , basic_auth: nil)
      if /GET/ =~ method
        Net::HTTP.start(host) do |http|
          req = Net::HTTP::Get.new(path)
          req.add_field('User-Agent', user_agent) unless user_agent.nil?
          req.basic_auth *basic_auth unless basic_auth.nil?
          response = http.request(req)
          { to: :accessed_list, request: self, code: response.code }
        end
      else
        { to: :manual_list, request: self }
      end
    end
  end
end
