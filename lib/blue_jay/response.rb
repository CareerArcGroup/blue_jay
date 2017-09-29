
require 'blue_jay/exceptions/rate_limit_exception'

module BlueJay
  class Response

    def initialize(id, response, parser, options={})
      @id = id
      @parser = parser
      @options = options
      @raw_response = response

      parse_response(response)
    end

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def id; @id end
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

    def code
      raw_response.code
    end

    def message
      raw_response.message
    end

    def headers
      raw_response.each_header.inject({}) do |memo,(k,v)|
        memo.update(k => v)
      end
    end

    # ============================================================================
    # Misc and Private Methods
    # ============================================================================

    def method_missing(method, *args, &block)
      @data.send(method, *args)
    end

    def to_s
      "#{code} - #{message} #{data unless successful?}"
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