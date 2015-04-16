
require 'blue_jay/exceptions/rate_limit_exception'

module BlueJay
  class Response

    def initialize(response, parser, options={})
      @parser = parser
      @options = options

      parse_response(response)

      raise RateLimitException if rate_limited?
    end

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def successful?; @successful end
    def successful=(val); @successful=val end
    def data; @data end
    def data=(val); @data=val end
    def errors; @errors end
    def errors=(val); @errors=val end
    def status; @status end
    def status=(val); @status=val end
    def rate_limited?; @rate_limited end
    def rate_limited=(val); @rate_limited=val end
    def rate_limit; @rate_limit end
    def rate_limit=(val); @rate_limit=val end
    def rate_limit_remaining; @rate_limit_remaining end
    def rate_limit_remaining=(val); @rate_limit_remaining=val end
    def rate_limit_reset_time; @rate_limit_reset_time end
    def rate_limit_reset_time=(val); @rate_limit_reset_time=val end

    def raw_data?
      options[:raw_data]
    end

    def debug?
      options[:debug]
    end

    # ============================================================================
    # Misc and Private Methods
    # ============================================================================

    def method_missing(method, *args, &block)
      @data.send(method, *args)
    end

    private

    def parse_response(response)
      @parser.parse_response(self, response)
      puts "BlueJay => #{response.inspect}" if debug?
      puts "  #{status}: #{errors.inspect}\n\t#{response.body}" if debug? && !successful?
    end

    def options
      @options
    end

  end
end