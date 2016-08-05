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
        self
      end

      private

      def filter_message(message)
        return message if BlueJay.trace?

        if omitting?
          if contains_multipart_epilogue?(message)
            stop_omitting!
          end
          nil
        elsif contains_multipart_boundry?(message)
          omit!
          "\"--#{multipart_boundary} #{omission_string} --#{multipart_boundary}--\\r\\n\\r\\n\""
        elsif contains_filtered_parameter?(message)
          remove_filtered_parameters(message)
        else
          message
        end
      end

      def remove_filtered_parameters(message)
        message.gsub(/(image|banner)=[^&"]+/, "\\1=#{omission_string}")
      end

      def contains_filtered_parameter?(message)
        message.include?("image=") || message.include?("banner=")
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