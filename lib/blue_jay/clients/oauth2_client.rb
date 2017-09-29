
require 'oauth2'
require 'blue_jay/response'
require 'securerandom'

module BlueJay
  class OAuth2Client < Client

    # filter sensitive data out of all requests...
    # some of these should never appear in the request anyway,
    # but they're listed here just to be safe...
    filtered_attributes :client_id, :client_secret, :token

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      @options = options
    end

    def authorize_url(redirect_uri, options={})
      oauth_client.auth_code.authorize_url(options.merge(redirect_uri: redirect_uri))
    end

    def authorize(code, redirect_uri, options={})
      @access_token = oauth_client.auth_code.get_token(code, options.merge(redirect_uri: redirect_uri))
      @token = @access_token.token
      @access_token
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

    def token
      @token ||= options[:token]
    end

    # ============================================================================
    # Private Methods
    # ============================================================================

    protected

    OAUTH_CLIENT_OPTIONS = [:site, :redirect_uri, :authorize_url, :token_url, :token_method, :auth_scheme, :connection_opts, :max_redirects, :raise_errors]
    ACCESS_TOKEN_OPTIONS = [:refresh_token, :expires_in, :expires_at, :mode, :header_format, :param_name]

    def oauth_client
      @oauth_client ||= OAuth2::Client.new(client_id, client_secret, oauth_client_options)
    end

    def access_token
      @access_token ||= OAuth2::AccessToken.new(oauth_client, token, access_token_options)
    end

    def oauth_client_options
      options.select {|k,v| OAUTH_CLIENT_OPTIONS.include? k}
    end

    def access_token_options
      options.select {|k,v| ACCESS_TOKEN_OPTIONS.include? k}
    end

    # when we build a request, sign it with the access token...
    def build_request(request)
      super.tap {|r| access_token.headers.each { |h,v| r[h] = v } }
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
