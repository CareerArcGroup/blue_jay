
require 'blue_jay/response'
require 'net/http/post/multipart'

module BlueJay
  class Client
    attr_reader :options

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      @options = options
    end

    def connected?
      raise NotImplementedError, 'implemented by subclass'
    end

    def authorized?
      raise NotImplementedError, 'implemented by subclass'
    end

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def site
      options[:site]
    end

    def proxy
      options[:proxy]
    end

    def debug?
      options[:debug]
    end

    def path_prefix
      options[:path_prefix]
    end

    protected

    # ============================================================================
    # Simple HTTP methods
    # ============================================================================

    def get(path, params={})
      build_response get_raw(uri_with_query(path,params))
    end

    def get_raw(path, headers={})
      perform_request(:get, "#{path_prefix}#{path}", nil, headers)
    end

    def post(path, body='')
      build_response post_raw(path, body)
    end

    def post_raw(path, body='', headers={})
      perform_request(:post, "#{path_prefix}#{path}", body, headers)
    end

    # ============================================================================
    # Core HTTP methods
    # ============================================================================

    # execute the HTTP request...
    def perform_request(method, path, body, headers={})
      uri = URI.join(site, path)
      add_standard_headers(headers)
      request = build_request(method, uri, body, headers)

      http_start(uri) do |http|
        http.request(request)
      end
    end

    # build the HTTP request object, depending
    # on the method and the content (handle multi-part POSTs)...
    def build_request(method, uri, body='', headers={})
      request = case method
        when :get
          Net::HTTP::Get.new(uri.to_s)
        when :post
          multipart?(body) ?
            Net::HTTP::Post::Multipart.new(uri, to_multipart_params(body)) :
            Net::HTTP::Post.new(uri.to_s).tap do |req|
              req["Content-Type"] ||= "application/x-www-form-urlencoded"
              req.body = transform_body(body)
            end
        else
          raise ArgumentError, "Unsupported method '#{method}'"
        end

      headers.each { |key,value| request[key] = value }
      request
    end

    # build the HTTP object...
    def http_start(uri, &block)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.port == 443)
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.set_debug_output(logger)

      if http.use_ssl?
        # use the system's built-in certificates
        http.cert_store = OpenSSL::X509::Store.new
        http.cert_store.set_default_paths
      end

      http.start(&block)
    end

    # add blue_jay standard headers...
    def add_standard_headers(headers={})
      headers.merge!("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
    end

    # build a URI with a query string based on the
    # provided hash of query key-value pairs...
    def uri_with_query(url, query={})
      uri = URI.parse(url)
      base_query = uri.query != nil ? URI.decode_www_form(uri.query) : []
      addl_query = Hash[query.map{|k,v| [k.to_s,v]}]
      new_query = Hash[*base_query.flatten].merge(addl_query)
      uri.query = URI.encode_www_form(new_query.to_a)
      uri.to_s
    end

    def transform_body(body)
      body.is_a?(Hash) ? URI.encode_www_form(body) : body
      #body
    end

    # ============================================================================
    # Response handling
    # ============================================================================

    def build_response(raw_data, options={})
      response = BlueJay::Response.new(raw_data, response_parser, options)
      response.successful? ? logger.debug(response) : logger.warn(response)
      response
    end

    def response_parser
      raise NotImplementedError, 'implemented by subclass'
    end

    # ============================================================================
    # Multi-part support methods
    # ============================================================================

    def multipart?(content)
      content.is_a?(Hash) && content.values.any? {|v| v.respond_to?(:to_io) || v.is_a?(UploadIO)}
    end

    def to_multipart_params(content)
      params = content.map {|k,v| [k, to_multipart_value(v)]}.flatten
      Hash[*params]
    end

    def to_multipart_value(value)
      return value unless value.respond_to?(:to_io) && value.respond_to?(:path)
      mime_type = BlueJay::MIME.mime_type_for(value.path)
      UploadIO.new(value, mime_type)
    end

    # ============================================================================
    # Logging
    # ============================================================================

    def logger
      @logger ||= LoggerWrapper.new(options[:logger] || default_logger)
    end

    def log_raw_response(message, response, severity=Logger::WARN)
      logger.add(severity) { message + ": " + build_response(response, :raw_data => true).to_s }
    end

    def default_logger
      log = Logger.new(STDOUT)
      log.level = debug? ? Logger::DEBUG : Logger::WARN
      log
    end
  end
end
