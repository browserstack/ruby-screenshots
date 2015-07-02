module Screenshot
  AuthenticationError  = Class.new(StandardError)
  InvalidRequest       = Class.new(StandardError)
  ScreenshotNotAllowed = Class.new(StandardError)
  UnexpectedError      = Class.new(StandardError)

  class Client
    API = 'https://www.browserstack.com/screenshots'

    def initialize(options = {})
      options.symbolize_keys!
      unless options[:username] && options[:password]
        fail 'Expecting Parameters: username and password in the options Hash!'
      end
      @authentication = 'Basic ' + Base64.encode64("#{options[:username]}:#{options[:password]}").strip
      self
    end

    def os_and_browsers
      response = http_get_request(extend_uri: 'browsers.json')
      parse(response)
    end

    def generate_screenshots(config_hash = {})
      response = http_post_request(data: Yajl::Encoder.encode(config_hash))
      response_json = parse(response)
      response_json[:job_id]
    end

    def screenshots_done?(job_id)
      screenshots_status(job_id) == 'done'
    end

    def screenshots_status(job_id)
      job_details = fetch_job_details(job_id)
      job_details[:state]
    end

    def screenshots(job_id)
      job_details = fetch_job_details(job_id)
      job_details[:screenshots]
    end

    private

    def http_get_request(options = {}, uri = API)
      uri = URI.parse uri
      uri.path = uri.path + "/#{options[:extend_uri]}" if options[:extend_uri]
      request = Net::HTTP::Get.new uri.request_uri
      make_request(uri, request)
    end

    def http_post_request(options = {}, uri = API)
      uri = URI.parse uri
      request = Net::HTTP::Post.new uri.request_uri, 'Content-Type' => 'application/json'
      request.body = options[:data] if options[:data]
      make_request(uri, request)
    end

    def setup_connection(uri)
      conn = Net::HTTP.new uri.host, uri.port
      conn.use_ssl = uri.scheme == 'https'
      conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
      conn.cert_store = OpenSSL::X509::Store.new
      conn.cert_store.set_default_paths
      conn
    end

    def make_request(uri, request)
      connection = setup_connection(uri)
      add_authentication(request)
      response = connection.request(request)
      http_response_code_check(response)
      response
    end

    def add_authentication(req)
      req['Authorization'] = @authentication
    end

    def http_response_code_check(response)
      error_message = encode(code: response.code, body: response.body)
      case response.code.to_i
      when 200
        response
      when 401
        fail AuthenticationError,  error_message
      when 403
        fail ScreenshotNotAllowed, error_message
      when 422
        fail InvalidRequest,       error_message
      else
        fail UnexpectedError,      error_message
      end
    end

    def fetch_job_details(job_id)
      response = http_get_request(extend_uri: "#{job_id}.json")
      parse(response)
    end

    def parse(response)
      parser = Yajl::Parser.new(symbolize_keys: true)
      parser.parse(response.body)
    end

    def encode(hash)
      Yajl::Encoder.encode(hash)
    end
  end # Client
end # Screenshot
