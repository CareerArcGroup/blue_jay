# frozen_string_literal: true

module BlueJay
  class BitlyClient < OAuth2Client
    def initialize(options = {})
      options[:site]          ||= 'https://api-ssl.bitly.com'
      options[:authorize_url] ||= 'https://bitly.com/oauth/authorize'
      options[:token_url]     ||= 'https://api-ssl.bitly.com/oauth/access_token'
      options[:path_prefix]   ||= '/v4'
      options[:token_mode]    ||= :query

      super(options)
    end

    def authorize_url(redirect_uri, options = {})
      super(redirect_uri, options.merge(client_id: client_id))
    end

    def authorized?
      account_info.successful?
    end

    def account_info
      get('/user')
    end

    def branded_short_domains
      get('/bsds')
    end

    def shorten(long_url, options = {})
      post('/shorten', options.merge(long_url: long_url))
    end

    protected

    def add_standard_headers(headers = {})
      super(headers.merge(
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      ))
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      BlueJay::BitlyParser
    end
  end
end
