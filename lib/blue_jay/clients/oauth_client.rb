
require 'blue_jay/response'
require 'net/http/post/multipart'

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
      @consumer ||= begin
        cons = OAuth::Consumer.new(consumer_key, consumer_secret, consumer_options)
        cons.http.set_debug_output($stdout) if debug?
        cons
      end
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
      multipart?(body) ? post_multipart(path, body, headers) : access_token.post(path, body, headers)
    end

    def post_multipart(path, body, headers={})
      uri = URI.join(site, path)
      params = to_multipart_params(body)
      request = Net::HTTP::Post::Multipart.new(path, params)
      headers.each {|key,value| request[key] = value}
      access_token.sign! request

      http_start(uri) do |http|
        http.request(request)
      end
    end

    def multipart?(content)
      content.is_a?(Hash) && content.values.any? {|v| v.respond_to?(:to_io)}
    end

    def to_multipart_params(content)
      params = content.map {|k,v| [k, to_multipart_value(v)]}.flatten
      Hash[*params]
    end

    def to_multipart_value(value)
      return value unless value.respond_to?(:to_io)
      mime_type = case value.path
      when /\.jpe?g/i
        'image/jpeg'
      when /\.gif$/i
        'image/gif'
      when /\.png$/i
        'image/png'
      else
        'application/octet-stream'
      end
      UploadIO.new(value, mime_type)
    end

  end
end
