module Screenshot
	class Client
          
    API = "http://www.browserstack.com/screenshots"
    
    def initialize(options={})
      options = symbolize_keys options
      unless options[:username] && options[:password]
        raise "Expecting Parameters: username and password in the options Hash!"
      end
      @authentication = "Basic " + Base64.encode64("#{options[:username]}:#{options[:password]}").strip
      #authenticate options, AUTH_URI
      self
    end

    def get_os_and_browsers
      res = http_get_request :extend_uri => "browsers.json"
      parse res
    end
    
    def generate_screenshots configHash={}
      res = http_post_request :data => Yajl::Encoder.encode(configHash)
      responseJson = parse res
      request = responseJson[:job_id]
    end

    def screenshots_done? job_id
      (screenshots_status job_id) == "done" ? true : false
    end

     def screenshots_status job_id
      res = http_get_request :extend_uri => "#{job_id}.json"
      responseJson = parse res
      responseJson[:state]
    end

    def screenshots job_id
      res = http_get_request :extend_uri => "#{job_id}.json"
      responseJson = parse res
      responseJson[:screenshots]
    end
    
    private
    def authenticate options, uri=API
      http_get_request options, uri
    end

    def http_get_request options={}, uri=API
      uri = URI.parse uri if uri
      uri.path = uri.path + "/#{options[:extend_uri].to_s}" if options[:extend_uri]
      req = Net::HTTP::Get.new uri.request_uri
      make_request req, options, uri
    end

    def http_post_request options={}, uri=API
      uri = URI.parse uri if uri
      req = Net::HTTP::Post.new uri.request_uri, initheader = {'Content-Type' =>'application/json'}
      req.body = options[:data] if options[:data]
      make_request req, options, uri
    end

    def make_request req, options={}, uri=API
      conn = Net::HTTP.new uri.host, uri.port
      add_authentication options, req
      res = conn.request req
      http_response_code_check res
      res
    end
    
    def add_authentication options, req
      req["Authorization"] = @authentication
      req
    end

    def http_response_code_check res
      case res.code.to_i
      when 200
        res
      when 401
        raise "401 Unauthorized : Authentication Failed!"
      when 422
        raise "Unprocessable entity."+"\n Response Body: "+res.body
      else
        raise "Unexpected Response Code : "+res.code+"\n Response Body: "+res.body
      end
    end

    def parse(response)
      parser = Yajl::Parser.new(:symbolize_keys => true)
      parser.parse(response.body)
    end

    def symbolize_keys hash
      hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

  end #Client
end #Screenshots
