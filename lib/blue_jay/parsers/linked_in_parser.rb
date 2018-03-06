module BlueJay
  class LinkedInParser < Parser

    RATE_LIMITED_MESSAGE = "Throttle limit for calls to this resource is reached."

    def self.parse_response(response, data)
      super(response, data)

      # handle the case of the empty or missing response...
      return if data.nil? || !data.kind_of?(Net::HTTPResponse)

      response.status = data.class

      begin

        # try to parse the response as JSON (unless @raw_data)...
        response.data = (response.raw_data? || data.body.length < 2) ? data.body : JSON.parse(data.body)
        response.errors = response.data if response.data.is_a?(Hash) && response.data['errorCode'] != nil

        # errors can be detected by the status code (not Success) or
        # by the presence of an "errors" object in the de-serialized response...
        response.successful = (data.kind_of?(Net::HTTPSuccess) && response.errors.nil?)

        # check for rate-limited response
        # https://developer.linkedin.com/docs/guide/v2/error-handling
        response.rate_limited = true if data.code == '429'

        # linkedin is inconsistent with the above documentation,
        # and can also return a 403 error we check the message as well.
        response.rate_limited = true if response.data.is_a?(Hash) && response.data['message'] == RATE_LIMITED_MESSAGE

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