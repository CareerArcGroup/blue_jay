module BlueJay
  class InstagramParser < Parser
    def self.parse_response(response, data)
      super(response, data)

      # handle the case of the empty or missing response...
      return if data.nil? || !data.kind_of?(Net::HTTPResponse)

      response.status = data.class

      begin
        # try to parse the response as JSON (unless @raw_data)...
        response.data = (response.raw_data? || data.body.length < 2) ? data.body : JSON.parse(data.body)

        unless response.data.is_a?(Hash) && metadata = response.data["meta"]
          response.successful = data.kind_of?(Net::HTTPSuccess)
          return
        end

        response.successful = (metadata["code"] == 200)
        response.errors = metadata unless response.successful?

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