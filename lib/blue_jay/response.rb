
require 'blue_jay/exceptions/rate_limit_exception'

module BlueJay
  class Response

    def initialize(response, parser, options={})
      @parser = parser
      @options = options
      @raw_response = response

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

    def raw_response
      @raw_response
    end

    def headers
      raw_response.header
    end

    # ============================================================================
    # Misc and Private Methods
    # ============================================================================

    def method_missing(method, *args, &block)
      @data.send(method, *args)
    end

    def to_s
      parts = ["BlueJay Parsed Response:"]
      parts += ["  Successful?:   #{successful?}"]
      parts += ["  Rate-limited?: #{rate_limited?}"]
      parts += ["    Remaining:   #{rate_limit_remaining}"] if rate_limit_remaining
      parts += ["    Reset time:  #{rate_limit_reset_time}"] if rate_limit_reset_time
      parts += ["  Data:          ", data]
      parts += ["  Errors:        ", errors.inspect] if !successful?

      parts.join("\n") + "\n"
    end

    private

    def parse_response(response)
      @parser.parse_response(self, response)
    end

    def options
      @options
    end
  end
end