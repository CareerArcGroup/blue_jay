require 'logger'

module BlueJay
  module Logging
    class GelfFormatter < ::Logger::Formatter
      def call(severity, timestamp, progname, msg)
        case msg
        when BlueJay::Trace
          hashify_trace(severity, timestamp, progname, msg)
        else
          msg
        end
      end

      private

      def hashify_trace(severity, timestamp, progname, trace)
        {
          short_message: "#{severity} #{progname}: #{trace.summary}",
          level: severity,
          timestamp: timestamp,
          _trace_id: trace.id,
          _request_method: trace.request.method.to_s.upcase,
          _request_uri: trace.request.uri.to_s,
          _request_body: remove_binary(trace.request.body).inspect,
          _request_headers: trace.request.headers.inspect,
          _response_successful: trace.response.successful?.to_s,
          _response_code: trace.response.code,
          _response_message: trace.response.message,
          _response_headers: trace.response.headers.inspect,
          _response_data: trace.response.data.inspect,
          _response_errors: trace.response.errors.inspect,
          _response_rate_limited: trace.response.rate_limited?.to_s,
          _response_rate_limit_remaining: trace.response.rate_limit_remaining,
          _response_rate_limit_reset_time: trace.response.rate_limit_reset_time,
          _http_log: trace.log,
          _duration: trace.duration
        }
      end

      def remove_binary(obj)
        if obj && obj.is_a?(Hash)
          obj.inject({}) do |memo, (k,v)|
            if [:banner, :image].include?(k)
              omission_string
            else
              memo.update(k => remove_binary(v))
            end
          end
        elsif obj.respond_to?(:to_io) || obj.is_a?(UploadIO)
          omission_string
        else
          obj
        end
      end

      def omission_string
        "[...snipped by BlueJay::Logging::GelfFormatter for brevity...]"
      end
    end
  end
end
