module SugoiHttpRequestTester
  class Request
    attr_accessor :path

    class << self
      attr_accessor :host, :basic_auth
    end

    def initialize(method: , user_agent: , path: )
      @method = method
      @user_agent = user_agent
      @path = path
    end

    def hash
      Digest::MD5.hexdigest([@method, @user_agent, @path].join)
    end

    def to_hash
      { method: @method,
        user_agent: normalized_user_agent,
        path: @path,
        mt: @method,
        ua: @user_agent,
        pt: @path,
        device_type: user_agent_type,
      }
    end

    def to_json
      to_hash.to_json
    end

    def run
      if /GET/ =~ @method
        Net::HTTP.start(self.class.host) do |http|
          req = Net::HTTP::Get.new(@path)
          req.add_field('User-Agent', normalized_user_agent) unless @user_agent.nil?
          req.basic_auth *self.class.basic_auth unless self.class.basic_auth.nil?
          response = http.request(req)
          { to: :accessed_list, request: self, code: response.code }
        end
      else
        { to: :manual_list, request: self }
      end
    end

    private

    def normalized_user_agent
      { pc: "sugou_http_request_tester #{SugoiHttpRequestTester::VERSION}",
        sp: "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Mobile Safari/537.36 sugou_http_request_tester #{SugoiHttpRequestTester::VERSION}",
      }[user_agent_type]
    end

    def user_agent_type
      if @user_agent =~ /iPhone|Android|Mobile|Windows Phone/
        :sp
      else
        :pc
      end
    end
  end
end
