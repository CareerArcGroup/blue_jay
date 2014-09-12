
require 'blue_jay/response'

module BlueJay
  class Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      @options = options
    end

    def authorize(token, secret, options={})
      request_token = OAuth::RequestToken.new(consumer, token, secret)
      @access_token = request_token.get_access_token(options)
      @token = @access_token.token
      @secret = @access_token.secret
      @access_token
    end

    def connected?
      raise NotImplementedError, 'implemented by subclass'
    end

    def authorized?
      raise NotImplementedError, 'implemented by subclass'
    end

    def request_token(options={})
      consumer.get_request_token(options)
    end

    def authentication_request_token(options={})
      request_token(options)
    end   

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def consumer_key
    	options[:consumer_key]
    end

    def consumer_secret
    	options[:consumer_secret]
    end

    def token
    	@token ||= options[:token]
    end

    def secret
    	@secret ||= options[:secret]
    end

    def proxy
    	options[:proxy]
    end

    def debug?
    	options[:debug]
    end

    def path_prefix
    	options[:path_prefix]
    end

    # ============================================================================
    # Private Methods
    # ============================================================================

    protected

    CONSUMER_OPTIONS = [:site, :authorize_path, :request_token_path, :access_token_path, :request_endpoint]

    def consumer
      @consumer ||= OAuth::Consumer.new(consumer_key, consumer_secret, consumer_options)
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
    end

    def consumer_options
    	options.select {|k,v| CONSUMER_OPTIONS.include? k}
    end

    def get(path)
      build_response get_raw(path)
    end

    def get_raw(path, headers={})
      add_standard_headers(headers)
      puts "BlueJay => GET #{consumer.uri}/#{path} #{headers}" if debug?
      access_token.get("/#{path_prefix}#{path}", headers)
    end

    def post(path, body='')
      build_response post_raw(path, body, headers)
    end

    def post_raw(path, body='', headers={})
      add_standard_headers(headers)
      puts "BlueJay => POST #{consumer.uri}/#{path} #{headers} BODY: #{body}" if debug?
      access_token.post("/#{path_prefix}#{path}", body, headers)
    end

    def add_standard_headers(headers={})
      headers.merge!("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
    end

    def options_to_args(options={})
      return "" if options.nil? || options.length == 0
      "?" + options.map{|k,v| "#{k}=#{v}"}.join('&')
    end

    def response_parser
    	raise NotImplementedError, 'implemented by subclass'
    end

    def build_response(raw_data, options={})
    	BlueJay::Response.new(raw_data, response_parser, options.merge(:debug => debug?))
    end

    def options
    	@options
    end

  end
end
