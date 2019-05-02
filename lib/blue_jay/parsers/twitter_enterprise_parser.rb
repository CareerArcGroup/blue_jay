# frozen_string_literal: true

module BlueJay
  class TwitterEnterpriseParser < TwitterParser
    MINUTE_RATE_LIMIT_HEADER = 'x-per-minute-limit'
    MINUTE_RATE_LIMIT_REMAINING_HEADER = 'x-per-minute-remaining'
    MINUTE_RATE_LIMIT_RESET_HEADER = 'x-per-minute-reset'
    SECOND_RATE_LIMIT_HEADER = 'x-per-second-limit'
    SECOND_RATE_LIMIT_REMAINING_HEADER = 'x-per-second-remaining'
    SECOND_RATE_LIMIT_RESET_HEADER = 'x-per-second-reset'

    class << self
      def parse_response(response, data)
        super(response, data)

        if data[MINUTE_RATE_LIMIT_REMAINING_HEADER].to_i.zero?
          response.rate_limited = true
          response.rate_limit_remaining = data[MINUTE_RATE_LIMIT_REMAINING_HEADER].to_i
          response.rate_limit_reset_time = Time.at(data[MINUTE_RATE_LIMIT_RESET_HEADER].to_i)
          response.rate_limit_sleep_seconds = [[data[MINUTE_RATE_LIMIT_RESET_HEADER].to_i - Time.now.utc.to_i, 30].max, 60].min
        elsif data[SECOND_RATE_LIMIT_REMAINING_HEADER].to_i.zero?
          response.rate_limited = true
          response.rate_limit_remaining = data[SECOND_RATE_LIMIT_REMAINING_HEADER].to_i
          response.rate_limit_reset_time = Time.at(data[SECOND_RATE_LIMIT_RESET_HEADER].to_i)
          response.rate_limit_sleep_seconds = 2
        end
      end
    end
  end
end
