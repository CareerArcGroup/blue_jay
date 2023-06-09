
require 'logger'
require 'blue_jay/request'
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

    def path_prefix
      options[:path_prefix]
    end

    def pretend?
      options[:pretend]
    end

    protected

    # ============================================================================
    # Simple HTTP methods
    # ============================================================================

    def get(path, params={}, headers={})
      perform_request(:get, uri_with_query(path, params), '', headers)
    end

    def post(path, body='', headers={})
      update_runtime_terms(body) if body.is_a?(Hash)
      perform_request(:post, path, body, headers)
    end

    def put(path, body='', headers={})
      update_runtime_terms(body) if body.is_a?(Hash)
      perform_request(:put, path, body, headers)
    end

    def delete(path, params={}, headers={})
      perform_request(:delete, uri_with_query(path, params), '', headers)
    end

    # ============================================================================
    # Core HTTP methods
    # ============================================================================

    # execute the HTTP request...
    def perform_request(method, path, body='', headers={})
      return BlueJay::Response::Pretend.new if pretend?

      uri     = path.blank? || path.start_with?('/') ? URI.join(site, "#{path_prefix}#{path}") : URI.parse(path)
      request = BlueJay::Request.new(method, uri, body, add_standard_headers(headers))
      trace   = BlueJay::Trace.begin(request, filtered_terms)

      http_logger.reset!

      http_request = build_request(request)
      http_response = http_start(uri) do |http|
        http.request(http_request)
      end

      response = BlueJay::Response.new(trace.id, http_response, response_parser)

      trace.complete_request(response)
      trace.log = http_logger.read

      # log the response based on success
      response.successful? ? logger.debug(trace) : logger.warn(trace)

      response
    end

    # build the HTTP request object, depending
    # on the method and the content (handle multi-part POSTs)...
    def build_request(request)
      request_uri = request.uri.request_uri
      http_request = case request.method
        when :get
          Net::HTTP::Get.new(request_uri)
        when :delete
          Net::HTTP::Delete.new(request_uri)
        when :post
          multipart?(request.body) ?
            Net::HTTP::Post::Multipart.new(request_uri, to_multipart_params(request.body)) :
            Net::HTTP::Post.new(request_uri).tap do |req|
              req["Content-Type"] ||= "application/x-www-form-urlencoded"
              req.body = transform_body(request.body)
            end
        when :put
          multipart?(request.body) ?
            Net::HTTP::Put::Multipart.new(request_uri, to_multipart_params(request.body)) :
            Net::HTTP::Put.new(request_uri).tap do |req|
              if request.body.respond_to?(:to_io) || request.body.is_a?(UploadIO)
                request.headers['Content-Type'] = if request.body.respond_to?(:content_type)
                  request.body.content_type
                elsif request.body.respond_to?(:path)
                  Voyager::MIME.mime_type_for(request.body.path)
                else
                  "application/octet-stream"
                end

                request.headers['Content-Length'] = request.body.size

                req.body_stream = request.body
              else
                req.body = transform_body(request.body)
              end
            end
        else
          raise ArgumentError, "Unsupported method '#{request.method}'"
        end

      request.headers['Content-Type'] = http_request['Content-Type'] if multipart?(request.body)
      request.headers.each { |key,value| http_request[key] = value }

      http_request
    end

    # build the HTTP object...
    def http_start(uri, &block)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.port == 443)
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.set_debug_output(http_logger)

      if http.use_ssl?
        # use the system's built-in certificates
        http.cert_store = OpenSSL::X509::Store.new
        http.cert_store.set_default_paths
      end

      http.start(&block)
    end

    # add blue_jay standard headers...
    def add_standard_headers(headers={})
      headers.merge("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
    end

    # build a URI with a query string based on the
    # provided hash of query key-value pairs...
    def uri_with_query(url, query={})
      uri = URI.parse(url)

      # build combined query from base url
      # along with any addition query in hash...
      base_query = uri.query != nil ? URI.decode_www_form(uri.query) : []
      addl_query = Hash[query.map{|k,v| [k.to_s,v]}]
      new_query  = Hash[*base_query.flatten].merge(addl_query)

      # add query values to runtime filtered terms...
      update_runtime_terms(new_query)

      # build the final uri
      uri.query = URI.encode_www_form(new_query.to_a)
      uri.to_s
    end

    def transform_body(body)
      body
    end

    # ============================================================================
    # Response handling
    # ============================================================================

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
    # Logging/tracing
    # ============================================================================

    class << self
      def filtered_attributes(*attributes)
        @filtered_attributes ||= []
        @filtered_attributes.concat(attributes) if attributes
      end

      def inherited(subclass)
        subclass.filtered_attributes(*filtered_attributes)
      end
    end

    def runtime_filtered_terms
      @runtime_filtered_terms ||= {}
    end

    def update_runtime_terms(terms)
      filtered_keys = self.class.filtered_attributes.map(&:to_s)

      terms.each do |term, value|
        if filtered_keys.include?(term.to_s)
          runtime_filtered_terms.update(term.to_sym => value)
        end
      end
    end

    def filtered_terms
      self.class.filtered_attributes.map do |term|
        runtime_filtered_terms.fetch(term, self.send(term))
      end.compact
    end

    def http_logger
      @http_logger ||= BlueJay::Logging::HttpLogger.new
    end

    def logger
      @logger ||= (options[:logger] || BlueJay.logger)
    end
  end
end
