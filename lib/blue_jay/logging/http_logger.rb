require 'logger'
require 'multipartable'

module BlueJay
  module Logging
    # a class for use as the http_debug_logger
    # for logging raw request/response data...
    class HttpLogger < Logger
      attr_reader :data

      def initialize
        super(@data = StringIO.new)
      end

      def read
        data.string.delete("\000")
      end

      def reset!
        data.flush
        data.truncate(0)

        self
      end
    end
  end
end