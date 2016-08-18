require 'logger'
require 'multipartable'

module BlueJay
  module Logging
    # a class for use as the http_debug_logger
    # for logging raw request/response data...
    class HttpLogger < Logger
      attr_reader :data

      FILTER_STRING = "[FILTERED]".freeze

      def initialize
        super(@data = StringIO.new)
      end

      def <<(message)
        filtered = filter_message(message)
        super(filtered) unless filtered.nil?
      end

      def read
        data.string.delete("\000")
      end

      def reset!
        data.flush
        data.truncate(0)

        filtered_terms = []

        self
      end

      def filtered_terms
        @filtered_terms ||= []
      end

      def filtered_terms=(value)
        @filtered_terms = value
      end

      def filter_body?
        @filter_body
      end

      def filter_body=(value)
        @filter_body = value
      end

      private

      def filter_message(message)
        filtered_terms.each do |filtered_term|
          case filtered_term
          when Regexp
            message.scan(filtered_term).each do |match|
              message.gsub!(match[0], FILTER_STRING)
            end
          else
            message.gsub!(filtered_term.to_s, FILTER_STRING)
          end
        end

        filter_multipart(message)
      end

      def filter_multipart(message)
        if omitting?
          if contains_multipart_epilogue?(message)
            stop_omitting!
          end
          nil
        elsif contains_multipart_boundry?(message)
          omit!
          "\"--#{multipart_boundary} #{omission_string} --#{multipart_boundary}--\\r\\n\\r\\n\""
        else
          message
        end
      end

      def contains_multipart_boundry?(message)
        message.include?("--#{multipart_boundary}")
      end

      def contains_multipart_epilogue?(message)
        message.include?("--#{multipart_boundary}--")
      end

      def multipart_boundary
        Multipartable::DEFAULT_BOUNDARY
      end

      def omission_string
        "[...snipped by BlueJay::Logging::HttpLogger for brevity...]"
      end

      def omitting?
        @omitting
      end

      def omit!
        @omitting = true
      end

      def stop_omitting!
        @omitting = false
      end
    end
  end
end