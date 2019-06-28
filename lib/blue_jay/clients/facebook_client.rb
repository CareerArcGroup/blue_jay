# frozen_string_literal: true

require 'openssl'

module BlueJay
  class FacebookClient < Client
    LONG_TOKEN_EXPIRES_IN = 5_184_000 # 60 days
    ME_EDGE = 'me'

    filtered_attributes :client_id, :client_secret, :access_token, :appsecret_proof

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options = {})
      options[:site] ||= 'https://graph.facebook.com'
      options[:path_prefix] ||= '/v3.0'
      super(options)
    end

    def authorize_url(redirect_uri, options = {})
      uri_with_query('https://www.facebook.com/v3.0/dialog/oauth', options.merge(client_id: client_id, redirect_uri: redirect_uri))
    end

    def authorize(code, redirect_uri, options = {})
      access_token_request(options.merge(redirect_uri: redirect_uri, code: code))
    end

    def exchange_access_token(options = {})
      access_token_request(options.merge(grant_type: 'fb_exchange_token', fb_exchange_token: access_token))
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    def graph_query(path, query = {})
      get(path, query)
    end

    def debug_token
      get('/debug_token', input_token: access_token, access_token: [client_id, client_secret].join('|'))
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
      [client_id, client_secret].join('|') if options[:app_client]
    end

    def access_token
      @access_token ||= options[:access_token] || options[:token] || app_access_token
    end

    def access_token_expires_at
      @access_token_expires_at ||= begin
        return nil unless access_token

        token_response = debug_token

        return nil unless token_response.successful?

        token_info = token_response.data['data']
        expires_at = token_info['expires_at'] || 0
        expires_at.positive? ? Time.at(expires_at) : (Time.now + LONG_TOKEN_EXPIRES_IN)
      end
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================
    def account_info(options = {})
      edge_info('me', options)
    end

    def edge_info(edge, options = {})
      get("/#{edge}", options)
    end

    def share(options = {})
      edge = extract_edge!(options)
      options[:attached_media] = options[:attached_media].inject([]) do |memo, media_fbid|
        memo << { "media_fbid" => media_fbid }
      end if options[:attached_media]

      post("/#{edge}/feed", options)
    end

    # ============================================================================
    # Facebook Jobs Methods
    # ============================================================================

    def job_application(id)
      options = { fields: "name,email,city_name,created_time,custom_responses,resume_url,education_experiences{school,area_of_study,start,end,graduated},work_experiences{company,position,current,start,end},phone_number" }
      get("/#{id}", options)
    end

    def job_applications(external_job_id)
      get("/#{external_job_id}/job_applications")
    end

    # ============================================================================
    # Photo Methods
    # ============================================================================

    def create_album(name, options = {})
      edge = extract_edge!(options)
      post("/#{edge}/albums", options.merge(name: name))
    end

    def albums(options = {})
      edge = extract_edge!(options)
      get("/#{edge}/albums", options)
    end

    def upload_photo(image_or_url, options = {})
      edge    = extract_edge!(options)
      options = multipart?(item: image_or_url) ?
        options.merge(source: image_or_url) :
        options.merge(url: image_or_url)

      post("/#{edge}/photos", options)
    end

    # ============================================================================
    # Page Methods
    # ============================================================================

    def page_access_token(page_id)
      get("/#{page_id}", fields: 'access_token')
    end

    def create_tab(page_id, options = {})
      post("/#{page_id}/tabs", options)
    end

    protected

    def extract_edge!(options = {})
      options.delete(:edge) || options.delete(:user_id) || options.delete(:page_id) || options.delete(:album_id) || options.delete(:object_id) || ME_EDGE
    end

    def access_token_request(options = {})
      response = get('/oauth/access_token', options.merge(client_id: client_id, client_secret: client_secret))

      @access_token = response.data['access_token'] if response.successful?

      response.successful?
    rescue StandardError
      false
    end

    def appsecret_proof
      @appsecret_proof ||= generate_appsecret_proof(access_token)
    end

    def generate_appsecret_proof(token)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), client_secret, token) if token
    end

    def get(path, params = {})
      params[:access_token]    ||= access_token
      params[:appsecret_proof] ||= generate_appsecret_proof(params[:access_token])
      super
    end

    def post(path, params = {})
      params[:access_token]    ||= access_token
      params[:appsecret_proof] ||= generate_appsecret_proof(params[:access_token])
      super
    end

    def transform_body(body)
      # transform array-valued parameters to follow convention.
      # for example, a body of { attached_media: [123, 456] } should
      # be treated as { attached_media[0]: 123, attached_media[1]: 456 }
      body = if body.is_a?(Hash)
               body.inject({}) do |memo, (key, value)|
                 if value.is_a?(Array)
                   value.each_with_index { |v, index| memo.update("#{key}[#{index}]" => transform_value(v)) }
                   memo
                 else
                   memo.update(key => transform_value(value))
                 end
               end
             else
               transform_value(body)
             end

      URI.encode_www_form(body)
    end

    def transform_value(value)
      case value
      when Hash  then value.inject({}) { |memo, (k, v)| memo.update(k => transform_value(v)) }.to_json
      when Array then value.inject([]) { |memo, v| memo << transform_value(v) }.to_json
      else value
      end
    end

    def response_parser
      BlueJay::FacebookParser
    end
  end
end
