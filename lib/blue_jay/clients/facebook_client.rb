
module BlueJay
  class FacebookClient < Client

    LONG_TOKEN_EXPIRES_IN = 5184000   # 60 days

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://graph.facebook.com'
      options[:path_prefix] ||= '/v2.0'
      super(options)
    end

    def authorize_url(redirect_uri, options={})
      uri_with_query("https://www.facebook.com/v2.0/dialog/oauth", options.merge(
        client_id: client_id,
        redirect_uri: redirect_uri
      ))
    end

    def authorize(code, redirect_uri, options={})
      access_token_request(options.merge(redirect_uri: redirect_uri, code: code))
    end

    def exchange_access_token(options={})
      access_token_request(options.merge(grant_type: "fb_exchange_token", fb_exchange_token: access_token))
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    def graph_query(path, query={})
      get(path, query)
    end

    def debug_token
      response = get_raw(uri_with_query("/debug_token",
        input_token: access_token,
        access_token: [client_id, client_secret].join("|")))

      if response && response.kind_of?(Net::HTTPSuccess)
        data_wrapper = JSON.parse(response.body)
        data_wrapper["data"]
      else
        logger.error("BlueJay: Unable to debug token '#{access_token}', API response: #{response.inspect}")
        nil
      end
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

    def app_access_token
      [client_id, client_secret].join("|") if options[:app_client]
    end

    def access_token
      @access_token ||= options[:access_token] || options[:token] || app_access_token
    end

    def access_token_expires_at
      @access_token_expires_at ||= begin
        return nil unless access_token
        return nil unless (token_info = debug_token)

        expires_at = token_info["expires_at"] || 0
        expires_at && expires_at > 0 ? Time.at(expires_at) : (Time.now + LONG_TOKEN_EXPIRES_IN)
      end
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

    def access_token_request(options={})
      begin
        response = get_raw(uri_with_query("/oauth/access_token", options.merge(
          client_id: client_id,
          client_secret: client_secret
        )))

        success = response.is_a? Net::HTTPSuccess

        if success
          @access_token = response.body.split('=').last if success
          @access_token_expires_at = nil
        else
          log_raw_response("Failed to retrieve access token", response)
        end

        success
      rescue
        false
      end
    end

    def get(path, params={})
      super(path, params.merge(access_token: access_token))
    end

    def post(path, params={})
      super(path, params.merge(access_token: access_token))
    end

    def transform_body(body)
      URI.encode_www_form(body)
    end

    def response_parser
      BlueJay::FacebookParser
    end

  end
end
