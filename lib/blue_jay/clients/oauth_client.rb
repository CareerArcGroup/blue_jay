
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

    def request_token(options={}, *arguments, &block)
      consumer.get_request_token(options, *arguments, &block)
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
      @consumer ||= OAuth::Consumer.new(consumer_key, consumer_secret, consumer_options).tap { |c| c.http.set_debug_output(output) }
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
    end

    def consumer_options
      options.select {|k,v| CONSUMER_OPTIONS.include? k}
    end

    # when we build a request, sign it with the access token...
    def build_request(method, uri, body='', headers={})
      super.tap {|r| access_token.sign! r}
    end

    def transform_body(body)
      if body.is_a?(Hash)
        OAuth::Helper.normalize(body)
      else
        body.to_s
      end
    end

  end
end
