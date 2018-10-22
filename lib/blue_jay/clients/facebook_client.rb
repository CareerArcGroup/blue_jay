
require 'openssl'

module BlueJay
  class FacebookClient < Client

    LONG_TOKEN_EXPIRES_IN = 5184000   # 60 days

    filtered_attributes :client_id, :client_secret, :access_token, :appsecret_proof

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://graph.facebook.com'
      options[:path_prefix] ||= '/v2.10'
      super(options)
    end

    def authorize_url(redirect_uri, options={})
      uri_with_query("https://www.facebook.com/v2.10/dialog/oauth", options.merge(
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
      response = get("/debug_token",
        input_token: access_token,
        access_token: [client_id, client_secret].join("|"))
    end

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def client_id
      options[:client_id] || options[:consumer_key]
    end

    def client_secret
      options[:client_secret] || options[:consumer_secret]
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

        token_response = debug_token

        return nil unless token_response.successful?

        token_info = token_response.data["data"]
        expires_at = token_info["expires_at"] || 0
        expires_at && expires_at > 0 ? Time.at(expires_at) : (Time.now + LONG_TOKEN_EXPIRES_IN)
      end
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    def account_info(options={})
      get('/me', options)
    end

    def share(options={})
      post('/me/feed', options)
    end

    # ============================================================================
    # Photo Methods
    # ============================================================================

    def create_album(name, options={})
      post('/me/albums', options.merge(name: name))
    end

    def albums(options={})
      get('/me/albums', options)
    end

    def upload_photo(image_or_url, options={})
      album_id = options.delete(:album_id)
      options = multipart?(item: image_or_url) ?
        options.merge(source: image_or_url) :
        options.merge(url: image_or_url)

      post("/#{album_id}/photos", options)
    end

    # ============================================================================
    # Page Methods
    # ============================================================================

    def page_access_token(page_id)
      get("/#{page_id}", fields: "access_token")
    end

    def create_tab(page_id, options={})
      post("/#{page_id}/tabs", options)
    end

    protected

    def access_token_request(options={})
      begin
        response = get("/oauth/access_token", options.merge(client_id: client_id, client_secret: client_secret))

        if response.successful?
          @access_token = response.data["access_token"]
        end

        response.successful?
      rescue
        false
      end
    end

    def appsecret_proof
      @appsecret_proof ||= generate_appsecret_proof(access_token)
    end

    def generate_appsecret_proof(token)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), client_secret, token) if token
    end

    def get(path, params={})
      params[:access_token]    ||= access_token
      params[:appsecret_proof] ||= generate_appsecret_proof(params[:access_token])
      super
    end

    def post(path, params={})
      params[:access_token]    ||= access_token
      params[:appsecret_proof] ||= generate_appsecret_proof(params[:access_token])
      super
    end

    def transform_body(body)
      URI.encode_www_form(body)
    end

    def response_parser
      BlueJay::FacebookParser
    end
  end
end
