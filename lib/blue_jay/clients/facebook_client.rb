
module BlueJay
  class FacebookClient < Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://graph.facebook.com'      
      super(options)
    end

    def authorize_url(redirect_uri, options={})
      uri_with_query("https://www.facebook.com/dialog/oauth", options.merge(
        client_id: client_id,
        redirect_uri: redirect_uri
      ))
    end

    def authorize(code, redirect_uri, options={})
      begin
        response = get_raw(uri_with_query("/oauth/access_token", options.merge(
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          code: code
        )))

        success = response.is_a? Net::HTTPSuccess

        if success
          @access_token, expires_in = response.body.split('&').map {|p| p.split('=').last}
          @access_token_expires_at = Time.now + expires_in.to_i
        end

        success
      rescue
        false
      end
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def client_id
      options[:client_id]
    end

    def client_secret
      options[:client_secret]
    end

    def access_token
      @access_token ||= options[:access_token] || options[:token]
    end

    def access_token_expires_at
      @access_token_expires_at
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    def account_info()
      get('/me')
    end

    def share(options = {})
      post('/me/feed', options)
    end

    protected

    def get(path)
      super(path, access_token: access_token)
    end

    def post(path, params = {})
      super(path, params.merge!(access_token: access_token))
    end

    def transform_body(body)
      URI.encode_www_form(body)
    end

    def response_parser
      BlueJay::FacebookParser
    end

  end
end
