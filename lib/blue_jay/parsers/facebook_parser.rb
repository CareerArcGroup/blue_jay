module BlueJay
  class FacebookParser < Parser

    RATE_LIMITED_CODES = [4, 32, 17, 341]

    def self.parse_response(response, data)
      super(response, data)

      # handle the case of the empty or missing response...
      return if data.nil? || !data.kind_of?(Net::HTTPResponse)

      response.status = data.class

      begin

        # try to parse the response as JSON (unless @raw_data)...
        response.data = (response.raw_data? || data.body.length < 2) ? data.body : JSON.parse(data.body)
        response.errors = response.data['error'] if response.data.is_a?(Hash) && response.data['error'] != nil

        # check for rate-limited response
        response.rate_limited = true if response.errors != nil && RATE_LIMITED_CODES.include?(response.errors['code'])

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