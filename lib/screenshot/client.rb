module Screenshot
	class Client
          
    API = "http://www.browserstack.com/screenshots"
    AUTH_URI = "http://api.browserstack.com/3"
    
    def initialize(options={})
        options = symbolize_keys options
        unless options[:username] && options[:password]
            raise "Expecting Parameters: username and password in the options Hash!"
        end
        authenticate options, AUTH_URI
        self
    end

    def get_os_and_browsers
        res = http_get_request :extend_uri => "browsers.json"
        parse res
    end
    
    def start_screenshots configHash={}
      res = http_post_request :data => Yajl::Encoder.encode(configHash)
      responseJson = parse res
      responseJson[:job_id]
    end

    def job_complete? job_id
      (job_state job_id) == "done" ? true : false
    end

     def job_state job_id
      res = http_get_request :extend_uri => "#{job_id}.json"
      responseJson = parse res
      responseJson[:state]
    end

    def screenshot_result job_id
      res = http_get_request :extend_uri => "#{job_id}.json"
      responseJson = parse res
      responseJson[:screenshots]
    end
    
    private
    def authenticate options, uri=API
      http_get_request options, uri
    end

    def http_get_request options={}, uri=API
      uri = URI.parse uri if uri.is_a?String
      uri.path = uri.path + "/#{options[:extend_uri].to_s}" if options[:extend_uri].is_a?String
      req = Net::HTTP::Get.new uri.request_uri
      make_request req, options, uri
    end

    def http_post_request options={}, uri=API
      uri = URI.parse uri if uri.is_a?String
      req = Net::HTTP::Post.new uri.request_uri, initheader = {'Content-Type' =>'application/json'}
      req.set_form_data({"data" => options[:data]}) if options[:data].is_a?String
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
        if @authorization.is_a?String
          req["Authorization"] = @authorization
          else
          req.basic_auth options[:username].to_s, options[:password].to_s
          @authorization = req["Authorization"]
        end
        req
    end

    def http_response_code_check res
      case res.code.to_i
        when 200
          res
        when 401
          raise "401 Unauthorized : Authentication Failed!"
        when 422
          raise "Unprocessable entity."
        else
          raise "Unexpected Response Code : "+res.code
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
