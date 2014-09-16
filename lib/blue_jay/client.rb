
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
      build_response get_raw(path)
    end

    def get_raw(path, headers={})
      add_standard_headers(headers)
      puts "BlueJay => GET #{site}#{path_prefix}#{path} #{headers}" if debug?
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
      puts "BlueJay => POST #{site}#{path_prefix}#{path} #{headers} BODY: #{transform_body(body)}" if debug?
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
      http.start(&block)
    end

    def add_standard_headers(headers={})
      headers.merge!("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
    end

    def options_to_args(options={})
      return "" if options.nil? || options.length == 0
      "?" + options.map{|k,v| "#{k}=#{v}"}.join('&')
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
