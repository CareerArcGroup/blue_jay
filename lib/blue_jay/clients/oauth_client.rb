
require 'blue_jay/response'

module BlueJay
  class OAuthClient < Client

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

    def get_core(path, headers={})
      access_token.get(path, headers)
    end

    def post_core(path, body='', headers={})
      access_token.post(path, body, headers)
    end
  end
end
