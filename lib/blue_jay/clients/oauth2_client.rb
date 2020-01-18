# frozen_string_literal: true

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

    def initialize(options = {})
      @options = options
    end

    def authorize_url(redirect_uri, options = {})
      oauth_client.auth_code.authorize_url(options.merge(redirect_uri: redirect_uri))
    end

    def authorize(code, redirect_uri, options = {})
      @access_token = oauth_client.auth_code.get_token(code, options.merge(redirect_uri: redirect_uri, mode: token_mode))
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

    def token_mode
      options.fetch(:token_mode, :header)
    end

    # ============================================================================
    # Private Methods
    # ============================================================================

    protected

    OAUTH_CLIENT_OPTIONS = %i[site redirect_uri authorize_url token_url token_method auth_scheme connection_opts max_redirects raise_errors].freeze
    ACCESS_TOKEN_OPTIONS = %i[refresh_token expires_in expires_at mode header_format param_name].freeze

    def oauth_client
      @oauth_client ||= OAuth2::Client.new(client_id, client_secret, oauth_client_options)
    end

    def access_token
      @access_token ||= OAuth2::AccessToken.new(oauth_client, token, access_token_options)
    end

    def oauth_client_options
      options.select { |k, _v| OAUTH_CLIENT_OPTIONS.include? k }.merge(common_options)
    end

    def access_token_options
      options.select { |k, _v| ACCESS_TOKEN_OPTIONS.include? k }.merge(common_options)
    end

    def common_options
      { connection_build: method(:build_connection) }
    end

    # when we build a request, sign it with the access token...
    def build_request(request)
      super.tap { |r| access_token.headers.each { |h, v| r[h] = v } }
    end

    def build_connection(builder)
      builder.request :url_encoded
      builder.use FilteredLogger, logger, filtered_terms
      builder.adapter Faraday.default_adapter
    end

    def transform_body(body)
      if body.is_a?(Hash)
        OAuth::Helper.normalize(body)
      else
        body.to_s
      end
    end

    class FilteredLogger < Faraday::Response::Logger
      def initialize(app, logger, filtered_terms)
        @actual_logger = logger
        @filtered_terms = filtered_terms

        super(app, BlueJay::Logging::HttpLogger.new, bodies: true, headers: true)
      end

      def call(env)
        @logger.reset!
        super
      end

      def on_complete(env)
        super

        message = BlueJay::Trace.filter(@logger.read, @filtered_terms)

        if env.response.success?
          @actual_logger.debug(message)
        else
          @actual_logger.warn(message)
        end
      end
    end
    private_constant :FilteredLogger
  end
end
