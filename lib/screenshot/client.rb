module Screenshot
	class Client

    API = "https://www.browserstack.com/screenshots"

    # Allowlist for job IDs accepted by screenshots_status/screenshots.
    # Alphanumeric, underscore, and hyphen only — blocks path traversal,
    # CRLF injection, and other URL-path tampering before the value is
    # interpolated into the API request path.
    JOB_ID_FORMAT = /\A[\w\-]{1,64}\z/

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
      validate_job_id! job_id
      res = http_get_request :extend_uri => "#{job_id}.json"
      responseJson = parse res
      responseJson[:state]
    end

    def screenshots job_id
      validate_job_id! job_id
      res = http_get_request :extend_uri => "#{job_id}.json"
      responseJson = parse res
      responseJson[:screenshots]
    end

    # Redact @authentication when the receiver is serialised — APM/error
    # trackers (Sentry, Bugsnag, Datadog) capture the receiver's inspect
    # output alongside exception frames, which would otherwise leak the
    # reversible Base64-encoded Basic Auth credential.
    def inspect
      "#<#{self.class.name}:0x#{(object_id << 1).to_s(16)} @authentication=[REDACTED]>"
    end
    alias_method :to_s, :inspect

    private
    def validate_job_id!(job_id)
      unless job_id.is_a?(String) && job_id =~ JOB_ID_FORMAT
        raise ArgumentError, "Invalid job_id: must match #{JOB_ID_FORMAT.source}"
      end
    end

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
      conn.use_ssl = uri.scheme == 'https'
      conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
      conn.cert_store = OpenSSL::X509::Store.new
      conn.cert_store.set_default_paths
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
        raise AuthenticationError.new("BrowserStack API responded #{res.code}", res.body)
      when 403
        raise ScreenshotNotAllowedError.new("BrowserStack API responded #{res.code}", res.body)
      when 422
        raise InvalidRequestError.new("BrowserStack API responded #{res.code}", res.body)
      else
        raise UnexpectedError.new("BrowserStack API responded #{res.code}", res.body)
      end
    end

    def parse(response)
      parser = Yajl::Parser.new(:symbolize_keys => true)
      begin
        result = parser.parse(response.body)
      rescue Yajl::ParseError => e
        # Wrap upstream parser errors (non-JSON 200 bodies — HTML
        # maintenance pages, plain text, truncated payloads) so callers
        # see a typed Screenshot::ParseError rather than a yajl-internal
        # exception that doesn't match `rescue Screenshot::*` blocks.
        raise ParseError, "BrowserStack API returned invalid JSON: #{e.message}"
      end
      unless result.is_a?(Hash)
        raise ParseError, "Expected a JSON object from BrowserStack API, got #{result.class}"
      end
      result
    end

    def encode(hash)
      Yajl::Encoder.encode(hash)
    end

    def symbolize_keys hash
      hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

  end #Client

  # Base class for BrowserStack API errors. Carries the raw response body
  # behind an opt-in `#body` reader so callers can inspect it deliberately;
  # the default exception message is a fixed status-code string so that
  # APM/log capture does not auto-ingest the body alongside the receiver's
  # instance variables.
  class APIError < StandardError
    attr_reader :body
    def initialize(message = nil, body = nil)
      super(message)
      @body = body
    end
  end

  class AuthenticationError < APIError
  end

  class InvalidRequestError < APIError
  end

  class ScreenshotNotAllowedError < APIError
  end

  class UnexpectedError < APIError
  end

  class ParseError < StandardError
  end

end #Screenshots
