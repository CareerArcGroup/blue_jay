
require 'blue_jay/response'

module BlueJay
  class Client

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

    # ============================================================================
    # Private Methods
    # ============================================================================

    protected

    def get(path, params={})
      build_response get_raw(uri_with_query(path,params))
    end

    def get_raw(path, headers={})
      add_standard_headers(headers)
      get_core("#{path_prefix}#{path}", headers)
    end

    def get_core(path, headers={})
      uri = URI.join(site, path)
      request = Net::HTTP::Get.new(uri.to_s)
      headers.each {|key,value| request[key] = value}

      http_start(uri) do |http|
        http.request(request)
      end
    end

    def post(path, body='')
      build_response post_raw(path, body)
    end

    def post_raw(path, body='', headers={})
      add_standard_headers(headers)
      post_core("#{path_prefix}#{path}", transform_body(body), headers)
    end

    def post_core(path, body='', headers={})
      uri = URI.join(site, path)
      request = Net::HTTP::Post.new(uri.to_s)
      headers.each {|key,value| request[key] = value}
      request.body = body

      http_start(uri) do |http|
        http.request(request)
      end
    end

    def http_start(uri, &block)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.port == 443)
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.set_debug_output($stdout) if debug?

      if http.use_ssl?
        # use the system's built-in certificates
        http.cert_store = OpenSSL::X509::Store.new
        http.cert_store.set_default_paths
      end

      http.start(&block)
    end

    def add_standard_headers(headers={})
      headers.merge!("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
    end

    def uri_with_query(url, query={})
      uri = URI.parse(url)
      base_query = uri.query != nil ? URI.decode_www_form(uri.query) : []
      addl_query = Hash[query.map{|k,v| [k.to_s,v]}]
      new_query = Hash[*base_query.flatten].merge(addl_query)
      uri.query = URI.encode_www_form(new_query.to_a)
      uri.to_s
    end

    def transform_body(body)
      body
    end

    def response_parser
      raise NotImplementedError, 'implemented by subclass'
    end

    def build_response(raw_data, options={})
      BlueJay::Response.new(raw_data, response_parser, options.merge(:debug => debug?))
    end

    def options
      @options
    end

  end
end
