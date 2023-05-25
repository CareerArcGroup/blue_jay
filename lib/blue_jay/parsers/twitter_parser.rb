module BlueJay
  class TwitterParser < Parser

    RATE_LIMIT_HEADER ="X-Rate-Limit-Limit"
    RATE_LIMIT_REMAINING_HEADER = "X-Rate-Limit-Remaining"
    RATE_LIMIT_RESET_HEADER = "X-Rate-Limit-Reset"

    def self.parse_response(response, data)
      super(response, data)

      # handle the case of the empty or missing response...
      return if data.nil? || !data.kind_of?(Net::HTTPResponse)

      reset_time_ticks = data[RATE_LIMIT_RESET_HEADER]

      response.status = data.class
      response.rate_limited = data.code == '429' # too many requests
      response.rate_limit = data[RATE_LIMIT_HEADER]
      response.rate_limit_remaining = data[RATE_LIMIT_REMAINING_HEADER]
      response.rate_limit_reset_time = (reset_time_ticks) ? Time.at(reset_time_ticks.to_i) : nil

      begin
        if response.status != Net::HTTPNoContent
          # try to parse the response as JSON (unless @raw_data)...
          response.data = (response.raw_data? || data.body.length < 2) ? data.body : JSON.parse(data.body)
          response.errors = response.data['errors'] if response.data.is_a?(Hash)
          response.data['error'] ||= response.errors.map { |e| e['message'] }.join(',') if response.errors
        end
        # errors can be detected by the status code (not Success) or
        # by the presence of an "errors" object in the de-serialized response...
        response.successful = (data.kind_of?(Net::HTTPSuccess) && response.errors.nil?)

      rescue JSON::ParserError => e
        # if we can't parse the response, return
        # a json response anyway that gives us information
        # about the response in a well structured manner...
        response.data = data.body
        response.successful = false
        response.errors = e
      end

    end

  end
end